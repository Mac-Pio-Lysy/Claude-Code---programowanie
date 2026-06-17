// ── STATE ──
let guests = [];
let tables = [];
let pairs  = [];

// ── KONFIGURACJA APLIKACJI (edytowalne stałe napisy, wspólne dla wszystkich) ──
const DEFAULT_APP_CONFIG = {
  eventName:      'Impreza Weselna Piotra i Patrycji',
  subtitle:       'Panel organizacji wesela',
  displayNames:   'Patrycji i Piotra',
  ceremonyPlace:  '',
  receptionPlace: '',
  menuOptions:    ['Danie mięsne', 'Danie rybne', 'Wegetariańskie', 'Wegańskie', 'Dla dziecka'],
};

// Aplikacja jest na stałe aplikacją weselną — ikona nagłówka i tytuł odliczania.
const WEDDING_ICON = '💍';
const WEDDING_HERO_TITLE = 'Do Waszego Ślubu';
// Imiona Osoby 1/2 (podział kosztów) trzymane są w budgetData.coupleNames,
// a data ślubu w globalnym weddingDate — Konfiguracja edytuje te same źródła.
let appConfig = Object.assign({}, DEFAULT_APP_CONFIG);

let _stateReady = false;    // true dopiero po udanym wczytaniu — chroni przed nadpisaniem danych pustym stanem
let nextGuestId = 1;
let nextTableId = 1;
let nextPairId  = 1;
let draggedGuestId = null;
let tvGuestDrag    = null; // { guestId, srcTableId } — table-view seat drag
let pairingGuestId = null;
let currentView          = 'dashboard';
let currentBudgetTab     = 'summary';
let currentTablesTab     = 'plan';   // podzakładka w „Stoły i goście": 'plan' | 'card' | 'summary'
let guestCardViewMode    = 'list';   // widok Kartoteki Gości: 'list' | 'cols'
let guestSummaryFilters  = { search: '', status: 'all', menu: 'all', diet: 'all', transport: 'all', accom: 'all' };
let paymentsSourceFilter = 'all';

let expenseFilters = { status: 'all', person: 'all', category: 'all' };
let expenseSort    = { field: null, dir: 'asc' };
let expenseOrder   = [];
let expTileDragId  = null;

let staffTables      = [];
let nextStaffTableId = 1;
let roomStaffDrag    = null;

const PAY_SOURCES = {
  sala:      { label: 'Sala',             icon: '&#127968;', color: '#1a56db', light: '#e8f1fd' },
  expenses:  { label: 'Wydatki',          icon: '&#128203;', color: '#059669', light: '#ecfdf5' },
  honeymoon: { label: 'Podr&#243;&#380; poślubna', icon: '&#9992;',   color: '#7c3aed', light: '#f5f3ff' },
};
let roomName = 'Sala weselna';
let roomDrag      = null; // { tableId, startMouseX, startMouseY, startPosX, startPosY }
let roomGuestDrag = null; // { guestId, srcTableId }

// ── PLAN SALI: wymiary i własne elementy ──
let roomMeta = { widthM: 0, lengthM: 0, tableDiameterM: 0 }; // wymiary sali i średnica stołów (metry)
let roomElements = [];           // { id, name, type, wM, lM, posX, posY, rotation }
let nextRoomElementId = 1;
let roomElementDrag = null;      // { id, startMouseX, startMouseY, startPosX, startPosY }
let roomElementResize = null;    // { id, corner, startMouseX, startMouseY, startFpW, startFpH, startPosX, startPosY, ppm, swap }
let roomTableResize = null;      // zmiana rozmiaru stołu z poziomu planu sali
let selectedRoomElementId = null;
let isEditing = false;           // tryb edycji „Plan sali" (false = podgląd, true = edycja)
let roomEditSnapshot = null;     // kopia stanu sali do funkcji „Anuluj"
let isFullscreen = false;        // tryb pełnoekranowy „Plan sali"
let roomFsScale = 1;             // bieżąca skala dopasowania (fit-to-screen)
let roomGridOn = false;          // siatka rozmiarów (snap) w planie sali
const ROOM_GRID = 20;            // krok siatki w px
let roomScale = 1;               // bieżąca skala EFEKTYWNA kanwy (dopasowanie × zoom) — używana przez logikę przeciągania
// ── PLAN SALI: ZOOM (powiększanie/oddalanie) i PAN (przesuwanie widoku) ──
// roomZoom to mnożnik powiększenia NAD bazowym dopasowaniem do ekranu (1 = dopasowane).
// Zoom i pan zmieniają wyłącznie widok (transform CSS) — nie ruszają danych ani rzeczywistych wymiarów.
let roomZoom    = 1;             // mnożnik powiększenia użytkownika (1 = „dopasuj do ekranu")
let roomPanX    = 0;             // przesunięcie widoku w poziomie (px ekranowe)
let roomPanY    = 0;             // przesunięcie widoku w pionie (px ekranowe)
let roomFitScale = 1;            // bazowa skala dopasowania sali do widoku (bez zoomu użytkownika)
let roomPan     = null;          // stan przeciągania tła (pan): { startX, startY, startPanX, startPanY }
let roomPinch   = null;          // stan gestu pinch: { startDist, startZoom }
let _roomZoomInit = false;       // czy podłączono już nasłuchy zoom/pan (kółko myszy / dotyk)
const ROOM_ZOOM_MIN = 0.4, ROOM_ZOOM_MAX = 5, ROOM_ZOOM_STEP = 1.25;

// Rozmiar „pudełka" stołu na kanwie (do wykrywania kolizji)
function _tableWrapSize(t) {
  const { tw, th } = rtTableDims(t);
  const PAD = 20;
  return { w: tw + PAD * 2, h: th + PAD * 2 + (t.isHonorTable ? 10 : 0) };
}
// Po zmianie wymiarów: dopasuj stół do sali (granice) i odsuń od kolizji (szuka wolnego miejsca).
function _fitTableInRoom(t) {
  if (!t) return;
  const sz = _tableWrapSize(t);
  const maxY = Math.max(0, (roomCanvasH || CANVAS_H) - sz.h);
  const maxX = Math.max(0, CANVAS_W - sz.w);
  // 1) musi mieścić się w sali (obrysie kanwy)
  t.posX = Math.max(0, Math.min(maxX, t.posX || 0));
  t.posY = Math.max(0, Math.min(maxY, t.posY || 0));
  // 2) nie może nachodzić na inne stoły — gdy koliduje, znajdź najbliższe wolne miejsce na siatce
  if (!_tableWouldOverlap(t.id, t.posX, t.posY)) return;
  const step = 20;
  for (let y = 0; y <= maxY; y += step) {
    for (let x = 0; x <= maxX; x += step) {
      if (!_tableWouldOverlap(t.id, x, y)) { t.posX = x; t.posY = y; return; }
    }
  }
  // brak wolnego miejsca — pozostaw w granicach sali (best effort)
  if (typeof showToast === 'function') showToast('Brak wolnego miejsca bez kolizji — sprawdź rozmieszczenie stołów.');
}
// Czy stół o danym id, ustawiony na (x,y), nachodziłby na inny stół?
function _tableWouldOverlap(movingId, x, y) {
  const mt = tables.find(t => t.id === movingId); if (!mt) return false;
  const ms = _tableWrapSize(mt);
  return tables.some(o => {
    if (o.id === movingId) return false;
    const os = _tableWrapSize(o);
    return x < o.posX + os.w && x + ms.w > o.posX && y < o.posY + os.h && y + ms.h > o.posY;
  });
}
function toggleRoomGrid() {
  roomGridOn = !roomGridOn;
  const canvas = document.getElementById('roomCanvas');
  if (canvas) canvas.classList.toggle('room-grid-on', roomGridOn);
  const btn = document.getElementById('roomGridBtn');
  if (btn) btn.classList.toggle('active', roomGridOn);
}

const CANVAS_W = 1400;
const CANVAS_H = 760;
let roomCanvasH = CANVAS_H;      // dynamiczna wysokość kanwy (gdy podano wymiary sali)

// Skala: ile pikseli przypada na 1 metr (na podstawie szerokości sali; domyślnie 40)
function roomPxPerMeter() {
  return roomMeta.widthM > 0 ? (CANVAS_W / roomMeta.widthM) : 40;
}

const CAT_CLASS = {
  'Państwo Młodzi': 'av-mlodzi',
  'Świadkowie':     'av-swiadkowie',
  'Rodzice':        'av-rodzice',
  'Rodzina':        'av-rodzina',
  'Znajomi':        'av-znajomi',
  'Praca':          'av-praca',
};

// ── UTILS ──
function esc(s) {
  return String(s)
    .replace(/&/g,'&amp;').replace(/</g,'&lt;')
    .replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

function safeUrl(url) {
  if (!url) return null;
  return (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('/')) ? url : null;
}

function initials(g) {
  return ((g.firstName||'').charAt(0) + (g.lastName||'').charAt(0)).toUpperCase() || '?';
}

function fullName(g) {
  return [g.firstName, g.lastName].filter(Boolean).join(' ');
}

function avatarHtml(g, cls = 'avatar') {
  const catCls = CAT_CLASS[g.category] || 'av-default';
  const img = safeUrl(g.photo)
    ? `<img src="${esc(g.photo)}" alt="${esc(initials(g))}">`
    : '';
  return `<div class="${cls} ${catCls}">${esc(initials(g))}${img}</div>`;
}

let toastTimer;
function showToast(msg) {
  const el = document.getElementById('toast');
  el.textContent = msg;
  el.classList.add('show');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => el.classList.remove('show'), 2600);
}

function renderAll() {
  renderGuests();
  renderTables();
  renderStaffTables();
  renderPairs();
  updateStats();
  if (currentView === 'room'          && !roomDrag) renderRoom();
  if (currentView === 'budget')        renderBudget();
  if (currentView === 'dashboard')     renderDashboard();
  if (currentView === 'schedule')      renderSchedule();
  if (currentView === 'tasks')         renderTasks();
  if (currentView === 'vendors')       renderVendors();
  if (currentView === 'rsvp')          renderRsvpPanel();
  if (currentView === 'gifts')         renderGifts();
  if (currentView === 'transport')     renderTransport();
  if (currentView === 'accommodation') renderAccommodation();
  if (currentView === 'budget')        renderPayments();
  if (currentView === 'tables' && currentTablesTab === 'card')    renderGuestCard();
  if (currentView === 'tables' && currentTablesTab === 'summary') renderGuestSummary();
  saveState();
}

// ── GUESTS ──
// Wypełnia listę „Dieta / menu" opcjami ze słownika menu z Konfiguracji
function _populateGuestMenuSelect() {
  const sel = document.getElementById('guestDiet');
  if (!sel) return;
  const opts = Array.isArray(appConfig.menuOptions) ? appConfig.menuOptions : [];
  sel.innerHTML = '<option value="">— wybierz —</option>' +
    opts.map(o => `<option value="${esc(o)}">${esc(o)}</option>`).join('');
}

// Pokaż/ukryj pola osoby towarzyszącej
function _toggleCompanionRow() {
  const cb  = document.getElementById('guestHasCompanion');
  const row = document.getElementById('companionRow');
  if (row) row.style.display = (cb && cb.checked) ? '' : 'none';
}

// Blokuj „Dodaj gościa" dopóki nie wpisano przynajmniej imienia
function _validateGuestForm() {
  const first = (document.getElementById('guestFirstName')?.value || '').trim();
  const btn   = document.getElementById('guestSubmitBtn');
  if (btn) btn.disabled = !first;
}

// Czyści formularz do stanu początkowego
function _resetGuestForm() {
  const v = (id, val) => { const el = document.getElementById(id); if (el) el.value = val; };
  const c = (id, val) => { const el = document.getElementById(id); if (el) el.checked = val; };
  v('guestFirstName', ''); v('guestLastName', ''); v('guestPhoto', '');
  v('guestInvitedBy', ''); v('guestWitness', ''); v('guestCategory', 'Rodzina'); v('guestGender', 'K');
  v('companionFirstName', ''); v('companionLastName', '');
  c('guestHasCompanion', false); c('guestNeedsAccommodation', false);
  _populateGuestMenuSelect();
  v('guestDiet', '');
  const hint = document.getElementById('coupleInfoHint'); if (hint) hint.textContent = '';
  _toggleCompanionRow();
  _validateGuestForm();
}

function openGuestForm() {
  _resetGuestForm();
  const modal = document.getElementById('guestFormModal');
  if (modal) modal.style.display = 'flex';
  setTimeout(() => document.getElementById('guestFirstName')?.focus(), 50);
}

function closeGuestForm(e) {
  if (e && e.target !== e.currentTarget) return;
  closeGuestFormDirect();
}

function closeGuestFormDirect() {
  const modal = document.getElementById('guestFormModal');
  if (modal) modal.style.display = 'none';
}

// Państwo Młodzi (Para Młoda) — dokładnie DWIE osoby
function _coupleMembers() { return guests.filter(g => (g.category || '') === 'Państwo Młodzi'); }
function showCoupleInfo() {
  const m = _coupleMembers();
  const hint = document.getElementById('coupleInfoHint');
  let msg;
  if (!m.length) msg = 'Nie oznaczono jeszcze Pary Młodej (kategoria „Państwo Młodzi").';
  else msg = '👑 Para Młoda: ' + m.map(g => fullName(g) || 'gość').join(' & ') + (m.length < 2 ? ' (brakuje 1 osoby)' : '');
  if (hint) hint.textContent = msg;
  showToast(msg);
}
// Wspólny szablon nowego gościa (domyślne pola)
function _newGuestBase() {
  return {
    diet:'standard', dietOther:'', hasCompanion:false, companionName:'',
    needsAccommodation:false, vehicleId:null, ownTransport:false, hotelId:null,
    accommodationStatus:null, tableId:null, seatIndex:null, pairId:null,
    menuChoice:'', preferences:'', allergies:'', cardNotes:'',
  };
}

function addGuest() {
  const first = document.getElementById('guestFirstName').value.trim();
  const last  = document.getElementById('guestLastName').value.trim();
  if (!first) { showToast('Podaj imię gościa'); document.getElementById('guestFirstName')?.focus(); return; }

  const category = document.getElementById('guestCategory').value;
  // Para Młoda = dokładnie dwie osoby (płeć bez znaczenia) — blokada trzeciej
  if (category === 'Państwo Młodzi' && _coupleMembers().length >= 2) {
    showToast('Para Młoda to dokładnie dwie osoby — nie można dodać trzeciej.');
    return;
  }

  const hasCompanion = !!document.getElementById('guestHasCompanion')?.checked;
  const compFirst = (document.getElementById('companionFirstName')?.value || '').trim();
  const compLast  = (document.getElementById('companionLastName')?.value || '').trim();
  const namedCompanion = hasCompanion && (compFirst || compLast);  // ma dane → osobny gość
  const invitedBy = document.getElementById('guestInvitedBy')?.value || null;

  guests.push(Object.assign(_newGuestBase(), {
    id: nextGuestId++,
    firstName:  first,
    lastName:   last,
    category,
    gender:     document.getElementById('guestGender').value,
    photo:      document.getElementById('guestPhoto').value.trim() || null,
    invitedBy,
    witness:    document.getElementById('guestWitness')?.value || null,
    // osoba towarzysząca: gdy podano dane → dodajemy ją jako osobnego gościa (niżej),
    // gdy zaznaczono bez danych → zostaje jako znacznik „+1" na tym gościu
    hasCompanion: hasCompanion && !namedCompanion,
    menuChoice: document.getElementById('guestDiet')?.value || '',
  }));

  // Osoba towarzysząca z danymi → od razu osobny gość na liście
  if (namedCompanion) {
    guests.push(Object.assign(_newGuestBase(), {
      id: nextGuestId++,
      firstName: compFirst,
      lastName:  compLast,
      // towarzysząca nie może być Parą Młodą
      category:  category === 'Państwo Młodzi' ? 'Znajomi' : category,
      gender:    'K',
      photo:     null,
      invitedBy,
      witness:   null,
    }));
  }

  _resetGuestForm();
  closeGuestFormDirect();
  renderGuests();
  updateStats();
  saveState();
  const extra = namedCompanion ? ` (+ ${[compFirst, compLast].filter(Boolean).join(' ')})` : '';
  showToast(`${first}${last ? ' ' + last : ''} dodany/a do listy${extra}`);
}

function removeGuest(guestId) {
  const g = guests.find(x => x.id === guestId);
  if (!g) return;
  if (g.tableId !== null) _unsetSeat(g);
  if (g.pairId  !== null) _breakPair(g.pairId, false);
  // Spójność danych: usuń powiązania gościa w pozostałych sekcjach, by nie zostawały „osierocone" odwołania
  vehicles.forEach(v => { if (Array.isArray(v.guestIds)) v.guestIds = v.guestIds.filter(id => id !== guestId); });
  giftsForGuests.forEach(it => { if (Array.isArray(it.guestIds)) it.guestIds = it.guestIds.filter(id => id !== guestId); });
  rsvpEntries = rsvpEntries.filter(e => e.guestId !== guestId);
  guests = guests.filter(x => x.id !== guestId);
  renderAll();
}

function removeGuestFromTable(guestId) {
  const g = guests.find(x => x.id === guestId);
  if (!g || g.tableId === null) return;
  _unsetSeat(g);
  renderAll();
  showToast('Gość usunięty ze stołu');
}

function _unsetSeat(g) {
  const t = tables.find(x => x.id === g.tableId);
  if (t && g.seatIndex !== null) t.seatsData[g.seatIndex] = null;
  g.tableId = null;
  g.seatIndex = null;
}

function _guestMoveBtn(g) {
  const available = tables.filter(t => {
    if (t.id === g.tableId) return false;
    return t.seatsData.filter(x => x !== null).length < t.seats;
  });
  if (!available.length) return '';
  const opts = available.map(t => {
    const free = t.seats - t.seatsData.filter(x=>x!==null).length;
    return `<button class="move-table-opt" onclick="moveGuestToTable(${g.id},${t.id})">${esc(t.name)} <span class="move-free">${free} wolnych</span></button>`;
  }).join('');
  return `<div class="move-wrap" id="move-wrap-${g.id}">
    <button class="btn btn-sm btn-move" onclick="toggleMoveDropdown(${g.id})">&#8635; Przenieś</button>
    <div class="move-dropdown" id="move-dd-${g.id}" style="display:none">${opts}</div>
  </div>`;
}
function toggleMoveDropdown(gId) {
  document.querySelectorAll('.move-dropdown').forEach(el => {
    if (el.id !== 'move-dd-'+gId) el.style.display = 'none';
  });
  const dd = document.getElementById('move-dd-'+gId);
  if (dd) dd.style.display = dd.style.display === 'none' ? 'block' : 'none';
}
function moveGuestToTable(guestId, tableId) {
  _assignToTable(tableId, guestId);
}
document.addEventListener('click', e => {
  if (!e.target.closest('.move-wrap')) {
    document.querySelectorAll('.move-dropdown').forEach(el => el.style.display = 'none');
  }
});

function setGuestQuickFilter(val) {
  const el = document.getElementById('filterQuick');
  if (el) el.value = val;
  document.querySelectorAll('#gfRow1 .gf-btn').forEach(b => {
    b.classList.toggle('gf-active', b.dataset.value === val);
  });
  renderGuests();
}

function setGuestCatFilter(val) {
  const el = document.getElementById('filterCat');
  if (el) el.value = val;
  document.querySelectorAll('#gfRow2 .gf-btn').forEach(b => {
    b.classList.toggle('gf-active', b.dataset.value === val);
  });
  renderGuests();
}

function renderGuests() {
  const quickFilter = document.getElementById('filterQuick')?.value ?? '';
  const catFilter   = document.getElementById('filterCat')?.value   ?? '';

  const filtered = guests.filter(g => {
    if (quickFilter === 'assigned'   && g.tableId === null)  return false;
    if (quickFilter === 'unassigned' && g.tableId !== null)  return false;
    if (quickFilter === 'groom'      && g.invitedBy !== 'groom') return false;
    if (quickFilter === 'bride'      && g.invitedBy !== 'bride') return false;
    if (catFilter && g.category !== catFilter) return false;
    return true;
  });

  const container = document.getElementById('guestList');
  if (!container) return;
  if (!filtered.length) {
    container.innerHTML = '<div class="empty-list">Brak gości spełniających kryteria.</div>';
    return;
  }

  container.innerHTML = filtered.map(g => {
    const table     = g.tableId !== null ? tables.find(t => t.id === g.tableId) : null;
    const pair      = g.pairId  !== null ? pairs.find(x => x.id === g.pairId) : null;
    const partner   = pair ? _pairPartner(g) : null;
    const isTarget  = pairingGuestId !== null && pairingGuestId !== g.id && g.pairId === null;
    const isChooser = pairingGuestId === g.id;

    const pairBtn = g.pairId !== null
      ? `<button class="btn btn-sm btn-danger" onclick="unpairGuest(${g.id})" title="Rozłącz parę">&#128148;</button>`
      : isChooser
        ? `<button class="btn btn-sm btn-pair active" onclick="cancelPairing()" title="Anuluj">✕</button>`
        : pairingGuestId === null
          ? `<button class="btn btn-sm btn-pair" onclick="startPairing(${g.id})" title="Połącz w parę">&#10084;</button>`
          : '';

    // Skrót pary — zawsze widoczny przy gościu (bez rozwijania opcji)
    const pairChip = partner
      ? `<span class="guest-pair-chip" title="${esc(pairTypeInfo(pair).label)}: ${esc(fullName(partner))}">${pairTypeInfo(pair).icon}&nbsp;${esc(partner.firstName || initials(partner))}</span>`
      : '';

    return `<div class="guest-item${g.tableId!==null?' assigned':''}${isTarget?' pairing-target':''}"
         id="guest-item-${g.id}"
         draggable="true"
         ondragstart="onGuestDragStart(event,${g.id})"
         ondragend="onGuestDragEnd()"
         ${isTarget ? `onclick="completePairing(${g.id})"` : ''}>
      <div class="guest-top-row"${!isTarget ? ` onclick="toggleGuestCard(${g.id})"` : ''}>
        ${avatarHtml(g)}
        <div class="guest-info">
          <div class="guest-name-row">
            <span class="guest-name">${esc(fullName(g))}</span>
            ${pairChip}
          </div>
          <div class="guest-meta">
            <span class="badge badge-cat">${esc(g.category)}</span>
            ${table   ? `<span class="badge badge-seated">&#10003; ${esc(table.name)}</span>` : ''}
            ${g.invitedBy === 'groom' ? `<span class="badge badge-groom">&#129309; Pan Młody</span>` : ''}
            ${g.invitedBy === 'bride' ? `<span class="badge badge-bride">&#128144; Panna Młoda</span>` : ''}
            ${g.witness === 'witness_groom' ? `<span class="badge badge-witness-g">&#9679; Świadek</span>` : ''}
            ${g.witness === 'witness_bride' ? `<span class="badge badge-witness-b">&#9679; Świadkowa</span>` : ''}
            ${g.diet && g.diet !== 'standard' ? `<span class="badge badge-diet">${dietLabel(g.diet, g.dietOther)}</span>` : ''}
            ${g.needsAccommodation ? `<span class="badge badge-accom">&#127968;</span>` : ''}
            ${g.hasCompanion ? `<span class="badge badge-companion" title="Osoba towarzysząca${g.companionName ? ': ' + esc(g.companionName) : ''}">&#128101; +1${g.companionName ? ' ' + esc(g.companionName) : ''}</span>` : ''}
          </div>
        </div>
        ${!isTarget ? `<button class="guest-expand-btn" type="button" aria-label="Pokaż opcje" title="Pokaż opcje">&#9660;</button>` : ''}
      </div>
      <div class="guest-actions">
        <button class="btn btn-sm btn-edit" onclick="openEditModal('guest',${g.id})" title="Edytuj gościa">&#9998; Edytuj</button>
        ${pairBtn}
        ${_guestMoveBtn(g)}
        ${g.tableId!==null ? `<button class="btn btn-sm btn-danger" onclick="removeGuestFromTable(${g.id})" title="Usuń ze stołu">&#10006; Ze stołu</button>` : ''}
        <button class="btn btn-sm btn-danger" onclick="removeGuest(${g.id})" title="Usuń gościa">&#128465;</button>
        <label class="guest-accom-toggle" title="Potrzebuje noclegu">
          <input type="checkbox" ${g.needsAccommodation ? 'checked' : ''} onchange="updateGuestField(${g.id},'needsAccommodation',this.checked)">
          <span>&#127968; Nocleg</span>
        </label>
      </div>
    </div>`;
  }).join('');
}

function toggleGuestCard(id) {
  const item = document.getElementById('guest-item-' + id);
  if (!item) return;
  const expanded = item.classList.toggle('expanded');
  const btn = item.querySelector('.guest-expand-btn');
  if (btn) btn.innerHTML = expanded ? '&#9650;' : '&#9660;';
}

// ── PAIRING ──
// Typy par — używane w legendzie i przy gościu
const PAIR_TYPES = {
  romantic: { icon: '\u{1F491}', label: 'Para' },                 // 💑
  parents:  { icon: '\u{1F46A}', label: 'Rodzice' },              // 👪
  plusone:  { icon: '\u{1F9D1}‍\u{1F91D}‍\u{1F9D1}', label: 'Z osobą towarzyszącą' }, // 🧑‍🤝‍🧑
};
function pairTypeKey(p) { return (p && PAIR_TYPES[p.type]) ? p.type : 'romantic'; }
function pairTypeInfo(p) { return PAIR_TYPES[pairTypeKey(p)]; }
function setPairType(pairId, type) {
  const p = pairs.find(x => x.id === pairId);
  if (!p || !PAIR_TYPES[type]) return;
  p.type = type;
  renderAll();
}

function startPairing(guestId) {
  pairingGuestId = guestId;
  const g = guests.find(x => x.id === guestId);
  document.getElementById('pairingMsg').textContent = `Wybierz parę dla: ${fullName(g)}`;
  document.getElementById('pairingOverlay').style.display = 'block';
  renderGuests();
}

function cancelPairing() {
  pairingGuestId = null;
  document.getElementById('pairingOverlay').style.display = 'none';
  renderGuests();
}

function completePairing(targetId) {
  if (!pairingGuestId || pairingGuestId === targetId) return;
  const g1 = guests.find(x => x.id === pairingGuestId);
  const g2 = guests.find(x => x.id === targetId);
  if (!g1 || !g2 || g2.pairId !== null) return;
  const pair = { id: nextPairId++, g1: g1.id, g2: g2.id, type: 'romantic' };
  pairs.push(pair);
  g1.pairId = pair.id;
  g2.pairId = pair.id;
  cancelPairing();
  renderAll();
  showToast(`${fullName(g1)} &#10084; ${fullName(g2)} – para!`);
}

function unpairGuest(guestId) {
  const g = guests.find(x => x.id === guestId);
  if (!g || g.pairId === null) return;
  _breakPair(g.pairId, true);
}

function _breakPair(pairId, rerender) {
  const pair = pairs.find(x => x.id === pairId);
  if (!pair) return;
  [pair.g1, pair.g2].forEach(id => {
    const g = guests.find(x => x.id === id);
    if (g) g.pairId = null;
  });
  pairs = pairs.filter(x => x.id !== pairId);
  if (rerender) renderAll();
}

function _pairPartner(g) {
  const pair = pairs.find(x => x.id === g.pairId);
  if (!pair) return null;
  return guests.find(x => x.id === (pair.g1 === g.id ? pair.g2 : pair.g1)) || null;
}

function renderPairs() {
  const container = document.getElementById('pairsList');
  if (!container) return;
  updatePairsCount();
  if (!pairs.length) {
    container.innerHTML = '<div class="empty-list">Brak par.<br>Kliknij &#10084; przy gościu.</div>';
    return;
  }
  container.innerHTML = pairs.map(p => {
    const g1 = guests.find(x => x.id === p.g1);
    const g2 = guests.find(x => x.id === p.g2);
    if (!g1 || !g2) return '';
    const ti = pairTypeInfo(p);
    const opts = Object.entries(PAIR_TYPES).map(([k, v]) =>
      `<option value="${k}"${pairTypeKey(p) === k ? ' selected' : ''}>${v.icon} ${v.label}</option>`).join('');
    return `<div class="pair-item">
      <div class="pair-type-badge">${ti.icon} ${esc(ti.label)}</div>
      <div class="pair-avatars">
        ${avatarHtml(g1,'avatar-sm')}
        <span class="pair-heart">${ti.icon}</span>
        ${avatarHtml(g2,'avatar-sm')}
      </div>
      <div class="pair-names">
        <span>${esc(fullName(g1))}</span>
        <span style="color:var(--pink)">&amp;</span>
        <span>${esc(fullName(g2))}</span>
      </div>
      <select class="pair-type-select" title="Typ pary" onchange="setPairType(${p.id},this.value)">${opts}</select>
      <button class="btn-unpair" onclick="unpairGuest(${g1.id})">Rozłącz</button>
    </div>`;
  }).join('');
}

// ── WYSUWANE PANELE BOCZNE (Pary + Personel) ──
// Oba mogą być otwarte jednocześnie; na desktopie układają się obok siebie.
let pairsPanelOpen = false;
let staffPanelOpen = false;
const DRAWER_WIDTH = 300; // musi odpowiadać szerokości .side-drawer w CSS

function togglePairsPanel(force) {
  pairsPanelOpen = (typeof force === 'boolean') ? force : !pairsPanelOpen;
  layoutDrawers();
}
function toggleStaffPanel(force) {
  staffPanelOpen = (typeof force === 'boolean') ? force : !staffPanelOpen;
  layoutDrawers();
}
function closeAllDrawers() {
  pairsPanelOpen = false;
  staffPanelOpen = false;
  layoutDrawers();
}

// Pozycjonuje panele i zakładki tak, by mogły współistnieć obok siebie (Pary najbardziej z prawej)
function layoutDrawers() {
  const pairs    = document.getElementById('panelPairs');
  const staff    = document.getElementById('panelStaff');
  const pairsTab = document.getElementById('pairsToggleTab');
  const staffTab = document.getElementById('staffToggleTab');
  const backdrop = document.getElementById('drawersBackdrop');
  const isMobile = window.innerWidth <= 660;
  const W = isMobile ? 0 : DRAWER_WIDTH; // na mobile panele nakładają się (brak przesunięcia)

  if (pairs) {
    pairs.classList.toggle('open', pairsPanelOpen);
    pairs.style.right = '0px';
  }
  if (staff) {
    staff.classList.toggle('open', staffPanelOpen);
    staff.style.right = (pairsPanelOpen ? W : 0) + 'px';
  }
  const totalOpen = (pairsPanelOpen ? W : 0) + (staffPanelOpen ? W : 0);
  if (pairsTab) pairsTab.style.right = totalOpen + 'px';
  if (staffTab) staffTab.style.right = totalOpen + 'px';
  if (backdrop) backdrop.classList.toggle('show', pairsPanelOpen || staffPanelOpen);
}
function updatePairsCount() {
  const el = document.getElementById('pairsCount');
  if (el) el.textContent = pairs.length || '';
}
function updateStaffCount() {
  const el = document.getElementById('staffCount');
  if (el) el.textContent = (staffTables && staffTables.length) || '';
}
// Przelicz pozycje paneli przy zmianie rozmiaru okna (np. desktop ↔ mobile)
window.addEventListener('resize', () => {
  if (pairsPanelOpen || staffPanelOpen) layoutDrawers();
});

// ── TABLES ──
function addTable() {
  const name  = (document.getElementById('tableName')?.value ?? '').trim() || `Stół ${nextTableId}`;
  const shape = document.getElementById('tableShape')?.value ?? 'round';
  const seats = parseInt(document.getElementById('tableSeats')?.value ?? '8');
  const idx = tables.length;
  const pos  = autoTablePos(idx);
  tables.push({ id: nextTableId++, name, shape, seats, seatsData: new Array(seats).fill(null), posX: pos.x, posY: pos.y, diamM: 0, rectWM: 0, rectLM: 0 });
  document.getElementById('tableName').value = '';
  renderTables();
  updateStats();
  saveState();
}

function deleteTable(tableId) {
  const t = tables.find(x => x.id === tableId);
  if (!t) return;
  t.seatsData.forEach(gId => {
    if (gId !== null) {
      const g = guests.find(x => x.id === gId);
      if (g) { g.tableId = null; g.seatIndex = null; }
    }
  });
  tables = tables.filter(x => x.id !== tableId);
  renderAll();
  showToast('Stół usunięty');
}

function changeTableSeats(tableId, delta) {
  const t = tables.find(x => x.id === tableId);
  if (!t) return;
  if (delta < 0) {
    const lastNull = t.seatsData.lastIndexOf(null);
    if (lastNull === -1) return; // wszystkie zajęte — nic nie rób
    t.seatsData.splice(lastNull, 1);
    t.seats = t.seatsData.length;
  } else {
    const newSeats = Math.min(t.seats + delta, 99);
    t.seatsData.push(...new Array(newSeats - t.seats).fill(null));
    t.seats = newSeats;
  }
  renderTables();
  updateStats();
}

function updateTableName(tableId, val) {
  const t = tables.find(x => x.id === tableId);
  if (t) { t.name = val; renderGuests(); }
}

function updateTableHonor(tableId, val) {
  const t = tables.find(x => x.id === tableId);
  if (!t) return;
  t.isHonorTable = val;
  renderTables();
  if (currentView === 'room') renderRoom();
  saveState();
}

// ── TABLE VISUAL ──
function getSeatPositions(shape, n, isHonorTable = false) {
  if (shape === 'round') {
    const cx = 100, cy = 100, r = 68;
    return Array.from({ length: n }, (_, i) => {
      const a = (i * 2 * Math.PI / n) - Math.PI / 2;
      return { x: cx + r * Math.cos(a), y: cy + r * Math.sin(a) };
    });
  }
  // rect: container 260×200, table 160×100 centered at (130,100)
  const cx = 130, cy = 100, tw = 160, th = 100, gap = 28;

  if (isHonorTable) {
    // Stół honorowy: miejsca tylko wzdłuż dolnej dłuższej krawędzi
    const pad    = 18;
    const xStart = cx - tw / 2 + pad;
    const xEnd   = cx + tw / 2 - pad;
    return Array.from({ length: n }, (_, i) => {
      const frac = n > 1 ? i / (n - 1) : 0.5;
      return { x: xStart + frac * (xEnd - xStart), y: cy + th / 2 + gap };
    });
  }

  const perimeter = 2 * (tw + th);
  return Array.from({ length: n }, (_, i) => {
    let d = (i * perimeter / n);
    let x, y;
    if      (d < tw)         { x = cx - tw/2 + d;          y = cy - th/2 - gap; }
    else if (d < tw + th)    { x = cx + tw/2 + gap;         y = cy - th/2 + (d - tw); }
    else if (d < 2*tw + th)  { x = cx + tw/2 - (d-tw-th);  y = cy + th/2 + gap; }
    else                     { x = cx - tw/2 - gap;         y = cy + th/2 - (d-2*tw-th); }
    return { x, y };
  });
}

// Tooltip miejsca przy stole — imię + najważniejsze dane gościa
// (spójnie z Listą gości / Kartoteką / Podsumowaniem gości)
function _guestSeatTitle(g) {
  const parts = [fullName(g)];
  const menu = (g.menuChoice || '').trim();
  if (menu) parts.push('Menu: ' + menu);
  if (g.diet && g.diet !== 'standard') parts.push('Dieta: ' + dietLabel(g.diet, g.dietOther));
  if ((g.allergies || '').trim()) parts.push('Alergie: ' + g.allergies.trim());
  if (g.needsAccommodation) parts.push('Nocleg');
  if (g.hasCompanion) parts.push('+1' + ((g.companionName || '').trim() ? ' ' + g.companionName.trim() : ''));
  return parts.join(' · ');
}

function renderTableVisual(t) {
  const isRound = t.shape === 'round';
  const cW = isRound ? 200 : 260;
  const cH = isRound ? 200 : 200;
  const positions = getSeatPositions(t.shape, t.seats, t.isHonorTable);

  let html = `<div class="table-visual"><div class="table-shape-container" style="width:${cW}px;height:${cH}px;position:relative;">`;

  // Table center shape
  if (isRound) {
    html += `<div class="table-center-round" style="width:82px;height:82px;">${esc(t.name)}</div>`;
  } else {
    const honorCls = t.isHonorTable ? ' table-center-honor' : '';
    html += `<div class="table-center-rect${honorCls}" style="width:160px;height:100px;">${t.isHonorTable ? '&#9733; ' : ''}${esc(t.name)}</div>`;
  }

  // Seat slots
  positions.forEach((pos, i) => {
    const gId = t.seatsData[i];
    const g   = gId !== null ? guests.find(x => x.id === gId) : null;
    const catCls = g ? (CAT_CLASS[g.category] || 'av-default') : '';
    const photoTag = g && safeUrl(g.photo)
      ? `<img class="seat-photo" src="${esc(g.photo)}" alt="${esc(initials(g))}">`
      : '';
    const label = g
      ? `<span style="font-size:0.6rem;font-weight:700;position:relative;z-index:1">${esc(initials(g))}</span>${photoTag}`
      : `<span style="font-size:0.6rem;color:#94a3b8">${i+1}</span>`;

    if (g) {
      // Occupied slot — draggable to move guest between tables
      html += `<div class="table-seat-slot occupied ${catCls}"
        style="left:${pos.x}px;top:${pos.y}px;"
        data-table="${t.id}" data-seat="${i}"
        draggable="true"
        ondragstart="tvSeatDragStart(event,${gId},${t.id})"
        ondragend="tvSeatDragEnd()"
        ondragover="onSeatDragOver(event)"
        ondragleave="onSeatDragLeave(event)"
        ondrop="onSeatDrop(event)"
        title="${esc(_guestSeatTitle(g))}">
        ${label}
      </div>`;
    } else {
      // Empty slot — receive-only drop target
      html += `<div class="table-seat-slot ${catCls}"
        style="left:${pos.x}px;top:${pos.y}px;"
        data-table="${t.id}" data-seat="${i}"
        ondragover="onSeatDragOver(event)"
        ondragleave="onSeatDragLeave(event)"
        ondrop="onSeatDrop(event)"
        title="Miejsce ${i+1}">
        ${label}
      </div>`;
    }
  });

  // Pair connectors (hearts between paired guests at same table)
  pairs.forEach(p => {
    const idx1 = t.seatsData.indexOf(p.g1);
    const idx2 = t.seatsData.indexOf(p.g2);
    if (idx1 !== -1 && idx2 !== -1) {
      const mx = (positions[idx1].x + positions[idx2].x) / 2;
      const my = (positions[idx1].y + positions[idx2].y) / 2;
      html += `<div class="pair-connector" style="left:${mx}px;top:${my}px;">&#10084;</div>`;
    }
  });

  html += `</div></div>`;
  return html;
}

function renderTables() {
  const grid = document.getElementById('tablesGrid');
  if (!tables.length) {
    grid.innerHTML = `<div class="empty-tables"><span class="empty-tables-icon">&#127869;</span>Brak stołów. Dodaj pierwszy stół powyżej.</div>`;
    return;
  }
  grid.innerHTML = tables.map(t => {
    const occupied = t.seatsData.filter(x => x !== null).length;
    const free = t.seats - occupied;
    const pct  = Math.round(occupied / t.seats * 100);
    return `<div class="table-card${free===0?' full':''}${t.isHonorTable?' honor-table-card':''}" id="table-card-${t.id}"
         ondragover="onTableDragOver(event,${t.id})"
         ondragleave="onTableDragLeave(event,${t.id})"
         ondrop="onTableDrop(event,${t.id})">
      <div class="table-header">
        <input class="table-name-input" type="text" value="${esc(t.name)}" oninput="updateTableName(${t.id},this.value)">
        <div class="table-controls">
          <div class="seats-control">
            <button class="seats-btn" onclick="changeTableSeats(${t.id},-1)" ${free===0?'disabled':''}>&#8722;</button>
            <span class="seats-num">${t.seats}</span>
            <button class="seats-btn" onclick="changeTableSeats(${t.id},1)">+</button>
          </div>
          <button class="btn btn-sm btn-edit" onclick="openEditModal('table',${t.id})" title="Edytuj stół">&#9998;</button>
          <button class="btn-delete-table" onclick="deleteTable(${t.id})">&#128465;</button>
        </div>
      </div>
      ${t.shape === 'rect' ? `<div class="honor-toggle-row">
        <label class="honor-toggle-label">
          <input type="checkbox" ${t.isHonorTable ? 'checked' : ''} onchange="updateTableHonor(${t.id},this.checked)">
          <span>&#9733; Stół Pary Młodej</span>
        </label>
        ${t.isHonorTable ? '<span class="honor-badge">Honorowy</span>' : ''}
      </div>` : ''}
      ${renderTableVisual(t)}
      <div class="table-footer">
        <div class="occupancy">${occupied}/${t.seats} zajętych &nbsp;·&nbsp; ${free} wolnych</div>
        <div class="occupancy-bar"><div class="occupancy-fill" style="width:${pct}%"></div></div>
      </div>
    </div>`;
  }).join('');
}

// ── DRAG & DROP ──

// Table-view seat drag (occupied avatar → another table)
function tvSeatDragStart(event, guestId, srcTableId) {
  tvGuestDrag    = { guestId, srcTableId };
  draggedGuestId = guestId;
  event.dataTransfer.effectAllowed = 'move';
  event.dataTransfer.setData('text/plain', String(guestId));

  setTimeout(() => {
    if (!tvGuestDrag) return;
    tables.forEach(t => {
      const card = document.getElementById(`table-card-${t.id}`);
      if (!card) return;
      if (t.id === srcTableId) {
        card.classList.add('tv-drag-src');
      } else {
        const free = t.seats - t.seatsData.filter(x => x !== null).length;
        card.classList.add(free > 0 ? 'tv-drop-ok' : 'tv-drop-full');
      }
    });
  }, 0);
}

function tvSeatDragEnd() {
  tvGuestDrag    = null;
  draggedGuestId = null;
  document.querySelectorAll('.table-card')
    .forEach(el => el.classList.remove('tv-drag-src', 'tv-drop-ok', 'tv-drop-full', 'drag-over'));
  document.querySelectorAll('.table-seat-slot')
    .forEach(el => el.classList.remove('drag-over-seat'));
}

function onGuestDragStart(event, guestId) {
  draggedGuestId = guestId;
  event.dataTransfer.effectAllowed = 'move';
  event.dataTransfer.setData('text/plain', String(guestId));
  document.getElementById(`guest-item-${guestId}`)?.classList.add('dragging');

  const g = guests.find(x => x.id === guestId);
  if (g) {
    const ghost = document.getElementById('dragGhost');
    ghost.innerHTML = avatarHtml(g, 'avatar-sm') + ' ' + esc(fullName(g));
    ghost.style.display = 'flex';
    event.dataTransfer.setDragImage(ghost, 0, 0);
  }
}

function onGuestDragEnd() {
  if (draggedGuestId) document.getElementById(`guest-item-${draggedGuestId}`)?.classList.remove('dragging');
  draggedGuestId = null;
  document.getElementById('dragGhost').style.display = 'none';
  document.querySelectorAll('.table-card').forEach(el => el.classList.remove('drag-over'));
  document.querySelectorAll('.table-seat-slot').forEach(el => el.classList.remove('drag-over-seat'));
}

function onTableDragOver(event, tableId) {
  // Block if dragging between tables and this is the source table
  if (tvGuestDrag && tableId === tvGuestDrag.srcTableId) {
    event.preventDefault();
    event.dataTransfer.dropEffect = 'none';
    return;
  }
  event.preventDefault();
  const t = tables.find(x => x.id === tableId);
  const free = t ? t.seats - t.seatsData.filter(x => x !== null).length : 0;
  if (!t || free === 0) { event.dataTransfer.dropEffect = 'none'; return; }
  event.dataTransfer.dropEffect = 'move';
  document.getElementById(`table-card-${tableId}`)?.classList.add('drag-over');
}

function onTableDragLeave(event, tableId) {
  const card = document.getElementById(`table-card-${tableId}`);
  if (card && !card.contains(event.relatedTarget)) card.classList.remove('drag-over');
}

function onTableDrop(event, tableId) {
  event.preventDefault();
  document.getElementById(`table-card-${tableId}`)?.classList.remove('drag-over');
  _assignToTable(tableId, _getDraggedId(event));
}

function onSeatDragOver(event) {
  event.preventDefault();
  event.stopPropagation();
  const slot    = event.currentTarget;
  const tableId = parseInt(slot.dataset.table);
  const seatIdx = parseInt(slot.dataset.seat);
  const t = tables.find(x => x.id === tableId);
  if (!t || t.seatsData[seatIdx] !== null) { event.dataTransfer.dropEffect='none'; return; }
  event.dataTransfer.dropEffect = 'move';
  slot.classList.add('drag-over-seat');
}

function onSeatDragLeave(event) {
  event.currentTarget.classList.remove('drag-over-seat');
}

function onSeatDrop(event) {
  event.preventDefault();
  event.stopPropagation();
  const slot    = event.currentTarget;
  slot.classList.remove('drag-over-seat');
  const tableId = parseInt(slot.dataset.table);
  const seatIdx = parseInt(slot.dataset.seat);
  _assignToSeat(tableId, seatIdx, _getDraggedId(event));
  document.getElementById(`table-card-${tableId}`)?.classList.remove('drag-over');
}

function _getDraggedId(event) {
  return draggedGuestId || parseInt(event.dataTransfer.getData('text/plain'));
}

function _assignToTable(tableId, guestId) {
  if (!guestId) return;
  const g = guests.find(x => x.id === guestId);
  const t = tables.find(x => x.id === tableId);
  if (!g || !t) return;
  const freeSeat = t.seatsData.indexOf(null);
  if (freeSeat === -1) { showToast('Stół jest pełny!'); return; }
  if (g.tableId === tableId) { showToast('Gość już jest przy tym stole.'); return; }
  if (g.tableId !== null) _unsetSeat(g);
  t.seatsData[freeSeat] = guestId;
  g.tableId   = tableId;
  g.seatIndex = freeSeat;
  renderAll();
  showToast(`${fullName(g)} → ${t.name}`);
}

function _assignToSeat(tableId, seatIdx, guestId) {
  if (!guestId) return;
  const g = guests.find(x => x.id === guestId);
  const t = tables.find(x => x.id === tableId);
  if (!g || !t) return;
  if (t.seatsData[seatIdx] !== null) { showToast('To miejsce jest już zajęte!'); return; }
  if (g.tableId !== null) _unsetSeat(g);
  t.seatsData[seatIdx] = guestId;
  g.tableId   = tableId;
  g.seatIndex = seatIdx;
  renderAll();
  showToast(`${fullName(g)} → miejsce ${seatIdx+1} (${t.name})`);
}

// ── DRAG & DROP DOTYKOWY (mobile / tablet) ──
// Natywne HTML5 drag&drop nie działa na ekranach dotykowych — poniżej
// własna obsługa touchstart / touchmove / touchend (przeciąganie inicjałów gości).
let _touchDrag = null;

// Zwraca id gościa dla elementu, który można przeciągać (kafelek gościa lub zajęte miejsce)
function _touchFindGuestId(target) {
  if (!target || !target.closest) return null;
  const guestEl = target.closest('.guest-item');
  if (guestEl && guestEl.id && guestEl.id.indexOf('guest-item-') === 0) {
    return parseInt(guestEl.id.replace('guest-item-', '')) || null;
  }
  const slot = target.closest('.table-seat-slot.occupied');
  if (slot && slot.dataset.table != null) {
    const t = tables.find(x => x.id === parseInt(slot.dataset.table));
    if (t) {
      const gId = t.seatsData[parseInt(slot.dataset.seat)];
      if (gId != null) return gId;
    }
  }
  return null;
}

function _touchGhost() {
  let gh = document.getElementById('touchDragGhost');
  if (!gh) {
    gh = document.createElement('div');
    gh.id = 'touchDragGhost';
    gh.className = 'touch-drag-ghost';
    document.body.appendChild(gh);
  }
  return gh;
}

function _onTouchDragStart(e) {
  if (currentView !== 'tables' || e.touches.length !== 1) return;
  const guestId = _touchFindGuestId(e.target);
  if (!guestId) return;
  const t = e.touches[0];
  // Start przez przytrzymanie (long-press) — nie koliduje z przewijaniem listy
  _touchDrag = { guestId, startX: t.clientX, startY: t.clientY, active: false, timer: null };
  _touchDrag.timer = setTimeout(() => {
    if (!_touchDrag) return;
    _touchDrag.active = true;
    draggedGuestId = _touchDrag.guestId;
    const g = guests.find(x => x.id === _touchDrag.guestId);
    const gh = _touchGhost();
    gh.innerHTML = g ? (avatarHtml(g, 'avatar-sm') + '<span>' + esc(fullName(g)) + '</span>') : '';
    gh.style.display = 'flex';
    gh.style.left = _touchDrag.startX + 'px';
    gh.style.top  = _touchDrag.startY + 'px';
    if (navigator.vibrate) try { navigator.vibrate(15); } catch (_) {}
  }, 220);
}

function _onTouchDragMove(e) {
  if (!_touchDrag) return;
  const t = e.touches[0];
  if (!_touchDrag.active) {
    // Ruch przed long-press = przewijanie → anuluj przeciąganie
    if (Math.hypot(t.clientX - _touchDrag.startX, t.clientY - _touchDrag.startY) > 10) {
      clearTimeout(_touchDrag.timer);
      _touchDrag = null;
    }
    return;
  }
  e.preventDefault(); // blokuj przewijanie podczas przeciągania
  const gh = _touchGhost();
  gh.style.left = t.clientX + 'px';
  gh.style.top  = t.clientY + 'px';
  _touchHighlight(t.clientX, t.clientY);
}

function _onTouchDragEnd(e) {
  if (!_touchDrag) return;
  const drag = _touchDrag;
  _touchDrag = null;
  clearTimeout(drag.timer);
  if (!drag.active) return; // zwykłe dotknięcie / przewinięcie
  const gh = document.getElementById('touchDragGhost');
  if (gh) gh.style.display = 'none';
  const t = e.changedTouches && e.changedTouches[0];
  if (t) _touchDropOn(document.elementFromPoint(t.clientX, t.clientY), drag.guestId);
  draggedGuestId = null;
  _touchClearHighlight();
}

function _touchHighlight(x, y) {
  _touchClearHighlight();
  const el = document.elementFromPoint(x, y);
  if (!el || !el.closest) return;
  const slot = el.closest('.table-seat-slot');
  if (slot && slot.dataset.table != null) {
    const tableId = parseInt(slot.dataset.table);
    const t = tables.find(z => z.id === tableId);
    if (t && t.seatsData[parseInt(slot.dataset.seat)] === null) slot.classList.add('drag-over-seat');
    document.getElementById(`table-card-${tableId}`)?.classList.add('drag-over');
    return;
  }
  const card = el.closest('.table-card');
  if (card) card.classList.add('drag-over');
}

function _touchClearHighlight() {
  document.querySelectorAll('.table-card.drag-over').forEach(el => el.classList.remove('drag-over'));
  document.querySelectorAll('.table-seat-slot.drag-over-seat').forEach(el => el.classList.remove('drag-over-seat'));
}

function _touchDropOn(el, guestId) {
  if (!el || !el.closest) return;
  const slot = el.closest('.table-seat-slot');
  if (slot && slot.dataset.table != null) {
    const tableId = parseInt(slot.dataset.table);
    const seatIdx = parseInt(slot.dataset.seat);
    const t = tables.find(z => z.id === tableId);
    if (t && t.seatsData[seatIdx] === null) { _assignToSeat(tableId, seatIdx, guestId); return; }
    if (t) { _assignToTable(tableId, guestId); return; } // zajęte miejsce → pierwsze wolne
  }
  const card = el.closest('.table-card');
  if (card && card.id.indexOf('table-card-') === 0) {
    _assignToTable(parseInt(card.id.replace('table-card-', '')), guestId);
  }
}

function initTouchDragDrop() {
  document.addEventListener('touchstart', _onTouchDragStart, { passive: true });
  document.addEventListener('touchmove',  _onTouchDragMove,  { passive: false });
  document.addEventListener('touchend',   _onTouchDragEnd,   { passive: true });
  document.addEventListener('touchcancel', _onTouchDragEnd,  { passive: true });
}

// ── STATS ──
function updateStats() {
  const statsBar = document.getElementById('statsBar');
  if (statsBar) statsBar.style.display = currentView === 'tables' ? '' : 'none';
  document.getElementById('statTotal').textContent      = guests.length;
  document.getElementById('statSeated').textContent     = guests.filter(g=>g.tableId!==null).length;
  document.getElementById('statUnassigned').textContent = guests.filter(g=>g.tableId===null).length;
  document.getElementById('statTables').textContent     = tables.length;
  document.getElementById('statSeats').textContent      = tables.reduce((s,t)=>s+t.seats,0);
  document.getElementById('statPairs').textContent      = pairs.length;
}

// ── BUDGET STATE ──
let budgetData = {
  total: 0,
  pricePerPerson: 0,
  venueMinGuests: 0,
  menuAddons: [],
  coupleNames: ['Osoba 1', 'Osoba 2'],
  expenses: [],
  includeVirtualInCalc: false,
  includeStaffInCalc: false,
  honeymoon: { name: '', link: '', totalAmount: 0, estimatedAmount: 0, installments: [] },
  tableDeco: { honorAddons: [], regularAddons: [] },
};
let nextAddonId          = 1;
let nextMenuAddonId      = 1;
let nextExpenseId        = 1;
let nextHoneymoonInstId  = 1;
let nextTableDecoId      = 1;

const EXPENSE_CATEGORIES = [
  { name: 'Sala i catering',         icon: '🍽', color: '#1a56db' },
  { name: 'Suknia ślubna',           icon: '👗', color: '#e879f9' },
  { name: 'Garnitur/strój',          icon: '👔', color: '#6366f1' },
  { name: 'Obrączki',                icon: '💍', color: '#fbbf24' },
  { name: 'Fotograf',                icon: '📷', color: '#34d399' },
  { name: 'Kamerzysta/wideo',        icon: '🎥', color: '#2dd4bf' },
  { name: 'Kwiaty/dekoracje',        icon: '💐', color: '#f87171' },
  { name: 'Bukiet ślubny',           icon: '🌹', color: '#fb7185' },
  { name: 'Kwiaty dla PM',           icon: '🌸', color: '#f472b6' },
  { name: 'Przystrojenie kościoła',  icon: '⛪', color: '#818cf8' },
  { name: 'Tort weselny',            icon: '🎂', color: '#a78bfa' },
  { name: 'Muzyka/DJ/zespół',        icon: '🎵', color: '#fb923c' },
  { name: 'Zaproszenia',             icon: '✉️', color: '#38bdf8' },
  { name: 'Uroda',                   icon: '💄', color: '#f472b6' },
  { name: 'Makijaż i fryzura',       icon: '💇', color: '#e879f9' },
  { name: 'Transport',               icon: '🚗', color: '#94a3b8' },
  { name: 'Dojazd do wesela',        icon: '🚌', color: '#64748b' },
  { name: 'Dojazd do kościoła',      icon: '🚗', color: '#475569' },
  { name: 'Upominki dla gości',      icon: '🎁', color: '#10b981' },
  { name: 'Upominki dla rodziców',   icon: '🎀', color: '#f59e0b' },
  { name: 'Upominki dla świadków',   icon: '🥂', color: '#8b5cf6' },
  { name: 'Podróż poślubna',         icon: '✈️', color: '#4ade80' },
  { name: 'Alkohol',                 icon: '🍾', color: '#7c3aed' },
  { name: 'Inne',                    icon: '📦', color: '#cbd5e1' },
];

function fmt(n) {
  return Number(n || 0).toLocaleString('pl-PL', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

// Czytelna nazwa wydatku: dla kategorii „Inne" użyj wpisanej nazwy własnej
function _expenseLabel(e) {
  if (!e) return 'Wydatek';
  if (e.category === 'Inne' && (e.customName || '').trim()) return e.customName.trim();
  return e.category || 'Wydatek';
}

// Lista kategorii wydatków — konfigurowalna per event (appConfig.expenseCategories), z fallbackiem do domyślnych
function getExpenseCategories() {
  const cfgList = appConfig && Array.isArray(appConfig.expenseCategories) ? appConfig.expenseCategories.filter(s => (s || '').trim()) : null;
  if (cfgList && cfgList.length) return cfgList.slice();
  return EXPENSE_CATEGORIES.map(c => c.name);
}
function _expenseCatIcon(name) {
  const def = EXPENSE_CATEGORIES.find(c => c.name === name);
  return def ? def.icon : '📦';
}
// <option>-y kategorii wydatków (z konfigurowalnej listy)
function _expenseCatOptionsHtml(selected) {
  return getExpenseCategories().map(name =>
    `<option value="${esc(name)}"${name === selected ? ' selected' : ''}>${_expenseCatIcon(name)} ${esc(name)}</option>`
  ).join('');
}

// ── BUDGET CALCULATIONS ──
function calcTableAddons(t) {
  return (t.addons || []).reduce((s, a) => s + (a.price || 0), 0);
}

function calcAllAddons() {
  return tables.reduce((s, t) => s + calcTableAddons(t), 0);
}

function calcCateringBase() {
  return (budgetData.pricePerPerson || 0) * guests.length;
}

function getSeatedCount() {
  return guests.filter(g => g.tableId !== null).length;
}

function getVirtualGuests() {
  return Math.max(0, (budgetData.venueMinGuests || 0) - getSeatedCount());
}

function calcVirtualGuestsCost() {
  return getVirtualGuests() * (budgetData.pricePerPerson || 0);
}

function getStaffPersonCount() {
  return staffTables.reduce((s, t) => s + (t.persons || 0), 0);
}
function getStaffCostPersonCount() {
  return staffTables.filter(t => t.includeInCost).reduce((s, t) => s + (t.persons || 0), 0);
}
function calcStaffCost() {
  return getStaffCostPersonCount() * (budgetData.pricePerPerson || 0);
}

function getEffectiveGuestCount() {
  const seated  = getSeatedCount();
  const virtual = getVirtualGuests();
  const staffCount = budgetData.includeStaffInCalc ? getStaffPersonCount() : 0;
  const virt = (budgetData.includeVirtualInCalc && virtual > 0) ? virtual : 0;
  return seated + virt + staffCount;
}

function calcMenuAddonsTotal() {
  const count = getEffectiveGuestCount();
  return (budgetData.menuAddons || []).reduce((s, a) => s + (a.pricePerPerson || 0) * count, 0);
}

function calcHoneymoonPaid() {
  return ((budgetData.honeymoon || {}).installments || [])
    .filter(i => i.status === 'paid').reduce((s, i) => s + (i.amount || 0), 0);
}

function getRegularTableCount() { return tables.filter(t => !t.isHonorTable).length; }
function getHonorTableCount()   { return tables.filter(t =>  t.isHonorTable).length; }

function calcHonorTableDecoTotal() {
  return (budgetData.tableDeco?.honorAddons || []).reduce((s, a) => s + (a.price || 0), 0);
}
function calcRegularTableDecoTotal() {
  const count = getRegularTableCount();
  return (budgetData.tableDeco?.regularAddons || []).reduce((s, a) => s + (a.pricePerTable || 0) * count, 0);
}
function calcTableDecoTotal() {
  return calcHonorTableDecoTotal() + calcRegularTableDecoTotal();
}

function calcCateringTotal() {
  return calcCateringBase() + calcVirtualGuestsCost() + calcStaffCost() + calcMenuAddonsTotal() + calcTableDecoTotal();
}

function calcAlcoholTotal()   { return (budgetData.alcoholItems || []).reduce((s, i) => s + (i.bottles || 0) * (i.pricePerBottle || 0), 0); }
function calcAlcoholBottles() { return (budgetData.alcoholItems || []).reduce((s, i) => s + (i.bottles || 0), 0); }
// Napoje bezalkoholowe — sumy
function calcSoftTotal()   { return (budgetData.softItems || []).reduce((s, i) => s + (i.bottles || 0) * (i.pricePerBottle || 0), 0); }
function calcSoftBottles() { return (budgetData.softItems || []).reduce((s, i) => s + (i.bottles || 0), 0); }
// Liczba osób do przeliczeń na osobę (opcjonalnie z gośćmi wirtualnymi = min. sali)
function _bevPersonCount(useVirtual) {
  const real = guests.length;
  const virt = useVirtual ? getVirtualGuests() : 0;
  return real + virt;
}

function calcExpensesPlanned()    { return budgetData.expenses.reduce((s, e) => s + (e.planned         || 0), 0) + calcAlcoholTotal() + calcSoftTotal(); }
function calcExpensesPaid()       { return budgetData.expenses.reduce((s, e) => s + (e.paid             || 0), 0); }
function calcExpensesEstimated()  { return budgetData.expenses.reduce((s, e) => s + (e.estimatedAmount  || 0), 0); }
function calcExpensesEffective()  { return budgetData.expenses.reduce((s, e) => s + _payEffective(e.planned || 0, e.estimatedAmount || 0), 0) + calcAlcoholTotal() + calcSoftTotal(); }

// ── Koszty zewnętrzne wchodzące do podsumowania budżetu (Dostawcy/Hotele/Transport) ──
// Dostawcy powiązani z budżetem są już liczeni jako wydatki — pomijamy ich tu, by nie liczyć podwójnie.
function calcVendorsExternalTotal() { return vendors.filter(v => !v.isBudgetLinked).reduce((s, v) => s + (v.price || 0), 0); }
function calcVendorsExternalPaid()  { return vendors.filter(v => !v.isBudgetLinked).reduce((s, v) => s + _vendorInstallmentSums(v).paid, 0); }
function calcHotelsTotal()    { return hotels.reduce((s, h) => s + ((h.pricePerNight || 0) * (h.personsPerRoom || 1)), 0); }
function calcTransportTotal() { return vehicles.reduce((s, v) => s + (v.cost || 0), 0); }
function calcExternalTotal()  { return calcVendorsExternalTotal() + calcHotelsTotal() + calcTransportTotal(); }

// ── BUDGET VIEW ──
function renderBudget() {
  renderTableCosts();
  renderExpenses();
  renderAlcohol();
  renderSoftDrinks();
  renderHoneymoon();
  renderCostBreakdown();
  renderCoupleSummary();
  renderCostPerTable();
  renderExternalCosts();
  renderBudgetOverview();
  renderCharts();
  setTimeout(initMobileCollapse, 0);
}

function renderBudgetOverview() {
  const catering         = calcCateringTotal();
  const h                = budgetData.honeymoon || {};
  const expConfirmed     = calcExpensesPlanned();
  const expEffective     = calcExpensesEffective();
  const expPaid          = calcExpensesPaid();
  const hmConfirmed      = h.totalAmount || 0;
  const hmEffective      = _payEffective(h.totalAmount || 0, h.estimatedAmount || 0);
  const honeymoonPaid    = calcHoneymoonPaid();
  const external         = calcExternalTotal();          // Dostawcy (niepowiązani) + Hotele + Transport
  const externalPaid     = calcVendorsExternalPaid();
  const totalConfirmed   = catering + expConfirmed + hmConfirmed + external;
  const totalEffective   = catering + expEffective + hmEffective + external;
  const totalPaid        = expPaid + honeymoonPaid + externalPaid;
  const hasEstimates     = totalEffective > totalConfirmed;
  const planForCalc      = hasEstimates ? totalEffective : totalConfirmed;
  const remaining        = Math.max(0, planForCalc - totalPaid);
  const budget           = budgetData.total || 0;
  const diff             = budget - planForCalc;

  document.getElementById('bstatPlanned').textContent   = fmt(totalConfirmed) + ' zł';
  document.getElementById('bstatCatering').textContent  = fmt(catering) + ' zł';
  document.getElementById('bstatPaid').textContent      = fmt(totalPaid) + ' zł';
  document.getElementById('bstatRemaining').textContent = fmt(remaining) + ' zł';

  const expEstTotal = calcExpensesEstimated();
  const expEstEl    = document.getElementById('bstatExpEst');
  const expEstRow   = document.getElementById('bstatExpEstRow');
  const expEstSep   = document.getElementById('bstatExpEstSep');
  if (expEstEl) expEstEl.textContent = fmt(expEstTotal) + ' zł';
  const showExpEst = expEstTotal > 0;
  if (expEstRow) expEstRow.style.display = showExpEst ? '' : 'none';
  if (expEstSep) expEstSep.style.display = showExpEst ? '' : 'none';

  const estEl  = document.getElementById('bstatEstimated');
  const estRow = estEl?.closest('.bstat');
  const estSep = estRow?.previousElementSibling;
  if (estEl) {
    estEl.textContent = '~ ' + fmt(totalEffective) + ' zł';
    const show = hasEstimates;
    if (estRow) estRow.style.display = show ? '' : 'none';
    if (estSep) estSep.style.display = show ? '' : 'none';
  }

  const diffEl = document.getElementById('bstatDiff');
  diffEl.textContent = (diff >= 0 ? '+' : '') + fmt(diff) + ' zł';
  diffEl.className = 'bstat-val ' + (diff >= 0 ? 'bval-green' : 'bval-red');

  const base      = Math.max(budget, totalEffective, 1);
  const confPct   = Math.min(100, totalConfirmed / base * 100);
  const effPct    = Math.min(100, totalEffective / base * 100);
  const paidPct   = Math.min(100, totalPaid / base * 100);
  document.getElementById('budgetProgPlanned').style.width   = confPct + '%';
  document.getElementById('budgetProgPaid').style.width      = paidPct + '%';
  const estProg = document.getElementById('budgetProgEstimated');
  if (estProg) {
    estProg.style.left  = confPct + '%';
    estProg.style.width = Math.max(0, effPct - confPct) + '%';
  }
  document.getElementById('budgetProgLabel').textContent  = Math.round(totalPaid / Math.max(planForCalc, 1) * 100) + '% opłacono';
  document.getElementById('budgetProgBudget').textContent = 'Budżet: ' + fmt(budget) + ' zł';
}

function onBudgetTotalChange(val) {
  budgetData.total = parseFloat(val) || 0;
  renderBudgetOverview();
  saveState();
}

// Read-only podsumowanie kosztów zewnętrznych (Dostawcy / Noclegi / Transport)
function renderExternalCosts() {
  const el = document.getElementById('externalCostsCard');
  if (!el) return;
  const vTotal = calcVendorsExternalTotal();
  const hTotal = calcHotelsTotal();
  const tTotal = calcTransportTotal();
  const grand  = vTotal + hTotal + tTotal;
  // Ten sam układ co pozostałe karty podsumowania budżetu (.extra-card-* / .cb-*)
  const erow = (name, amount, note) => `<div class="cb-row">
    <span class="cb-name">${esc(name)}</span>
    <span class="cb-date">${esc(note || '')}</span>
    <strong class="cb-amt">${fmt(amount)} zł</strong>
  </div>`;
  const vendorRows = vendors.filter(v => !v.isBudgetLinked).map(v => {
    const s = _vendorInstallmentSums(v);
    return erow(vendorLabel(v), v.price || 0, s.paid ? `zapłacono ${fmt(s.paid)} zł` : '');
  }).join('') || '<div class="cb-empty">Brak (lub powiązani z budżetem)</div>';
  const hotelRows = hotels.map(h => erow((h.name || 'Hotel') + (h.inComplex ? ' 🏨' : ''), (h.pricePerNight || 0) * (h.personsPerRoom || 1), 'zł/noc')).join('') || '<div class="cb-empty">Brak hoteli</div>';
  const transRows = vehicles.map(v => erow(v.description || v.type || 'Pojazd', v.cost || 0)).join('') || '<div class="cb-empty">Brak pojazdów</div>';
  el.innerHTML = `
    <div class="extra-card-header">&#128279; Koszty zewnętrzne</div>
    <div class="extra-card-body">
      <p class="cb-note">Wliczane do całkowitego podsumowania budżetu. Edycja w sekcjach Dostawcy / Noclegi / Transport. Dostawcy powiązani z budżetem liczeni są jako wydatki.</p>
      <div class="cb-section">
        <div class="cb-hdr cb-hdr-planned">&#128104;&#8205;&#127859; Dostawcy &mdash; ${fmt(vTotal)} zł</div>${vendorRows}
      </div>
      <div class="cb-section">
        <div class="cb-hdr cb-hdr-planned">&#127976; Noclegi / Hotele &mdash; ${fmt(hTotal)} zł</div>${hotelRows}
      </div>
      <div class="cb-section">
        <div class="cb-hdr cb-hdr-planned">&#128663; Transport &mdash; ${fmt(tTotal)} zł</div>${transRows}
      </div>
      <div class="cb-total-row">
        <span>Razem koszty zewnętrzne:</span>
        <strong class="bval-orange">${fmt(grand)} zł</strong>
      </div>
    </div>`;
}

// ── TABLE COSTS ──
function renderTableCosts() {
  const container = document.getElementById('tableCostsList');
  const badge     = document.getElementById('cateringTotalBadge');

  const ppp           = budgetData.pricePerPerson || 0;
  const guestCount    = guests.length;
  const base          = calcCateringBase();
  const seated        = getSeatedCount();
  const venueMin      = budgetData.venueMinGuests || 0;
  const virtualGuests = getVirtualGuests();
  const virtualCost   = calcVirtualGuestsCost();
  const effCount      = getEffectiveGuestCount();
  const menuTotal     = calcMenuAddonsTotal();
  const decoTotal     = calcTableDecoTotal();
  const honorDecoTotal   = calcHonorTableDecoTotal();
  const regularDecoTotal = calcRegularTableDecoTotal();
  const regularCount  = getRegularTableCount();
  const honorCount    = getHonorTableCount();
  const staffTotal       = getStaffPersonCount();
  const staffCostCount   = getStaffCostPersonCount();
  const staffCost        = calcStaffCost();
  const total            = base + virtualCost + staffCost + menuTotal + decoTotal;

  if (badge) badge.textContent = fmt(total) + ' zł';

  // 1. Cena za osobę
  const formulaCard = `
    <div class="tc-formula-card">
      <div class="tc-formula-header">&#128101; Cena za osobę (cały event)</div>
      <div class="tc-formula-body">
        <div class="tc-formula-input-row">
          <label>Cena&nbsp;/&nbsp;os.:</label>
          <input class="price-input price-input-lg" type="number"
                 value="${ppp || ''}" min="0" step="0.01" placeholder="0,00"
                 onchange="updateGlobalPricePerPerson(parseFloat(this.value)||0)">
          <span class="currency-sm">zł</span>
        </div>
        <div class="tc-formula-result ${guestCount > 0 && ppp > 0 ? 'tc-formula-active' : ''}">
          <span class="tc-formula-eq">
            <span class="tc-formula-ppp">${fmt(ppp)}&nbsp;zł</span>
            <span class="tc-formula-op">×</span>
            <span class="tc-formula-guests">${guestCount}&nbsp;${guestCount === 1 ? 'gość' : 'gości'}</span>
            <span class="tc-formula-op">=</span>
            <span class="tc-formula-total">${fmt(base)}&nbsp;zł</span>
          </span>
        </div>
      </div>
    </div>`;

  // 2. Wirtualni goście
  const virtualCard = `
    <div class="vguests-card">
      <div class="vguests-header">&#127963; Wirtualni goście (minimum sali)</div>
      <div class="vguests-body">
        <div class="vguests-input-row">
          <label>Min. wymagane przez salę:</label>
          <input type="number" value="${venueMin || ''}" min="0" step="1" placeholder="0"
                 onchange="updateVenueMinGuests(parseInt(this.value)||0)">
          <span>os.</span>
        </div>
        <div class="vguests-stats">
          <div class="vguests-stat">
            <span class="vguests-label">Rzeczywiści (przy stolikach):</span>
            <span class="vguests-val" id="vgSeated">${seated}</span>
          </div>
          <div class="vguests-stat">
            <span class="vguests-label">Wirtualni:</span>
            <span class="vguests-val ${virtualGuests > 0 ? 'vguests-warn' : 'vguests-ok'}" id="vgVirtual">${virtualGuests}</span>
          </div>
          <div class="vguests-stat" id="vgCostRow" style="${virtualGuests > 0 ? '' : 'display:none'}">
            <span class="vguests-label">Koszt wirtualnych:</span>
            <span class="vguests-val vguests-cost" id="vgCost">${fmt(virtualCost)}&nbsp;zł</span>
          </div>
        </div>
        <label class="vg-include-label">
          <input type="checkbox" ${budgetData.includeVirtualInCalc ? 'checked' : ''}
                 onchange="toggleVirtualInCalc(this.checked)">
          Uwzględnij gości wirtualnych w mnożniku dodatków
          <span class="vg-include-hint" id="vgIncludeHint">(${effCount} os. w obliczeniach)</span>
        </label>
      </div>
    </div>`;

  // 2b. Personel (stoły obsługi)
  const staffRows = staffTables.length
    ? staffTables.map(t => `
        <div class="staff-budget-row">
          <span class="staff-budget-icon">${staffRoleIcon(t.name)}</span>
          <span class="staff-budget-name">${esc(t.name)}</span>
          <span class="staff-budget-persons">${t.persons}&nbsp;os.</span>
          <span class="staff-budget-badge ${t.includeInCost ? 'sbadge-cost' : 'sbadge-free'}">${t.includeInCost ? 'w kosztach' : 'bez kosztów'}</span>
        </div>`).join('')
    : '<div class="staff-budget-empty">Brak stolików personelu. Dodaj je w zakładce Plan Stołów.</div>';

  const staffBreakdown = `
    <div class="staff-budget-summary">
      <span class="staff-sum-item">&#127937; Goście: <strong>${seated}</strong></span>
      <span class="staff-sum-sep">+</span>
      <span class="staff-sum-item">&#127963; Wirtualni: <strong>${virtualGuests}</strong></span>
      <span class="staff-sum-sep">+</span>
      <span class="staff-sum-item">&#128119; Personel: <strong>${staffTotal}</strong></span>
      <span class="staff-sum-sep">=</span>
      <span class="staff-sum-total">&#128203; W wycenie: <strong>${effCount}</strong></span>
    </div>`;

  const staffCard = `
    <div class="staff-budget-card">
      <div class="staff-budget-header">&#128119; Personel (stoły obsługi)</div>
      <div class="staff-budget-body">
        ${staffRows}
        ${staffTables.length ? `
        <div class="staff-budget-totals" id="staffBudgetTotals">
          <span>Łącznie: <strong>${staffTotal} os.</strong></span>
          ${staffCostCount > 0 ? `<span class="staff-cost-info">w kosztach: <strong>${staffCostCount} os.</strong> = <strong>${fmt(staffCost)} zł</strong></span>` : ''}
        </div>` : ''}
        <label class="vg-include-label" style="margin-top:8px">
          <input type="checkbox" ${budgetData.includeStaffInCalc ? 'checked' : ''}
                 onchange="toggleStaffInCalc(this.checked)">
          Uwzględnij personel w wycenie dodatków do menu
          <span class="vg-include-hint" id="staffIncludeHint">(+${staffTotal} os. do mnożnika)</span>
        </label>
        ${staffBreakdown}
      </div>
    </div>`;

  // 3. Dodatki do menu (mnożone przez efektywną liczbę gości) — FIX: effCount zamiast seated
  const menuAddonRows = (budgetData.menuAddons || []).map(a => {
    const lineTotal = (a.pricePerPerson || 0) * effCount;
    return `<div class="menu-addon-row">
      <input class="menu-addon-name" type="text" value="${esc(a.name)}" placeholder="Nazwa dodatku"
             onchange="updateMenuAddon(${a.id},'name',this.value)">
      <input class="menu-addon-price" type="number" value="${a.pricePerPerson || 0}" min="0" step="0.01"
             onchange="updateMenuAddon(${a.id},'pricePerPerson',parseFloat(this.value)||0)">
      <span class="menu-addon-per">zł/os</span>
      <span class="menu-addon-total" id="ma-total-${a.id}">= ${fmt(lineTotal)}&nbsp;zł</span>
      <button class="btn-menu-addon-del" onclick="deleteMenuAddon(${a.id})">&#10005;</button>
    </div>`;
  }).join('');

  const menuAddonsCard = `
    <div class="menu-addons-card">
      <div class="menu-addons-header">
        &#127869; Dodatki do menu (per osoba)
        <button class="btn-ma-add" onclick="addMenuAddon()">+ Dodaj</button>
      </div>
      <div class="menu-addons-body">
        <div class="menu-addons-info" id="maAddonsInfo">Mnożone przez ${effCount} os.${budgetData.includeVirtualInCalc && virtualGuests > 0 ? ' (w tym ' + virtualGuests + ' wirtualnych)' : ''}</div>
        ${menuAddonRows || '<div style="font-size:0.76rem;color:var(--text-light);padding:4px 0">Brak dodatków do menu.</div>'}
        <div class="menu-addons-total-row" id="maAddonsTotal" style="${menuTotal > 0 ? '' : 'display:none'}">
          <span>Łącznie dodatki do menu:</span>
          <span class="menu-addons-total-val">${fmt(menuTotal)}&nbsp;zł</span>
        </div>
      </div>
    </div>`;

  // 4. Dekoracje stołów (per stolik) — ta sama struktura co menu addons
  const honorAddons   = budgetData.tableDeco?.honorAddons   || [];
  const regularAddons = budgetData.tableDeco?.regularAddons || [];

  const honorRows = honorAddons.map(a => `
    <div class="menu-addon-row">
      <input class="menu-addon-name" type="text" value="${esc(a.name)}" placeholder="Nazwa dekoracji"
             onchange="updateTableDecoAddon('honor',${a.id},'name',this.value)">
      <input class="menu-addon-price" type="number" value="${a.price || 0}" min="0" step="0.01"
             onchange="updateTableDecoAddon('honor',${a.id},'price',parseFloat(this.value)||0)">
      <span class="menu-addon-per">zł</span>
      <span class="menu-addon-total" id="tdeco-honor-${a.id}">= ${fmt(a.price || 0)}&nbsp;zł</span>
      <button class="btn-menu-addon-del" onclick="deleteTableDecoAddon('honor',${a.id})">&#10005;</button>
    </div>`).join('');

  const regularRows = regularAddons.map(a => {
    const lineTotal = (a.pricePerTable || 0) * regularCount;
    return `<div class="menu-addon-row">
      <input class="menu-addon-name" type="text" value="${esc(a.name)}" placeholder="Nazwa dekoracji"
             onchange="updateTableDecoAddon('regular',${a.id},'name',this.value)">
      <input class="menu-addon-price" type="number" value="${a.pricePerTable || 0}" min="0" step="0.01"
             onchange="updateTableDecoAddon('regular',${a.id},'pricePerTable',parseFloat(this.value)||0)">
      <span class="menu-addon-per">zł/st</span>
      <span class="menu-addon-total" id="tdeco-reg-${a.id}">= ${fmt(lineTotal)}&nbsp;zł</span>
      <button class="btn-menu-addon-del" onclick="deleteTableDecoAddon('regular',${a.id})">&#10005;</button>
    </div>`;
  }).join('');

  const tableDecoCard = `
    <div class="menu-addons-card table-deco-card">
      <div class="menu-addons-header">&#129717; Dekoracje stołów (per stolik)</div>
      <div class="menu-addons-body">

        <div class="tdeco-sub-hdr">
          &#9733; Stół Pary Młodej
          ${honorCount === 0 ? '<span class="tdeco-hint">(brak stołu honorowego)</span>' : ''}
          <button class="btn-ma-add" onclick="addTableDecoAddon('honor')">+ Dodaj</button>
        </div>
        ${honorAddons.length
          ? honorRows + `<div class="menu-addons-total-row" id="tdecoHonorTotal"><span>Suma — stół honorowy:</span><span class="menu-addons-total-val">${fmt(honorDecoTotal)}&nbsp;zł</span></div>`
          : '<div class="menu-addons-info">Brak dekoracji dla stołu honorowego.</div>'}

        <div class="tdeco-sub-sep"></div>

        <div class="tdeco-sub-hdr">
          &#127860; Pozostałe stoły
          <span class="tdeco-count">(${regularCount} ${_stoliczkLabel(regularCount)})</span>
          <button class="btn-ma-add" onclick="addTableDecoAddon('regular')">+ Dodaj</button>
        </div>
        <div class="menu-addons-info" id="tdecoRegInfo">Mnożone przez ${regularCount} ${_stoliczkLabel(regularCount)}</div>
        ${regularAddons.length
          ? regularRows + `<div class="menu-addons-total-row" id="tdecoRegTotal"><span>Suma — pozostałe stoły:</span><span class="menu-addons-total-val">${fmt(regularDecoTotal)}&nbsp;zł</span></div>`
          : '<div style="font-size:0.76rem;color:var(--text-light);padding:2px 0">Brak dekoracji dla pozostałych stołów.</div>'}

        <div class="menu-addons-total-row tdeco-grand-row" id="tdecoGrandTotal" style="${decoTotal > 0 ? '' : 'display:none'}">
          <span>&#129717; Łącznie dekoracje stołów:</span>
          <span class="menu-addons-total-val">${fmt(decoTotal)}&nbsp;zł</span>
        </div>

      </div>
    </div>`;

  // 5. Podsumowanie dodatków
  const addonsSummaryCard = (menuTotal > 0 || decoTotal > 0) ? `
    <div class="addons-summary-card" id="addonsSummaryCard">
      <div class="addons-sum-header">&#128202; Podsumowanie dodatków</div>
      <div class="addons-sum-body">
        <div class="addons-sum-row">
          <span>&#127869; Dodatki per osoba (${effCount} os.):</span>
          <strong id="addonsSumPerPerson">${fmt(menuTotal)}&nbsp;zł</strong>
        </div>
        <div class="addons-sum-row">
          <span>&#129717; Dodatki per stolik (${tables.length} st.):</span>
          <strong id="addonsSumPerTable">${fmt(decoTotal)}&nbsp;zł</strong>
        </div>
        <div class="addons-sum-row addons-sum-grand">
          <span>&#128176; Łącznie wszystkie dodatki:</span>
          <strong id="addonsSumAll">${fmt(menuTotal + decoTotal)}&nbsp;zł</strong>
        </div>
      </div>
    </div>` : `<div id="addonsSummaryCard" style="display:none"></div>`;

  // 6. Podsumowanie catering
  const summaryFooter = `
    <div class="tc-summary">
      <div class="tc-sum-row" id="tcSumRowBase">
        <span>Catering (${guestCount} os. × ${fmt(ppp)} zł):</span>
        <strong>${fmt(base)} zł</strong>
      </div>
      <div class="tc-sum-row" id="tcSumRowVirtual" style="${virtualCost > 0 ? '' : 'display:none'}">
        <span>Goście wirtualni (${virtualGuests} os.):</span><strong>${fmt(virtualCost)} zł</strong>
      </div>
      <div class="tc-sum-row" id="tcSumRowStaff" style="${staffCost > 0 ? '' : 'display:none'}">
        <span>Personel (${staffCostCount} os.):</span><strong>${fmt(staffCost)} zł</strong>
      </div>
      <div class="tc-sum-row" id="tcSumRowMenuAddons" style="${menuTotal > 0 ? '' : 'display:none'}">
        <span>Dodatki do menu (${effCount} os.):</span><strong>${fmt(menuTotal)} zł</strong>
      </div>
      <div class="tc-sum-row" id="tcSumRowTableDeco" style="${decoTotal > 0 ? '' : 'display:none'}">
        <span>Dekoracje stołów (${honorCount > 0 ? 'honorowy + ' : ''}${regularCount} st.):</span><strong>${fmt(decoTotal)} zł</strong>
      </div>
      <div class="tc-sum-row tc-sum-grand" id="tcSumRowGrand">
        <span>&#128176; Razem sala:</span>
        <strong class="tc-total-val">${fmt(total)} zł</strong>
      </div>
    </div>`;

  const addonsColsRow = `<div class="addons-cols-row">${menuAddonsCard}${tableDecoCard}</div>`;
  container.innerHTML = formulaCard + virtualCard + staffCard + addonsColsRow + addonsSummaryCard + summaryFooter;
  setTimeout(initMobileCollapse, 0);
}

function _stoliczkLabel(n) {
  if (n === 1) return 'stolik';
  if (n >= 2 && n <= 4) return 'stoliki';
  return 'stolików';
}

// ── STAFF TABLES ──
const STAFF_ROLE_ICONS = { 'DJ': '&#127911;', 'Barman': '&#127379;', 'Fotograf': '&#128247;', 'Fotobuda': '&#128248;', 'Obsługa': '&#127869;' };
function staffRoleIcon(name) { return STAFF_ROLE_ICONS[name] || '&#128119;'; }

function autoStaffTablePos(idx) {
  return { x: 50 + (idx % 6) * 150, y: 600 + Math.floor(idx / 6) * 110 };
}

function addStaffTable() {
  const nameSelect  = document.getElementById('staffTableName');
  const customInput = document.getElementById('staffTableCustomName');
  const personsInput = document.getElementById('staffTablePersons');
  let name = nameSelect?.value || 'Obsługa';
  if (name === 'Inne') name = (customInput?.value || '').trim() || 'Personel';
  const persons = parseInt(personsInput?.value) || 1;
  const pos = autoStaffTablePos(staffTables.length);
  staffTables.push({ id: nextStaffTableId++, name, persons, includeInCost: false, posX: pos.x, posY: pos.y });
  if (personsInput) personsInput.value = 2;
  renderStaffTables();
  if (currentView === 'room') renderRoom();
  renderBudget();
  saveState();
}

function updateStaffTable(id, field, value) {
  const t = staffTables.find(x => x.id === id);
  if (!t) return;
  t[field] = value;
  renderStaffTables();
  if (currentView === 'room') renderRoom();
  renderBudget();
  saveState();
}

function deleteStaffTable(id) {
  staffTables = staffTables.filter(t => t.id !== id);
  renderStaffTables();
  if (currentView === 'room') renderRoom();
  renderBudget();
  saveState();
}

function toggleStaffInCalc(checked) {
  budgetData.includeStaffInCalc = checked;
  renderTableCosts();
  renderBudgetOverview();
  renderCharts();
  saveState();
}

function renderStaffTables() {
  if (typeof updateStaffCount === 'function') updateStaffCount();
  _fillVendorPicker('staffVendorPick', '+ Z dostawcy');
  const list = document.getElementById('staffTablesList');
  if (!list) return;
  if (!staffTables.length) {
    list.innerHTML = '<div class="empty-list">Brak stolików personelu. Dodaj pierwszy powyżej.</div>';
    return;
  }
  list.innerHTML = staffTables.map(t => `
    <div class="staff-table-card" id="staff-card-${t.id}">
      <span class="staff-card-icon">${staffRoleIcon(t.name)}</span>
      <input class="staff-card-name" type="text" value="${esc(t.name)}"
             onchange="updateStaffTable(${t.id},'name',this.value)">
      <input class="staff-card-persons" type="number" value="${t.persons}" min="1" max="99"
             onchange="updateStaffTable(${t.id},'persons',parseInt(this.value)||1)">
      <span class="staff-card-per">os.</span>
      <label class="staff-cost-chk" title="Uwzględnij w kosztach cateringu">
        <input type="checkbox" ${t.includeInCost ? 'checked' : ''}
               onchange="updateStaffTable(${t.id},'includeInCost',this.checked)">
        zł
      </label>
      <button class="btn-delete-staff" onclick="deleteStaffTable(${t.id})" title="Usuń">&#128465;</button>
    </div>`).join('');
}

function renderRoomStaffTable(t) {
  const tw = 110; const th = 68; const PAD = 14;
  const wrapW = tw + PAD * 2; const wrapH = th + PAD * 2;
  const shapeHtml = `<div class="rt-shape rt-rect rt-staff"
    style="width:${tw}px;height:${th}px;left:${PAD}px;top:${PAD}px">
    <div class="rt-label">
      <div class="rt-staff-icon">${staffRoleIcon(t.name)}</div>
      <div class="rt-name">${esc(t.name)}</div>
      <div class="rt-count">${t.persons} os. &middot; personel</div>
    </div>
  </div>`;
  return `<div class="rt-wrap rt-staff-wrap" data-staff-id="${t.id}"
    style="left:${t.posX}px;top:${t.posY}px;width:${wrapW}px;height:${wrapH}px"
    onmousedown="startRoomStaffTableDrag(event,${t.id})">
    ${shapeHtml}
    <div class="rt-delete" onclick="event.stopPropagation();deleteStaffTable(${t.id})" title="Usuń">&#10005;</div>
  </div>`;
}

function startRoomStaffTableDrag(e, id) {
  if (e.button !== 0) return;
  e.preventDefault();
  const t = staffTables.find(x => x.id === id);
  if (!t) return;
  roomStaffDrag = { id, startMouseX: e.clientX, startMouseY: e.clientY, startPosX: t.posX, startPosY: t.posY };
  document.querySelector(`.rt-staff-wrap[data-staff-id="${id}"]`)?.classList.add('rt-dragging');
}

function updateGlobalPricePerPerson(price) {
  budgetData.pricePerPerson = price;
  _refreshFormulaDisplay();
  _refreshVirtualGuests();
  renderBudgetOverview();
  renderCharts();
  saveState();
}

function _refreshFormulaDisplay() {
  const ppp = budgetData.pricePerPerson || 0;
  const n   = guests.length;
  const base = calcCateringBase();

  const pppEl    = document.querySelector('.tc-formula-ppp');
  const guestsEl = document.querySelector('.tc-formula-guests');
  const totalEl  = document.querySelector('.tc-formula-total');
  const resultEl = document.querySelector('.tc-formula-result');
  if (pppEl)    pppEl.textContent    = fmt(ppp) + ' zł';
  if (guestsEl) guestsEl.textContent = n + ' ' + (n === 1 ? 'gość' : 'gości');
  if (totalEl)  totalEl.textContent  = fmt(base) + ' zł';
  if (resultEl) resultEl.className   = 'tc-formula-result' + (n > 0 && ppp > 0 ? ' tc-formula-active' : '');

  _refreshCateringSummaryRows();
}

function _refreshCateringSummaryRows() {
  const ppp           = budgetData.pricePerPerson || 0;
  const n             = guests.length;
  const base          = calcCateringBase();
  const virtualGuests  = getVirtualGuests();
  const virtualCost    = calcVirtualGuestsCost();
  const staffTotal     = getStaffPersonCount();
  const staffCostCount = getStaffCostPersonCount();
  const staffCost      = calcStaffCost();
  const effCount       = getEffectiveGuestCount();
  const menuTotal      = calcMenuAddonsTotal();
  const decoTotal      = calcTableDecoTotal();
  const honorCount     = getHonorTableCount();
  const regularCount   = getRegularTableCount();
  const total          = base + virtualCost + staffCost + menuTotal + decoTotal;

  const badge = document.getElementById('cateringTotalBadge');
  if (badge) badge.textContent = fmt(total) + ' zł';

  const rowBase = document.getElementById('tcSumRowBase');
  if (rowBase) rowBase.innerHTML = `<span>Catering (${n} os. × ${fmt(ppp)} zł):</span><strong>${fmt(base)} zł</strong>`;

  const rowVirtual = document.getElementById('tcSumRowVirtual');
  if (rowVirtual) {
    rowVirtual.style.display = virtualCost > 0 ? '' : 'none';
    rowVirtual.innerHTML = `<span>Goście wirtualni (${virtualGuests} os.):</span><strong>${fmt(virtualCost)} zł</strong>`;
  }

  const rowStaff = document.getElementById('tcSumRowStaff');
  if (rowStaff) {
    rowStaff.style.display = staffCost > 0 ? '' : 'none';
    rowStaff.innerHTML = `<span>Personel (${staffCostCount} os.):</span><strong>${fmt(staffCost)} zł</strong>`;
  }

  const rowMenu = document.getElementById('tcSumRowMenuAddons');
  if (rowMenu) {
    rowMenu.style.display = menuTotal > 0 ? '' : 'none';
    rowMenu.innerHTML = `<span>Dodatki do menu (${effCount} os.):</span><strong>${fmt(menuTotal)} zł</strong>`;
  }

  const rowDeco = document.getElementById('tcSumRowTableDeco');
  if (rowDeco) {
    rowDeco.style.display = decoTotal > 0 ? '' : 'none';
    rowDeco.innerHTML = `<span>Dekoracje stołów (${honorCount > 0 ? 'honorowy + ' : ''}${regularCount} st.):</span><strong>${fmt(decoTotal)} zł</strong>`;
  }

  const rowGrand = document.getElementById('tcSumRowGrand');
  if (rowGrand) rowGrand.innerHTML = `<span>&#128176; Razem sala:</span><strong class="tc-total-val">${fmt(total)} zł</strong>`;

  const sp = document.getElementById('addonsSumPerPerson');
  const st = document.getElementById('addonsSumPerTable');
  const sa = document.getElementById('addonsSumAll');
  if (sp) sp.textContent = fmt(menuTotal) + ' zł';
  if (st) st.textContent = fmt(decoTotal) + ' zł';
  if (sa) sa.textContent = fmt(menuTotal + decoTotal) + ' zł';

  // Odśwież hinty
  const vgHint = document.getElementById('vgIncludeHint');
  if (vgHint) vgHint.textContent = `(${effCount} os. w obliczeniach)`;
  const staffHint = document.getElementById('staffIncludeHint');
  if (staffHint) staffHint.textContent = `(+${staffTotal} os. do mnożnika)`;
  const info = document.getElementById('maAddonsInfo');
  if (info) {
    const extras = [];
    if (budgetData.includeVirtualInCalc && virtualGuests > 0) extras.push(`${virtualGuests} wirtualnych`);
    if (budgetData.includeStaffInCalc && staffTotal > 0) extras.push(`${staffTotal} personel`);
    info.textContent = `Mnożone przez ${effCount} os.${extras.length ? ' (w tym ' + extras.join(', ') + ')' : ''}`;
  }
  const staffTotalsEl = document.getElementById('staffBudgetTotals');
  if (staffTotalsEl) {
    staffTotalsEl.innerHTML = `<span>Łącznie: <strong>${staffTotal} os.</strong></span>${staffCostCount > 0 ? `<span class="staff-cost-info">w kosztach: <strong>${staffCostCount} os.</strong> = <strong>${fmt(staffCost)} zł</strong></span>` : ''}`;
  }
}

function addAddon(tableId, isAlcohol = false) {
  const t = tables.find(x => x.id === tableId);
  if (!t) return;
  if (!t.addons) t.addons = [];
  t.addons.push({ id: nextAddonId++, name: isAlcohol ? 'Alkohol z zewnątrz' : '', price: 0, isAlcohol, note: '' });
  renderBudget();
  saveState();
}

function updateAddon(tableId, addonId, field, value) {
  const t = tables.find(x => x.id === tableId);
  if (!t) return;
  const a = (t.addons || []).find(x => x.id === addonId);
  if (!a) return;
  a[field] = value;
  // Surgical update: only refresh this table's addon total + summary
  const addonsForTable = calcTableAddons(t);
  const el = document.getElementById(`tc-addons-total-${tableId}`);
  if (el) {
    el.style.display = addonsForTable > 0 ? '' : 'none';
    const strong = el.querySelector('strong');
    if (strong) strong.textContent = fmt(addonsForTable) + ' zł';
  }
  _refreshCateringSummaryRows();
  renderBudgetOverview();
  renderCharts();
  saveState();
}

function deleteAddon(tableId, addonId) {
  const t = tables.find(x => x.id === tableId);
  if (!t) return;
  t.addons = (t.addons || []).filter(x => x.id !== addonId);
  renderBudget();
  saveState();
}

// ── VIRTUAL GUESTS ──
function updateVenueMinGuests(val) {
  budgetData.venueMinGuests = val;
  _refreshVirtualGuests();
  _refreshCateringSummaryRows();
  renderBudgetOverview();
  renderCostPerTable();
  renderCharts();
  saveState();
}

function _refreshVirtualGuests() {
  const seated        = getSeatedCount();
  const virtualGuests = getVirtualGuests();
  const virtualCost   = calcVirtualGuestsCost();

  const seatedEl = document.getElementById('vgSeated');
  if (seatedEl) seatedEl.textContent = seated;

  const virtualEl = document.getElementById('vgVirtual');
  if (virtualEl) {
    virtualEl.textContent = virtualGuests;
    virtualEl.className = 'vguests-val ' + (virtualGuests > 0 ? 'vguests-warn' : 'vguests-ok');
  }

  const costRow = document.getElementById('vgCostRow');
  if (costRow) costRow.style.display = virtualGuests > 0 ? '' : 'none';

  const costEl = document.getElementById('vgCost');
  if (costEl) costEl.textContent = fmt(virtualCost) + ' zł';
}

// ── MENU ADDONS (global) ──
function addMenuAddon() {
  if (!budgetData.menuAddons) budgetData.menuAddons = [];
  budgetData.menuAddons.push({ id: nextMenuAddonId++, name: '', pricePerPerson: 0 });
  renderBudget();
  saveState();
}

function updateMenuAddon(addonId, field, value) {
  const a = (budgetData.menuAddons || []).find(x => x.id === addonId);
  if (!a) return;
  a[field] = value;
  _refreshMenuAddonLine(addonId);
  _refreshCateringSummaryRows();
  renderBudgetOverview();
  renderCostPerTable();
  renderCharts();
  saveState();
}

function deleteMenuAddon(addonId) {
  budgetData.menuAddons = (budgetData.menuAddons || []).filter(x => x.id !== addonId);
  renderBudget();
  saveState();
}

function _refreshMenuAddonLine(addonId) {
  const count = getEffectiveGuestCount();
  const a = (budgetData.menuAddons || []).find(x => x.id === addonId);
  if (!a) return;
  const lineTotal = (a.pricePerPerson || 0) * count;
  const el = document.getElementById('ma-total-' + addonId);
  if (el) el.textContent = '= ' + fmt(lineTotal) + ' zł';

  const menuTotal = calcMenuAddonsTotal();
  const totalRow  = document.getElementById('maAddonsTotal');
  if (totalRow) {
    totalRow.style.display = menuTotal > 0 ? '' : 'none';
    if (menuTotal > 0) {
      totalRow.innerHTML = '<span>Łącznie dodatki do menu:</span><span class="menu-addons-total-val">' + fmt(menuTotal) + ' zł</span>';
    }
  }
}

// ── TABLE DECORATIONS (per stolik) ──
function _ensureTableDeco() {
  if (!budgetData.tableDeco) budgetData.tableDeco = { honorAddons: [], regularAddons: [] };
  if (!budgetData.tableDeco.honorAddons)   budgetData.tableDeco.honorAddons   = [];
  if (!budgetData.tableDeco.regularAddons) budgetData.tableDeco.regularAddons = [];
}

function addTableDecoAddon(type) {
  _ensureTableDeco();
  if (type === 'honor') {
    budgetData.tableDeco.honorAddons.push({ id: nextTableDecoId++, name: '', price: 0 });
  } else {
    budgetData.tableDeco.regularAddons.push({ id: nextTableDecoId++, name: '', pricePerTable: 0 });
  }
  renderTableCosts();
  _refreshCateringSummaryRows();
  renderBudgetOverview();
  renderCharts();
  saveState();
}

function updateTableDecoAddon(type, id, field, value) {
  _ensureTableDeco();
  const list = type === 'honor' ? budgetData.tableDeco.honorAddons : budgetData.tableDeco.regularAddons;
  const a = list.find(x => x.id === id);
  if (!a) return;
  a[field] = value;
  _refreshTableDecoLines(type, id);
  _refreshCateringSummaryRows();
  renderBudgetOverview();
  renderCharts();
  saveState();
}

function deleteTableDecoAddon(type, id) {
  _ensureTableDeco();
  if (type === 'honor') {
    budgetData.tableDeco.honorAddons = budgetData.tableDeco.honorAddons.filter(x => x.id !== id);
  } else {
    budgetData.tableDeco.regularAddons = budgetData.tableDeco.regularAddons.filter(x => x.id !== id);
  }
  renderTableCosts();
  _refreshCateringSummaryRows();
  renderBudgetOverview();
  renderCharts();
  saveState();
}

function _refreshTableDecoLines(type, id) {
  if (type === 'honor') {
    const a = (budgetData.tableDeco?.honorAddons || []).find(x => x.id === id);
    if (!a) return;
    const el = document.getElementById('tdeco-honor-' + id);
    if (el) el.textContent = '= ' + fmt(a.price || 0) + ' zł';
    const subtotalRow = document.getElementById('tdecoHonorTotal');
    if (subtotalRow) {
      const val = subtotalRow.querySelector('.menu-addons-total-val');
      if (val) val.textContent = fmt(calcHonorTableDecoTotal()) + ' zł';
    }
  } else {
    const count = getRegularTableCount();
    const a = (budgetData.tableDeco?.regularAddons || []).find(x => x.id === id);
    if (!a) return;
    const lineTotal = (a.pricePerTable || 0) * count;
    const el = document.getElementById('tdeco-reg-' + id);
    if (el) el.textContent = '= ' + fmt(lineTotal) + ' zł';
    const subtotalRow = document.getElementById('tdecoRegTotal');
    if (subtotalRow) {
      const val = subtotalRow.querySelector('.menu-addons-total-val');
      if (val) val.textContent = fmt(calcRegularTableDecoTotal()) + ' zł';
    }
  }
  const decoTotal = calcTableDecoTotal();
  const grandRow = document.getElementById('tdecoGrandTotal');
  if (grandRow) {
    grandRow.style.display = decoTotal > 0 ? '' : 'none';
    const val = grandRow.querySelector('.menu-addons-total-val');
    if (val) val.textContent = fmt(decoTotal) + ' zł';
  }
}

// ── EXPENSES ──
// ── SZYBKIE POZYCJE — gotowe, typowe wydatki ślubne (z konfigurowalnej listy kategorii) ──
// Lista chipów = getExpenseCategories() (ta sama, którą konfiguruje się w Konfiguracji),
// dzięki czemu pozostaje spójna z kategoriami wydatków. Klik tworzy gotową pozycję wydatku.
function _expenseQuickCats() {
  return getExpenseCategories().filter(c => c !== 'Inne');
}
function renderExpenseQuickAdd() {
  const wrap = document.getElementById('expQuickAdd');
  if (!wrap) return;
  const cats = _expenseQuickCats();
  const counts = {};
  budgetData.expenses.forEach(e => { counts[e.category] = (counts[e.category] || 0) + 1; });
  wrap.innerHTML = `
    <div class="exp-qa-head">
      <span class="exp-qa-title">&#9889; Szybkie pozycje</span>
      <span class="exp-qa-hint">kliknij, aby dodać gotowy wydatek &mdash; listę zmienisz w Konfiguracji</span>
    </div>
    <div class="exp-qa-chips">
      ${cats.map((name, i) => {
        const n = counts[name] || 0;
        return `<button class="exp-qa-chip${n ? ' added' : ''}" onclick="addExpenseForCategoryIdx(${i})" title="Dodaj wydatek: ${esc(name)}">
          <span class="exp-qa-ico">${_expenseCatIcon(name)}</span>
          <span class="exp-qa-name">${esc(name)}</span>
          ${n ? `<span class="exp-qa-badge" title="Tyle pozycji już dodano">${n}</span>` : `<span class="exp-qa-plus">+</span>`}
        </button>`;
      }).join('')}
      <button class="exp-qa-chip exp-qa-custom" onclick="addExpense()" title="Dodaj własny, dowolny wydatek">
        <span class="exp-qa-ico">&#10133;</span><span class="exp-qa-name">Własna pozycja</span>
      </button>
    </div>`;
}
function addExpenseForCategoryIdx(i) {
  const name = _expenseQuickCats()[i];
  if (name) addExpenseForCategory(name);
}
function addExpenseForCategory(name) {
  const newId = nextExpenseId++;
  const known = getExpenseCategories().includes(name);
  budgetData.expenses.push({
    id: newId,
    category: known ? name : 'Inne',
    customName: known ? '' : name,
    planned: 0,
    estimatedAmount: 0,
    paid: 0,
    paymentDate: '',
    note: '',
    splitP1: 0,
    splitP2: 0,
    sidePanel: false,
  });
  expenseOrder.push(newId);
  expenseFilters = { status: 'all', person: 'all', category: 'all' };
  renderExpenses();
  renderCoupleSummary();
  renderCostPerTable();
  renderBudgetOverview();
  renderCharts();
  saveState();
  const newTile = document.getElementById('exp-' + newId);
  if (newTile) {
    newTile.scrollIntoView({ behavior: 'smooth', block: 'center' });
    newTile.classList.add('exp-highlight');
    setTimeout(() => newTile.classList.remove('exp-highlight'), 1200);
  }
}

function addExpense(asSidePanel) {
  const newId = nextExpenseId++;
  budgetData.expenses.push({
    id: newId,
    category: 'Inne',
    customName: '',
    planned: 0,
    estimatedAmount: 0,
    paid: 0,
    paymentDate: '',
    note: '',
    splitP1: 0,
    splitP2: 0,
    sidePanel: !!asSidePanel,
  });
  expenseOrder.push(newId);
  expenseFilters = { status: 'all', person: 'all', category: 'all' };
  renderExpenses();
  renderCoupleSummary();
  renderCostPerTable();
  renderBudgetOverview();
  renderCharts();
  saveState();
  const newTile = document.getElementById('exp-' + newId);
  if (newTile) {
    newTile.scrollIntoView({ behavior: 'smooth', block: 'center' });
    newTile.classList.add('exp-highlight');
    setTimeout(() => newTile.classList.remove('exp-highlight'), 1200);
  }
}

function updateExpenseCat(expId, value) {
  const e = budgetData.expenses.find(x => x.id === expId);
  if (!e) return;
  e.category = value;
  if (value !== 'Inne') e.customName = '';
  renderExpenses();
  renderCostBreakdown();
  renderCharts();
  saveState();
}

function openExpCatPicker(expId) {
  const e    = budgetData.expenses.find(x => x.id === expId);
  const wrap = document.getElementById('exp-cat-wrap-' + expId);
  if (!wrap || !e) return;
  const opts = _expenseCatOptionsHtml(e.category);
  wrap.className = 'exp-cat-wrap';
  wrap.innerHTML = `<select class="exp-cat-select"
    onchange="updateExpenseCat(${expId},this.value)"
    onblur="renderExpenses()">${opts}</select>`;
  wrap.querySelector('select').focus();
}

function updateExpense(expId, field, value) {
  const e = budgetData.expenses.find(x => x.id === expId);
  if (!e) return;
  e[field] = value;
  _refreshExpenseRow(expId);
  renderCoupleSummary();
  renderCostPerTable();
  renderBudgetOverview();
  renderCharts();
  saveState();
}

function deleteExpense(expId) {
  budgetData.expenses = budgetData.expenses.filter(x => x.id !== expId);
  expenseOrder = expenseOrder.filter(id => id !== expId);
  // Spójność: odłącz zadania/dostawców powiązanych z usuwanym wpisem (bez „osieroconych" referencji)
  tasks.forEach(t => {
    if (t.budgetExpenseId === expId) { t.budgetExpenseId = null; t.isBudgetLinked = false; t.estimatedCost = 0; t.budgetCategory = ''; }
  });
  vendors.forEach(v => {
    if (v.budgetExpenseId === expId) { v.budgetExpenseId = null; v.isBudgetLinked = false; v.contractAmount = 0; v.budgetCategory = ''; }
  });
  renderExpenses();
  renderCoupleSummary();
  renderCostPerTable();
  renderBudgetOverview();
  renderCharts();
  saveState();
}

// ── EXPENSE ORDER & FILTER HELPERS ──
function syncExpenseOrder() {
  budgetData.expenses.forEach(e => {
    if (!expenseOrder.includes(e.id)) expenseOrder.push(e.id);
  });
  expenseOrder = expenseOrder.filter(id => budgetData.expenses.some(e => e.id === id));
}

function getExpensesToShow() {
  syncExpenseOrder();
  // Wydatki oznaczone jako „panel boczny" mają osobny obszar — pomijamy je na głównej liście
  let list = expenseOrder.map(id => budgetData.expenses.find(e => e.id === id)).filter(Boolean).filter(e => !e.sidePanel);

  list = list.filter(e => {
    if (expenseFilters.status !== 'all') {
      const paid = e.paid || 0, plan = e.planned || 0;
      const isPaid    = paid >= plan && plan > 0;
      const isPartial = paid > 0 && !isPaid;
      if (expenseFilters.status === 'paid'    && !isPaid)            return false;
      if (expenseFilters.status === 'partial' && !isPartial)         return false;
      if (expenseFilters.status === 'unpaid'  && (isPaid||isPartial)) return false;
    }
    if (expenseFilters.person !== 'all') {
      const sp1 = e.splitP1 || 0, sp2 = e.splitP2 || 0;
      if (expenseFilters.person === 'p1'   && sp1 <= 0)          return false;
      if (expenseFilters.person === 'p2'   && sp2 <= 0)          return false;
      if (expenseFilters.person === 'both' && (sp1 <= 0||sp2 <= 0)) return false;
    }
    if (expenseFilters.category !== 'all' && e.category !== expenseFilters.category) return false;
    return true;
  });

  if (expenseSort.field !== null) {
    const dir = expenseSort.dir === 'asc' ? 1 : -1;
    list.sort((a, b) => {
      let va, vb;
      if (expenseSort.field === 'planned')     { va = a.planned||0;   vb = b.planned||0; }
      else if (expenseSort.field === 'paid')   { va = a.paid||0;      vb = b.paid||0; }
      else if (expenseSort.field === 'remaining') {
        va = Math.max(0, (a.planned||0)-(a.paid||0));
        vb = Math.max(0, (b.planned||0)-(b.paid||0));
      }
      else if (expenseSort.field === 'paymentDate') { va = a.paymentDate||'9999'; vb = b.paymentDate||'9999'; }
      else if (expenseSort.field === 'category')    { va = a.category||'';        vb = b.category||''; }
      else return 0;
      return va < vb ? -1*dir : va > vb ? 1*dir : 0;
    });
  }

  return list;
}

function setExpenseFilter(type, value) {
  expenseFilters[type] = value;
  renderExpenses();
}

function setExpenseSort(field) {
  if (field === null) {
    expenseSort.field = null;
  } else if (expenseSort.field === field) {
    expenseSort.dir = expenseSort.dir === 'asc' ? 'desc' : 'asc';
  } else {
    expenseSort.field = field;
    expenseSort.dir = 'asc';
  }
  renderExpenses();
}

function renderExpenseFilters() {
  const bar = document.getElementById('expFiltersBar');
  if (!bar) return;

  const n1 = esc(budgetData.coupleNames[0] || 'Osoba 1');
  const n2 = esc(budgetData.coupleNames[1] || 'Osoba 2');

  const statusDefs = [
    { val: 'all',     label: 'Wszystkie',      cls: '' },
    { val: 'paid',    label: '&#10003; Opłacone',    cls: 'exp-fbtn-paid' },
    { val: 'partial', label: '&#9889; Częściowo',    cls: 'exp-fbtn-partial' },
    { val: 'unpaid',  label: '&#10007; Nieopłacone', cls: 'exp-fbtn-unpaid' },
  ];
  const statusBtns = statusDefs.map(s =>
    `<button class="exp-fbtn ${s.cls}${expenseFilters.status===s.val?' efb-active':''}"
      onclick="setExpenseFilter('status','${s.val}')">${s.label}</button>`
  ).join('');

  const personDefs = [
    { val: 'all',  label: 'Wszyscy' },
    { val: 'p1',   label: n1 },
    { val: 'p2',   label: n2 },
    { val: 'both', label: 'Oboje' },
  ];
  const personBtns = personDefs.map(p =>
    `<button class="exp-fbtn${expenseFilters.person===p.val?' efb-active':''}"
      onclick="setExpenseFilter('person','${p.val}')">${p.label}</button>`
  ).join('');

  const catOpts = [`<option value="all"${expenseFilters.category==='all'?' selected':''}>Wszystkie kategorie</option>`]
    .concat(getExpenseCategories().map(name =>
      `<option value="${esc(name)}"${expenseFilters.category===name?' selected':''}>${_expenseCatIcon(name)} ${esc(name)}</option>`
    )).join('');

  const sortDefs = [
    { field: null,          label: '&#8801; Ręcznie' },
    { field: 'planned',     label: 'Planowane' },
    { field: 'paid',        label: 'Opłacone' },
    { field: 'remaining',   label: 'Pozostało' },
    { field: 'paymentDate', label: 'Data' },
    { field: 'category',    label: 'Kategoria' },
  ];
  const sortBtns = sortDefs.map(s => {
    const isActive = expenseSort.field === s.field;
    const dirIcon  = isActive && s.field !== null ? (expenseSort.dir==='asc'?' ↑':' ↓') : '';
    const title    = s.field === null ? 'Ręczna kolejność — przeciągaj kafelki' : '';
    return `<button class="exp-sort-btn${isActive?' esb-active':''}" title="${title}"
      onclick="setExpenseSort(${s.field===null?'null':`'${s.field}'`})">${s.label}${dirIcon}</button>`;
  }).join('');

  bar.innerHTML = `
    <div class="exp-filter-group">
      <span class="exp-filter-label">Status:</span>
      <div class="exp-filter-btns">${statusBtns}</div>
    </div>
    <div class="exp-filter-group">
      <span class="exp-filter-label">Osoba:</span>
      <div class="exp-filter-btns">${personBtns}</div>
    </div>
    <div class="exp-filter-group">
      <span class="exp-filter-label">Kategoria:</span>
      <select class="exp-filter-select" onchange="setExpenseFilter('category',this.value)">${catOpts}</select>
    </div>
    <div class="exp-filter-group exp-sort-group">
      <span class="exp-filter-label">Sortuj:</span>
      <div class="exp-sort-btns">${sortBtns}</div>
    </div>`;
}

function renderExpenseTile(e, isDrag) {
  const paid = e.paid || 0, plan = e.planned || 0, est = e.estimatedAmount || 0;
  const effective = _payEffective(plan, est);
  const isPred    = plan === 0 && est > 0;
  const statusCls = paid >= effective && effective > 0 ? 'exp-paid' : paid > 0 ? 'exp-partial' : 'exp-unpaid';
  const badgeCls  = paid >= effective && effective > 0 ? 'exp-badge-paid' : paid > 0 ? 'exp-badge-partial' : 'exp-badge-unpaid';
  const badgeTxt  = paid >= effective && effective > 0 ? '✓ Opłacone' : paid > 0 ? '⚡ Częściowo' : '✗ Nieopłacone';
  const pct       = effective > 0 ? Math.min(100, (paid / effective) * 100) : 0;
  const diff      = plan > 0 && est > 0 ? plan - est : null;
  const diffHtml  = diff !== null
    ? `<span class="exp-est-diff ${diff < 0 ? 'eed-over' : 'eed-under'}">${diff > 0 ? '−' : '+'}${fmt(Math.abs(diff))}&nbsp;zł</span>`
    : '';

  const catDef = EXPENSE_CATEGORIES.find(c => c.name === e.category) || EXPENSE_CATEGORIES[EXPENSE_CATEGORIES.length - 1];
  const selectedCatOpts = _expenseCatOptionsHtml(e.category);

  const sp1 = e.splitP1 || 0, sp2 = e.splitP2 || 0;
  const splitSum = sp1 + sp2;
  const sfull    = splitSum >= plan && plan > 0;
  const spart    = splitSum > 0 && !sfull;
  const splitCls = sfull ? 'split-covered' : spart ? 'split-partial' : plan > 0 ? 'split-uncovered' : '';
  const splitTxt = sfull ? '✓ Pokryty' : spart ? '⚡ '+fmt(splitSum)+' / '+fmt(plan)+' zł' : plan > 0 ? '✗ Niepokryty' : '';
  const n1 = esc(budgetData.coupleNames[0] || 'Osoba 1');
  const n2 = esc(budgetData.coupleNames[1] || 'Osoba 2');

  const catCtrl = e.category !== 'Inne'
    ? `<select class="exp-h-cat-select" id="exp-cat-wrap-${e.id}" onchange="updateExpenseCat(${e.id},this.value)">${selectedCatOpts}</select>`
    : `<span class="exp-cat-icon">&#128230;</span>
       <input class="exp-cat-inne-input exp-h-inne" type="text"
              value="${esc(e.customName||'Inne')}" placeholder="Własna nazwa…"
              onchange="updateExpense(${e.id},'customName',this.value)">
       <button class="exp-cat-change-btn" title="Zmień kategorię"
               onclick="openExpCatPicker(${e.id})">&#9660;</button>`;

  const dragHandle = isDrag
    ? `<div class="exp-drag-handle" title="Przeciągnij, aby zmienić kolejność">&#8801;</div>` : '';

  const dragAttrs = isDrag
    ? `draggable="true"
       ondragstart="onExpTileDragStart(event,${e.id})"
       ondragover="onExpTileDragOver(event,${e.id})"
       ondragleave="onExpTileDragLeave(event)"
       ondrop="onExpTileDrop(event,${e.id})"
       ondragend="onExpTileDragEnd()"` : '';

  return `<div class="expense-row ${statusCls}${isDrag?' exp-draggable':''}" id="exp-${e.id}" ${dragAttrs}>
    <div class="exp-h-main">
      ${dragHandle}
      <div class="exp-h-cat">${catCtrl}</div>
      <div class="exp-h-mid">
        <div class="exp-h-amt">
          <label>Ostateczna</label>
          <div class="exp-input-wrap">
            <input type="number" value="${plan||''}" min="0" step="0.01" placeholder="—"
                   onchange="updateExpense(${e.id},'planned',parseFloat(this.value)||0)">
            <span class="currency-sm">zł</span>
          </div>
        </div>
        <div class="exp-h-amt">
          <label><span class="exp-tilde">~</span>&nbsp;Przewid.${diffHtml}</label>
          <div class="exp-input-wrap">
            <input type="number" value="${est||''}" min="0" step="0.01" placeholder="—"
                   class="exp-est-input${isPred ? ' exp-est-only' : ''}"
                   onchange="updateExpense(${e.id},'estimatedAmount',parseFloat(this.value)||0)">
            <span class="currency-sm">zł</span>
          </div>
        </div>
        <div class="exp-h-amt">
          <label>Opłacono</label>
          <div class="exp-input-wrap">
            <input type="number" value="${paid||''}" min="0" step="0.01" placeholder="—"
                   onchange="updateExpense(${e.id},'paid',parseFloat(this.value)||0)">
            <span class="currency-sm">zł</span>
          </div>
        </div>
      </div>
      <div class="exp-h-right">
        <span class="exp-status-badge ${badgeCls}">${badgeTxt}</span>
        <input type="date" class="exp-h-date" value="${esc(e.paymentDate||'')}"
               onchange="updateExpense(${e.id},'paymentDate',this.value)">
        <button class="btn-row-edit" onclick="toggleExpenseSidePanel(${e.id})" title="${e.sidePanel ? 'Przenieś do głównej listy' : 'Przenieś do panelu bocznego'}">&#8646;</button>
        <button class="btn-row-edit" onclick="openEditModal('expense',${e.id})" title="Edytuj">&#9998;</button>
        <button class="btn-exp-expand" id="exp-expand-btn-${e.id}" onclick="toggleExpDetail(${e.id})" title="Notatka / podział">&#8942;</button>
        <button class="btn-exp-del" onclick="deleteExpense(${e.id})" title="Usuń">&#128465;</button>
      </div>
    </div>
    ${effective > 0 ? `<div class="exp-mini-bar${isPred ? ' exp-mini-bar-est' : ''}"><div class="exp-mini-fill" style="width:${pct}%"></div></div>` : ''}
    <div class="exp-h-detail" id="exp-detail-${e.id}">
      <input type="text" class="exp-note" placeholder="Notatka…" value="${esc(e.note||'')}"
             onchange="updateExpense(${e.id},'note',this.value)">
      <div class="exp-split-section">
        <div class="exp-split-hdr">Podział kosztów${splitTxt ? ` &nbsp;<span class="exp-split-badge ${splitCls}">${splitTxt}</span>` : ''}</div>
        <div class="exp-split-row">
          <div class="exp-split-col">
            <label>${n1}:</label>
            <div class="exp-input-wrap">
              <input type="number" value="${sp1}" min="0" step="0.01"
                     onchange="updateExpense(${e.id},'splitP1',parseFloat(this.value)||0)">
              <span class="currency-sm">zł</span>
            </div>
          </div>
          <div class="exp-split-col">
            <label>${n2}:</label>
            <div class="exp-input-wrap">
              <input type="number" value="${sp2}" min="0" step="0.01"
                     onchange="updateExpense(${e.id},'splitP2',parseFloat(this.value)||0)">
              <span class="currency-sm">zł</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>`;
}

function toggleExpDetail(id) {
  const panel = document.getElementById('exp-detail-' + id);
  const btn   = document.getElementById('exp-expand-btn-' + id);
  if (!panel) return;
  const open = panel.classList.toggle('exp-detail-open');
  if (btn) btn.classList.toggle('exp-expand-active', open);
}

function renderExpenses() {
  const container = document.getElementById('expensesList');
  const summary   = document.getElementById('expSummary');
  const filtersBar = document.getElementById('expFiltersBar');
  _fillVendorPicker('expVendorPick', '+ Z dostawcy');
  renderExpenseQuickAdd();

  const hasExpenses = budgetData.expenses.length > 0;
  if (filtersBar) filtersBar.style.display = hasExpenses ? '' : 'none';
  if (hasExpenses) renderExpenseFilters();

  if (!hasExpenses) {
    container.innerHTML = '<div class="empty-list">Brak wydatków. Kliknij + Dodaj.</div>';
    if (summary) summary.style.display = 'none';
    return;
  }

  const isDrag    = expenseSort.field === null;
  const toShow    = getExpensesToShow();

  if (!toShow.length) {
    container.innerHTML = '<div class="empty-list">Brak wydatków spełniających kryteria filtrów.</div>';
  } else {
    container.innerHTML = toShow.map(e => renderExpenseTile(e, isDrag)).join('');
  }

  const expPlan = calcExpensesPlanned();
  const expEst  = calcExpensesEstimated();
  const expPaid = calcExpensesPaid();
  document.getElementById('expSumPlanned').textContent   = fmt(expPlan) + ' zł';
  document.getElementById('expSumEstimated').textContent = fmt(expEst)  + ' zł';
  document.getElementById('expSumPaid').textContent      = fmt(expPaid) + ' zł';
  document.getElementById('expSumRem').textContent       = fmt(Math.max(0, expPlan - expPaid)) + ' zł';
  if (summary) summary.style.display = 'block';

  renderExpenseSidePanels();
  applyAlcoholPanelVisibility();
}

// Wydatki oznaczone jako „panel boczny" — w prawej kolumnie, obok alkoholu
function renderExpenseSidePanels() {
  const cont = document.getElementById('expenseSidePanels');
  if (!cont) return;
  const side = budgetData.expenses.filter(e => e.sidePanel);
  cont.innerHTML = side.map(e => `
    <div class="expense-side-panel">
      <div class="esp-hdr">
        <span class="esp-title">${esc((e.category === 'Inne' ? (e.customName || 'Wydatek') : e.category))}</span>
      </div>
      ${renderExpenseTile(e, false)}
    </div>`).join('');
}

// Pokaż/ukryj panel alkoholu
function applyAlcoholPanelVisibility() {
  const section = document.getElementById('alcoholSection');
  const restore = document.getElementById('restoreAlcoholBtn');
  const hidden  = !!budgetData.alcoholPanelHidden;
  if (section) section.style.display = hidden ? 'none' : '';
  if (restore) restore.style.display = hidden ? '' : 'none';
}
function hideAlcoholPanel() {
  budgetData.alcoholPanelHidden = true;
  applyAlcoholPanelVisibility();
  saveState();
}
function showAlcoholPanel() {
  budgetData.alcoholPanelHidden = false;
  applyAlcoholPanelVisibility();
  saveState();
}
function toggleExpenseSidePanel(id) {
  const e = budgetData.expenses.find(x => x.id === id);
  if (!e) return;
  e.sidePanel = !e.sidePanel;
  renderExpenses();
  renderCoupleSummary();
  renderBudgetOverview();
  renderCharts();
  saveState();
}

// ── ALKOHOL ──────────────────────────────────────────────────────────────

const ALCOHOL_TYPES = ['Wódka','Wino','Piwo','Szampan','Whisky','Nalewka','Gin','Rum','Inne'];

function addAlcohol() {
  if (!budgetData.alcoholItems) budgetData.alcoholItems = [];
  budgetData.alcoholItems.push({
    id: budgetData.nextAlcoholId = (budgetData.nextAlcoholId || 0) + 1,
    type: 'Wódka', name: '', bottles: 0, pricePerBottle: 0,
  });
  renderAlcohol(); renderBudgetOverview(); renderCharts(); saveState();
}

function updateAlcohol(id, field, value) {
  const item = (budgetData.alcoholItems || []).find(i => i.id === id);
  if (!item) return;
  item[field] = value;
  renderAlcohol(); renderBudgetOverview(); renderCharts(); saveState();
}

function updateAlcoholSplit(field, value) {
  budgetData[field] = value;
  renderAlcohol(); saveState();
}

function deleteAlcohol(id) {
  budgetData.alcoholItems = (budgetData.alcoholItems || []).filter(i => i.id !== id);
  renderAlcohol(); renderBudgetOverview(); renderCharts(); saveState();
}

function renderAlcohol() {
  const listEl    = document.getElementById('alcoholList');
  const summaryEl = document.getElementById('alcoholSummary');
  if (!listEl || !summaryEl) return;

  const items = budgetData.alcoholItems || [];

  if (!items.length) {
    listEl.innerHTML    = '<div class="alcohol-empty">Kliknij + Dodaj, aby dodać pozycje alkoholu.</div>';
    summaryEl.innerHTML = '';
    return;
  }

  listEl.innerHTML = items.map(item => {
    const total    = (item.bottles || 0) * (item.pricePerBottle || 0);
    const typeOpts = ALCOHOL_TYPES.map(t =>
      `<option value="${t}"${item.type === t ? ' selected' : ''}>${t}</option>`).join('');
    return `
    <div class="alcohol-item-row" id="alc-${item.id}">
      <div class="alc-row-top">
        <select class="alc-type-sel" onchange="updateAlcohol(${item.id},'type',this.value)">${typeOpts}</select>
        <input type="text" class="alc-name-inp" value="${esc(item.name||'')}" placeholder="Marka / nazwa (opcjonalnie)"
               onchange="updateAlcohol(${item.id},'name',this.value)">
        <button class="btn-alc-del" onclick="deleteAlcohol(${item.id})" title="Usuń">&#128465;</button>
      </div>
      <div class="alc-row-bottom">
        <div class="alc-field">
          <label>Butelki</label>
          <input type="number" class="alc-num-inp" value="${item.bottles||''}" min="0" step="1" placeholder="0"
                 onchange="updateAlcohol(${item.id},'bottles',parseFloat(this.value)||0)">
        </div>
        <div class="alc-operator">×</div>
        <div class="alc-field">
          <label>Cena/szt. (zł)</label>
          <input type="number" class="alc-num-inp" value="${item.pricePerBottle||''}" min="0" step="0.01" placeholder="0,00"
                 onchange="updateAlcohol(${item.id},'pricePerBottle',parseFloat(this.value)||0)">
        </div>
        <div class="alc-operator">=</div>
        <div class="alc-total-wrap">
          <label>Łącznie</label>
          <span class="alc-total-val">${fmt(total)} zł</span>
        </div>
      </div>
    </div>`;
  }).join('');

  const totalBottles = calcAlcoholBottles();
  const totalCost    = calcAlcoholTotal();
  const [p1Name, p2Name] = budgetData.coupleNames || ['Osoba 1', 'Osoba 2'];
  const splitP1 = budgetData.alcoholSplitP1 || 0;
  const splitP2 = budgetData.alcoholSplitP2 || 0;
  const splitSum = splitP1 + splitP2;
  const overWarn = splitSum > totalCost + 0.01 && totalCost > 0;
  // Przeliczenie na osobę (opcjonalnie z gośćmi wirtualnymi)
  const perVirt   = !!budgetData.alcoholPerPersonVirtual;
  const pc        = _bevPersonCount(perVirt);
  const perBottles= pc ? (totalBottles / pc) : 0;
  const perCost   = pc ? (totalCost / pc) : 0;

  summaryEl.innerHTML = `
  <div class="alcohol-summary">
    <div class="alc-sum-stats">
      <div class="alc-sum-stat">
        <div class="alc-sum-stat-val">${totalBottles}</div>
        <div class="alc-sum-stat-lbl">butelek łącznie</div>
      </div>
      <div class="alc-sum-stat-sep"></div>
      <div class="alc-sum-stat">
        <div class="alc-sum-stat-val alc-cost-val">${fmt(totalCost)} zł</div>
        <div class="alc-sum-stat-lbl">łączny koszt</div>
      </div>
      <div class="alc-sum-stat-sep"></div>
      <div class="alc-sum-stat">
        <div class="alc-sum-stat-val">${pc ? perBottles.toFixed(2) : '—'}</div>
        <div class="alc-sum-stat-lbl">butelek / os.</div>
      </div>
      <div class="alc-sum-stat-sep"></div>
      <div class="alc-sum-stat">
        <div class="alc-sum-stat-val alc-cost-val">${pc ? fmt(perCost) + ' zł' : '—'}</div>
        <div class="alc-sum-stat-lbl">koszt / os.${pc ? ' (' + pc + ' os.)' : ''}</div>
      </div>
    </div>
    <label class="bev-perperson-toggle"><input type="checkbox" ${perVirt ? 'checked' : ''} onchange="updateAlcoholSplit('alcoholPerPersonVirtual', this.checked)"> Uwzględniaj gości wirtualnych (min. sali) w przeliczeniu na osobę</label>
    <div class="alc-split-section">
      <div class="alc-split-title">&#9878; Podział kosztów</div>
      <div class="alc-split-row">
        <div class="alc-split-col">
          <label>${esc(p1Name)}</label>
          <div class="exp-input-wrap">
            <input type="number" value="${splitP1||''}" min="0" step="0.01" placeholder="0,00"
                   onchange="updateAlcoholSplit('alcoholSplitP1',parseFloat(this.value)||0)">
            <span class="currency-sm">zł</span>
          </div>
        </div>
        <div class="alc-split-col">
          <label>${esc(p2Name)}</label>
          <div class="exp-input-wrap">
            <input type="number" value="${splitP2||''}" min="0" step="0.01" placeholder="0,00"
                   onchange="updateAlcoholSplit('alcoholSplitP2',parseFloat(this.value)||0)">
            <span class="currency-sm">zł</span>
          </div>
        </div>
      </div>
      ${overWarn ? `<div class="alc-split-warn">&#9888; Suma podziału (${fmt(splitSum)} zł) przekracza łączny koszt (${fmt(totalCost)} zł)</div>` : ''}
    </div>
  </div>`;
}

// ══════════════════════════════════════════════════════
//  NAPOJE BEZALKOHOLOWE — sekcja analogiczna do alkoholu
// ══════════════════════════════════════════════════════
const SOFT_TYPES = ['Woda','Soki','Napoje gazowane','Kawa / Herbata','Energetyki','Inne'];
function addSoftDrink() {
  if (!budgetData.softItems) budgetData.softItems = [];
  budgetData.softItems.push({
    id: budgetData.nextSoftId = (budgetData.nextSoftId || 0) + 1,
    type: 'Woda', name: '', bottles: 0, pricePerBottle: 0,
  });
  renderSoftDrinks(); renderBudgetOverview(); renderCharts(); saveState();
}
function updateSoftDrink(id, field, value) {
  const item = (budgetData.softItems || []).find(i => i.id === id);
  if (!item) return;
  item[field] = value;
  renderSoftDrinks(); renderBudgetOverview(); renderCharts(); saveState();
}
function updateSoftSplit(field, value) {
  budgetData[field] = value;
  renderSoftDrinks(); saveState();
}
function deleteSoftDrink(id) {
  budgetData.softItems = (budgetData.softItems || []).filter(i => i.id !== id);
  renderSoftDrinks(); renderBudgetOverview(); renderCharts(); saveState();
}
function renderSoftDrinks() {
  const listEl    = document.getElementById('softList');
  const summaryEl = document.getElementById('softSummary');
  if (!listEl || !summaryEl) return;
  const items = budgetData.softItems || [];
  if (!items.length) {
    listEl.innerHTML    = '<div class="alcohol-empty">Kliknij + Dodaj, aby dodać napoje bezalkoholowe.</div>';
    summaryEl.innerHTML = '';
    return;
  }
  listEl.innerHTML = items.map(item => {
    const total    = (item.bottles || 0) * (item.pricePerBottle || 0);
    const typeOpts = SOFT_TYPES.map(t => `<option value="${t}"${item.type === t ? ' selected' : ''}>${t}</option>`).join('');
    return `
    <div class="alcohol-item-row" id="soft-${item.id}">
      <div class="alc-row-top">
        <select class="alc-type-sel" onchange="updateSoftDrink(${item.id},'type',this.value)">${typeOpts}</select>
        <input type="text" class="alc-name-inp" value="${esc(item.name||'')}" placeholder="Marka / nazwa (opcjonalnie)"
               onchange="updateSoftDrink(${item.id},'name',this.value)">
        <button class="btn-alc-del" onclick="deleteSoftDrink(${item.id})" title="Usuń">&#128465;</button>
      </div>
      <div class="alc-row-bottom">
        <div class="alc-field">
          <label>Sztuki</label>
          <input type="number" class="alc-num-inp" value="${item.bottles||''}" min="0" step="1" placeholder="0"
                 onchange="updateSoftDrink(${item.id},'bottles',parseFloat(this.value)||0)">
        </div>
        <div class="alc-operator">×</div>
        <div class="alc-field">
          <label>Cena/szt. (zł)</label>
          <input type="number" class="alc-num-inp" value="${item.pricePerBottle||''}" min="0" step="0.01" placeholder="0,00"
                 onchange="updateSoftDrink(${item.id},'pricePerBottle',parseFloat(this.value)||0)">
        </div>
        <div class="alc-operator">=</div>
        <div class="alc-total-wrap">
          <label>Łącznie</label>
          <span class="alc-total-val">${fmt(total)} zł</span>
        </div>
      </div>
    </div>`;
  }).join('');

  const totalBottles = calcSoftBottles();
  const totalCost    = calcSoftTotal();
  const [p1Name, p2Name] = budgetData.coupleNames || ['Osoba 1', 'Osoba 2'];
  const splitP1 = budgetData.softSplitP1 || 0;
  const splitP2 = budgetData.softSplitP2 || 0;
  const splitSum = splitP1 + splitP2;
  const overWarn = splitSum > totalCost + 0.01 && totalCost > 0;
  const perVirt   = !!budgetData.softPerPersonVirtual;
  const pc        = _bevPersonCount(perVirt);
  const perBottles= pc ? (totalBottles / pc) : 0;
  const perCost   = pc ? (totalCost / pc) : 0;

  summaryEl.innerHTML = `
  <div class="alcohol-summary">
    <div class="alc-sum-stats">
      <div class="alc-sum-stat">
        <div class="alc-sum-stat-val">${totalBottles}</div>
        <div class="alc-sum-stat-lbl">sztuk łącznie</div>
      </div>
      <div class="alc-sum-stat-sep"></div>
      <div class="alc-sum-stat">
        <div class="alc-sum-stat-val alc-cost-val">${fmt(totalCost)} zł</div>
        <div class="alc-sum-stat-lbl">łączny koszt</div>
      </div>
      <div class="alc-sum-stat-sep"></div>
      <div class="alc-sum-stat">
        <div class="alc-sum-stat-val">${pc ? perBottles.toFixed(2) : '—'}</div>
        <div class="alc-sum-stat-lbl">sztuk / os.</div>
      </div>
      <div class="alc-sum-stat-sep"></div>
      <div class="alc-sum-stat">
        <div class="alc-sum-stat-val alc-cost-val">${pc ? fmt(perCost) + ' zł' : '—'}</div>
        <div class="alc-sum-stat-lbl">koszt / os.${pc ? ' (' + pc + ' os.)' : ''}</div>
      </div>
    </div>
    <label class="bev-perperson-toggle"><input type="checkbox" ${perVirt ? 'checked' : ''} onchange="updateSoftSplit('softPerPersonVirtual', this.checked)"> Uwzględniaj gości wirtualnych (min. sali) w przeliczeniu na osobę</label>
    <div class="alc-split-section">
      <div class="alc-split-title">&#9878; Podział kosztów</div>
      <div class="alc-split-row">
        <div class="alc-split-col">
          <label>${esc(p1Name)}</label>
          <div class="exp-input-wrap">
            <input type="number" value="${splitP1||''}" min="0" step="0.01" placeholder="0,00"
                   onchange="updateSoftSplit('softSplitP1',parseFloat(this.value)||0)">
            <span class="currency-sm">zł</span>
          </div>
        </div>
        <div class="alc-split-col">
          <label>${esc(p2Name)}</label>
          <div class="exp-input-wrap">
            <input type="number" value="${splitP2||''}" min="0" step="0.01" placeholder="0,00"
                   onchange="updateSoftSplit('softSplitP2',parseFloat(this.value)||0)">
            <span class="currency-sm">zł</span>
          </div>
        </div>
      </div>
      ${overWarn ? `<div class="alc-split-warn">&#9888; Suma podziału (${fmt(splitSum)} zł) przekracza łączny koszt (${fmt(totalCost)} zł)</div>` : ''}
    </div>
  </div>`;
}

// ── EXPENSE TILE DRAG & DROP ──
function onExpTileDragStart(event, id) {
  expTileDragId = id;
  event.dataTransfer.effectAllowed = 'move';
  event.dataTransfer.setData('text/plain', String(id));
  setTimeout(() => document.getElementById('exp-'+id)?.classList.add('exp-tile-dragging'), 0);
}

function onExpTileDragOver(event, id) {
  if (expTileDragId === null || expTileDragId === id) return;
  event.preventDefault();
  event.dataTransfer.dropEffect = 'move';
  document.querySelectorAll('.expense-row.exp-drag-over-top, .expense-row.exp-drag-over-bot')
    .forEach(el => { el.classList.remove('exp-drag-over-top','exp-drag-over-bot'); });
  const el = document.getElementById('exp-'+id);
  if (!el) return;
  const rect = el.getBoundingClientRect();
  el.classList.add(event.clientY < rect.top + rect.height / 2 ? 'exp-drag-over-top' : 'exp-drag-over-bot');
}

function onExpTileDragLeave(event) {
  event.currentTarget.classList.remove('exp-drag-over-top','exp-drag-over-bot');
}

function onExpTileDrop(event, targetId) {
  event.preventDefault();
  document.querySelectorAll('.expense-row.exp-drag-over-top,.expense-row.exp-drag-over-bot')
    .forEach(el => { el.classList.remove('exp-drag-over-top','exp-drag-over-bot'); });
  if (expTileDragId === null || expTileDragId === targetId) return;

  const fromIdx = expenseOrder.indexOf(expTileDragId);
  if (fromIdx === -1) return;

  const targetEl = document.getElementById('exp-'+targetId);
  const toIdx    = expenseOrder.indexOf(targetId);
  if (toIdx === -1) return;

  let insertBefore = true;
  if (targetEl) {
    const rect = targetEl.getBoundingClientRect();
    insertBefore = event.clientY < rect.top + rect.height / 2;
  }

  expenseOrder.splice(fromIdx, 1);
  const newToIdx = expenseOrder.indexOf(targetId);
  expenseOrder.splice(insertBefore ? newToIdx : newToIdx + 1, 0, expTileDragId);

  saveState();
  renderExpenses();
}

function onExpTileDragEnd() {
  document.querySelectorAll('.expense-row').forEach(el =>
    el.classList.remove('exp-tile-dragging','exp-drag-over-top','exp-drag-over-bot')
  );
  expTileDragId = null;
}

// ── SURGICAL DOM HELPERS ──
function _refreshExpenseRow(expId) {
  const e   = budgetData.expenses.find(x => x.id === expId);
  const row = document.getElementById(`exp-${expId}`);
  if (!e || !row) return;

  const paid = e.paid || 0, plan = e.planned || 0;
  const isPaid    = paid >= plan && plan > 0;
  const isPartial = paid > 0 && !isPaid;
  const key = isPaid ? 'paid' : isPartial ? 'partial' : 'unpaid';
  const labels = { paid: '✓ Opłacone', partial: '⚡ Częściowo', unpaid: '✗ Nieopłacone' };

  row.className = `expense-row exp-${key}`;

  const badge = row.querySelector('.exp-status-badge');
  if (badge) {
    badge.className = `exp-status-badge exp-badge-${key}`;
    badge.textContent = labels[key];
  }

  const fill = row.querySelector('.exp-mini-fill');
  if (fill) fill.style.width = (plan > 0 ? Math.min(100, paid / plan * 100) : 0) + '%';

  const splitBadge = row.querySelector('.exp-split-badge');
  if (splitBadge) {
    const sp1 = e.splitP1 || 0, sp2 = e.splitP2 || 0;
    const splitSum = sp1 + sp2;
    const sfull = splitSum >= plan && plan > 0;
    const spart = splitSum > 0 && !sfull;
    const sCls = sfull ? 'split-covered' : spart ? 'split-partial' : plan > 0 ? 'split-uncovered' : '';
    const sTxt = sfull ? '✓ Pokryty' : spart ? '⚡ ' + fmt(splitSum) + ' / ' + fmt(plan) + ' zł' : plan > 0 ? '✗ Niepokryty' : '';
    splitBadge.className = 'exp-split-badge ' + sCls;
    splitBadge.textContent = sTxt;
  }

  _refreshExpenseSummary();
}

function _refreshExpenseSummary() {
  const p  = calcExpensesPlanned();
  const es = calcExpensesEstimated();
  const q  = calcExpensesPaid();
  const sp = document.getElementById('expSumPlanned');
  const se = document.getElementById('expSumEstimated');
  const sq = document.getElementById('expSumPaid');
  const sr = document.getElementById('expSumRem');
  const sm = document.getElementById('expSummary');
  if (sp) sp.textContent = fmt(p)  + ' zł';
  if (se) se.textContent = fmt(es) + ' zł';
  if (sq) sq.textContent = fmt(q)  + ' zł';
  if (sr) sr.textContent = fmt(Math.max(0, p - q)) + ' zł';
  if (sm) sm.style.display = budgetData.expenses.length ? 'block' : 'none';
}

// ── COUPLE SPLIT SUMMARY ──
function updateCoupleName(index, name) {
  budgetData.coupleNames[index] = name;
  renderExpenses();
  renderCoupleSummary();
  saveState();
}

function renderCoupleSummary() {
  const card = document.getElementById('coupleCard');
  if (!card) return;

  const n1 = budgetData.coupleNames[0] || 'Osoba 1';
  const n2 = budgetData.coupleNames[1] || 'Osoba 2';
  const total1 = budgetData.expenses.reduce((s, e) => s + (e.splitP1 || 0), 0);
  const total2 = budgetData.expenses.reduce((s, e) => s + (e.splitP2 || 0), 0);
  const diff   = total1 - total2;
  const absDiff = Math.abs(diff);

  let balanceHtml;
  if (!budgetData.expenses.length) {
    balanceHtml = '<div class="couple-no-expenses">Dodaj wydatki i podział, aby zobaczyć bilans</div>';
  } else if (absDiff < 0.01) {
    balanceHtml = '<div class="couple-balance">Koszty są <strong>równo podzielone</strong> ✓</div>';
  } else {
    const payer    = diff > 0 ? esc(n1) : esc(n2);
    const receiver = diff > 0 ? esc(n2) : esc(n1);
    balanceHtml = `<div class="couple-balance">${payer} płaci więcej o <strong>${fmt(absDiff)} zł</strong><br><small>dokłada do wydatków: ${receiver}</small></div>`;
  }

  card.innerHTML = `
    <div class="extra-card-header">&#128145; Podział kosztów pary</div>
    <div class="extra-card-body">
      <div class="couple-names-row">
        <div class="couple-name-edit">
          <label>Imię 1:</label>
          <input type="text" class="couple-name-input" value="${esc(n1)}"
                 onchange="updateCoupleName(0,this.value)" placeholder="Imię">
        </div>
        <div class="couple-name-edit">
          <label>Imię 2:</label>
          <input type="text" class="couple-name-input" value="${esc(n2)}"
                 onchange="updateCoupleName(1,this.value)" placeholder="Imię">
        </div>
      </div>
      <div class="couple-totals">
        <div class="couple-person-row">
          <span class="couple-person-name">${esc(n1)}:</span>
          <span class="couple-person-val">${fmt(total1)} zł</span>
        </div>
        <div class="couple-person-row">
          <span class="couple-person-name">${esc(n2)}:</span>
          <span class="couple-person-val">${fmt(total2)} zł</span>
        </div>
        ${balanceHtml}
      </div>
    </div>`;
}

// ── COST PER TABLE ──
function renderCostPerTable() {
  const card = document.getElementById('costPerTableCard');
  if (!card) return;

  const effCount       = getEffectiveGuestCount();
  const cateringBase   = calcCateringBase() + calcVirtualGuestsCost();
  const menuAddTotal   = calcMenuAddonsTotal();
  const tableDecoAmt   = calcTableDecoTotal();
  const cateringTotal  = cateringBase + menuAddTotal + tableDecoAmt;
  const otherExp       = calcExpensesPlanned();
  const honeymoonTotal = (budgetData.honeymoon || {}).totalAmount || 0;
  const grandTotal     = cateringTotal + otherExp + honeymoonTotal;

  if (!effCount) {
    card.innerHTML = `
      <div class="extra-card-header">&#128101; Koszt na osobę</div>
      <div class="extra-card-body"><div class="cpt-no-tables">Brak gości przy stolikach</div></div>`;
    return;
  }

  const r = n => effCount > 0 ? fmt(n / effCount) : '0,00';

  card.innerHTML = `
    <div class="extra-card-header">&#128101; Koszt na osobę</div>
    <div class="extra-card-body">
      <div class="cpt-stat cpt-basis"><span>Podstawa oblicze&#324;:</span><strong>${effCount} os.</strong></div>
      <div class="cpt-stat cpt-indent"><span>&#8627; Catering bazowy:</span><strong>${r(cateringBase)} z&#322;</strong></div>
      ${menuAddTotal > 0 ? `<div class="cpt-stat cpt-indent"><span>&#8627; Dodatki do menu:</span><strong>${r(menuAddTotal)} z&#322;</strong></div>` : ''}
      ${tableDecoAmt > 0 ? `<div class="cpt-stat cpt-indent"><span>&#8627; Dekoracje sto&#322;&#243;w:</span><strong>${r(tableDecoAmt)} z&#322;</strong></div>` : ''}
      <div class="cpt-stat"><span>Catering &#322;&#261;cznie:</span><strong>${r(cateringTotal)} z&#322;</strong></div>
      ${otherExp > 0 ? `<div class="cpt-stat"><span>Inne wydatki:</span><strong>${r(otherExp)} z&#322;</strong></div>` : ''}
      ${honeymoonTotal > 0 ? `<div class="cpt-stat"><span>Podr&#243;&#380; po&#347;lubna:</span><strong>${r(honeymoonTotal)} z&#322;</strong></div>` : ''}
      <div class="cpt-stat cpt-main"><span>Koszt / osoba:</span><strong>${r(grandTotal)} z&#322;</strong></div>
      <div class="cpt-note">Tylko do wgl&#261;du organizator&#243;w</div>
    </div>`;
}

// ── CHARTS ──
function renderCharts() {
  renderPieChart();
  renderBarChart();
  renderProgressChart();
}

function pieChartSvg(data, size) {
  const total = data.reduce((s, d) => s + d.value, 0);
  if (!total) return null;
  const cx = size / 2, cy = size / 2, r = size / 2 - 8, ri = r * 0.54;
  let angle = -Math.PI / 2;
  const paths = data.map(d => {
    if (!d.value) return '';
    const slice = (d.value / total) * 2 * Math.PI;
    const x1 = cx + r * Math.cos(angle),   y1 = cy + r * Math.sin(angle);
    const ex = cx + r * Math.cos(angle + slice), ey = cy + r * Math.sin(angle + slice);
    const xi = cx + ri * Math.cos(angle),  yi = cy + ri * Math.sin(angle);
    const xie= cx + ri * Math.cos(angle + slice), yie= cy + ri * Math.sin(angle + slice);
    const lg = slice > Math.PI ? 1 : 0;
    const path = `M${xi.toFixed(1)},${yi.toFixed(1)} L${x1.toFixed(1)},${y1.toFixed(1)} A${r},${r} 0 ${lg},1 ${ex.toFixed(1)},${ey.toFixed(1)} L${xie.toFixed(1)},${yie.toFixed(1)} A${ri},${ri} 0 ${lg},0 ${xi.toFixed(1)},${yi.toFixed(1)} Z`;
    angle += slice;
    return `<path d="${path}" fill="${d.color}" stroke="white" stroke-width="1.5"/>`;
  }).join('');
  return `<svg width="${size}" height="${size}" viewBox="0 0 ${size} ${size}" xmlns="http://www.w3.org/2000/svg">${paths}</svg>`;
}

function renderPieChart() {
  const container = document.getElementById('chartPieBody');
  const legend    = document.getElementById('chartPieLegend');
  if (!container) return;

  const items = [];
  const catering = calcCateringTotal();
  if (catering > 0) items.push({ label: 'Catering', value: catering, color: '#1a56db' });

  const grouped = {};
  budgetData.expenses.forEach(e => {
    if (!grouped[e.category]) grouped[e.category] = 0;
    grouped[e.category] += (e.planned || 0);
  });
  Object.entries(grouped).forEach(([cat, val]) => {
    if (val > 0) {
      const cfg = EXPENSE_CATEGORIES.find(c => c.name === cat);
      items.push({ label: cat, value: val, color: cfg?.color || '#94a3b8' });
    }
  });

  const alcoholTotal = calcAlcoholTotal();
  if (alcoholTotal > 0) items.push({ label: 'Alkohol', value: alcoholTotal, color: '#7c3aed' });

  if (!items.length) {
    container.innerHTML = '<div class="chart-empty">Brak danych</div>';
    legend.innerHTML = '';
    return;
  }

  const svg = pieChartSvg(items, 180);
  container.innerHTML = svg || '<div class="chart-empty">Brak danych</div>';
  legend.innerHTML = items.map(d => `
    <div class="legend-row">
      <span class="legend-dot" style="background:${d.color}"></span>
      <span class="legend-label">${esc(d.label)}</span>
      <span class="legend-val">${fmt(d.value)} zł</span>
    </div>`).join('');
}

function renderBarChart() {
  const container = document.getElementById('chartBarBody');
  if (!container) return;
  const data = budgetData.expenses
    .filter(e => e.planned || e.paid)
    .slice(0, 10)
    .map(e => {
      const cfg = EXPENSE_CATEGORIES.find(c => c.name === e.category);
      const shortLabel = e.category.length > 8 ? e.category.substring(0, 7) + '…' : e.category;
      return { label: shortLabel, planned: e.planned || 0, paid: e.paid || 0, color: cfg?.color || '#94a3b8' };
    });

  if (!data.length) { container.innerHTML = '<div class="chart-empty">Brak danych</div>'; return; }

  const W = 320, H = 190, ml = 36, mr = 8, mt = 10, mb = 44;
  const pw = W - ml - mr, ph = H - mt - mb;
  const maxVal = Math.max(...data.flatMap(d => [d.planned, d.paid]), 1);
  const gw = pw / data.length;
  const bw = Math.min(gw * 0.34, 22);

  let s = '';
  // Grid
  for (let i = 0; i <= 4; i++) {
    const y = mt + ph - (ph * i / 4);
    const v = (maxVal * i / 4);
    s += `<line x1="${ml}" y1="${y.toFixed(1)}" x2="${ml+pw}" y2="${y.toFixed(1)}" stroke="#e2ecfa" stroke-width="1"/>`;
    s += `<text x="${(ml-4).toFixed(0)}" y="${(y+3).toFixed(0)}" text-anchor="end" font-size="7.5" fill="#8ba8d8">${v>=1000?(v/1000).toFixed(1)+'k':Math.round(v)}</text>`;
  }
  data.forEach((d, i) => {
    const cx = ml + i * gw + gw / 2;
    const h1 = (d.planned / maxVal) * ph, h2 = (d.paid / maxVal) * ph;
    s += `<rect x="${(cx-bw-2).toFixed(1)}" y="${(mt+ph-h1).toFixed(1)}" width="${bw}" height="${h1.toFixed(1)}" fill="#76b5f7" rx="2"/>`;
    s += `<rect x="${(cx+2).toFixed(1)}"     y="${(mt+ph-h2).toFixed(1)}" width="${bw}" height="${h2.toFixed(1)}" fill="#1a56db" rx="2"/>`;
    s += `<text x="${cx.toFixed(0)}" y="${(H-mb+14).toFixed(0)}" text-anchor="middle" font-size="7.5" fill="#5a6a8a">${esc(d.label)}</text>`;
  });
  s += `<line x1="${ml}" y1="${mt+ph}" x2="${ml+pw}" y2="${mt+ph}" stroke="#c5d8f6" stroke-width="1.5"/>`;
  // Legend
  s += `<rect x="${W-72}" y="3" width="9" height="9" fill="#76b5f7" rx="1.5"/>`;
  s += `<text x="${W-60}" y="11" font-size="7.5" fill="#5a6a8a">Planowane</text>`;
  s += `<rect x="${W-72}" y="15" width="9" height="9" fill="#1a56db" rx="1.5"/>`;
  s += `<text x="${W-60}" y="23" font-size="7.5" fill="#5a6a8a">Opłacone</text>`;

  container.innerHTML = `<svg width="${W}" height="${H}" viewBox="0 0 ${W} ${H}" xmlns="http://www.w3.org/2000/svg">${s}</svg>`;
}

function renderProgressChart() {
  const container = document.getElementById('chartProgBody');
  if (!container) return;
  const items = budgetData.expenses.filter(e => e.planned || e.paid);
  if (!items.length) { container.innerHTML = '<div class="chart-empty">Brak danych</div>'; return; }

  container.innerHTML = `<div style="width:100%;display:flex;flex-direction:column;gap:8px;padding:4px 0">` +
    items.map(e => {
      const plan = e.planned || 0, paid = e.paid || 0;
      const pct  = plan > 0 ? Math.min(100, (paid / plan) * 100) : 0;
      const fillCls = pct >= 100 ? 'prog-fill-full' : pct > 0 ? 'prog-fill-partial' : 'prog-fill-zero';
      const cfg = EXPENSE_CATEGORIES.find(c => c.name === e.category);
      const nm  = _expenseLabel(e);
      const lbl = nm.length > 16 ? nm.substring(0, 14) + '…' : nm;
      return `<div class="prog-item">
        <div class="prog-label">
          <span>${cfg?.icon || ''} ${esc(lbl)}</span>
          <span class="prog-label-val">${Math.round(pct)}%</span>
        </div>
        <div class="prog-bg">
          <div class="prog-fill ${fillCls}" style="width:${pct}%"></div>
        </div>
      </div>`;
    }).join('') + `</div>`;
}

// ── ROOM PLAN ──
// ══════════════════════════════════════════════
//  MOBILE COLLAPSIBLE SECTIONS
// ══════════════════════════════════════════════

const MOB_COLLAPSE_KEY = 'mob-collapse-v2';

const MOB_SECTION_LABELS = {
  'btabPanel-catering':  '🍽 Koszty stołów',
  'btabPanel-expenses':  '📋 Wydatki i Alkohol',
  'btabPanel-honeymoon': '✈️ Podróż poślubna',
  'btabPanel-payments':  '💳 Harmonogram płatności',
  'btabPanel-summary':   '📊 Podsumowanie',
};

const MOB_CARD_TARGETS = [
  { sel: '.menu-addons-card:not(.table-deco-card)', hdrSel: '.menu-addons-header', key: 'menuAddons' },
  { sel: '.table-deco-card',                         hdrSel: '.menu-addons-header', key: 'tableDeco'  },
  { sel: '.vguests-card',                            hdrSel: '.vguests-header',     key: 'vguests'    },
  { sel: '.staff-budget-card',                       hdrSel: '.staff-budget-header',key: 'staff'      },
  { sel: '.alcohol-section',                         hdrSel: '.alcohol-section-hdr',key: 'alcohol'    },
];

function _getMobState() {
  try { return JSON.parse(localStorage.getItem(MOB_COLLAPSE_KEY) || '{}'); }
  catch { return {}; }
}
function _saveMobState(state) {
  try { localStorage.setItem(MOB_COLLAPSE_KEY, JSON.stringify(state)); } catch {}
}

function toggleMobSection(key, btn) {
  // btn lives inside the header element; header lives inside the wrapper
  const hdrEl  = btn.parentElement;
  const wrapper = hdrEl.parentElement;
  if (!wrapper) return;

  const nowCollapsed = !wrapper.classList.contains('mob-collapsed');
  wrapper.classList.toggle('mob-collapsed', nowCollapsed);

  Array.from(wrapper.children).forEach(child => {
    if (child !== hdrEl) child.style.display = nowCollapsed ? 'none' : '';
  });

  btn.textContent = nowCollapsed ? '▼' : '▲';
  const state = _getMobState();
  state[key] = nowCollapsed;
  _saveMobState(state);
}

// Pasek statystyk: zwinięty = jedna linia (małe liczby), rozwinięty = pełny układ
function toggleStatsBar(btn) {
  const bar = document.getElementById('statsBar');
  if (!bar) return;
  const nowCollapsed = !bar.classList.contains('stats-collapsed');
  bar.classList.toggle('stats-collapsed', nowCollapsed);
  btn.textContent = nowCollapsed ? '▼' : '▲';
  const state = _getMobState();
  state.statsBar = nowCollapsed;
  _saveMobState(state);
}

// Pasek budżetu: zwinięty = tylko „Pozostało: <kwota>", rozwinięty = wszystkie wartości
function toggleBudgetBar(btn) {
  const bar = document.querySelector('.budget-overview');
  if (!bar) return;
  const nowCollapsed = !bar.classList.contains('budget-collapsed');
  bar.classList.toggle('budget-collapsed', nowCollapsed);
  btn.textContent = nowCollapsed ? '▼' : '▲';
  const state = _getMobState();
  state.budgetBar = nowCollapsed;
  _saveMobState(state);
}

function initMobileCollapse() {
  if (window.innerWidth > 768) return;
  const state = _getMobState();

  // 1. Budget tab panels → mobile section headers
  document.querySelectorAll('.btab-panel').forEach(panel => {
    if (panel.querySelector(':scope > .mob-section-hdr')) return; // already done

    const key   = panel.id;
    const title = MOB_SECTION_LABELS[key] || key;
    const collapsed = !!state[key];

    const hdr = document.createElement('div');
    hdr.className = 'mob-section-hdr';
    hdr.innerHTML = `<span class="mob-section-hdr-title">${title}</span>
      <button class="mob-toggle-btn" onclick="toggleMobSection('${key}',this)">${collapsed ? '▼' : '▲'}</button>`;
    panel.insertBefore(hdr, panel.firstChild);

    if (collapsed) {
      Array.from(panel.children).forEach((child, i) => {
        if (i > 0) child.style.display = 'none';
      });
    }
  });

  // 2. Specific cards with their own headers
  MOB_CARD_TARGETS.forEach(({ sel, hdrSel, key }) => {
    document.querySelectorAll(sel).forEach(card => {
      if (card.querySelector('.mob-toggle-btn')) return;
      const hdr = card.querySelector(hdrSel);
      if (!hdr) return;

      const collapsed = !!state[key];
      const btn = document.createElement('button');
      btn.className = 'mob-toggle-btn';
      btn.textContent = collapsed ? '▼' : '▲';
      btn.onclick = () => toggleMobSection(key, btn);
      hdr.appendChild(btn);

      if (collapsed) {
        Array.from(card.children).forEach(child => {
          if (child !== hdr) child.style.display = 'none';
        });
      }
    });
  });

  // 3. View section-containers (RSVP, Harmonogram, Zadania, Dostawcy, Transport, Noclegi, Prezenty)
  [
    ['viewRsvp',          'rsvp'],
    ['viewSchedule',      'schedule'],
    ['viewTasks',         'tasks'],
    ['viewVendors',       'vendors'],
    ['viewTransport',     'transport'],
    ['viewAccommodation', 'accommodation'],
    ['viewGifts',         'gifts'],
    ['viewGallery',       'gallery'],
    ['viewAccess',        'access'],
  ].forEach(([viewId, key]) => {
    const view = document.getElementById(viewId);
    if (!view) return;
    const container = view.querySelector('.section-container');
    if (!container) return;
    const hdr = container.querySelector('.section-header');
    if (!hdr || hdr.querySelector('.mob-toggle-btn')) return;
    const collapsed = !!state[key];
    const btn = document.createElement('button');
    btn.className = 'mob-toggle-btn';
    btn.textContent = collapsed ? '▼' : '▲';
    btn.onclick = () => toggleMobSection(key, btn);
    hdr.appendChild(btn);
    if (collapsed) {
      Array.from(container.children).forEach(child => {
        if (child !== hdr) child.style.display = 'none';
      });
    }
  });

  // 4. Tables view panels (Lista Gości, Plan Stołów)
  [
    ['panelGuests', '.panel-title', 'panelGuests'],
    ['panelTables', '.panel-title', 'panelTables'],
  ].forEach(([panelId, hdrSel, key]) => {
    const panel = document.getElementById(panelId);
    if (!panel) return;
    const hdr = panel.querySelector(hdrSel);
    if (!hdr || hdr.querySelector('.mob-toggle-btn')) return;
    const collapsed = !!state[key];
    const btn = document.createElement('button');
    btn.className = 'mob-toggle-btn';
    btn.textContent = collapsed ? '▼' : '▲';
    btn.onclick = () => toggleMobSection(key, btn);
    hdr.appendChild(btn);
    if (collapsed) {
      Array.from(panel.children).forEach(child => {
        if (child !== hdr) child.style.display = 'none';
      });
    }
  });

  // 5. Kanban columns (Zadania)
  document.querySelectorAll('.kanban-col').forEach((col, i) => {
    const hdr = col.querySelector('.kanban-col-hdr');
    if (!hdr || hdr.querySelector('.mob-toggle-btn')) return;
    const key = `kanban-${i}`;
    const collapsed = !!state[key];
    const btn = document.createElement('button');
    btn.className = 'mob-toggle-btn';
    btn.textContent = collapsed ? '▼' : '▲';
    btn.onclick = () => toggleMobSection(key, btn);
    hdr.appendChild(btn);
    if (collapsed) {
      Array.from(col.children).forEach(child => {
        if (child !== hdr) child.style.display = 'none';
      });
    }
  });

  // 6. Pasek statystyk (Stoły i goście) — domyślnie zwinięty do jednej linii
  const statsBar = document.getElementById('statsBar');
  if (statsBar && !statsBar.querySelector('.stats-toggle-btn')) {
    const collapsed = state.statsBar === undefined ? true : !!state.statsBar;
    statsBar.classList.toggle('stats-collapsed', collapsed);
    const btn = document.createElement('button');
    btn.className = 'mob-toggle-btn stats-toggle-btn';
    btn.textContent = collapsed ? '▼' : '▲';
    btn.onclick = () => toggleStatsBar(btn);
    statsBar.appendChild(btn);
  }

  // 7. Pasek budżetu całkowitego (Budżet) — strzałka zwijająca do „Pozostało"
  const budgetBar = document.querySelector('.budget-overview');
  if (budgetBar && !budgetBar.querySelector('.budget-toggle-btn')) {
    const collapsed = !!state.budgetBar; // domyślnie rozwinięty
    budgetBar.classList.toggle('budget-collapsed', collapsed);
    const btn = document.createElement('button');
    btn.className = 'mob-toggle-btn budget-toggle-btn';
    btn.textContent = collapsed ? '▼' : '▲';
    btn.onclick = () => toggleBudgetBar(btn);
    budgetBar.appendChild(btn);
  }
}

function toggleMobileNav() {
  const drawer   = document.getElementById('mobileDrawer');
  const backdrop = document.getElementById('mobileBackdrop');
  if (!drawer) return;
  const open = drawer.classList.toggle('mob-open');
  if (backdrop) backdrop.classList.toggle('mob-open', open);
  document.body.classList.toggle('mob-nav-open', open);
}

function closeMobileNav() {
  const drawer   = document.getElementById('mobileDrawer');
  const backdrop = document.getElementById('mobileBackdrop');
  if (drawer)   drawer.classList.remove('mob-open');
  if (backdrop) backdrop.classList.remove('mob-open');
  document.body.classList.remove('mob-nav-open');
}

function switchView(view) {
  closeMobileNav();
  currentView = view;

  // Hide all view panels with explicit display:none
  document.querySelectorAll('.view-panel').forEach(el => {
    el.style.display = 'none';
  });

  // Deactivate all nav buttons
  document.querySelectorAll('.nav-btn').forEach(el => el.classList.remove('active'));

  // Show target panel — must set explicit value to override CSS .view-panel{display:none}
  const viewIds = {
    tables: 'viewTables', room: 'viewRoom', budget: 'viewBudget',
    dashboard: 'viewDashboard', rsvp: 'viewRsvp', payments: 'viewPayments',
    schedule: 'viewSchedule', tasks: 'viewTasks', vendors: 'viewVendors',
    transport: 'viewTransport', accommodation: 'viewAccommodation', gifts: 'viewGifts',
    gallery: 'viewGallery', access: 'viewAccess', config: 'viewConfig',
    devsettings: 'viewDevSettings', analytics: 'viewAnalytics', music: 'viewMusic',
  };
  const panelId = viewIds[view];
  if (panelId) {
    const el = document.getElementById(panelId);
    if (el) el.style.display = window.innerWidth <= 768 ? 'block' : 'flex';
  }

  // Activate nav button
  const navIds = {
    dashboard: 'navDashboard', tables: 'navTables', room: 'navRoom', rsvp: 'navRsvp',
    budget: 'navBudget', schedule: 'navSchedule',
    tasks: 'navTasks', vendors: 'navVendors', transport: 'navTransport',
    accommodation: 'navAccommodation', gifts: 'navGifts', gallery: 'navGallery',
    access: 'navAccess', config: 'navConfig',
    analytics: 'navAnalytics', music: 'navMusic',
  };
  const navBtn = document.getElementById(navIds[view]);
  if (navBtn) navBtn.classList.add('active');

  // Wyróżnij kategorię zawierającą aktywną zakładkę (widoczne, gdy grupa zwinięta)
  document.querySelectorAll('.nav-group.nav-group-active')
    .forEach(g => g.classList.remove('nav-group-active'));
  if (navBtn) { const g = navBtn.closest('.nav-group'); if (g) g.classList.add('nav-group-active'); }
  // Zwiń rozwinięte kategorie po wyborze zakładki
  closeNavGroups();

  // Widoki z menu ustawień (trybik) — podświetl trybik zamiast zakładki nav
  const settingsViews = ['config', 'access', 'devsettings'];
  const gearBtn = document.getElementById('settingsGearBtn');
  if (gearBtn) gearBtn.classList.toggle('active', settingsViews.includes(view));
  const setItemIds = { config: 'setItemConfig', access: 'setItemAccess', devsettings: 'setItemDevSettings' };
  document.querySelectorAll('.settings-menu-item').forEach(el => el.classList.remove('active'));
  const setItem = document.getElementById(setItemIds[view]);
  if (setItem) setItem.classList.add('active');

  // Pasek podzakładek i pasek statystyk — tylko dla widoku „Stoły i goście".
  // Pasek podzakładek jest nad statystykami, więc przełączanie podzakładek
  // nie przesuwa statystyk (brak przeskoków w layoucie).
  const tablesTabBar = document.getElementById('tablesTabBar');
  if (tablesTabBar) tablesTabBar.style.display = view === 'tables' ? 'flex' : 'none';
  const statsBar = document.getElementById('statsBar');
  if (statsBar) statsBar.style.display = view === 'tables' ? 'flex' : 'none';

  // Render content for the target view
  switch (view) {
    case 'tables':
      renderGuests();
      renderTables();
      renderPairs();
      renderStaffTables();
      updateStats();
      applyTablesTab();   // przywróć aktywną podzakładkę (Plan stołów / Kartoteka Gości)
      break;
    case 'room':          isEditing = false; selectedRoomElementId = null; if (isFullscreen) exitRoomFullscreen(); _resetRoomZoom(); renderRoom(); break;
    case 'budget':        renderBudget(); renderPayments(); break;
    case 'dashboard':     renderDashboard();     break;
    case 'analytics':     renderAnalytics();     break;
    case 'music':         renderMusic(); renderMusicQR(); break;
    case 'schedule':      renderSchedule(); renderScheduleQR(); applyScheduleTab(); break;
    case 'gallery':       renderGalleryView();   break;
    case 'access':        renderAccessView();    break;
    case 'config':        renderConfigView();    break;
    case 'devsettings':   if (typeof renderBackupList === 'function') renderBackupList(); break;
    case 'tasks':         renderTasks();         break;
    case 'vendors':       renderVendors();       break;
    case 'rsvp':          renderRsvpPanel();     break;
    case 'gifts':         renderGifts();         break;
    case 'transport':     renderTransport();     break;
    case 'accommodation': renderAccommodation(); break;
    // payments is now a sub-tab inside budget view
  }
  if (window.innerWidth <= 768) setTimeout(initMobileCollapse, 0);
}

function updateRoomName(val) {
  roomName = val;
  const label = document.getElementById('roomCanvasLabel');
  if (label) label.textContent = val;
  saveState();
}

function autoTablePos(index) {
  const cols = 5;
  const col = index % cols;
  const row = Math.floor(index / cols);
  return { x: 60 + col * 230, y: 70 + row * 230 };
}

// Returns { tw, th } — inner table dimensions in room plan
function rtTableDims(t) {
  const ppm = (roomMeta.widthM > 0) ? roomPxPerMeter() : 40;
  if (t.shape === 'round') {
    // Priorytet: rozmiar per-stół (diamM) → globalna średnica → wg liczby miejsc
    if (t.diamM > 0) { const d = Math.max(50, Math.min(500, t.diamM * ppm)); return { tw: d, th: d }; }
    if (roomMeta.tableDiameterM > 0 && roomMeta.widthM > 0) {
      const d = Math.max(50, Math.min(400, roomMeta.tableDiameterM * roomPxPerMeter()));
      return { tw: d, th: d };
    }
    const d = Math.max(86, 58 + t.seats * 5);
    return { tw: d, th: d };
  }
  // prostokątny — per-stół wymiary (rectWM × rectLM) lub wg liczby miejsc
  if (t.rectWM > 0 && t.rectLM > 0) {
    return { tw: Math.max(60, Math.min(700, t.rectWM * ppm)), th: Math.max(40, Math.min(500, t.rectLM * ppm)) };
  }
  return { tw: Math.max(118, 68 + t.seats * 9), th: 76 };
}

// Returns seat dot positions (absolute within rt-wrap)
function rtSeatPositions(t) {
  const { tw, th } = rtTableDims(t);
  const PAD = 20; // space around shape for dots
  const cx = PAD + tw / 2;
  const cy = PAD + th / 2;
  const n   = t.seats;

  if (t.shape === 'round') {
    const r = tw / 2 + 14;
    return Array.from({ length: n }, (_, i) => {
      const a = (i * 2 * Math.PI / n) - Math.PI / 2;
      return { x: cx + r * Math.cos(a), y: cy + r * Math.sin(a) };
    });
  }

  if (t.isHonorTable) {
    // Stół honorowy: miejsca tylko wzdłuż dolnej dłuższej krawędzi
    const pad    = 10;
    const xStart = cx - tw / 2 + pad;
    const xEnd   = cx + tw / 2 - pad;
    const y      = cy + th / 2 + 15;
    return Array.from({ length: n }, (_, i) => {
      const frac = n > 1 ? i / (n - 1) : 0.5;
      return { x: xStart + frac * (xEnd - xStart), y };
    });
  }

  const perimeter = 2 * (tw + th);
  const gap = 15;
  return Array.from({ length: n }, (_, i) => {
    let d = i * perimeter / n;
    let x, y;
    if      (d < tw)         { x = cx - tw/2 + d;          y = cy - th/2 - gap; }
    else if (d < tw + th)    { x = cx + tw/2 + gap;         y = cy - th/2 + (d - tw); }
    else if (d < 2*tw + th)  { x = cx + tw/2 - (d-tw-th);  y = cy + th/2 + gap; }
    else                     { x = cx - tw/2 - gap;         y = cy + th/2 - (d-2*tw-th); }
    return { x, y };
  });
}

function renderRoomTable(t) {
  const { tw, th } = rtTableDims(t);
  const PAD  = 20;
  const extraBottom = t.isHonorTable ? 10 : 0;
  const wrapW = tw + PAD * 2;
  const wrapH = th + PAD * 2 + extraBottom;
  const occupied = t.seatsData.filter(x => x !== null).length;

  const stateClass = occupied === 0 ? 'empty' : occupied >= t.seats ? 'full' : '';
  const honorCls   = t.isHonorTable ? ' rt-honor' : '';

  const shapeHtml = `<div class="rt-shape rt-${t.shape} ${stateClass}${honorCls}"
    style="width:${tw}px;height:${th}px;left:${PAD}px;top:${PAD}px">
    <div class="rt-label">
      ${t.isHonorTable ? '<div class="rt-honor-star">&#9733;</div>' : ''}
      <div class="rt-name">${esc(t.name)}</div>
      <div class="rt-count">${occupied}/${t.seats}</div>
    </div>
  </div>`;

  const positions = rtSeatPositions(t);
  const dotsHtml = positions.map((pos, i) => {
    const gId = t.seatsData[i];
    const g   = gId !== null ? guests.find(x => x.id === gId) : null;
    if (g) {
      return `<div class="rt-dot rt-dot-occupied"
        draggable="true"
        data-guest-id="${g.id}"
        data-table-id="${t.id}"
        style="left:${pos.x}px;top:${pos.y}px"
        onmousedown="event.stopPropagation()"
        ondragstart="roomGuestDragStart(event,${g.id},${t.id})"
        ondragend="roomGuestDragEnd()"
        onmouseenter="showGuestTooltip(event,${g.id})"
        onmouseleave="hideGuestTooltip()">${esc(initials(g))}</div>`;
    }
    return `<div class="rt-dot rt-dot-empty" style="left:${pos.x}px;top:${pos.y}px"></div>`;
  }).join('');

  // Uchwyty zmiany rozmiaru — w trybie edycji, na rogach (widoczne po najechaniu na stół)
  const handles = isEditing
    ? ['nw','ne','sw','se'].map(c => `<div class="rt-resize rt-resize-${c} rt-th-resize" onmousedown="startRoomTableResize(event,${t.id},'${c}')" title="Zmień rozmiar"></div>`).join('')
    : '';

  return `<div class="rt-wrap${isEditing ? ' rt-editable' : ''}" data-id="${t.id}"
    style="left:${t.posX}px;top:${t.posY}px;width:${wrapW}px;height:${wrapH}px"
    onmousedown="startRoomTableDrag(event,${t.id})">
    ${shapeHtml}
    ${dotsHtml}
    <div class="rt-delete" onclick="event.stopPropagation();deleteTable(${t.id})" title="Usuń stół">&#10005;</div>
    ${handles}
  </div>`;
}

// ── ROOM GUEST DRAG & DROP (event delegation on #roomCanvas) ──
function roomGuestDragStart(event, guestId, srcTableId) {
  if (!isEditing) { event.preventDefault(); return; }
  roomGuestDrag = { guestId, srcTableId };
  event.dataTransfer.effectAllowed = 'move';
  event.dataTransfer.setData('text/plain', String(guestId));

  // Highlight tables after the drag-image is captured (requires setTimeout)
  setTimeout(() => {
    if (!roomGuestDrag) return;
    tables.forEach(t => {
      const wrap = document.querySelector(`.rt-wrap[data-id="${t.id}"]`);
      if (!wrap) return;
      if (t.id === srcTableId) {
        wrap.classList.add('rt-drag-src');
      } else {
        const free = t.seats - t.seatsData.filter(x => x !== null).length;
        wrap.classList.add(free > 0 ? 'rt-drop-ok' : 'rt-drop-full');
      }
    });
  }, 0);
}

function roomGuestDragEnd() {
  roomGuestDrag = null;
  document.querySelectorAll('.rt-wrap').forEach(el =>
    el.classList.remove('rt-drag-src', 'rt-drop-ok', 'rt-drop-full', 'rt-drop-over')
  );
}

// All three handlers delegated on the #roomCanvas element
function roomCanvasDragOver(event) {
  if (!roomGuestDrag) return;
  const wrap = event.target.closest('.rt-wrap');
  if (!wrap) return;
  event.preventDefault(); // must call to allow drop on this canvas

  const tableId = parseInt(wrap.dataset.id);
  if (tableId === roomGuestDrag.srcTableId) {
    event.dataTransfer.dropEffect = 'none';
    document.querySelectorAll('.rt-wrap.rt-drop-over').forEach(el => el.classList.remove('rt-drop-over'));
    return;
  }

  const t    = tables.find(x => x.id === tableId);
  const free = t ? t.seats - t.seatsData.filter(x => x !== null).length : 0;

  if (free > 0) {
    event.dataTransfer.dropEffect = 'move';
    if (!wrap.classList.contains('rt-drop-over')) {
      document.querySelectorAll('.rt-wrap.rt-drop-over').forEach(el => el.classList.remove('rt-drop-over'));
      wrap.classList.add('rt-drop-over');
    }
  } else {
    event.dataTransfer.dropEffect = 'none';
    document.querySelectorAll('.rt-wrap.rt-drop-over').forEach(el => el.classList.remove('rt-drop-over'));
  }
}

function roomCanvasDragLeave(event) {
  if (!roomGuestDrag) return;
  const canvas = document.getElementById('roomCanvas');
  if (canvas && !canvas.contains(event.relatedTarget)) {
    document.querySelectorAll('.rt-wrap.rt-drop-over').forEach(el => el.classList.remove('rt-drop-over'));
  }
}

function roomCanvasDrop(event) {
  if (!roomGuestDrag) return;
  event.preventDefault();

  const wrap = event.target.closest('.rt-wrap');
  const { guestId, srcTableId } = roomGuestDrag;
  roomGuestDragEnd();

  if (!wrap) return;
  const tableId = parseInt(wrap.dataset.id);
  if (tableId === srcTableId) return;

  const t    = tables.find(x => x.id === tableId);
  const free = t ? t.seats - t.seatsData.filter(x => x !== null).length : 0;
  if (!t || free === 0) { showToast('Brak wolnych miejsc przy tym stoliku!'); return; }

  _assignToTable(tableId, guestId);
}

function renderRoom() {
  const canvas = document.getElementById('roomCanvas');
  if (!canvas) return;
  // Dynamiczna wysokość kanwy, gdy podano wymiary sali (zachowanie proporcji szer×dł)
  roomCanvasH = CANVAS_H;
  if (roomMeta.widthM > 0 && roomMeta.lengthM > 0) {
    roomCanvasH = Math.max(CANVAS_H, Math.round(roomMeta.lengthM * roomPxPerMeter()));
  }
  canvas.style.minHeight = roomCanvasH + 'px';

  const dimLabel = (roomMeta.widthM > 0 && roomMeta.lengthM > 0)
    ? `<div class="room-dim-label">${roomMeta.widthM} m × ${roomMeta.lengthM} m</div>` : '';
  const tableHtml      = tables.map(renderRoomTable).join('');
  const staffTableHtml = staffTables.map(renderRoomStaffTable).join('');
  const elementHtml    = roomElements.map(renderRoomElement).join('');
  canvas.innerHTML = `<div class="room-canvas-label">${esc(roomName)}</div>${dimLabel}${elementHtml}${tableHtml}${staffTableHtml}`;
  _applyRoomEditUI();
  _initRoomZoomControls();   // podłącz (raz) zoom kółkiem i gesty dotykowe
  _applyRoomFit();        // dopasowanie do okna (podgląd i edycja) lub pełny ekran
  _updateRoomFsBtn();
}

const ROOM_EL_PAD = 6;
const ROOM_EL_MIN_PX = 30;

// Rozpoznaje typ elementu z jego nazwy (do tekstury/ikony)
function _elementType(name) {
  const n = (name || '').toLowerCase();
  if (n.includes('parkiet')) return 'parkiet';
  if (n.includes('orkiestra')) return 'orkiestra';
  if (n.includes('dj')) return 'dj';
  if (n.includes('bar')) return 'bar';
  if (n.includes('scen')) return 'scena';
  return 'custom';
}

// Geometria elementu: piksele kształtu (tw×th), kąt obrotu i ślad (footprint) na kanwie.
// Przy obrocie 90/270 ślad ma zamienione wymiary (szerokość↔długość).
function _elGeom(el) {
  const ppm = roomPxPerMeter();
  const tw  = Math.max(46, Math.round((el.wM || 1) * ppm));
  const th  = Math.max(36, Math.round((el.lM || 1) * ppm));
  const rot = (((el.rotation || 0) % 360) + 360) % 360;
  const swap = (rot === 90 || rot === 270);
  return { ppm, tw, th, rot, swap, fpW: swap ? th : tw, fpH: swap ? tw : th };
}

// Utrzymuje element wewnątrz obrysu sali (kanwy)
function _clampElPos(el) {
  const g = _elGeom(el);
  const wrapW = g.fpW + ROOM_EL_PAD * 2, wrapH = g.fpH + ROOM_EL_PAD * 2;
  el.posX = Math.max(0, Math.min(CANVAS_W - wrapW, el.posX));
  el.posY = Math.max(0, Math.min(roomCanvasH - wrapH, el.posY));
}

// Aktualizuje style istniejącego węzła DOM (na żywo, bez przebudowy — zachowuje uchwyty)
function _styleElementNode(node, el) {
  const g = _elGeom(el);
  const wrapW = g.fpW + ROOM_EL_PAD * 2, wrapH = g.fpH + ROOM_EL_PAD * 2;
  node.style.left = el.posX + 'px'; node.style.top = el.posY + 'px';
  node.style.width = wrapW + 'px'; node.style.height = wrapH + 'px';
  const shape = node.querySelector('.rt-shape');
  if (shape) {
    shape.style.width = g.tw + 'px'; shape.style.height = g.th + 'px';
    shape.style.left = ((wrapW - g.tw) / 2) + 'px';
    shape.style.top  = ((wrapH - g.th) / 2) + 'px';
    shape.style.transform = 'rotate(' + g.rot + 'deg)';
  }
  const dimEl = node.querySelector('.rt-count');
  if (dimEl && el.wM && el.lM) dimEl.textContent = `${el.wM}×${el.lM} m`;
}

// Renderuje własny element sali (Orkiestra, DJ, Bar, Scena, Parkiet, własny) jako blok z podpisem
function renderRoomElement(el) {
  const g = _elGeom(el);
  const PAD = ROOM_EL_PAD;
  const wrapW = g.fpW + PAD * 2, wrapH = g.fpH + PAD * 2;
  const shapeLeft = (wrapW - g.tw) / 2, shapeTop = (wrapH - g.th) / 2;
  const type = el.type || _elementType(el.name);
  const sel  = isEditing && el.id === selectedRoomElementId;
  const dims = (el.wM && el.lM) ? `${el.wM}×${el.lM} m` : '';
  const handles = sel
    ? ['nw', 'ne', 'sw', 'se'].map(c =>
        `<div class="rt-resize rt-resize-${c}" onmousedown="startRoomElementResize(event,${el.id},'${c}')"></div>`).join('')
    : '';
  const tools = sel ? `
    <div class="rt-el-tools">
      <button class="rt-el-tool rt-el-rotate" onmousedown="event.stopPropagation()" onclick="event.stopPropagation();rotateRoomElement(${el.id})" title="Obróć o 90°">&#8635;</button>
      <button class="rt-el-tool rt-el-trash" onmousedown="event.stopPropagation()" onclick="event.stopPropagation();deleteRoomElement(${el.id})" title="Usuń element">&#128465;</button>
    </div>` : '';
  return `<div class="rt-wrap rt-element-wrap${sel ? ' rt-selected' : ''}" data-element-id="${el.id}" data-type="${type}"
    style="left:${el.posX}px;top:${el.posY}px;width:${wrapW}px;height:${wrapH}px"
    onmousedown="startRoomElementDrag(event,${el.id})">
    <div class="rt-shape rt-rect rt-element rt-el-${type}" style="width:${g.tw}px;height:${g.th}px;left:${shapeLeft}px;top:${shapeTop}px;transform:rotate(${g.rot}deg)">
      <div class="rt-label">
        <div class="rt-name">${esc(el.name)}</div>
        ${dims ? `<div class="rt-count">${dims}</div>` : ''}
      </div>
    </div>
    ${tools}
    ${handles}
  </div>`;
}

function selectRoomElement(id) {
  if (selectedRoomElementId === id) return;
  selectedRoomElementId = id;
  renderRoom();
}

// Klik w pustą część kanwy odznacza element
function roomCanvasMouseDown(e) {
  if (roomElementDrag || roomElementResize || roomDrag || roomStaffDrag || roomTableResize) return;   // właśnie zaczęło się przeciąganie/zmiana rozmiaru
  if (e.target.closest('.rt-element-wrap')) return;
  if (selectedRoomElementId !== null) { selectedRoomElementId = null; renderRoom(); }
  // Pan tła — przeciąganie widoku, gdy klikamy tło (nie stół/element). Działa w podglądzie i edycji.
  if (e.button === 0 && !e.target.closest('.rt-wrap, .rt-staff-wrap, .rt-element-wrap')) {
    e.preventDefault();
    _roomInstantZoom();
    roomPan = { startX: e.clientX, startY: e.clientY, startPanX: roomPanX, startPanY: roomPanY };
    document.getElementById('roomCanvas')?.classList.add('room-panning');
  }
}

function startRoomElementDrag(e, id) {
  if (!isEditing) return;
  if (e.button !== 0) return;
  e.preventDefault();
  const el = roomElements.find(x => x.id === id);
  if (!el) return;
  if (selectedRoomElementId !== id) selectRoomElement(id);  // zaznacz (przebudowuje kanwę)
  roomElementDrag = { id, startMouseX: e.clientX, startMouseY: e.clientY, startPosX: el.posX, startPosY: el.posY };
  document.querySelector(`.rt-element-wrap[data-element-id="${id}"]`)?.classList.add('rt-dragging');
}

// Obrót zaznaczonego elementu o 90° (0→90→180→270→0) z płynną animacją CSS
function rotateRoomElement(id) {
  const el = roomElements.find(x => x.id === id);
  if (!el) return;
  el.rotation = (((el.rotation || 0) + 90) % 360);
  _clampElPos(el);                       // ślad mógł zmienić wymiary — utrzymaj w sali
  const node = document.querySelector(`.rt-element-wrap[data-element-id="${id}"]`);
  if (node) _styleElementNode(node, el); // animuje transform (transition w CSS)
  saveState();
}

function startRoomElementResize(e, id, corner) {
  if (!isEditing) return;
  if (e.button !== 0) return;
  e.preventDefault();
  e.stopPropagation();
  const el = roomElements.find(x => x.id === id);
  if (!el) return;
  const g = _elGeom(el);
  roomElementResize = {
    id, corner, startMouseX: e.clientX, startMouseY: e.clientY,
    startFpW: g.fpW, startFpH: g.fpH, startPosX: el.posX, startPosY: el.posY,
    ppm: g.ppm, swap: g.swap,
  };
}

// Zmiana rozmiaru STOŁU z poziomu planu sali (uchwyty na rogach, tryb edycji)
function startRoomTableResize(e, id, corner) {
  if (!isEditing) return;
  if (e.button !== 0) return;
  e.preventDefault();
  e.stopPropagation();
  const t = tables.find(x => x.id === id); if (!t) return;
  const { tw, th } = rtTableDims(t);
  const ppm = (roomMeta.widthM > 0) ? roomPxPerMeter() : 40;
  roomTableResize = {
    id, corner, startMouseX: e.clientX, startMouseY: e.clientY,
    startTW: tw, startTH: th, startPosX: t.posX, startPosY: t.posY,
    ppm, round: t.shape === 'round',
  };
}

// ── DODAWANIE / USUWANIE ELEMENTÓW SALI ──
function addRoomElement() {
  const sel  = document.getElementById('roomElName');
  const cust = document.getElementById('roomElCustom');
  const wIn  = document.getElementById('roomElW');
  const lIn  = document.getElementById('roomElL');
  let name = sel ? sel.value : 'Element';
  if (name === 'Inne') name = (cust && cust.value.trim()) || 'Element';
  const wM = parseFloat(wIn && wIn.value) || 2;
  const lM = parseFloat(lIn && lIn.value) || 2;
  const idx = roomElements.length;
  const newEl = {
    id: nextRoomElementId++, name, type: _elementType(name), wM, lM,
    posX: 40 + (idx % 6) * 130, posY: 40 + Math.floor(idx / 6) * 110,
    rotation: 0,
  };
  _clampElPos(newEl);
  roomElements.push(newEl);
  if (cust) { cust.value = ''; cust.style.display = 'none'; }
  selectedRoomElementId = newEl.id;   // od razu zaznacz nowy element
  renderRoom();
  saveState();
  showToast('Dodano element: ' + name);
}
function deleteRoomElement(id) {
  roomElements = roomElements.filter(x => x.id !== id);
  if (selectedRoomElementId === id) selectedRoomElementId = null;
  renderRoom();
  saveState();
}
function updateRoomMeta(field, val) {
  roomMeta[field] = Math.max(0, parseFloat(val) || 0);
  renderRoom();
  renderTables();
  saveState();
}

// ══════════════════════════════════════════════════════
//  PLAN SALI — TRYB EDYCJI (podgląd ↔ edycja)
// ══════════════════════════════════════════════════════
// Stosuje widoczność paneli/przycisków zależnie od isEditing
function _applyRoomEditUI() {
  const panels  = document.getElementById('roomConfigPanels');
  const editBtn = document.getElementById('roomEditBtn');
  const actions = document.getElementById('roomEditActions');
  const view    = document.querySelector('#viewRoom .room-view');
  if (panels)  panels.classList.toggle('open', isEditing);
  if (editBtn) editBtn.style.display = isEditing ? 'none' : '';
  if (actions) actions.style.display = isEditing ? 'flex' : 'none';
  if (view)    view.classList.toggle('room-editing', isEditing);
}

// Migawka stanu sali (do „Anuluj"): nazwa, wymiary, elementy oraz pozycje
// i przypisania miejsc stołów/personelu — wszystko, co można zmienić w tej sesji.
function _snapshotRoomState() {
  return JSON.stringify({
    roomName, roomMeta, roomElements, nextRoomElementId,
    tablePos:  tables.map(t => ({ id: t.id, posX: t.posX, posY: t.posY, seatsData: (t.seatsData || []).slice() })),
    staffPos:  staffTables.map(t => ({ id: t.id, posX: t.posX, posY: t.posY })),
    guestSeat: guests.map(g => ({ id: g.id, tableId: g.tableId, seatIndex: g.seatIndex })),
  });
}

// Przywraca stan sali z migawki
function _restoreRoomState(snap) {
  let s; try { s = JSON.parse(snap); } catch (_) { return; }
  roomName          = s.roomName;
  roomMeta          = s.roomMeta;
  roomElements      = s.roomElements || [];
  nextRoomElementId = s.nextRoomElementId || 1;
  (s.tablePos || []).forEach(p => {
    const t = tables.find(x => x.id === p.id);
    if (t) { t.posX = p.posX; t.posY = p.posY; if (p.seatsData) t.seatsData = p.seatsData.slice(); }
  });
  (s.staffPos || []).forEach(p => { const t = staffTables.find(x => x.id === p.id); if (t) { t.posX = p.posX; t.posY = p.posY; } });
  (s.guestSeat || []).forEach(p => { const g = guests.find(x => x.id === p.id); if (g) { g.tableId = p.tableId; g.seatIndex = p.seatIndex; } });
  // odśwież pola wymiarów sali
  const set = (id, val) => { const el = document.getElementById(id); if (el) el.value = val; };
  set('roomWidthInput',     roomMeta.widthM        || '');
  set('roomLengthInput',    roomMeta.lengthM       || '');
  set('roomTableDiamInput', roomMeta.tableDiameterM || '');
  const nameInput = document.getElementById('roomNameInput');
  if (nameInput) nameInput.value = roomName;
}

function enterRoomEdit() {
  isEditing = true;
  roomEditSnapshot = _snapshotRoomState();   // zapamiętaj stan na potrzeby „Anuluj"
  selectedRoomElementId = null;
  renderRoom();
  renderTables();
  _scheduleRoomRefit();        // przelicz dopasowanie po slide-down paneli
}

function saveRoomEdit() {
  isEditing = false;
  selectedRoomElementId = null;
  roomEditSnapshot = null;
  saveState();                 // utrwal layout (localStorage + Firestore)
  renderRoom();
  renderTables();
  _scheduleRoomRefit();
  showToast('Zapisano plan sali');
}

function cancelRoomEdit() {
  if (roomEditSnapshot) _restoreRoomState(roomEditSnapshot);
  roomEditSnapshot = null;
  isEditing = false;
  selectedRoomElementId = null;
  saveState();                 // utrwal przywrócony stan
  renderRoom();
  renderTables();
  _scheduleRoomRefit();
  showToast('Anulowano zmiany');
}

// ══════════════════════════════════════════════════════
//  PLAN SALI — DOPASOWANIE (fit-to-screen) — podgląd i pełny ekran
// ══════════════════════════════════════════════════════
// Dopasowuje siatkę sali do okna (pełny ekran) z zachowaniem proporcji (transform: scale)
function _fitRoomToScreen() {
  const canvas = document.getElementById('roomCanvas');
  if (!canvas) return;
  const PAD = 48; // margines, by krawędzie się nie ucinały
  const availW = Math.max(100, window.innerWidth  - PAD);
  const availH = Math.max(100, window.innerHeight - PAD);
  // CANVAS_W × roomCanvasH odzwierciedlają proporcje sali (widthM × lengthM)
  const s = Math.max(0.1, Math.min(availW / CANVAS_W, availH / roomCanvasH));
  roomFitScale = s;
  _applyRoomTransform();   // nałóż zoom użytkownika i pan na bazowe dopasowanie
}

// Stosuje aktualny transform kanwy: bazowe dopasowanie × zoom użytkownika + przesunięcie (pan).
// Zoom/pan to wyłącznie widok — nie zmieniają danych ani rzeczywistych wymiarów stołów/elementów.
function _applyRoomTransform() {
  const canvas = document.getElementById('roomCanvas');
  if (!canvas) return;
  const eff = roomFitScale * roomZoom;
  roomScale  = eff;        // skala efektywna — kompensacja w logice przeciągania (mousemove)
  roomFsScale = eff;
  canvas.style.transformOrigin = 'center center';
  canvas.style.transform = `translate(${roomPanX}px, ${roomPanY}px) scale(${eff})`;
  _updateRoomZoomUI();
}

// Dopasowuje siatkę sali do dostępnej przestrzeni w trybie PODGLĄDU (desktop i mobile).
// Bazuje na szerokości wrappera i wysokości widocznej do dołu okna — bez ucinania i bez przewijania.
function _fitRoomPreview() {
  const wrap   = document.getElementById('roomCanvasWrapper');
  const canvas = document.getElementById('roomCanvas');
  if (!wrap || !canvas) return;
  const cs   = getComputedStyle(wrap);
  const padX = parseFloat(cs.paddingLeft) + parseFloat(cs.paddingRight);
  const padY = parseFloat(cs.paddingTop)  + parseFloat(cs.paddingBottom);
  // wysokość = od górnej krawędzi wrappera do dołu okna (działa też na mobile bez sztywnej wysokości)
  const rectTop = wrap.getBoundingClientRect().top;
  const availH  = Math.max(140, window.innerHeight - rectTop - 12);
  wrap.style.height = availH + 'px';               // ogranicz wrapper do widocznej przestrzeni
  const innerW = Math.max(50, wrap.clientWidth - padX);
  const innerH = Math.max(50, availH - padY);
  // CANVAS_W × roomCanvasH zachowują proporcje sali (widthM × lengthM)
  const s = Math.max(0.05, Math.min(innerW / CANVAS_W, innerH / roomCanvasH));
  roomFitScale = s;
  _applyRoomTransform();   // nałóż zoom użytkownika i pan na bazowe dopasowanie
}

// ── PLAN SALI: STEROWANIE ZOOMEM I PRZESUWANIEM (pan) ──
function _roomWrapperCenter() {
  const wrap = document.getElementById('roomCanvasWrapper');
  if (!wrap) return null;
  const r = wrap.getBoundingClientRect();
  return { x: r.left + r.width / 2, y: r.top + r.height / 2 };
}
// Ustawia poziom zoomu; opcjonalnie utrzymuje punkt (focalX,focalY) nieruchomo — kursor lub środek gestu pinch.
function _setRoomZoom(newZoom, focalX, focalY) {
  newZoom = Math.max(ROOM_ZOOM_MIN, Math.min(ROOM_ZOOM_MAX, newZoom));
  if (focalX != null && roomZoom > 0) {
    const c = _roomWrapperCenter();
    if (c) {
      // transform-origin = środek kanwy (pokrywa się ze środkiem wrappera + pan).
      // Utrzymujemy punkt focal nieruchomo, korygując przesunięcie proporcjonalnie do zmiany skali.
      const ratio = newZoom / roomZoom;
      const dX = focalX - c.x, dY = focalY - c.y;
      roomPanX = dX - (dX - roomPanX) * ratio;
      roomPanY = dY - (dY - roomPanY) * ratio;
    }
  }
  roomZoom = newZoom;
  _applyRoomTransform();
}
function roomZoomIn()  { _roomSmoothZoom(); _setRoomZoom(roomZoom * ROOM_ZOOM_STEP); }
function roomZoomOut() { _roomSmoothZoom(); _setRoomZoom(roomZoom / ROOM_ZOOM_STEP); }
// „Dopasuj do ekranu" — reset zoomu i przesunięcia oraz ponowne dopasowanie do widoku.
function roomZoomFit() {
  _roomSmoothZoom();
  roomZoom = 1; roomPanX = 0; roomPanY = 0;
  _applyRoomFit();
}
function _resetRoomZoom() { roomZoom = 1; roomPanX = 0; roomPanY = 0; }
function _updateRoomZoomUI() {
  const lbl = document.getElementById('roomZoomLabel');
  if (lbl) lbl.textContent = Math.round(roomZoom * 100) + '%';
}
// Płynne przejście (przyciski/dopasowanie) vs. natychmiastowe (gesty ciągłe: kółko/pinch/pan)
function _roomSmoothZoom()  { document.getElementById('roomCanvas')?.classList.remove('room-no-transition'); }
function _roomInstantZoom() { document.getElementById('roomCanvas')?.classList.add('room-no-transition'); }
function _touchDist(t) { return Math.hypot(t[0].clientX - t[1].clientX, t[0].clientY - t[1].clientY); }
function _touchMid(t)  { return { x: (t[0].clientX + t[1].clientX) / 2, y: (t[0].clientY + t[1].clientY) / 2 }; }

// Podłącza nasłuchy: Ctrl+kółko (zoom do kursora) oraz dotyk (pinch-to-zoom 2 palce, pan 1 palcem po tle).
// Wywoływane raz — wrapper jest stały w DOM, więc działa też w trybie pełnoekranowym.
function _initRoomZoomControls() {
  if (_roomZoomInit) return;
  const wrap = document.getElementById('roomCanvasWrapper');
  if (!wrap) return;
  _roomZoomInit = true;

  wrap.addEventListener('wheel', e => {
    if (currentView !== 'room' || !e.ctrlKey) return;   // zoom tylko z Ctrl — bez Ctrl działa normalne przewijanie
    e.preventDefault();
    _roomInstantZoom();
    _setRoomZoom(roomZoom * (e.deltaY < 0 ? 1.12 : 1 / 1.12), e.clientX, e.clientY);
  }, { passive: false });

  wrap.addEventListener('touchstart', e => {
    if (currentView !== 'room') return;
    if (e.touches.length === 2) {
      e.preventDefault();
      _roomInstantZoom();
      roomPinch = { startDist: _touchDist(e.touches), startZoom: roomZoom };
      roomPan = null;
    } else if (e.touches.length === 1) {
      const t = e.touches[0];
      // jeden palec po tle (nie po stole/elemencie) = przesuwanie widoku
      if (!(t.target && t.target.closest && t.target.closest('.rt-wrap, .rt-staff-wrap, .rt-element-wrap'))) {
        _roomInstantZoom();
        roomPan = { startX: t.clientX, startY: t.clientY, startPanX: roomPanX, startPanY: roomPanY };
      }
    }
  }, { passive: false });

  wrap.addEventListener('touchmove', e => {
    if (currentView !== 'room') return;
    if (roomPinch && e.touches.length === 2) {
      e.preventDefault();
      const dist = _touchDist(e.touches);
      if (roomPinch.startDist > 0) {
        const mid = _touchMid(e.touches);
        _setRoomZoom(roomPinch.startZoom * (dist / roomPinch.startDist), mid.x, mid.y);
      }
    } else if (roomPan && e.touches.length === 1) {
      e.preventDefault();
      const t = e.touches[0];
      roomPanX = roomPan.startPanX + (t.clientX - roomPan.startX);
      roomPanY = roomPan.startPanY + (t.clientY - roomPan.startY);
      _applyRoomTransform();
    }
  }, { passive: false });

  const endTouch = e => {
    if (e.touches.length < 2) roomPinch = null;
    if (e.touches.length === 0) roomPan = null;
  };
  wrap.addEventListener('touchend', endTouch);
  wrap.addEventListener('touchcancel', endTouch);
}

// Wybiera właściwe dopasowanie zależnie od trybu.
// Podgląd ORAZ edycja: kanwa dopasowana do okna (wyśrodkowana, proporcje sali, bez wychodzenia poza ekran).
function _applyRoomFit() {
  const wrap   = document.getElementById('roomCanvasWrapper');
  const canvas = document.getElementById('roomCanvas');
  if (!wrap || !canvas) return;
  if (isFullscreen) {
    wrap.classList.remove('room-fit'); wrap.style.height = '';
    _fitRoomToScreen();
  } else {
    wrap.classList.add('room-fit');
    _fitRoomPreview();
  }
}

// Ponowne dopasowanie po animacjach (np. slide-down paneli konfiguracji w trybie edycji)
function _scheduleRoomRefit() {
  setTimeout(() => { if (currentView === 'room') _applyRoomFit(); }, 80);
  setTimeout(() => { if (currentView === 'room') _applyRoomFit(); }, 460);
}

// Przelicz dopasowanie przy zmianie rozmiaru okna (always-on; podgląd i edycja, też na mobile)
window.addEventListener('resize', () => {
  if (currentView === 'room' && !isFullscreen) _fitRoomPreview();
});

// Stały referencyjny handler ESC (ten sam obiekt do add/removeEventListener)
function _roomFsEscKeydown(e) {
  if (e.key === 'Escape' || e.key === 'Esc') exitRoomFullscreen();
}
function _roomFsResize() {
  if (isFullscreen) _fitRoomToScreen();
}

function _updateRoomFsBtn() {
  const btn = document.getElementById('roomFsBtn');
  if (!btn) return;
  btn.innerHTML = isFullscreen
    ? '<span class="room-fs-ico">&#10219;&#10218;</span> Zamknij pełny ekran'
    : '<span class="room-fs-ico">&#10218;&#10219;</span> Pełny ekran';
  btn.title = isFullscreen ? 'Zamknij pełny ekran (ESC)' : 'Pełny ekran';
}

function toggleRoomFullscreen() {
  if (isFullscreen) exitRoomFullscreen(); else enterRoomFullscreen();
}

function enterRoomFullscreen() {
  if (isFullscreen) return;
  isFullscreen = true;
  _resetRoomZoom();   // wejście do pełnego ekranu zaczyna od czystego dopasowania
  const wrap = document.getElementById('roomCanvasWrapper');
  if (wrap) {
    wrap.classList.remove('room-fit');   // zdejmij dopasowanie podglądu
    wrap.style.height = '';              // wyczyść narzuconą wysokość
    wrap.classList.add('room-fs-active');
  }
  _fitRoomToScreen();
  document.addEventListener('keydown', _roomFsEscKeydown);   // dodaj listener ESC...
  window.addEventListener('resize', _roomFsResize);
  document.body.classList.add('room-fs-lock');
  _updateRoomFsBtn();
}

function exitRoomFullscreen() {
  if (!isFullscreen) return;
  isFullscreen = false;
  const wrap = document.getElementById('roomCanvasWrapper');
  if (wrap) wrap.classList.remove('room-fs-active');
  const canvas = document.getElementById('roomCanvas');
  if (canvas) { canvas.style.transform = ''; canvas.style.transformOrigin = ''; }
  roomFsScale = 1;
  _resetRoomZoom();   // wyjście z pełnego ekranu wraca do dopasowania podglądu
  document.removeEventListener('keydown', _roomFsEscKeydown); // ...i USUŃ go przy wyjściu
  window.removeEventListener('resize', _roomFsResize);
  document.body.classList.remove('room-fs-lock');
  _applyRoomFit();   // powrót do dopasowania podglądu
  _updateRoomFsBtn();
}

// ── GUEST TOOLTIP ──
function showGuestTooltip(event, guestId) {
  const g = guests.find(x => x.id === guestId);
  if (!g) return;
  const tip = document.getElementById('rtTooltip');
  if (!tip) return;

  const invLabel = g.invitedBy === 'groom' ? '&#129309; Pan Młody'
                 : g.invitedBy === 'bride'  ? '&#128144; Panna Młoda'
                 : null;

  // Dane logistyczno-żywieniowe — spójnie z Listą gości / Kartoteką / Podsumowaniem
  const extra = [];
  const menu = (g.menuChoice || '').trim();
  if (menu) extra.push(`&#127869; ${esc(menu)}`);
  if (g.diet && g.diet !== 'standard') extra.push(`&#129382; ${esc(dietLabel(g.diet, g.dietOther))}`);
  if ((g.allergies || '').trim()) extra.push(`&#9888;&#65039; ${esc(g.allergies.trim())}`);
  if (g.needsAccommodation) extra.push('&#127968; Nocleg');
  if (g.hasCompanion) extra.push(`&#128101; +1${(g.companionName || '').trim() ? ' ' + esc(g.companionName.trim()) : ''}`);

  tip.innerHTML =
    `<div class="rtt-name">${esc(fullName(g))}</div>` +
    `<div class="rtt-cat">${esc(g.category)}</div>` +
    (invLabel ? `<div class="rtt-invited">Zaproszony przez: ${invLabel}</div>` : '') +
    (extra.length ? `<div class="rtt-extra">${extra.join(' · ')}</div>` : '');

  tip.style.display = 'block';
  tip.style.left = '0px';
  tip.style.top  = '0px';

  const dotRect = event.currentTarget.getBoundingClientRect();
  const tipRect = tip.getBoundingClientRect();
  let x = dotRect.left + dotRect.width  / 2 - tipRect.width / 2;
  let y = dotRect.top  - tipRect.height - 8;
  x = Math.max(4, Math.min(window.innerWidth  - tipRect.width  - 4, x));
  if (y < 4) y = dotRect.bottom + 8;
  tip.style.left = x + 'px';
  tip.style.top  = y + 'px';
}

function hideGuestTooltip() {
  const tip = document.getElementById('rtTooltip');
  if (tip) tip.style.display = 'none';
}

// ── ROOM TABLE DRAG ──
function startRoomTableDrag(e, tableId) {
  if (e.button !== 0) return;
  if (roomGuestDrag) return; // guest drag in progress — don't move table
  e.preventDefault();
  const t = tables.find(x => x.id === tableId);
  if (!t) return;
  roomDrag = { tableId, startMouseX: e.clientX, startMouseY: e.clientY, startPosX: t.posX, startPosY: t.posY };
  document.querySelector(`.rt-wrap[data-id="${tableId}"]`)?.classList.add('rt-dragging');
}

document.addEventListener('mousemove', e => {
  const _sc = roomScale || 1;   // kompensacja skali dopasowania (podgląd/edycja/pełny ekran)
  if (roomPan) {
    // pan = przesunięcie w pikselach ekranowych (1:1), niezależnie od skali
    roomPanX = roomPan.startPanX + (e.clientX - roomPan.startX);
    roomPanY = roomPan.startPanY + (e.clientY - roomPan.startY);
    _applyRoomTransform();
    return;
  }
  if (roomDrag) {
    const t  = tables.find(x => x.id === roomDrag.tableId);
    const el = document.querySelector(`.rt-wrap[data-id="${roomDrag.tableId}"]`);
    if (t && el) {
      const dx = (e.clientX - roomDrag.startMouseX) / _sc;
      const dy = (e.clientY - roomDrag.startMouseY) / _sc;
      // ograniczenie do obrysu sali (kanwy)
      let nx = Math.max(0, Math.min(CANVAS_W - el.offsetWidth,  roomDrag.startPosX + dx));
      let ny = Math.max(0, Math.min(roomCanvasH - el.offsetHeight, roomDrag.startPosY + dy));
      // snap do siatki, jeśli włączona
      if (roomGridOn) { nx = Math.round(nx / ROOM_GRID) * ROOM_GRID; ny = Math.round(ny / ROOM_GRID) * ROOM_GRID; }
      // blokada nachodzenia stołów — zastosuj tylko gdy brak kolizji
      if (!_tableWouldOverlap(roomDrag.tableId, nx, ny)) {
        t.posX = nx; t.posY = ny;
        el.style.left = nx + 'px';
        el.style.top  = ny + 'px';
      }
    }
  }
  if (roomStaffDrag) {
    const t  = staffTables.find(x => x.id === roomStaffDrag.id);
    const el = document.querySelector(`.rt-staff-wrap[data-staff-id="${roomStaffDrag.id}"]`);
    if (t && el) {
      const dx = (e.clientX - roomStaffDrag.startMouseX) / _sc;
      const dy = (e.clientY - roomStaffDrag.startMouseY) / _sc;
      t.posX = Math.max(0, Math.min(CANVAS_W - el.offsetWidth,  roomStaffDrag.startPosX + dx));
      t.posY = Math.max(0, Math.min(roomCanvasH - el.offsetHeight, roomStaffDrag.startPosY + dy));
      el.style.left = t.posX + 'px';
      el.style.top  = t.posY + 'px';
    }
  }
  if (roomElementDrag) {
    const t  = roomElements.find(x => x.id === roomElementDrag.id);
    const el = document.querySelector(`.rt-element-wrap[data-element-id="${roomElementDrag.id}"]`);
    if (t && el) {
      const dx = (e.clientX - roomElementDrag.startMouseX) / _sc;
      const dy = (e.clientY - roomElementDrag.startMouseY) / _sc;
      t.posX = Math.max(0, Math.min(CANVAS_W - el.offsetWidth,  roomElementDrag.startPosX + dx));
      t.posY = Math.max(0, Math.min(roomCanvasH - el.offsetHeight, roomElementDrag.startPosY + dy));
      el.style.left = t.posX + 'px';
      el.style.top  = t.posY + 'px';
    }
  }
  if (roomElementResize) {
    const r  = roomElementResize;
    const el = roomElements.find(x => x.id === r.id);
    const node = document.querySelector(`.rt-element-wrap[data-element-id="${r.id}"]`);
    if (el && node) {
      const PAD = ROOM_EL_PAD, MIN = ROOM_EL_MIN_PX;
      const dx = (e.clientX - r.startMouseX) / _sc, dy = (e.clientY - r.startMouseY) / _sc;
      const c = r.corner;
      let fpW = r.startFpW, fpH = r.startFpH, posX = r.startPosX, posY = r.startPosY;
      if (c.includes('e')) fpW = r.startFpW + dx;
      if (c.includes('w')) { fpW = r.startFpW - dx; posX = r.startPosX + dx; }
      if (c.includes('s')) fpH = r.startFpH + dy;
      if (c.includes('n')) { fpH = r.startFpH - dy; posY = r.startPosY + dy; }
      // minimalny rozmiar
      if (fpW < MIN) { if (c.includes('w')) posX -= (MIN - fpW); fpW = MIN; }
      if (fpH < MIN) { if (c.includes('n')) posY -= (MIN - fpH); fpH = MIN; }
      // nie wychodź poza krawędź sali (lewą/górną)
      if (posX < 0) { if (c.includes('w')) fpW += posX; posX = 0; }
      if (posY < 0) { if (c.includes('n')) fpH += posY; posY = 0; }
      // nie przekraczaj prawej/dolnej krawędzi sali ani jej wymiarów
      fpW = Math.max(MIN, Math.min(fpW, CANVAS_W - 2 * PAD - posX));
      fpH = Math.max(MIN, Math.min(fpH, roomCanvasH - 2 * PAD - posY));
      // ślad → metry (uwzględnij obrót: przy 90/270 szer.↔dł.)
      const wFromW = Math.max(0.3, Math.round((fpW / r.ppm) * 10) / 10);
      const hFromH = Math.max(0.3, Math.round((fpH / r.ppm) * 10) / 10);
      if (r.swap) { el.lM = wFromW; el.wM = hFromH; }
      else        { el.wM = wFromW; el.lM = hFromH; }
      el.posX = posX; el.posY = posY;
      _styleElementNode(node, el);
    }
  }
  if (roomTableResize) {
    const r = roomTableResize;
    const t = tables.find(x => x.id === r.id);
    const node = document.querySelector(`.rt-wrap[data-id="${r.id}"]`);
    if (t && node) {
      const PAD = 20, MIN = 40;
      const dx = (e.clientX - r.startMouseX) / _sc, dy = (e.clientY - r.startMouseY) / _sc;
      const c = r.corner;
      let tw = r.startTW, th = r.startTH, posX = r.startPosX, posY = r.startPosY;
      if (c.includes('e')) tw = r.startTW + dx;
      if (c.includes('w')) { tw = r.startTW - dx; posX = r.startPosX + dx; }
      if (c.includes('s')) th = r.startTH + dy;
      if (c.includes('n')) { th = r.startTH - dy; posY = r.startPosY + dy; }
      if (r.round) { const d = Math.max(tw, th); tw = d; th = d; }   // koło — kwadratowy ślad
      // minimalny rozmiar
      if (tw < MIN) { if (c.includes('w')) posX -= (MIN - tw); tw = MIN; }
      if (th < MIN) { if (c.includes('n')) posY -= (MIN - th); th = MIN; }
      // nie wychodź poza krawędź sali (lewą/górną)
      if (posX < 0) { if (c.includes('w')) tw += posX; posX = 0; }
      if (posY < 0) { if (c.includes('n')) th += posY; posY = 0; }
      // musi mieścić się w sali (prawa/dolna krawędź); wrap = kształt + 2*PAD
      tw = Math.max(MIN, Math.min(tw, CANVAS_W - 2 * PAD - posX));
      th = Math.max(MIN, Math.min(th, roomCanvasH - 2 * PAD - posY));
      if (r.round) { const d = Math.min(tw, th); tw = d; th = d; }
      // zapamiętaj poprzednie wartości (do cofnięcia przy kolizji)
      const prev = { diamM: t.diamM, rectWM: t.rectWM, rectLM: t.rectLM, posX: t.posX, posY: t.posY };
      if (r.round) t.diamM = Math.max(0.3, Math.round((tw / r.ppm) * 10) / 10);
      else { t.rectWM = Math.max(0.3, Math.round((tw / r.ppm) * 10) / 10); t.rectLM = Math.max(0.3, Math.round((th / r.ppm) * 10) / 10); }
      t.posX = posX; t.posY = posY;
      // nie pozwól nachodzić na inne stoły — przy kolizji cofnij tę klatkę
      if (_tableWouldOverlap(r.id, t.posX, t.posY)) {
        t.diamM = prev.diamM; t.rectWM = prev.rectWM; t.rectLM = prev.rectLM; t.posX = prev.posX; t.posY = prev.posY;
      } else {
        node.outerHTML = renderRoomTable(t);   // lekki re-render pojedynczego stołu (kształt + miejsca + uchwyty)
      }
    }
  }
});

document.addEventListener('mouseup', e => {
  if (roomPan) {
    roomPan = null;
    document.getElementById('roomCanvas')?.classList.remove('room-panning');
  }
  if (roomDrag) {
    document.querySelector(`.rt-wrap[data-id="${roomDrag.tableId}"]`)?.classList.remove('rt-dragging');
    roomDrag = null;
    saveState();
  }
  if (roomStaffDrag) {
    document.querySelector(`.rt-staff-wrap[data-staff-id="${roomStaffDrag.id}"]`)?.classList.remove('rt-dragging');
    roomStaffDrag = null;
    saveState();
  }
  if (roomElementDrag) {
    document.querySelector(`.rt-element-wrap[data-element-id="${roomElementDrag.id}"]`)?.classList.remove('rt-dragging');
    roomElementDrag = null;
    saveState();
  }
  if (roomElementResize) {
    roomElementResize = null;
    renderRoom();   // znormalizuj uchwyty i etykietę
    saveState();
  }
  if (roomTableResize) {
    roomTableResize = null;
    renderRoom();   // znormalizuj uchwyty, miejsca i etykiety
    saveState();
  }
});

// ── NEW STATE ──
let weddingDate    = null;
let weddingTime    = '16:00';   // godzina ślubu (HH:MM, strefa Europe/Warsaw)
let scheduleEvents = [];
let nextScheduleId = 1;
let scheduleView   = 'list'; // 'list' | 'columns' | 'gantt'
let scheduleCols   = 3;      // liczba kolumn w widoku kolumnowym (1–5)
let tasks          = [];
let nextTaskId     = 1;
let vendors        = [];
let nextVendorId   = 1;
let rsvpEntries    = [];
let nextRsvpId     = 1;
let gifts          = [];
let nextGiftId     = 1;
let giftsForGuests = [];        // upominki dla gości: {id, category, name, qty, cost, guestIds[]}
let nextGiftForId  = 1;
let giftProposals  = [];        // propozycje/lista życzeń: {id, title, desc, link}
let nextProposalId = 1;
let giftProposalsPublic = false; // (legacy) dawna globalna flaga widoczności propozycji
let giftsTab       = 'received'; // 'received' | 'forguests' | 'proposals'
let giftForGuestsBasis = '';     // '' | 'real' | 'realvirtual' — podstawa przeliczania upominków
let vehicles       = [];
let nextVehicleId  = 1;
let hotels         = [];
let nextHotelId    = 1;
let payments       = [];
let nextPaymentId  = 1;
let nextInstallmentId = 1;
let transportNotes = { weddingCar: '', parking: '' };
let internalTransport = [];        // { id, type, info, showToGuests }
let nextInternalTransportId = 1;
let transportShowOwn = true;       // filtr: pokaż/ukryj transport własny
const INTERNAL_TRANSPORT_TYPES = ['Bolt', 'Taxi', 'Uber', 'FreeNow', 'Inne'];
let countdownInterval = null;

// ── MUZYKA: lista piosenek (kurowana przez parę) ──
// utwór: { id, title, artist, cover, preview, moment, genre, status, fromGuest, guestName }
let songs       = [];
let nextSongId  = 1;
const MUSIC_MOMENTS = ['Pierwszy taniec', 'Wejście', 'Oczepiny', 'Wolne', 'Imprezowe', 'Inne'];
const MUSIC_STATUSES = {
  proposal: { label: 'Propozycja',         cls: 'ms-proposal', icon: '💡' },
  approved: { label: 'Zatwierdzone',       cls: 'ms-approved', icon: '✅' },
  rejected: { label: 'Odrzucone',          cls: 'ms-rejected', icon: '✖️' },
  dj:       { label: 'Zostawiamy DJowi',   cls: 'ms-dj',       icon: '🎧' },
};
let musicTab     = 'list';   // 'list' | 'guests'
let musicFilters = { moment: 'all', status: 'all', genre: '' };
let musicSort    = 'added';
let _guestProposals     = [];     // propozycje gości z kolekcji Firestore /musicProposals
let _musicProposalsUnsub = null;

// ── CHECKLISTA na dzień ślubu ──
// pozycja: { id, category, text, done }
let checklist        = [];
let nextChecklistId  = 1;
const CHECKLIST_CATEGORIES = ['Co zabrać', 'Kto co przynosi', 'Przed ceremonią', 'Po ceremonii'];
let scheduleTab = 'plan';   // 'plan' | 'checklist'

// ── „OD CZEGO ZACZĄĆ?" — sugerowana kolejność organizacji wesela ──
// pozycja: { id, label, note, done } — edytowalna i synchronizowana per event
let planningSteps      = [];
let nextPlanningStepId = 1;
let planningEditMode   = false;
const DEFAULT_PLANNING_STEPS = [
  { label: 'Wybór i rezerwacja sali weselnej' },
  { label: 'Ustalenie daty (zależnie od dostępności sali i kościoła)' },
  { label: 'Rezerwacja kościoła / USC', note: 'Dotyczy ślubu kościelnego lub konkordatowego' },
  { label: 'Dodanie listy gości' },
  { label: 'Znalezienie i rezerwacja DJ / zespołu' },
  { label: 'Fotograf / kamerzysta' },
  { label: 'Florystka / dekoracje' },
  { label: 'Garnitur i suknia ślubna' },
  { label: 'Obrączki' },
  { label: 'Plan stołów i pozostałe szczegóły' },
];

// ── GUEST FIELD HELPERS ──
function dietLabel(diet, dietOther) {
  const labels = { standard:'Std', vegetarian:'Vege', vegan:'Vegan', glutenfree:'GF', other: dietOther || 'Inne' };
  return labels[diet] || diet;
}

function updateGuestField(guestId, field, value) {
  const g = guests.find(x => x.id === guestId);
  if (!g) return;
  g[field] = value;
  renderGuests();
  saveState();
}

// ── COUNTDOWN ──
// Data i godzina ślubu edytowane wyłącznie w „Konfiguracji" (globalne weddingDate / weddingTime).

// Offset strefy Europe/Warsaw względem UTC (w minutach) dla danego momentu — uwzględnia czas letni/zimowy
function _warsawOffsetMinutes(date) {
  const dtf = new Intl.DateTimeFormat('en-US', {
    timeZone: 'Europe/Warsaw', hour12: false,
    year: 'numeric', month: '2-digit', day: '2-digit',
    hour: '2-digit', minute: '2-digit', second: '2-digit',
  });
  const map = {};
  for (const p of dtf.formatToParts(date)) map[p.type] = p.value;
  let hour = +map.hour;
  if (hour === 24) hour = 0; // niektóre silniki zwracają 24 dla północy
  const asUTC = Date.UTC(+map.year, +map.month - 1, +map.day, hour, +map.minute, +map.second);
  return Math.round((asUTC - date.getTime()) / 60000);
}

// Zamienia „ścienną" datę+godzinę w Warszawie na dokładny moment UTC (milisekundy), z obsługą DST
function _warsawWallClockToMs(y, mo, d, h, mi) {
  const guess = Date.UTC(y, mo - 1, d, h, mi, 0);
  const off1 = _warsawOffsetMinutes(new Date(guess));
  let ms = guess - off1 * 60000;
  const off2 = _warsawOffsetMinutes(new Date(ms));
  if (off2 !== off1) ms = guess - off2 * 60000; // korekta na granicy zmiany czasu
  return ms;
}

// Zwraca docelowy moment ślubu (ms) lub null, gdy brak daty
function weddingTargetMs() {
  const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(weddingDate || '');
  if (!m) return null;
  const t = /^(\d{1,2}):(\d{2})/.exec(weddingTime || '16:00');
  const hh = t ? Math.min(23, +t[1]) : 16;
  const mi = t ? Math.min(59, +t[2]) : 0;
  return _warsawWallClockToMs(+m[1], +m[2], +m[3], hh, mi);
}

function startCountdown() {
  if (countdownInterval) clearInterval(countdownInterval);
  tickCountdown();
  countdownInterval = setInterval(tickCountdown, 1000);
}

// Odświeża kafelek „Licznik do ślubu" na bieżąco (co sekundę)
function _updateCountdownTile() {
  const tile = document.querySelector('.dash-widget[data-id="countdown"]');
  if (!tile || typeof DASH_WIDGETS === 'undefined') return;
  let data = {};
  try { data = DASH_WIDGETS.countdown.body() || {}; } catch (_) {}
  const numEl = tile.querySelector('.dw-num');
  const subEl = tile.querySelector('.dw-sub');
  if (numEl) numEl.innerHTML = (data.num != null ? data.num : '—');
  if (subEl) subEl.textContent = data.sub || '';
}

function tickCountdown() {
  if (typeof _updateCountdownTile === 'function') _updateCountdownTile();
  const days  = document.getElementById('cdDays');
  const hours = document.getElementById('cdHours');
  const mins  = document.getElementById('cdMins');
  const secs  = document.getElementById('cdSecs');
  const disp     = document.getElementById('countdownDisplay');
  const noDate   = document.getElementById('countdownNoDate');

  // Brak daty — pokaż komunikat, ukryj licznik
  if (!weddingDate) {
    [days,hours,mins,secs].forEach(el => { if (el) el.textContent = '--'; });
    if (disp)    disp.style.display = 'none';
    if (noDate)  noDate.style.display = '';
    return;
  }
  if (disp)    disp.style.display = '';
  if (noDate)  noDate.style.display = 'none';

  if (!days) return;
  const target = weddingTargetMs();
  const diff   = (target === null ? 0 : target) - Date.now();
  if (diff <= 0) {
    days.textContent='0'; hours.textContent='00'; mins.textContent='00'; if(secs) secs.textContent='00';
    return;
  }
  const d = Math.floor(diff / 86400000);
  const h = Math.floor((diff % 86400000) / 3600000);
  const m = Math.floor((diff % 3600000)  / 60000);
  const s = Math.floor((diff % 60000)    / 1000);
  days.textContent  = d;
  hours.textContent = String(h).padStart(2,'0');
  mins.textContent  = String(m).padStart(2,'0');
  if (secs) secs.textContent = String(s).padStart(2,'0');
}

// ── DASHBOARD ──
function renderDashboard() {
  renderPlanningBanner();
  renderDashboardWidgets();
}

// ══════════════════════════════════════════════════════
//  „OD CZEGO ZACZĄĆ?" — sugerowana kolejność planowania (karta na Dashboardzie)
// ══════════════════════════════════════════════════════
function _ensurePlanningSteps() {
  if (!Array.isArray(planningSteps) || !planningSteps.length) {
    planningSteps = DEFAULT_PLANNING_STEPS.map((s, i) => ({ id: i + 1, label: s.label, note: s.note || '', done: false }));
    nextPlanningStepId = planningSteps.length + 1;
  }
}
function renderPlanningGuide() {
  const list = document.getElementById('pgList');
  if (!list) return;
  _ensurePlanningSteps();
  const steps = planningSteps;
  const done = steps.filter(s => s.done).length;
  const pct = steps.length ? Math.round((done / steps.length) * 100) : 0;
  const bar = document.getElementById('pgProgressBar'); if (bar) bar.style.width = pct + '%';
  const lbl = document.getElementById('pgProgressLabel'); if (lbl) lbl.textContent = `${done} z ${steps.length} ukończonych · ${pct}%`;
  list.innerHTML = steps.map((s, i) => `
    <div class="pg-item${s.done ? ' done' : ''}">
      <input type="checkbox" class="pg-cb" id="pg-cb-${s.id}" ${s.done ? 'checked' : ''} onchange="togglePlanningStep(${s.id})">
      <span class="pg-num">${i + 1}</span>
      ${planningEditMode
        ? `<input class="pg-edit-input" value="${esc(s.label)}" onchange="editPlanningStep(${s.id}, this.value)">`
        : `<label class="pg-label" for="pg-cb-${s.id}">${esc(s.label)}${s.note ? `<span class="pg-note">${esc(s.note)}</span>` : ''}</label>`}
      ${planningEditMode ? `<button class="pg-del" onclick="deletePlanningStep(${s.id})" title="Usuń krok">&#10006;</button>` : ''}
    </div>`).join('');
  const editBtn  = document.getElementById('pgEditBtn');  if (editBtn)  editBtn.innerHTML  = planningEditMode ? '&#10003; Gotowe' : '&#9999;&#65039; Edytuj';
  const addBtn   = document.getElementById('pgAddBtn');   if (addBtn)   addBtn.style.display   = planningEditMode ? '' : 'none';
  const resetBtn = document.getElementById('pgResetBtn'); if (resetBtn) resetBtn.style.display = planningEditMode ? '' : 'none';
  // Utrzymaj baner na Dashboardzie w zgodzie z postępem/edycją kroków
  renderPlanningBanner();
}
function togglePlanningStep(id) {
  const s = planningSteps.find(x => x.id === id); if (!s) return;
  s.done = !s.done;
  renderPlanningGuide();
  saveState();
}
function togglePlanningEdit() {
  planningEditMode = !planningEditMode;
  renderPlanningGuide();
}
function editPlanningStep(id, val) {
  const s = planningSteps.find(x => x.id === id); if (!s) return;
  s.label = (val || '').trim() || s.label;
  s.note = '';   // własna treść zastępuje domyślną adnotację
  renderPlanningGuide();
  saveState();
}
function addPlanningStep() {
  _ensurePlanningSteps();
  const id = nextPlanningStepId++;
  planningSteps.push({ id, label: 'Nowy krok', note: '', done: false });
  planningEditMode = true;
  renderPlanningGuide();
  saveState();
  const inp = document.querySelector(`#pgList .pg-item:last-child .pg-edit-input`);
  if (inp) { inp.focus(); inp.select(); }
}
function deletePlanningStep(id) {
  planningSteps = planningSteps.filter(x => x.id !== id);
  renderPlanningGuide();
  saveState();
}
function resetPlanningSteps() {
  if (!confirm('Przywrócić domyślną listę kroków „Od czego zacząć?"? Wprowadzone zmiany zostaną utracone.')) return;
  planningSteps = [];
  _ensurePlanningSteps();
  renderPlanningGuide();
  saveState();
}
// Modal „Od czego zacząć?" — otwierany z menu Ustawień oraz automatycznie w przewodniku
function openPlanningGuide() {
  if (typeof closeSettingsMenu === 'function') try { closeSettingsMenu(); } catch (_) {}
  // Otwarcie z menu = „pokaż ponownie" — przywróć baner na Dashboardzie
  try { localStorage.removeItem(_planningBannerKey()); } catch (_) {}
  renderPlanningBanner();
  planningEditMode = false;
  const m = document.getElementById('planningGuideModal');
  if (m) m.style.display = 'flex';
  renderPlanningGuide();
}
function closePlanningGuide() {
  const m = document.getElementById('planningGuideModal');
  if (m) m.style.display = 'none';
}

// ── BANER „Od czego zacząć?" na Dashboardzie (między tytułem a licznikiem) ──
function _planningBannerKey() {
  const email = (typeof _currentUserEmail === 'function' ? _currentUserEmail() : '') || 'anon';
  return 'weddingPlanningBannerHidden:' + email;
}
function isPlanningBannerHidden() {
  try { return !!localStorage.getItem(_planningBannerKey()); } catch (_) { return false; }
}
function hidePlanningBanner() {
  try { localStorage.setItem(_planningBannerKey(), '1'); } catch (_) {}
  renderPlanningBanner();
}
function renderPlanningBanner() {
  const banner = document.getElementById('planningBanner');
  if (!banner) return;
  const hero = banner.closest('.dashboard-hero');
  if (isPlanningBannerHidden()) {
    banner.style.display = 'none';
    if (hero) hero.classList.remove('has-planning-banner');
    return;
  }
  _ensurePlanningSteps();
  const steps = planningSteps;
  const done = steps.filter(s => s.done).length;
  const pct = steps.length ? Math.round((done / steps.length) * 100) : 0;
  const sub = document.getElementById('pbSub');
  if (sub) sub.textContent = `Sugerowana kolejność planowania · ${done}/${steps.length} ukończonych · ${pct}%`;
  const stepsEl = document.getElementById('pbSteps');
  if (stepsEl) {
    const preview = steps.slice(0, 3);
    stepsEl.innerHTML = preview.map((s, i) =>
      `<span class="pb-step${s.done ? ' done' : ''}"><span class="pb-step-num">${i + 1}</span><span class="pb-step-txt">${esc(s.label)}</span></span>`
    ).join('') + (steps.length > 3 ? `<span class="pb-more">+${steps.length - 3} więcej</span>` : '');
  }
  banner.style.display = '';
  if (hero) hero.classList.add('has-planning-banner');
}

// ══════════════════════════════════════════════════════
//  DASHBOARD — personalizowane widżety (zapis w Firestore per użytkownik)
// ══════════════════════════════════════════════════════
// Katalog dostępnych kafelków. „body" zwraca treść na żywo (liczba/podpis). „view" = dokąd prowadzi skrót.
const DASH_WIDGETS = {
  guests: {
    icon: '👥', title: 'Goście', view: 'tables',
    body: () => {
      const attending = rsvpEntries.filter(e => e.guestId && e.status === 'attending').length;
      const noRsvp = guests.filter(g => !rsvpEntries.some(e => e.guestId === g.id)).length;
      return { num: guests.length, sub: `${attending} potwierdzeń · ${noRsvp} bez odpowiedzi` };
    },
  },
  tables: {
    icon: '🪑', title: 'Stoły', view: 'tables',
    body: () => ({
      num: tables.length,
      sub: `${tables.reduce((s, t) => s + (t.seats || 0), 0)} miejsc`,
    }),
  },
  budget: {
    icon: '💰', title: 'Budżet', view: 'budget',
    body: () => ({
      num: fmt(calcCateringTotal() + calcExpensesPlanned()) + ' zł',
      sub: `Limit: ${fmt(budgetData.total || 0)} zł`,
    }),
  },
  schedule: {
    icon: '📅', title: 'Harmonogram', view: 'schedule',
    body: () => ({ num: scheduleEvents.length, sub: 'punktów programu' }),
  },
  tasks: {
    icon: '✅', title: 'Zadania', view: 'tasks',
    body: () => {
      const done = tasks.filter(t => t.status === 'done').length;
      return { num: `${done}/${tasks.length}`, sub: `${tasks.length - done} pozostało` };
    },
  },
  transport: {
    icon: '🚗', title: 'Transport', view: 'transport',
    body: () => {
      const inCars = new Set(vehicles.flatMap(v => v.guestIds || []));
      return { num: vehicles.length, sub: `${guests.filter(g => !inCars.has(g.id)).length} gości bez transportu` };
    },
  },
  accommodation: {
    icon: '🏨', title: 'Noclegi', view: 'accommodation',
    body: () => ({
      num: guests.filter(g => g.needsAccommodation).length,
      sub: `${guests.filter(g => g.accommodationStatus === 'reserved').length} zarezerwowanych`,
    }),
  },
  gifts: {
    icon: '🎁', title: 'Prezenty', view: 'gifts',
    body: () => ({ num: gifts.length, sub: `${gifts.filter(g => g.thanked).length} z podziękowaniem` }),
  },
  countdown: {
    icon: '💍', title: 'Licznik do ślubu', view: 'config',
    body: () => {
      const target = (typeof weddingTargetMs === 'function') ? weddingTargetMs() : null;
      if (target === null) return { num: '—', sub: 'Ustaw datę w Konfiguracji' };
      const diff = target - Date.now();
      if (diff <= 0) return { num: '🎉', sub: 'Już po ślubie!' };
      const p = n => String(n).padStart(2, '0');
      const d = Math.floor(diff / 86400000);
      const h = Math.floor((diff % 86400000) / 3600000);
      const m = Math.floor((diff % 3600000) / 60000);
      const s = Math.floor((diff % 60000) / 1000);
      return { num: d, sub: `dni · ${p(h)}:${p(m)}:${p(s)}` };
    },
  },
  rsvp: {
    icon: '📋', title: 'Potwierdzenia', view: 'rsvp',
    body: () => {
      const attending = rsvpEntries.filter(e => e.guestId && e.status === 'attending').length;
      const declined = rsvpEntries.filter(e => e.guestId && e.status === 'not_attending').length;
      return { num: attending, sub: `${declined} odmów · ${rsvpEntries.length} odpowiedzi` };
    },
  },
  alcohol: {
    icon: '🍾', title: 'Alkohol', view: 'budget',
    onClick: "switchView('budget');switchBudgetTab('expenses')",
    body: () => ({
      num: fmt(calcAlcoholTotal()) + ' zł',
      sub: `${calcAlcoholBottles()} butelek`,
    }),
  },
  honeymoon: {
    icon: '✈️', title: 'Podróż poślubna', view: 'budget',
    onClick: "switchView('budget');switchBudgetTab('honeymoon')",
    body: () => {
      const h = budgetData.honeymoon || {};
      return { num: fmt(h.totalAmount || 0) + ' zł', sub: (h.name || '').trim() || 'Podróż poślubna' };
    },
  },
  payments: {
    icon: '💳', title: 'Płatności', view: 'budget',
    onClick: "switchView('budget');switchBudgetTab('payments')",
    body: () => {
      const allInst = payments.flatMap(p => p.installments);
      const overdue = allInst.filter(i => i.status !== 'paid' && i.dueDate && new Date(i.dueDate) < new Date()).length;
      const soon = allInst.filter(i => i.status !== 'paid' && isInstallmentDueSoon(i.dueDate)).length;
      return { num: overdue + soon, sub: `${overdue} zaległych · ${soon} wkrótce`, alert: overdue > 0 };
    },
  },
  vendors: {
    icon: '👨‍🍳', title: 'Dostawcy', view: 'vendors',
    body: () => ({
      num: vendors.length,
      sub: `${vendors.filter(v => v.paymentStatus === 'confirmed' || v.paymentStatus === 'paid').length} potwierdzonych`,
    }),
  },
  gallery: {
    icon: '📸', title: 'Galeria', view: 'gallery',
    body: () => ({
      num: (typeof _galleryAdminItems !== 'undefined' ? _galleryAdminItems.length : 0),
      sub: 'zdjęć i filmów',
    }),
  },
  music: {
    icon: '🎵', title: 'Muzyka', view: 'music',
    body: () => {
      const approved = songs.filter(s => s.status === 'approved').length;
      const fromGuests = songs.filter(s => s.fromGuest).length;
      return { num: songs.length, sub: `${approved} zatwierdzonych · ${fromGuests} od gości` };
    },
  },
  checklist: {
    icon: '☑️', title: 'Checklista', view: 'schedule',
    onClick: "switchView('schedule');switchScheduleTab('checklist')",
    body: () => {
      const done = checklist.filter(it => it.done).length;
      return { num: `${done}/${checklist.length}`, sub: `${checklist.length - done} do zrobienia` };
    },
  },
};
const DASH_WIDGET_SIZES = ['small', 'medium', 'large'];
const DEFAULT_DASH_LAYOUT = {
  widgets: [
    { id: 'countdown', size: 'medium' },
    { id: 'guests', size: 'medium' },
    { id: 'budget', size: 'small' },
    { id: 'tasks', size: 'small' },
    { id: 'payments', size: 'small' },
    { id: 'rsvp', size: 'small' },
    { id: 'schedule', size: 'small' },
    { id: 'vendors', size: 'small' },
  ],
};

let dashLayout       = null;     // {widgets:[{id,size}]}
let dashLayoutLoaded = false;
let dashEditMode     = false;
let dashAddZoneOpen  = false;
let _dragWidgetId    = null;

function _dashLayoutKey() {
  const email = (typeof _currentUserEmail === 'function' ? _currentUserEmail() : '') || 'anon';
  return 'weddingDashLayout:' + email;
}
function _dashLayoutDocRef() {
  if (!window.firebase || !firebase.firestore) return null;
  const email = (typeof _currentUserEmail === 'function' ? _currentUserEmail() : '') || 'anon';
  const id = email.replace(/[^a-z0-9]/gi, '_') || 'anon';
  return firebase.firestore().collection('dashboardLayouts').doc(id);
}

function _cloneDefaultLayout() {
  return { widgets: DEFAULT_DASH_LAYOUT.widgets.map(w => ({ id: w.id, size: w.size })) };
}
function _sanitizeLayout(layout) {
  if (!layout || !Array.isArray(layout.widgets)) return _cloneDefaultLayout();
  const seen = new Set();
  const widgets = [];
  layout.widgets.forEach(w => {
    if (!w || !DASH_WIDGETS[w.id] || seen.has(w.id)) return;
    seen.add(w.id);
    widgets.push({ id: w.id, size: DASH_WIDGET_SIZES.includes(w.size) ? w.size : 'small' });
  });
  return { widgets };
}

function getDashLayout() {
  if (!dashLayout) {
    // Najpierw natychmiastowy odczyt z localStorage (cache), potem Firestore nadpisze
    try {
      const raw = localStorage.getItem(_dashLayoutKey());
      dashLayout = raw ? _sanitizeLayout(JSON.parse(raw)) : _cloneDefaultLayout();
    } catch (_) { dashLayout = _cloneDefaultLayout(); }
  }
  return dashLayout;
}

function loadDashLayout() {
  if (dashLayoutLoaded) return;
  dashLayoutLoaded = true;
  const ref = _dashLayoutDocRef();
  if (!ref) { renderDashboardWidgets(); return; }
  ref.get()
    .then(doc => {
      if (doc.exists) {
        dashLayout = _sanitizeLayout(doc.data());
        try { localStorage.setItem(_dashLayoutKey(), JSON.stringify(dashLayout)); } catch (_) {}
        renderDashboardWidgets();
      }
    })
    .catch(() => {});
}

function saveDashLayout() {
  const layout = getDashLayout();
  try { localStorage.setItem(_dashLayoutKey(), JSON.stringify(layout)); } catch (_) {}
  const ref = _dashLayoutDocRef();
  if (ref) ref.set({ widgets: layout.widgets, _ts: Date.now() }).catch(() => {});
}

function renderDashboardWidgets() {
  if (!dashLayoutLoaded) loadDashLayout();
  const grid = document.getElementById('dashWidgets');
  if (!grid) return;
  const layout = getDashLayout();

  grid.classList.toggle('editing', dashEditMode);
  grid.innerHTML = layout.widgets.map(w => {
    const def = DASH_WIDGETS[w.id];
    if (!def) return '';
    let data = {};
    try { data = def.body() || {}; } catch (_) { data = {}; }
    const sizeCtrl = DASH_WIDGET_SIZES.map(sz => {
      const lbl = sz === 'small' ? 'S' : sz === 'medium' ? 'M' : 'L';
      return `<button class="dw-size-btn${w.size === sz ? ' active' : ''}" title="${sz}"
        onclick="event.stopPropagation();setWidgetSize('${w.id}','${sz}')">${lbl}</button>`;
    }).join('');
    const editControls = dashEditMode
      ? `<button class="dw-remove" title="Ukryj widżet" onclick="event.stopPropagation();hideWidget('${w.id}')">&#10006;</button>
         <div class="dw-sizes">${sizeCtrl}</div>`
      : '';
    const onclick = dashEditMode ? '' : `onclick="${def.onClick || `switchView('${def.view}')`}"`;
    const drag = dashEditMode
      ? `draggable="true" ondragstart="dwDragStart(event,'${w.id}')" ondragover="dwDragOver(event,'${w.id}')" ondrop="dwDrop(event,'${w.id}')" ondragend="dwDragEnd(event)"` : '';
    return `<div class="dash-widget dw-${w.size}${data.alert ? ' dw-alert' : ''}${dashEditMode ? ' editing' : ''}" data-id="${w.id}" ${onclick} ${drag}>
      ${editControls}
      <div class="dw-icon">${def.icon}</div>
      <div class="dw-num">${data.num != null ? data.num : '—'}</div>
      <div class="dw-title">${esc(def.title)}</div>
      ${data.sub ? `<div class="dw-sub">${esc(data.sub)}</div>` : ''}
    </div>`;
  }).join('');

  renderWidgetAddZone(layout);

  const editBtn  = document.getElementById('dwEditBtn');
  const addBtn   = document.getElementById('dwAddBtn');
  const resetBtn = document.getElementById('dwResetBtn');
  if (editBtn)  editBtn.innerHTML = dashEditMode ? '&#10003; Gotowe' : '&#9999;&#65039; Edytuj';
  if (addBtn)   addBtn.style.display   = dashEditMode ? '' : 'none';
  if (resetBtn) resetBtn.style.display = dashEditMode ? '' : 'none';
}

function renderWidgetAddZone(layout) {
  const zone = document.getElementById('dashWidgetAddZone');
  if (!zone) return;
  if (!dashEditMode || !dashAddZoneOpen) { zone.style.display = 'none'; zone.innerHTML = ''; return; }
  const present = new Set(layout.widgets.map(w => w.id));
  const missing = Object.keys(DASH_WIDGETS).filter(id => !present.has(id));
  zone.style.display = 'block';
  if (!missing.length) {
    zone.innerHTML = `<div class="dwa-title">Wszystkie widżety są już dodane &#9989;</div>`;
    return;
  }
  zone.innerHTML = `<div class="dwa-title">&#10133; Dodaj widżet</div>
    <div class="dwa-grid">${missing.map(id =>
      `<button class="dwa-chip" onclick="addWidget('${id}')">
        <span class="dwa-chip-icon">${DASH_WIDGETS[id].icon}</span>${esc(DASH_WIDGETS[id].title)}</button>`).join('')}</div>`;
}

// Wywoływane po zalogowaniu/zmianie użytkownika — przeładuj układ widżetów dla właściwego konta
function onDashboardUserChange() {
  dashLayoutLoaded = false;
  dashLayout = null;
  if (currentView === 'dashboard') renderDashboard();
}

function toggleDashEdit() {
  dashEditMode = !dashEditMode;
  if (!dashEditMode) dashAddZoneOpen = false;
  renderDashboardWidgets();
}
function toggleAddWidget() {
  dashAddZoneOpen = !dashAddZoneOpen;
  renderDashboardWidgets();
}
function setWidgetSize(id, size) {
  if (!DASH_WIDGET_SIZES.includes(size)) return;
  const layout = getDashLayout();
  const w = layout.widgets.find(x => x.id === id);
  if (!w) return;
  w.size = size;
  saveDashLayout();
  renderDashboardWidgets();
}
function hideWidget(id) {
  const layout = getDashLayout();
  layout.widgets = layout.widgets.filter(w => w.id !== id);
  saveDashLayout();
  renderDashboardWidgets();
}
function addWidget(id) {
  if (!DASH_WIDGETS[id]) return;
  const layout = getDashLayout();
  if (!layout.widgets.some(w => w.id === id)) layout.widgets.push({ id, size: 'small' });
  saveDashLayout();
  renderDashboardWidgets();
}
function resetDashLayout() {
  if (!confirm('Przywrócić domyślny układ widżetów?')) return;
  dashLayout = _cloneDefaultLayout();
  saveDashLayout();
  renderDashboardWidgets();
}

// ── Przeciąganie widżetów (zmiana kolejności) ──
function dwDragStart(e, id) {
  _dragWidgetId = id;
  e.dataTransfer.effectAllowed = 'move';
  try { e.dataTransfer.setData('text/plain', id); } catch (_) {}
  if (e.currentTarget) e.currentTarget.classList.add('dragging');
}
function dwDragOver(e, overId) {
  e.preventDefault();
  e.dataTransfer.dropEffect = 'move';
  document.querySelectorAll('.dash-widget.drop-target').forEach(el => el.classList.remove('drop-target'));
  if (overId !== _dragWidgetId && e.currentTarget) e.currentTarget.classList.add('drop-target');
}
function dwDrop(e, overId) {
  e.preventDefault();
  const from = _dragWidgetId;
  if (!from || from === overId) return;
  const layout = getDashLayout();
  const order = layout.widgets;
  const fromIdx = order.findIndex(w => w.id === from);
  const toIdx = order.findIndex(w => w.id === overId);
  if (fromIdx === -1 || toIdx === -1) return;
  const [moved] = order.splice(fromIdx, 1);
  order.splice(toIdx, 0, moved);
  saveDashLayout();
  renderDashboardWidgets();
}
function dwDragEnd() {
  _dragWidgetId = null;
  document.querySelectorAll('.dash-widget.dragging, .dash-widget.drop-target')
    .forEach(el => el.classList.remove('dragging', 'drop-target'));
}

// ── SCHEDULE ──
const SCHED_CATS = [
  {name:'Przygotowania',color:'#3b82f6',icon:'💄'},
  {name:'Ceremonia',    color:'#7c3aed',icon:'💒'},
  {name:'Sesja',        color:'#059669',icon:'📷'},
  {name:'Wesele',       color:'#d97706',icon:'🥂'},
  {name:'Tort',         color:'#ec4899',icon:'🎂'},
  {name:'Taniec',       color:'#ef4444',icon:'💃'},
  {name:'Inne',         color:'#6b7280',icon:'📌'},
];

// Linki do miejsc — używane TYLKO jednorazowo do zapisania ich w Firestore (migracja).
// Po zapisaniu wyświetlanie opiera się wyłącznie na danych z Firestore.
const SCHED_MAP_CHURCH = 'https://maps.app.goo.gl/i4wi2VWk5Fk1HWTY9';
const SCHED_MAP_HALL   = 'https://maps.app.goo.gl/y4iuPfPuRzFuJdkZA';

function _schedNorm(s) {
  return (s || '').toLowerCase()
    .replace(/ą/g,'a').replace(/ć/g,'c').replace(/ę/g,'e').replace(/ł/g,'l')
    .replace(/ń/g,'n').replace(/ó/g,'o').replace(/ś/g,'s').replace(/ź/g,'z').replace(/ż/g,'z');
}
// Dobiera startowy link do miejsca na podstawie nazwy wydarzenia (tylko do migracji)
function _seedUrlForName(name) {
  const n = _schedNorm(name);
  if (n.includes('ceremonia')) return SCHED_MAP_CHURCH;              // Ceremonia ślubna (kościół)
  if (n.includes('przyjazd') && !n.includes('rodzic')) return SCHED_MAP_HALL; // Przyjazd na wesele (sala)
  return null;
}
// Link wydarzenia w panelu organizatora — wyłącznie z danych (ręcznie wpisany URL)
function schedEventLink(ev) {
  return (ev.locationUrl || '').trim() || null;
}

// Jednorazowa migracja: zapisuje linki do map przy „Ceremonia ślubna" i „Przyjazd na wesele"
let locationLinksSeeded = false;
function seedLocationLinks() {
  if (locationLinksSeeded) return;
  let changed = false;
  scheduleEvents.forEach(ev => {
    if ((ev.locationUrl || '').trim()) return; // nie nadpisuj istniejącego linku
    const url = _seedUrlForName(ev.name);
    if (url) {
      ev.locationUrl = url;
      ev.showLinkToGuests = true;
      changed = true;
    }
  });
  locationLinksSeeded = true;
  if (changed && typeof renderSchedule === 'function') renderSchedule();
  saveState(); // utrwala flagę locationLinksSeeded (i ewentualne zmiany)
}

function addScheduleEvent() {
  scheduleEvents.push({ id:nextScheduleId++, hour:12, minute:0, duration:60, name:'Nowe wydarzenie', description:'', location:'', responsible:'', category:'Inne', private:false, locationUrl:'', showLinkToGuests:false });
  renderSchedule(); saveState();
}
function switchScheduleView(mode) {
  scheduleView = mode;
  ['list','columns','gantt'].forEach(m => {
    const b = document.getElementById('schv-' + m);
    if (b) b.classList.toggle('schv-active', m === mode);
  });
  const colsCtrl = document.getElementById('schedColsCtrl');
  if (colsCtrl) colsCtrl.style.display = (mode === 'columns') ? '' : 'none';
  renderSchedule();
}
function setScheduleCols(n) {
  scheduleCols = Math.max(1, Math.min(5, n || 1));
  const numEl = document.getElementById('schedColsNum');
  if (numEl) numEl.textContent = scheduleCols;
  if (scheduleView !== 'columns') switchScheduleView('columns');
  else renderSchedule();
}
function updateScheduleEvent(id, field, value) {
  const ev = scheduleEvents.find(e=>e.id===id);
  if (!ev) return;
  ev[field] = (field==='hour'||field==='minute') ? (parseInt(value)||0) : value;
  renderSchedule(); saveState();
}
function deleteScheduleEvent(id) {
  scheduleEvents = scheduleEvents.filter(e=>e.id!==id);
  renderSchedule(); saveState();
}
function addDefaultSchedule() {
  const defaults = [
    {hour:10,minute:0,name:'Przygotowania',description:'Fryzjer, makijaż, ubieranie',location:'Dom Panny Młodej',responsible:'Panna Młoda',category:'Przygotowania'},
    {hour:13,minute:30,name:'Wyjazd do kościoła',description:'',location:'',responsible:'Oboje',category:'Ceremonia'},
    {hour:14,minute:0,name:'Ceremonia ślubna',description:'Ślub kościelny / cywilny',location:'Kościół / USC',responsible:'Oboje',category:'Ceremonia'},
    {hour:15,minute:30,name:'Sesja zdjęciowa',description:'Zdjęcia plenerowe',location:'Plener',responsible:'Fotograf',category:'Sesja'},
    {hour:17,minute:0,name:'Przyjazd na salę',description:'Powitanie gości',location:'Sala weselna',responsible:'Oboje',category:'Wesele'},
    {hour:22,minute:0,name:'Tort weselny',description:'Krojenie tortu',location:'Sala weselna',responsible:'Oboje',category:'Tort'},
    {hour:1, minute:0,name:'Ostatni taniec',description:'Walc zamykający',location:'Sala weselna',responsible:'Oboje',category:'Taniec'},
  ];
  defaults.forEach(d => {
    const url = _seedUrlForName(d.name);
    scheduleEvents.push({
      id:nextScheduleId++, private:false,
      locationUrl: url || '', showLinkToGuests: !!url,
      ...d,
    });
  });
  renderSchedule(); saveState();
}
function _tevHtml(ev) {
  const cat = SCHED_CATS.find(c => c.name === ev.category) || SCHED_CATS[6];
  const catOpts = SCHED_CATS.map(ct =>
    `<option value="${ct.name}" ${ct.name === ev.category ? 'selected' : ''}>${ct.icon} ${ct.name}</option>`
  ).join('');
  const hh = String(ev.hour).padStart(2, '0');
  const mm = String(ev.minute).padStart(2, '0');
  const isPrivate = !!ev.private;
  const link = schedEventLink(ev);
  const showsToGuests = !!link && !!ev.showLinkToGuests;
  return `<div class="tev${isPrivate ? ' tev-private' : ''}" style="border-left:4px solid ${cat.color}" id="tev-${ev.id}">
    <div class="tev-meta">
      <div class="tev-time">
        <input type="number" class="tev-hh" value="${ev.hour}" min="0" max="23" onchange="updateScheduleEvent(${ev.id},'hour',parseInt(this.value)||0)">:<input type="number" class="tev-mm" value="${mm}" min="0" max="59" onchange="updateScheduleEvent(${ev.id},'minute',parseInt(this.value)||0)">
      </div>
      <div class="tev-dot" style="background:${cat.color}">${cat.icon}</div>
    </div>
    <div class="tev-body">
      <div class="tev-row1">
        ${isPrivate ? '<span class="tev-lock" title="Wydarzenie prywatne — ukryte przed gośćmi">&#128274;</span>' : ''}
        <input class="tev-name" type="text" value="${esc(ev.name)}" onchange="updateScheduleEvent(${ev.id},'name',this.value)">
        <select class="tev-cat" onchange="updateScheduleEvent(${ev.id},'category',this.value)">${catOpts}</select>
        ${link ? `<a class="tev-map-link" href="${esc(link)}" target="_blank" rel="noopener" title="Otwórz mapę">&#128205; Mapa</a>` : ''}
        <label class="tev-private-toggle" title="Ukryj to wydarzenie na publicznej stronie harmonogramu dla gości">
          <input type="checkbox" ${isPrivate ? 'checked' : ''} onchange="updateScheduleEvent(${ev.id},'private',this.checked)"> &#128274; Prywatne
        </label>
        <button class="btn-tev-edit" onclick="openEditModal('schedule',${ev.id})" title="Edytuj">&#9998;</button>
        <button class="btn-tev-del" onclick="deleteScheduleEvent(${ev.id})">&#128465;</button>
      </div>
      <div class="tev-row2">
        <input class="tev-input" type="text" value="${esc(ev.description)}" placeholder="Opis…" onchange="updateScheduleEvent(${ev.id},'description',this.value)">
        <input class="tev-input" type="text" value="${esc(ev.location)}" placeholder="Miejsce…" onchange="updateScheduleEvent(${ev.id},'location',this.value)">
        <input class="tev-input" type="text" value="${esc(ev.responsible)}" placeholder="Odpowiedzialny…" onchange="updateScheduleEvent(${ev.id},'responsible',this.value)">
      </div>
      <div class="tev-row3">
        <input class="tev-input tev-url" type="url" value="${esc(ev.locationUrl || '')}" placeholder="&#128279; Link do lokalizacji (URL)…" onchange="updateScheduleEvent(${ev.id},'locationUrl',this.value.trim())">
        <label class="tev-guest-toggle" title="Pokaż ten link gościom na stronie /harmonogram">
          <input type="checkbox" ${ev.showLinkToGuests ? 'checked' : ''} onchange="updateScheduleEvent(${ev.id},'showLinkToGuests',this.checked)"> &#128065; Pokaż link gościom
        </label>
        ${link ? `<span class="tev-link-state ${showsToGuests ? 'tls-on' : 'tls-off'}">${showsToGuests ? 'widoczny dla gości' : 'tylko organizatorzy'}</span>` : ''}
      </div>
    </div>
  </div>`;
}

function renderSchedule() {
  const c = document.getElementById('scheduleTimeline');
  if (!c) return;
  if (!scheduleEvents.length) {
    c.innerHTML = `<div class="empty-list">Brak wydarzeń.<br><button class="btn btn-primary" onclick="addDefaultSchedule()">&#128197; Dodaj domyślny harmonogram</button></div>`;
    return;
  }
  const sorted = [...scheduleEvents].sort((a, b) => {
    const ah = a.hour < 6 ? a.hour + 24 : a.hour, bh = b.hour < 6 ? b.hour + 24 : b.hour;
    return (ah * 60 + a.minute) - (bh * 60 + b.minute);
  });
  if (scheduleView === 'gantt')   { _renderSchedGantt(c, sorted);   return; }
  if (scheduleView === 'columns') { _renderSchedCols(c, sorted);    return; }
  c.innerHTML = '<div class="timeline-list">' + sorted.map(_tevHtml).join('') + '</div>';
}

function _renderSchedCols(c, sorted) {
  const n = Math.max(1, Math.min(5, scheduleCols || 3));
  const pad = x => String(x).padStart(2, '0');
  // Rozdziel wydarzenia kolejno na N kolumn (chronologicznie, równomiernie)
  const cols = Array.from({ length: n }, () => []);
  const per = Math.max(1, Math.ceil(sorted.length / n));
  sorted.forEach((ev, i) => { cols[Math.min(n - 1, Math.floor(i / per))].push(ev); });
  c.innerHTML = `<div class="sched-cols">${cols.map((evs, idx) => {
    const range = evs.length
      ? `${pad(evs[0].hour)}:${pad(evs[0].minute)}–${pad(evs[evs.length - 1].hour)}:${pad(evs[evs.length - 1].minute)}`
      : '';
    return `<div class="sched-col">
      <div class="sched-col-hdr"><span class="sched-col-title">Część ${idx + 1}</span><span class="sched-col-sub">${range || '—'}</span></div>
      <div class="timeline-list">${evs.length ? evs.map(_tevHtml).join('') : '<div class="sched-col-empty">Brak wydarzeń</div>'}</div>
    </div>`;
  }).join('')}</div>`;
}

function _renderSchedGantt(c, sorted) {
  if (!sorted.length) { c.innerHTML = '<div class="empty-list">Brak wydarzeń.</div>'; return; }

  const toMin = e => { const h = e.hour < 6 ? e.hour + 24 : e.hour; return h * 60 + e.minute; };
  const minStart = Math.min(...sorted.map(toMin));
  const maxEnd   = Math.max(...sorted.map(e => toMin(e) + (e.duration || 60)));
  const rangeStart = Math.floor(minStart / 60) * 60 - 30;
  const rangeEnd   = Math.ceil(maxEnd  / 60) * 60 + 30;
  const span = rangeEnd - rangeStart;

  const pct = m => ((m - rangeStart) / span * 100).toFixed(2) + '%';

  const hours = [];
  for (let h = Math.floor(rangeStart / 60); h <= Math.ceil(rangeEnd / 60); h++) {
    const m = h * 60;
    if (m >= rangeStart && m <= rangeEnd) hours.push(h);
  }

  const ruler = hours.map(h => {
    const lbl = String(h % 24).padStart(2, '0') + ':00';
    return `<div class="gantt-hr" style="left:${pct(h * 60)}"><span class="gantt-hr-lbl">${lbl}</span></div>`;
  }).join('');

  const rows = sorted.map(ev => {
    const cat  = SCHED_CATS.find(ct => ct.name === ev.category) || SCHED_CATS[6];
    const start = toMin(ev);
    const dur   = ev.duration || 60;
    const hh = String(ev.hour).padStart(2, '0'), mm = String(ev.minute).padStart(2, '0');
    return `<div class="gantt-row">
      <div class="gantt-row-lbl" title="${esc(ev.name)}">${cat.icon} <strong>${hh}:${mm}</strong> ${ev.private ? '&#128274; ' : ''}${esc(ev.name)}</div>
      <div class="gantt-track">
        ${hours.map(h => `<div class="gantt-grid-line" style="left:${pct(h * 60)}"></div>`).join('')}
        <div class="gantt-bar" style="left:${pct(start)};width:${(dur/span*100).toFixed(2)}%;background:${cat.color}" title="${esc(ev.name)} (${dur} min)">
          <span class="gantt-bar-lbl">${esc(ev.name)}</span>
        </div>
      </div>
    </div>`;
  }).join('');

  c.innerHTML = `<div class="gantt-wrap">
    <div class="gantt-ruler">${ruler}</div>
    <div class="gantt-rows">${rows}</div>
  </div>`;
}

// ── TASKS ──
const KANBAN_COLS = [
  { status:'todo',       label:'Do zrobienia', color:'#ef4444', icon:'📋' },
  { status:'inprogress', label:'W trakcie',    color:'#f59e0b', icon:'⏳' },
  { status:'done',       label:'Zrobione',     color:'#10b981', icon:'✅' },
  { status:'cancelled',  label:'Anulowane',    color:'#94a3b8', icon:'🚫' },
];
const TASK_STATUS_LABELS  = { todo:'Do zrobienia', inprogress:'W trakcie', done:'Zrobione', cancelled:'Anulowane' };
const TASK_PERSON_LABELS  = { groom:'Pan Młody', bride:'Panna Młoda', both:'Oboje' };
const TASK_PERSON_COLORS  = { groom:'#3b82f6',   bride:'#ec4899',     both:'#6b7280' };
const TASK_PRIORITIES = [
  { value:'low',  label:'Niski',   color:'#10b981', icon:'🟢' },
  { value:'med',  label:'Średni',  color:'#f59e0b', icon:'🟡' },
  { value:'high', label:'Wysoki',  color:'#ef4444', icon:'🔴' },
];
let taskView = 'board'; // 'board' | 'gantt'
let taskFilters = { status:'all', person:'', link:'all', date:'all' };
let taskSort = 'none';  // 'none' | 'date' | 'priority' | 'status'

function addTask() {
  tasks.push({ id:nextTaskId++, name:'Nowe zadanie', dueDate:'', startDate:'', endDate:'',
    responsible:'both', status:'todo', priority:'med', linkType:'', linkId:null,
    assigneeName:'', vendorId:null, giftId:null,
    isBudgetLinked:false, estimatedCost:0, budgetCategory:'', budgetExpenseId:null });
  renderTasks(); saveState();
}

// Inicjały przypisanej osoby (awatar na karcie)
function _assigneeInitials(name) {
  const parts = (name || '').trim().split(/\s+/).filter(Boolean);
  if (!parts.length) return '?';
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

function setTaskView(v) {
  taskView = v;
  ['board','gantt'].forEach(m => document.getElementById('tv-'+m)?.classList.toggle('schv-active', m===v));
  renderTasks();
}
function setTaskFilter(field, val) { taskFilters[field] = val; renderTasks(); }
function setTaskSort(val) { taskSort = val; renderTasks(); }
function updateTask(id,field,value) {
  const t=tasks.find(x=>x.id===id); if(!t) return;
  t[field]=value; renderTasks(); saveState();
}
function deleteTask(id) {
  const t = tasks.find(x => x.id === id);
  // Powiązany wpis budżetowy — zapytaj, czy usunąć także jego
  if (t && t.isBudgetLinked && t.budgetExpenseId != null) {
    const exp = budgetData.expenses.find(x => x.id === t.budgetExpenseId);
    if (exp && confirm('To zadanie jest powiązane z wpisem w budżecie. Usunąć także powiązany wpis budżetowy?')) {
      budgetData.expenses = budgetData.expenses.filter(x => x.id !== t.budgetExpenseId);
      if (typeof expenseOrder !== 'undefined') expenseOrder = expenseOrder.filter(eid => eid !== t.budgetExpenseId);
      if (typeof renderBudgetOverview === 'function') renderBudgetOverview();
      if (currentView === 'budget' && typeof renderExpenses === 'function') renderExpenses();
    }
  }
  tasks = tasks.filter(x => x.id !== id);
  renderTasks(); saveState();
}

function _taskCardHtml(t) {
  const today = new Date(); today.setHours(0,0,0,0);
  const overdue = t.dueDate && t.status!=='done' && t.status!=='cancelled' && new Date(t.dueDate) < today;
  const pc = TASK_PERSON_COLORS[t.responsible] || '#6b7280';
  const pl = TASK_PERSON_LABELS[t.responsible] || t.responsible;
  const prio = TASK_PRIORITIES.find(p => p.value === (t.priority||'med')) || TASK_PRIORITIES[1];
  const dateStr = t.dueDate
    ? `<span class="kcard-date${overdue?' kcard-overdue':''}">${overdue?'⚠ ':'📅 '}${t.dueDate}</span>`
    : '';
  // Znaczniki powiązań (referencje): budżet, dostawca, prezent
  const budgetStr = t.isBudgetLinked
    ? `<span class="kcard-link kcard-budget" title="Budżet${t.budgetCategory?': '+esc(t.budgetCategory):''}" onclick="event.stopPropagation();switchView('budget')">💰 ${fmt(t.estimatedCost||0)} zł</span>`
    : '';
  const vendor  = t.vendorId != null ? vendors.find(v => v.id === t.vendorId) : null;
  const vendorStr = vendor
    ? `<span class="kcard-link" title="Dostawca" onclick="event.stopPropagation();switchView('vendors')">👨‍🍳 ${esc(vendorLabel(vendor))}</span>`
    : '';
  const gift    = t.giftId != null ? gifts.find(g => g.id === t.giftId) : null;
  const giftStr = gift
    ? `<span class="kcard-link" title="Prezent" onclick="event.stopPropagation();switchView('gifts')">🎁 ${esc(gift.description||gift.from||'Prezent')}</span>`
    : '';
  const assigneeAv = t.assigneeName
    ? `<span class="kcard-assignee" title="Przypisano: ${esc(t.assigneeName)}">${esc(_assigneeInitials(t.assigneeName))}</span>`
    : '';
  const done = t.status==='done', cancelled = t.status==='cancelled';
  return `<div class="kanban-card${done?' kcard-done':''}${cancelled?' kcard-cancelled':''}"
      id="kcard-${t.id}" draggable="true"
      ondragstart="kanbanDragStart(event,${t.id})"
      ondragend="kanbanDragEnd(event)">
    <div class="kcard-top">
      <span class="kcard-prio" title="Priorytet: ${prio.label}" style="color:${prio.color}">${prio.icon}</span>
      <input class="kcard-name${done||cancelled?' kcard-striked':''}" type="text"
        value="${esc(t.name)}" onchange="updateTask(${t.id},'name',this.value)">
      ${assigneeAv}
    </div>
    <div class="kcard-footer">
      <span class="kcard-person" style="background:${pc}22;color:${pc}">${pl}</span>
      ${dateStr}
      ${budgetStr}
      ${vendorStr}
      ${giftStr}
      <div class="kcard-actions">
        <button class="btn-row-edit" onclick="openEditModal('task',${t.id})" title="Edytuj">&#9998;</button>
        <button class="btn-row-del" onclick="deleteTask(${t.id})">&#128465;</button>
      </div>
    </div>
  </div>`;
}

// Filtrowanie + sortowanie zadań (wspólne dla tablicy i Gantta)
function _filteredSortedTasks() {
  const today = new Date(); today.setHours(0,0,0,0);
  let list = tasks.filter(t => {
    if (taskFilters.status !== 'all' && t.status !== taskFilters.status) return false;
    if (taskFilters.person && t.responsible !== taskFilters.person) return false;
    const hasVendor = t.vendorId != null, hasGift = t.giftId != null, hasBudget = !!t.isBudgetLinked;
    if (taskFilters.link === 'none'   && (hasVendor || hasGift || hasBudget)) return false;
    if (taskFilters.link === 'vendor' && !hasVendor) return false;
    if (taskFilters.link === 'budget' && !hasBudget) return false;
    if (taskFilters.link === 'gift'   && !hasGift)   return false;
    if (taskFilters.date === 'withdate' && !t.dueDate) return false;
    if (taskFilters.date === 'nodate'   && t.dueDate)  return false;
    if (taskFilters.date === 'overdue'  && !(t.dueDate && t.status!=='done' && t.status!=='cancelled' && new Date(t.dueDate) < today)) return false;
    return true;
  });
  if (taskSort === 'date') {
    list = [...list].sort((a,b) => (a.dueDate||'9999').localeCompare(b.dueDate||'9999'));
  } else if (taskSort === 'priority') {
    const rank = { high:0, med:1, low:2 };
    list = [...list].sort((a,b) => (rank[a.priority]??1) - (rank[b.priority]??1));
  } else if (taskSort === 'status') {
    const order = KANBAN_COLS.map(c=>c.status);
    list = [...list].sort((a,b) => order.indexOf(a.status) - order.indexOf(b.status));
  }
  return list;
}

function setTaskPersonFilter(val) {
  taskFilters.person = val;
  const el = document.getElementById('taskFilterPerson');
  if (el) el.value = val;
  document.querySelectorAll('#taskFilters .gf-btn').forEach(b => {
    b.classList.toggle('gf-active', b.dataset.value === val);
  });
  renderTasks();
}

function renderTasks() {
  const board = document.getElementById('kanbanBoard');
  const lbl   = document.getElementById('tasksProgressLabel');
  const fill  = document.getElementById('tasksProgressFill');
  if (!board) return;

  const done = tasks.filter(t=>t.status==='done').length;
  const pct  = tasks.length ? Math.round(done/tasks.length*100) : 0;
  if (lbl)  lbl.textContent  = `${done}/${tasks.length} ukończonych (${pct}%)`;
  if (fill) fill.style.width = pct+'%';

  const filtered = _filteredSortedTasks();
  const ganttCont = document.getElementById('tasksGantt');

  if (taskView === 'gantt') {
    board.style.display = 'none';
    if (ganttCont) { ganttCont.style.display = ''; _renderTasksGantt(ganttCont, filtered); }
    return;
  }
  board.style.display = '';
  if (ganttCont) ganttCont.style.display = 'none';

  board.innerHTML = KANBAN_COLS.map(col => {
    const colTasks = filtered.filter(t=>t.status===col.status);
    const cards    = colTasks.map(_taskCardHtml).join('');
    return `<div class="kanban-col"
        ondragover="event.preventDefault();this.classList.add('kol-over')"
        ondragleave="this.classList.remove('kol-over')"
        ondrop="kanbanDrop(event,'${col.status}')">
      <div class="kanban-col-hdr" style="border-top:3px solid ${col.color}">
        <span class="kcol-title">${col.icon} ${col.label}</span>
        <span class="kcol-count" style="background:${col.color}22;color:${col.color}">${colTasks.length}</span>
      </div>
      <div class="kanban-cards">
        ${cards || '<div class="kanban-empty">Brak zadań</div>'}
      </div>
    </div>`;
  }).join('');
  setTimeout(initMobileCollapse, 0);
}

// ── HARMONOGRAM ZADAŃ (wykres Gantta) ──
function _renderTasksGantt(c, list) {
  // Bierzemy tylko zadania z jakąkolwiek datą (start/koniec/termin)
  const withDates = list.map(t => {
    const start = t.startDate || t.dueDate || t.endDate;
    const end   = t.endDate || t.dueDate || t.startDate;
    return start && end ? { t, start, end } : null;
  }).filter(Boolean);

  if (!withDates.length) {
    c.innerHTML = '<div class="empty-list">Brak zadań z datami. Ustaw datę rozpoczęcia/zakończenia lub termin w edycji zadania.</div>';
    return;
  }

  const toDay = d => Math.floor(new Date(d + 'T00:00:00').getTime() / 86400000);
  let minD = Infinity, maxD = -Infinity;
  withDates.forEach(w => { minD = Math.min(minD, toDay(w.start)); maxD = Math.max(maxD, toDay(w.end)); });
  const span = Math.max(1, maxD - minD + 1);
  const fmtD = ds => { const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(ds); return m ? `${m[3]}.${m[2]}` : ds; };

  const rows = withDates.map(({ t, start, end }) => {
    const s = toDay(start) - minD, e = toDay(end) - minD;
    const left = (s / span * 100).toFixed(2);
    const width = Math.max(2, ((e - s + 1) / span * 100)).toFixed(2);
    const col = KANBAN_COLS.find(k => k.status === t.status) || KANBAN_COLS[0];
    return `<div class="tg-row">
      <div class="tg-label" title="${esc(t.name)}" onclick="openEditModal('task',${t.id})">${col.icon} ${esc(t.name)}</div>
      <div class="tg-track">
        <div class="tg-bar" style="left:${left}%;width:${width}%;background:${col.color}"
             title="${esc(t.name)} (${fmtD(start)}–${fmtD(end)})" onclick="openEditModal('task',${t.id})">
          <span class="tg-bar-lbl">${fmtD(start)}–${fmtD(end)}</span>
        </div>
      </div>
    </div>`;
  }).join('');

  c.innerHTML = `<div class="tg-wrap">
    <div class="tg-head"><div class="tg-label tg-head-lbl">Zadanie</div><div class="tg-track tg-head-range">${fmtD(withDates.reduce((a,w)=>w.start<a?w.start:a, withDates[0].start))} → ${fmtD(withDates.reduce((a,w)=>w.end>a?w.end:a, withDates[0].end))}</div></div>
    ${rows}
  </div>`;
}

function kanbanDragStart(event, taskId) {
  event.dataTransfer.setData('kTaskId', String(taskId));
  event.dataTransfer.effectAllowed = 'move';
  setTimeout(() => document.getElementById('kcard-'+taskId)?.classList.add('kcard-dragging'), 0);
}
function kanbanDragEnd(event) {
  document.querySelectorAll('.kcard-dragging').forEach(el=>el.classList.remove('kcard-dragging'));
  document.querySelectorAll('.kol-over').forEach(el=>el.classList.remove('kol-over'));
}
function kanbanDrop(event, newStatus) {
  event.preventDefault();
  event.currentTarget.classList.remove('kol-over');
  const id = parseInt(event.dataTransfer.getData('kTaskId'));
  if (!id) return;
  const t = tasks.find(x=>x.id===id);
  if (t && t.status !== newStatus) { t.status=newStatus; renderTasks(); saveState(); }
}

// ── VENDORS ──
const VENDOR_CATS=['Fotograf','Kamerzysta','Muzyka','Kwiaty','Tort','Catering','Transport','Inne'];
const VENDOR_STATUSES=[
  {value:'contacted',label:'Skontaktowano',color:'#3b82f6'},
  {value:'confirmed',label:'Potwierdzony', color:'#10b981'},
  {value:'paid',     label:'Opłacony',     color:'#6d28d9'},
  {value:'cancelled',label:'Anulowany',    color:'#ef4444'},
];
function addVendor() {
  const cf = document.getElementById('vendorFilterCat');
  const sf = document.getElementById('vendorFilterStatus');
  if (cf) cf.value = '';
  if (sf) sf.value = '';
  vendors.push({id:nextVendorId++,category:'Fotograf',customCategory:'',companyName:'',contactName:'',phone:'',email:'',price:0,paymentStatus:'contacted',notes:'',mapUrl:'',
    isBudgetLinked:false,contractAmount:0,budgetCategory:'',budgetExpenseId:null,installments:[]});
  renderVendors(); saveState();
}

// ── Raty dostawcy (płatności częściowe: zadatek, 1 rata, 2 rata…) ──
function _nextInstId(arr) { return (arr || []).reduce((m, x) => Math.max(m, (x.id || 0) + 1), 1); }
function addVendorInstallment(vendorId) {
  const v = vendors.find(x => x.id === vendorId); if (!v) return;
  if (!Array.isArray(v.installments)) v.installments = [];
  const n = v.installments.length;
  const label = n === 0 ? 'Zadatek' : `${n}. rata`;
  v.installments.push({ id: _nextInstId(v.installments), label, amount: 0, dueDate: '', status: 'due' });
  renderVendors(); saveState();
}
function updateVendorInstallment(vendorId, instId, field, value) {
  const v = vendors.find(x => x.id === vendorId); if (!v) return;
  const it = (v.installments || []).find(x => x.id === instId); if (!it) return;
  it[field] = field === 'amount' ? (parseFloat(value) || 0) : value;
  renderVendors(); saveState();
}
function deleteVendorInstallment(vendorId, instId) {
  const v = vendors.find(x => x.id === vendorId); if (!v) return;
  v.installments = (v.installments || []).filter(x => x.id !== instId);
  renderVendors(); saveState();
}
// Suma rat zapłaconych / pozostałych
function _vendorInstallmentSums(v) {
  const list = v.installments || [];
  const total = list.reduce((s, i) => s + (i.amount || 0), 0);
  const paid  = list.filter(i => i.status === 'paid').reduce((s, i) => s + (i.amount || 0), 0);
  return { total, paid, remaining: Math.max(0, total - paid) };
}
function updateVendor(id,field,value) {
  const v=vendors.find(x=>x.id===id);
  if(v){v[field]=field==='price'?(parseFloat(value)||0):value; renderVendors(); saveState();}
}
function deleteVendor(id) {
  const v = vendors.find(x => x.id === id);
  // Powiązany wpis budżetowy — zapytaj, czy usunąć także jego
  if (v && v.isBudgetLinked && v.budgetExpenseId != null) {
    const exp = budgetData.expenses.find(x => x.id === v.budgetExpenseId);
    if (exp && confirm('Ten dostawca jest powiązany z wpisem w budżecie. Usunąć także powiązany wpis budżetowy?')) {
      budgetData.expenses = budgetData.expenses.filter(x => x.id !== v.budgetExpenseId);
      if (typeof expenseOrder !== 'undefined') expenseOrder = expenseOrder.filter(eid => eid !== v.budgetExpenseId);
      if (typeof renderBudgetOverview === 'function') renderBudgetOverview();
      if (currentView === 'budget' && typeof renderExpenses === 'function') renderExpenses();
    }
  }
  vendors = vendors.filter(x => x.id !== id);
  // Spójność: wyczyść powiązanie w zadaniach wskazujących na usuniętego dostawcę
  tasks.forEach(t => { if (t.vendorId === id) t.vendorId = null; });
  renderVendors(); saveState();
}

// ── Reużywalny wybór istniejącego dostawcy (Noclegi/Budżet/Plan sali/Zadania) ──
function vendorLabel(v) {
  return (v.companyName || v.contactName || (v.category === 'Inne' ? v.customCategory : v.category) || 'Dostawca');
}
function _vendorOptionsHtml(placeholder) {
  const opts = vendors.map(v => {
    const cat = (v.category && v.category !== 'Inne') ? ' (' + esc(v.category) + ')' : '';
    return `<option value="${v.id}">${esc(vendorLabel(v))}${cat}</option>`;
  }).join('');
  return `<option value="">${esc(placeholder || '— z dostawcy —')}</option>${opts}`;
}
// Wypełnia <select id> opcjami dostawców (jeśli element istnieje)
function _fillVendorPicker(id, placeholder) {
  const el = document.getElementById(id);
  if (el) el.innerHTML = _vendorOptionsHtml(placeholder);
}
// Budżet: dodaj wydatek na podstawie istniejącego dostawcy
function addExpenseFromVendor(vendorId) {
  const v = vendors.find(x => x.id === parseInt(vendorId));
  if (!v) return;
  const name = vendorLabel(v);
  const newId = nextExpenseId++;
  budgetData.expenses.push({
    id: newId, category: 'Inne', customName: name,
    planned: v.price || 0, estimatedAmount: 0, paid: 0, paymentDate: '',
    note: 'Dostawca: ' + name, splitP1: 0, splitP2: 0, sidePanel: false, vendorId: v.id,
  });
  expenseOrder.push(newId);
  renderExpenses(); renderCoupleSummary(); renderBudgetOverview(); renderCharts(); saveState();
  showToast('Dodano wydatek: ' + name);
}
// Noclegi: wypełnij formularz hotelu danymi dostawcy
function _prefillHotelFromVendor(id) {
  const v = vendors.find(x => x.id === parseInt(id));
  if (!v) return;
  const set = (f, val) => { const el = document.getElementById('ef_' + f); if (el && val) el.value = val; };
  set('name', v.companyName || v.contactName || '');
  set('phone', v.phone || '');
}
// Plan sali: wypełnij nazwę stołu personelu danymi dostawcy
function _prefillStaffFromVendor(id) {
  const v = vendors.find(x => x.id === parseInt(id));
  if (!v) return;
  const sel = document.getElementById('staffTableName');
  const cust = document.getElementById('staffTableCustomName');
  if (sel) sel.value = 'Inne';
  if (cust) { cust.style.display = ''; cust.value = vendorLabel(v); }
}
function renderVendors() {
  const c=document.getElementById('vendorsList'); if(!c) return;
  const cf=document.getElementById('vendorFilterCat')?.value||'';
  const sf=document.getElementById('vendorFilterStatus')?.value||'';
  const filtered=vendors.filter(v=>(!cf||v.category===cf)&&(!sf||v.paymentStatus===sf));
  if(!filtered.length){c.innerHTML='<div class="empty-list">Brak dostawców.</div>';return;}
  c.innerHTML='<div class="vendors-grid">'+filtered.map(v=>{
    const st=VENDOR_STATUSES.find(s=>s.value===v.paymentStatus)||VENDOR_STATUSES[0];
    const catOpts=VENDOR_CATS.map(cat=>`<option value="${cat}"${cat===v.category?' selected':''}>${cat}</option>`).join('');
    const stOpts=VENDOR_STATUSES.map(s=>`<option value="${s.value}"${s.value===v.paymentStatus?' selected':''}>${s.label}</option>`).join('');
    const otherField = v.category==='Inne'
      ? `<input class="vendor-field vendor-field-custom" type="text" value="${esc(v.customCategory||'')}" placeholder="Wpisz kategorię…" onchange="updateVendor(${v.id},'customCategory',this.value)">`
      : '';
    const displayCat = v.category==='Inne' && v.customCategory ? v.customCategory : v.category;
    const budgetChip = v.isBudgetLinked
      ? `<span class="vendor-budget-chip" title="Powiązano z budżetem${v.budgetCategory?': '+esc(v.budgetCategory):''}" onclick="switchView('budget')">💰 ${fmt(v.contractAmount||0)} zł</span>`
      : '';
    return `<div class="vendor-card">
      <div class="vendor-hdr">
        <span class="vendor-type-badge" title="Dostawca">🏢 Dostawca</span>
        <select class="vendor-cat" onchange="updateVendor(${v.id},'category',this.value)">${catOpts}</select>
        <span class="vendor-badge" style="background:${st.color}22;color:${st.color}">${st.label}</span>
        ${budgetChip}
        <button class="btn-row-edit" onclick="openEditModal('vendor',${v.id})" title="Edytuj">&#9998;</button>
        <button class="btn-row-del" onclick="deleteVendor(${v.id})">&#128465;</button>
      </div>
      ${otherField}
      <input class="vendor-field" type="text" value="${esc(v.companyName)}" placeholder="Nazwa firmy" onchange="updateVendor(${v.id},'companyName',this.value)">
      <input class="vendor-field" type="text" value="${esc(v.contactName)}" placeholder="Imię kontaktu" onchange="updateVendor(${v.id},'contactName',this.value)">
      <div class="vendor-phone-row">
        ${v.phone?`<a href="tel:${esc(v.phone)}" class="vendor-phone-link">&#128222; ${esc(v.phone)}</a>`:''}
        <input class="vendor-field" type="tel" value="${esc(v.phone)}" placeholder="Telefon" onchange="updateVendor(${v.id},'phone',this.value)">
      </div>
      <input class="vendor-field" type="email" value="${esc(v.email)}" placeholder="Email" onchange="updateVendor(${v.id},'email',this.value)">
      <div class="vendor-map-row">
        ${safeUrl(v.mapUrl) ? `<a href="${esc(v.mapUrl)}" target="_blank" rel="noopener" class="vendor-map-link">&#128205; Mapa</a>` : ''}
        <input class="vendor-field" type="url" value="${esc(v.mapUrl||'')}" placeholder="Link do Google Maps" onchange="updateVendor(${v.id},'mapUrl',this.value)">
      </div>
      <div class="vendor-price-row">
        <label>Cena:</label>
        <input class="vendor-price" type="number" value="${v.price||0}" min="0" onchange="updateVendor(${v.id},'price',this.value)"> zł
        <select class="vendor-status" onchange="updateVendor(${v.id},'paymentStatus',this.value)">${stOpts}</select>
      </div>
      ${(() => {
        const list = v.installments || [];
        const sums = _vendorInstallmentSums(v);
        const rows = list.map(it => `
          <div class="vi-row">
            <input class="vi-label" type="text" value="${esc(it.label||'')}" placeholder="np. Zadatek / 1. rata" onchange="updateVendorInstallment(${v.id},${it.id},'label',this.value)">
            <input class="vi-amount" type="number" min="0" value="${it.amount||0}" onchange="updateVendorInstallment(${v.id},${it.id},'amount',this.value)" title="Kwota (zł)">
            <input class="vi-date" type="date" value="${esc(it.dueDate||'')}" onchange="updateVendorInstallment(${v.id},${it.id},'dueDate',this.value)" title="Termin">
            <select class="vi-status ${it.status==='paid'?'vi-paid':''}" onchange="updateVendorInstallment(${v.id},${it.id},'status',this.value)">
              <option value="due"${it.status!=='paid'?' selected':''}>Do zapłaty</option>
              <option value="paid"${it.status==='paid'?' selected':''}>Zapłacona</option>
            </select>
            <button class="btn-row-del" onclick="deleteVendorInstallment(${v.id},${it.id})" title="Usuń ratę">&#128465;</button>
          </div>`).join('');
        return `<div class="vendor-installments">
          <div class="vi-hdr"><span>&#128181; Raty / płatności częściowe</span>
            <button class="btn btn-sm btn-primary" onclick="addVendorInstallment(${v.id})">+ Rata</button>
          </div>
          <div class="vi-list">${rows}</div>
          ${list.length ? `<div class="vi-summary">Zapłacono: <b class="vi-paid-sum">${fmt(sums.paid)} zł</b> · Pozostało: <b class="vi-rem-sum">${fmt(sums.remaining)} zł</b> · Suma rat: ${fmt(sums.total)} zł</div>` : ''}
        </div>`;
      })()}
      <textarea class="vendor-notes" placeholder="Notatki…" onchange="updateVendor(${v.id},'notes',this.value)">${esc(v.notes)}</textarea>
    </div>`;
  }).join('')+'</div>';
}

// ── RSVP ──
function normalizePL(str) {
  return (str||'').toLowerCase()
    .replace(/ą/g,'a').replace(/ć/g,'c').replace(/ę/g,'e').replace(/ł/g,'l')
    .replace(/ń/g,'n').replace(/ó/g,'o').replace(/ś/g,'s').replace(/ź/g,'z').replace(/ż/g,'z')
    .replace(/\s+/g,' ').trim();
}
function levenshtein(a,b) {
  if(!a.length) return b.length; if(!b.length) return a.length;
  const dp=Array.from({length:a.length+1},(_,i)=>Array.from({length:b.length+1},(_,j)=>i?j?0:i:j));
  for(let i=1;i<=a.length;i++) for(let j=1;j<=b.length;j++)
    dp[i][j]=a[i-1]===b[j-1]?dp[i-1][j-1]:1+Math.min(dp[i-1][j],dp[i][j-1],dp[i-1][j-1]);
  return dp[a.length][b.length];
}
function findGuestMatch(input) {
  const norm=normalizePL(input);
  if(norm.length<2) return {exact:null,close:[]};
  const scored=guests.map(g=>{
    const gn=normalizePL(fullName(g));
    const score=Math.min(levenshtein(norm,gn),levenshtein(norm,normalizePL(g.firstName||'')),levenshtein(norm,normalizePL(g.lastName||'')));
    return {guest:g,score};
  });
  const exact=scored.find(s=>s.score===0);
  const threshold=Math.max(2,Math.floor(norm.length/4));
  const close=scored.filter(s=>s.score>0&&s.score<=threshold).sort((a,b)=>a.score-b.score).slice(0,3).map(s=>s.guest);
  return {exact:exact?.guest||null,close};
}
function addRsvpManual(guestId, status, companionName) {
  rsvpEntries = rsvpEntries.filter(e => e.guestId !== guestId);
  rsvpEntries.push({
    id: nextRsvpId++, rawName: '', status, message: '',
    guestId, manual: true, timestamp: new Date().toISOString(),
    companionName: companionName || '',
  });
  renderRsvpPanel(); saveState();
}
function assignRsvpEntry(entryId, guestId) {
  const e = rsvpEntries.find(x => x.id === entryId);
  if (e) { e.guestId = guestId; e.manual = true; renderRsvpPanel(); saveState(); }
}
function deleteRsvpEntry(entryId) { rsvpEntries = rsvpEntries.filter(e => e.id !== entryId); renderRsvpPanel(); saveState(); }
function clearAllRsvp() { if (!confirm('Wyczyścić wszystkie potwierdzenia?')) return; rsvpEntries = []; renderRsvpPanel(); saveState(); }
function getGuestRsvpStatus(gId) { const e = rsvpEntries.filter(x => x.guestId === gId).slice(-1)[0]; return e ? e.status : null; }

function confirmPairRsvp(guestId, status) {
  rsvpEntries = rsvpEntries.filter(e => e.guestId !== guestId);
  rsvpEntries.push({
    id: nextRsvpId++, rawName: '', status, message: '',
    guestId, manual: true, timestamp: new Date().toISOString(), companionName: '',
  });
  renderRsvpPanel(); saveState();
}

function setRsvpCompanion(guestId, name) {
  const entry = rsvpEntries.filter(e => e.guestId === guestId).slice(-1)[0];
  if (entry) { entry.companionName = name; saveState(); }
}

function _rsvpStCls(st) { return st === 'attending' ? 'rsvp-att' : st === 'not_attending' ? 'rsvp-not' : 'rsvp-none'; }
function _rsvpStLbl(st) { return st === 'attending' ? '&#10003; Przyjdzie' : st === 'not_attending' ? '&#10007; Nie przyjdzie' : '&#9633; Brak'; }

function _buildRsvpGroups() {
  const shown = new Set();
  const groups = [];
  for (const g of guests) {
    if (shown.has(g.id)) continue;
    shown.add(g.id);
    if ((g.category || '') === 'Państwo Młodzi') continue;  // Para Młoda nie wymaga potwierdzenia RSVP
    if (g.pairId !== null) {
      const pair = pairs.find(p => p.id === g.pairId);
      if (pair) {
        const partnerId = pair.g1 === g.id ? pair.g2 : pair.g1;
        const partner = guests.find(x => x.id === partnerId);
        if (partner && !shown.has(partnerId)) {
          shown.add(partnerId);
          groups.push({ type: 'pair', g1: g, g2: partner });
          continue;
        }
      }
    }
    groups.push({ type: 'single', g });
  }
  return groups;
}

function _rsvpManualSel(gId) {
  return `<select class="rsvp-manual" onchange="if(this.value)addRsvpManual(${gId},this.value)">
    <option value="">Zmień…</option>
    <option value="attending">&#10003; Przyjdzie</option>
    <option value="not_attending">&#10007; Nie przyjdzie</option>
  </select>`;
}

function _renderRsvpGroup(group) {
  if (group.type === 'single') {
    const g = group.g;
    const st = getGuestRsvpStatus(g.id);
    const entry = rsvpEntries.filter(e => e.guestId === g.id).slice(-1)[0];
    const companionSection = st === 'attending' ? `
      <div class="rsvp-companion-row">
        <label class="rsvp-companion-lbl">&#128100; Osoba towarzysząca:</label>
        <input type="text" class="rsvp-companion-input" placeholder="Imię i nazwisko…"
               value="${esc(entry?.companionName || '')}"
               onchange="setRsvpCompanion(${g.id},this.value)">
      </div>` : '';
    return `<div class="rsvp-guest-row ${_rsvpStCls(st)}">
      <div class="rsvp-gi">${avatarHtml(g, 'avatar-sm')}<div>
        <div class="rsvp-gname">${esc(fullName(g))}</div>
        ${entry?.message ? `<div class="rsvp-msg">&ldquo;${esc(entry.message)}&rdquo;</div>` : ''}
        ${entry?.companionName ? `<div class="rsvp-companion-tag">&#128100; ${esc(entry.companionName)}</div>` : ''}
      </div></div>
      <div class="rsvp-actions">
        <span class="rsvp-lbl ${_rsvpStCls(st)}">${_rsvpStLbl(st)}</span>
        ${_rsvpManualSel(g.id)}
      </div>
      ${companionSection}
    </div>`;
  }

  // Pair group
  const { g1, g2 } = group;
  const st1 = getGuestRsvpStatus(g1.id);
  const st2 = getGuestRsvpStatus(g2.id);
  const e1  = rsvpEntries.filter(e => e.guestId === g1.id).slice(-1)[0];
  const e2  = rsvpEntries.filter(e => e.guestId === g2.id).slice(-1)[0];

  const memberHtml = (g, st, entry, partner, partnerSt) => {
    const oneClick = st && !partnerSt
      ? `<button class="btn btn-sm rsvp-pair-confirm-btn" onclick="confirmPairRsvp(${partner.id},'${st}')">
           ${st === 'attending' ? '&#10003;' : '&#10007;'} Potwierdź też ${esc(partner.firstName)}
         </button>` : '';
    return `<div class="rsvp-pair-member ${_rsvpStCls(st)}">
      <div class="rsvp-gi">${avatarHtml(g, 'avatar-sm')}<div>
        <div class="rsvp-gname">${esc(fullName(g))}</div>
        ${entry?.message ? `<div class="rsvp-msg">&ldquo;${esc(entry.message)}&rdquo;</div>` : ''}
      </div></div>
      <div class="rsvp-actions">
        <span class="rsvp-lbl ${_rsvpStCls(st)}">${_rsvpStLbl(st)}</span>
        ${_rsvpManualSel(g.id)}
        ${oneClick}
      </div>
    </div>`;
  };

  const bothSt = st1 === st2 && st1 ? `<span class="rsvp-pair-joint-lbl ${_rsvpStCls(st1)}">${_rsvpStLbl(st1)} oboje</span>` : '';

  return `<div class="rsvp-pair-card">
    <div class="rsvp-pair-header">&#10084; Para ${bothSt}</div>
    ${memberHtml(g1, st1, e1, g2, st2)}
    <div class="rsvp-pair-divider"></div>
    ${memberHtml(g2, st2, e2, g1, st1)}
  </div>`;
}

function renderRsvpPanel() {
  const statsRow = document.getElementById('rsvpStatsRow');
  const resList  = document.getElementById('rsvpResponsesList');
  const unmList  = document.getElementById('rsvpUnmatchedList');
  if (!statsRow) return;

  const attending = rsvpEntries.filter(e => e.guestId && e.status === 'attending').length;
  const notAtt    = rsvpEntries.filter(e => e.guestId && e.status === 'not_attending').length;
  // Para Młoda (Państwo Młodzi) nie wymaga potwierdzenia — pomiń w statystyce „brak odpowiedzi"
  const noReply   = guests.filter(g => (g.category||'') !== 'Państwo Młodzi' && !rsvpEntries.some(e => e.guestId === g.id)).length;
  statsRow.innerHTML = `
    <div class="rsvp-stat rsvp-att"><span class="rsn">${attending}</span><span>Przyjdą</span></div>
    <div class="rsvp-stat rsvp-not"><span class="rsn">${notAtt}</span><span>Nie przyjdą</span></div>
    <div class="rsvp-stat rsvp-none"><span class="rsn">${noReply}</span><span>Brak odpowiedzi</span></div>`;

  if (resList) {
    const groups = _buildRsvpGroups();
    resList.innerHTML = groups.map(_renderRsvpGroup).join('') || '<div class="empty-list">Brak gości.</div>';
  }

  if (unmList) {
    const unm = rsvpEntries.filter(e => !e.guestId);
    if (!unm.length) { unmList.innerHTML = '<div class="empty-list" style="padding:8px 0">Brak nieprzypisanych.</div>'; return; }
    const gOpts = guests.map(g => `<option value="${g.id}">${esc(fullName(g))}</option>`).join('');
    unmList.innerHTML = unm.map(e => `<div class="rsvp-unmatched-row">
      <div><strong>${esc(e.rawName)}</strong> &#8594; ${e.status === 'attending' ? 'Przyjdzie' : 'Nie przyjdzie'}
        ${e.message ? `<br><em>&ldquo;${esc(e.message)}&rdquo;</em>` : ''}
      </div>
      <div class="rsvp-um-actions">
        <select class="rsvp-assign" onchange="if(this.value)assignRsvpEntry(${e.id},parseInt(this.value))">
          <option value="">Przypisz do gościa…</option>${gOpts}
        </select>
        <button class="btn btn-sm btn-danger" onclick="deleteRsvpEntry(${e.id})">Usuń</button>
      </div>
    </div>`).join('');
  }
}

// ── GIFTS ──
function addGift() { gifts.push({id:nextGiftId++,from:'',description:'',value:null,thanked:false}); renderGifts(); saveState(); }
function updateGift(id,field,value) { const g=gifts.find(x=>x.id===id); if(g){g[field]=value; _refreshGiftsSummary(); saveState();} }
function deleteGift(id) {
  gifts=gifts.filter(x=>x.id!==id);
  // Spójność: wyczyść powiązanie w zadaniach wskazujących na usunięty prezent
  tasks.forEach(t => { if (t.giftId === id) t.giftId = null; });
  renderGifts(); saveState();
}
function _refreshGiftsSummary() {
  const s=document.getElementById('giftsSummary'); if(!s) return;
  const total=gifts.reduce((sum,g)=>sum+(g.value||0),0);
  const thanked=gifts.filter(g=>g.thanked).length;
  s.innerHTML=`<div class="sum-stat"><span class="sv">${gifts.length}</span><span>Prezentów</span></div>
    <div class="sum-stat"><span class="sv">${fmt(total)} zł</span><span>Łączna wartość</span></div>
    <div class="sum-stat"><span class="sv">${thanked}/${gifts.length}</span><span>Podziękowano</span></div>`;
}
// ── Zakładki prezentów ──
function switchGiftsTab(tab) {
  giftsTab = tab;
  ['received','forguests','proposals'].forEach(t => {
    const btn = document.getElementById('gtab-' + t);
    if (btn) btn.classList.toggle('active', t === tab);
    const panel = document.getElementById('gtabPanel-' + t);
    if (panel) panel.style.display = (t === tab) ? '' : 'none';
  });
  renderGifts();
}

function renderGifts() {
  renderGiftsReceived();
  renderGiftsForGuests();
  renderGiftProposals();
}

function renderGiftsReceived() {
  const c=document.getElementById('giftsList'); if(!c) return;
  _refreshGiftsSummary();
  if(!gifts.length){c.innerHTML='<div class="empty-list">Brak prezentów.</div>';return;}
  c.innerHTML='<div class="gifts-grid">'+gifts.map(g=>`<div class="gift-card${g.thanked?' gift-thanked':''}">
    <div class="gift-hdr">
      <input class="gift-field" type="text" value="${esc(g.from)}" placeholder="Od kogo…" onchange="updateGift(${g.id},'from',this.value)">
      <button class="btn-row-edit" onclick="openEditModal('gift',${g.id})" title="Edytuj">&#9998;</button>
      <button class="btn-row-del" onclick="deleteGift(${g.id})">&#128465;</button>
    </div>
    <input class="gift-field" type="text" value="${esc(g.description)}" placeholder="Opis prezentu…" onchange="updateGift(${g.id},'description',this.value)">
    <div class="gift-footer">
      <div class="gift-val-wrap">
        <input class="gift-val" type="number" value="${g.value||''}" min="0" placeholder="Wartość" onchange="updateGift(${g.id},'value',parseFloat(this.value)||null)">
        <span class="currency-sm">zł</span>
      </div>
      <label class="gift-thank">
        <input type="checkbox" ${g.thanked?'checked':''} onchange="updateGift(${g.id},'thanked',this.checked)">
        &#10003; Podziękowano
      </label>
    </div>
  </div>`).join('')+'</div>';
}

// ── UPOMINKI DLA GOŚCI ──
const GIFT_GUEST_CATS = [
  { key:'guests',     label:'Goście',      icon:'🎁' },
  { key:'witnesses',  label:'Świadkowie',  icon:'🤝' },
  { key:'parents',    label:'Rodzice',     icon:'👪' },
  { key:'distinction',label:'Wyróżnienie', icon:'⭐' },
];
function addGiftForGuest(catKey) {
  giftsForGuests.push({ id: nextGiftForId++, category: catKey, name:'', qty:1, cost:0, guestIds:[] });
  renderGiftsForGuests(); saveState();
}
function updateGiftForGuest(id, field, value) {
  const it = giftsForGuests.find(x => x.id === id); if (!it) return;
  it[field] = (field === 'qty' || field === 'cost') ? (parseFloat(value) || 0) : value;
  renderGiftsForGuests(); saveState();
}
function deleteGiftForGuest(id) {
  giftsForGuests = giftsForGuests.filter(x => x.id !== id);
  renderGiftsForGuests(); saveState();
}
function addDistinctionGuest(id, guestId) {
  const it = giftsForGuests.find(x => x.id === id); if (!it || !guestId) return;
  const gid = parseInt(guestId);
  if (!it.guestIds.includes(gid)) it.guestIds.push(gid);
  renderGiftsForGuests(); saveState();
}
function removeDistinctionGuest(id, guestId) {
  const it = giftsForGuests.find(x => x.id === id); if (!it) return;
  it.guestIds = it.guestIds.filter(g => g !== parseInt(guestId));
  renderGiftsForGuests(); saveState();
}
// Przeliczanie upominków na liczbę osób (rzeczywiści / rzeczywiści + wirtualni)
function setGiftForGuestsBasis(which, checked) {
  giftForGuestsBasis = checked ? which : (giftForGuestsBasis === which ? '' : giftForGuestsBasis);
  renderGiftsForGuests(); saveState();
}
function renderGiftsForGuests() {
  const c = document.getElementById('giftsForGuestsList'); if (!c) return;
  const sum = document.getElementById('giftsForGuestsSummary');
  const basis = giftForGuestsBasis;
  const personCount = basis === 'real' ? guests.length
                    : basis === 'realvirtual' ? guests.length + getVirtualGuests()
                    : 0;
  // ilość użyta do obliczeń: gdy włączono przeliczanie — liczba osób, inaczej ręczna ilość
  const effQty = it => basis ? personCount : (it.qty || 0);

  const calcCtrl = `<div class="gforg-calc">
    <label class="gforg-calc-opt"><input type="checkbox" ${basis === 'real' ? 'checked' : ''} onchange="setGiftForGuestsBasis('real', this.checked)"> Przelicz na gości rzeczywistych${basis === 'real' ? ` (${personCount} os.)` : ''}</label>
    <label class="gforg-calc-opt"><input type="checkbox" ${basis === 'realvirtual' ? 'checked' : ''} onchange="setGiftForGuestsBasis('realvirtual', this.checked)"> Przelicz na rzeczywistych + wirtualnych${basis === 'realvirtual' ? ` (${personCount} os.)` : ''}</label>
  </div>`;

  let grand = 0, count = 0;
  const cats = GIFT_GUEST_CATS.map(cat => {
    const items = giftsForGuests.filter(it => it.category === cat.key);
    const catTotal = items.reduce((s, it) => s + effQty(it) * (it.cost || 0), 0);
    grand += catTotal; count += items.length;
    const rows = items.map(it => {
      const lineTotal = effQty(it) * (it.cost || 0);
      const distinctionUI = cat.key === 'distinction' ? `
        <div class="gforg-distinction">
          <div class="gforg-chips">
            ${(it.guestIds || []).map(gid => { const g = guests.find(x => x.id === gid); return g ? `<span class="gforg-chip">${esc(fullName(g) || 'Gość')}<button onclick="removeDistinctionGuest(${it.id},${gid})" title="Usuń">✕</button></span>` : ''; }).join('') || '<span class="gforg-chip-empty">Brak wybranych osób</span>'}
          </div>
          <select class="gforg-guestsel" onchange="if(this.value){addDistinctionGuest(${it.id},this.value);this.value='';}">
            <option value="">+ Dodaj osobę…</option>
            ${guests.map(g => `<option value="${g.id}">${esc(fullName(g) || 'Gość')}</option>`).join('')}
          </select>
        </div>` : '';
      return `<div class="gforg-item">
        <input class="gforg-name" type="text" value="${esc(it.name)}" placeholder="Upominek…" onchange="updateGiftForGuest(${it.id},'name',this.value)">
        <input class="gforg-qty" type="number" min="0" value="${it.qty||0}" title="Ilość" ${basis ? 'disabled' : ''} onchange="updateGiftForGuest(${it.id},'qty',this.value)">
        <span class="gforg-x">×</span>
        <input class="gforg-cost" type="number" min="0" value="${it.cost||0}" title="Koszt/szt. (zł)" onchange="updateGiftForGuest(${it.id},'cost',this.value)">
        <span class="gforg-eq">${basis ? `= ${effQty(it)} × ${fmt(it.cost||0)} = ` : '= '}${fmt(lineTotal)} zł</span>
        <button class="btn-row-del" onclick="deleteGiftForGuest(${it.id})" title="Usuń">&#128465;</button>
        ${distinctionUI}
      </div>`;
    }).join('') || '<div class="gforg-empty">Brak upominków w tej kategorii.</div>';
    return `<div class="gforg-cat">
      <div class="gforg-cat-hdr">
        <span class="gforg-cat-title">${cat.icon} ${cat.label}</span>
        <span class="gforg-cat-total">${fmt(catTotal)} zł</span>
        <button class="btn btn-sm btn-primary" onclick="addGiftForGuest('${cat.key}')">+ Upominek</button>
      </div>
      <div class="gforg-list">${rows}</div>
    </div>`;
  }).join('');
  c.innerHTML = calcCtrl + cats;
  if (sum) sum.innerHTML = `<div class="sum-stat"><span class="sv">${count}</span><span>Upominków</span></div>
    <div class="sum-stat"><span class="sv">${fmt(grand)} zł</span><span>Łączny koszt${basis ? ` (${personCount} os.)` : ''}</span></div>`;
}

// ── PROPOZYCJE / LISTA ŻYCZEŃ ──
function addGiftProposal() {
  giftProposals.push({ id: nextProposalId++, title:'', desc:'', link:'', showToGuests:false });
  renderGiftProposals(); saveState();
}
function updateGiftProposal(id, field, value) {
  const p = giftProposals.find(x => x.id === id); if (!p) return;
  p[field] = value;
  saveState();
}
function deleteGiftProposal(id) {
  giftProposals = giftProposals.filter(x => x.id !== id);
  renderGiftProposals(); saveState();
}
function toggleGiftProposalVisibility(id, checked) {
  const p = giftProposals.find(x => x.id === id); if (!p) return;
  p.showToGuests = !!checked;
  saveState();
}
function renderGiftProposals() {
  const c = document.getElementById('giftProposalsList'); if (!c) return;
  if (!giftProposals.length) { c.innerHTML = '<div class="empty-list">Brak propozycji. Kliknij „+ Dodaj propozycję".</div>'; return; }
  c.innerHTML = '<div class="gprop-list">' + giftProposals.map(p => `
    <div class="gprop-card${p.showToGuests ? ' gprop-public' : ''}">
      <input class="gprop-title" type="text" value="${esc(p.title)}" placeholder="Tytuł propozycji…" onchange="updateGiftProposal(${p.id},'title',this.value)">
      <textarea class="gprop-desc" placeholder="Opis (np. Zamiast kwiatów prosimy o wpłatę na podróż)…" onchange="updateGiftProposal(${p.id},'desc',this.value)">${esc(p.desc)}</textarea>
      <input class="gprop-link" type="url" value="${esc(p.link || '')}" placeholder="🔗 Link (opcjonalnie)…" onchange="updateGiftProposal(${p.id},'link',this.value)">
      <label class="gprop-visible"><input type="checkbox" ${p.showToGuests ? 'checked' : ''} onchange="toggleGiftProposalVisibility(${p.id},this.checked)"> &#128065; Pokaż tę propozycję gościom</label>
      <button class="btn-row-del gprop-del" onclick="deleteGiftProposal(${p.id})" title="Usuń">&#128465;</button>
    </div>`).join('') + '</div>';
}

// ── TRANSPORT ──
const VEHICLE_TYPES=['Auto wynajęte','Auto własne','Auto rodziców Pana Młodego','Auto rodziców Panny Młodej','Bus','Taxi/Uber','Inne'];
function addVehicle() {
  vehicles.push({id:nextVehicleId++,type:'Auto własne',description:'',driver:'',seats:4,route:'',departureTime:'',guestIds:[],cost:0});
  renderTransport(); saveState();
}
function updateVehicle(id,field,value) {
  const v=vehicles.find(x=>x.id===id); if(!v) return;
  v[field]=field==='seats'?(parseInt(value)||1):value;
  renderTransport(); saveState();
}
function deleteVehicle(id) {
  const v=vehicles.find(x=>x.id===id);
  if(v)(v.guestIds||[]).forEach(gId=>{const g=guests.find(x=>x.id===gId);if(g)g.vehicleId=null;});
  vehicles=vehicles.filter(x=>x.id!==id); renderTransport(); saveState();
}
function assignGuestToVehicle(guestId,vehicleId) {
  vehicles.forEach(v=>{v.guestIds=(v.guestIds||[]).filter(id=>id!==guestId);});
  const g=guests.find(x=>x.id===guestId); if(g){ g.vehicleId=vehicleId||null; if(vehicleId) g.ownTransport=false; }
  if(vehicleId){const v=vehicles.find(x=>x.id===vehicleId);if(v)v.guestIds=[...(v.guestIds||[]),guestId];}
  renderTransport(); saveState();
}
// Transport własny gościa
function setGuestOwnTransport(guestId, on) {
  const g = guests.find(x => x.id === guestId); if (!g) return;
  if (on) { // usuń z pojazdów
    vehicles.forEach(v => { v.guestIds = (v.guestIds || []).filter(id => id !== guestId); });
    g.vehicleId = null;
  }
  g.ownTransport = !!on;
  renderTransport(); saveState();
}
function toggleTransportShowOwn() {
  transportShowOwn = !transportShowOwn;
  renderTransport();
}
// ── Transport wewnętrzny (Bolt/Taxi/inne) ──
function addInternalTransport() {
  internalTransport.push({ id: nextInternalTransportId++, type: 'Bolt', info: '', showToGuests: true });
  renderTransport(); saveState();
}
function updateInternalTransport(id, field, value) {
  const it = internalTransport.find(x => x.id === id); if (!it) return;
  it[field] = value;
  saveState();
  if (field !== 'info') renderTransport();
}
function deleteInternalTransport(id) {
  internalTransport = internalTransport.filter(x => x.id !== id);
  renderTransport(); saveState();
}
function saveTransportNotes() {
  transportNotes.weddingCar=document.getElementById('weddingCarNote')?.value||'';
  transportNotes.parking=document.getElementById('parkingNote')?.value||'';
  saveState();
}
function renderTransport() {
  const c=document.getElementById('vehiclesList'); if(!c) return;
  const assigned=new Set(vehicles.flatMap(v=>v.guestIds||[]));
  const ownGuests = guests.filter(g => g.ownTransport && !assigned.has(g.id));
  const ownSet = new Set(ownGuests.map(g => g.id));
  const unassigned=guests.filter(g=>!assigned.has(g.id) && !ownSet.has(g.id));

  // ── Pasek podziału transportu (ikony) ──
  const typeCounts = {};
  vehicles.forEach(v => {
    const n = (v.guestIds || []).length;
    typeCounts[v.type] = (typeCounts[v.type] || 0) + n;
  });
  const typeIcon = ty => {
    const s = (ty || '').toLowerCase();
    if (s.includes('bus')) return '🚐';
    if (s.includes('taxi') || s.includes('uber')) return '🚖';
    if (s.includes('wynaj')) return '🚗';
    if (s.includes('rodzic')) return '👪';
    return '🚙';
  };
  const chips = [];
  chips.push(`<span class="t-split-chip" title="Transport własny">🚶 Własny: <b>${ownGuests.length}</b></span>`);
  Object.keys(typeCounts).forEach(ty => {
    if (typeCounts[ty] > 0) chips.push(`<span class="t-split-chip">${typeIcon(ty)} ${esc(ty)}: <b>${typeCounts[ty]}</b></span>`);
  });
  chips.push(`<span class="t-split-chip t-split-none" title="Bez transportu">❓ Bez transportu: <b>${unassigned.length}</b></span>`);
  let html = `<div class="transport-split-bar">${chips.join('')}
    <label class="t-own-toggle"><input type="checkbox" ${transportShowOwn?'checked':''} onchange="toggleTransportShowOwn()"> Pokaż transport własny</label>
  </div>`;

  html+=`<div class="transport-section-hdr">Goście bez transportu (${unassigned.length})</div>`;
  if(unassigned.length){
    const vOpts=vehicles.map(v=>`<option value="${v.id}">${esc(v.description||v.type)}</option>`).join('');
    html+='<div class="transport-unassigned">'+unassigned.map(g=>`<div class="t-guest-chip">
      ${esc(fullName(g))}
      <select class="t-assign" onchange="var val=this.value; if(val==='own'){setGuestOwnTransport(${g.id},true);} else if(val){assignGuestToVehicle(${g.id},parseInt(val));}">
        <option value="">Przypisz…</option>
        <option value="own">🚶 Transport własny</option>
        ${vOpts}
      </select>
    </div>`).join('')+'</div>';
  } else { html+='<div class="transport-ok">Wszyscy goście mają transport ✓</div>'; }

  // ── Transport własny (z filtrem) ──
  if (transportShowOwn && ownGuests.length) {
    html += `<div class="transport-section-hdr" style="margin-top:16px">🚶 Transport własny (${ownGuests.length})</div>`;
    html += '<div class="transport-unassigned">' + ownGuests.map(g => `<span class="t-guest-chip t-own-chip">
      ${esc(fullName(g))}
      <button class="vp-rm" title="Cofnij" onclick="setGuestOwnTransport(${g.id},false)">✕</button>
    </span>`).join('') + '</div>';
  }

  html+=`<div class="transport-section-hdr" style="margin-top:16px">Pojazdy (${vehicles.length})</div>`;
  if(!vehicles.length){html+='<div class="empty-list">Brak pojazdów.</div>';}
  else html+='<div class="vehicles-grid">'+vehicles.map(v=>{
    const passengers=(v.guestIds||[]).map(id=>guests.find(g=>g.id===id)).filter(Boolean);
    const free=v.seats-passengers.length;
    const datalistId=`vtypes-${v.id}`;
    const typeDatalist=`<datalist id="${datalistId}">${VEHICLE_TYPES.map(t=>`<option value="${t}">`).join('')}</datalist>`;
    return `<div class="vehicle-card">
      <div class="vehicle-hdr">
        ${typeDatalist}
        <input class="vehicle-type-inp" type="text" list="${datalistId}" value="${esc(v.type)}" placeholder="Typ pojazdu…" onchange="updateVehicle(${v.id},'type',this.value)">
        <span class="vehicle-seats-badge${free===0?' badge-full':''}">${passengers.length}/${v.seats}</span>
        <button class="btn-row-edit" onclick="openEditModal('vehicle',${v.id})" title="Edytuj">&#9998;</button>
        <button class="btn-row-del" onclick="deleteVehicle(${v.id})">&#128465;</button>
      </div>
      <input class="v-field" type="text" value="${esc(v.description)}" placeholder="Opis pojazdu…" onchange="updateVehicle(${v.id},'description',this.value)">
      <div class="v-row">
        <input class="v-field" type="text" value="${esc(v.driver)}" placeholder="Kierowca…" onchange="updateVehicle(${v.id},'driver',this.value)">
        <input class="v-field" type="text" value="${esc(v.route)}" placeholder="Trasa…" onchange="updateVehicle(${v.id},'route',this.value)">
      </div>
      <div class="v-row">
        <label>Odjazd:</label>
        <input type="time" value="${esc(v.departureTime)}" onchange="updateVehicle(${v.id},'departureTime',this.value)">
        <label>Miejsc:</label>
        <input type="number" class="v-seats-n" value="${v.seats}" min="1" max="60" onchange="updateVehicle(${v.id},'seats',this.value)">
      </div>
      <div class="v-passengers">
        <div class="vp-hdr">${passengers.length}/${v.seats} pasażerów${free===0?' — PEŁNY':''}:</div>
        ${passengers.map(g=>`<span class="vp-chip">${esc(fullName(g))}<button class="vp-rm" onclick="assignGuestToVehicle(${g.id},null)">✕</button></span>`).join('')}
      </div>
    </div>`;
  }).join('')+'</div>';

  // ── Transport wewnętrzny (Bolt/Taxi/inne) — może pojawić się w harmonogramie dla gości ──
  html += `<div class="transport-section-hdr" style="margin-top:16px">🚖 Transport wewnętrzny
    <button class="btn btn-primary btn-sm" style="margin-left:auto" onclick="addInternalTransport()">+ Dodaj</button></div>`;
  if (!internalTransport.length) {
    html += '<div class="empty-list">Brak. Dodaj np. Bolt / Taxi i informację jak się dostać.</div>';
  } else {
    const typeOpts = it => INTERNAL_TRANSPORT_TYPES.map(t => `<option value="${t}"${it.type===t?' selected':''}>${t}</option>`).join('');
    html += '<div class="internal-transport-list">' + internalTransport.map(it => `
      <div class="it-card">
        <div class="it-row">
          <select class="it-type" onchange="updateInternalTransport(${it.id},'type',this.value)">${typeOpts(it)}</select>
          <label class="it-show"><input type="checkbox" ${it.showToGuests?'checked':''} onchange="updateInternalTransport(${it.id},'showToGuests',this.checked)"> Pokaż gościom</label>
          <button class="btn-row-del" onclick="deleteInternalTransport(${it.id})">&#128465;</button>
        </div>
        <textarea class="it-info" placeholder="Jak się dostać? np. zamów Bolta na adres sali, kod rabatowy…" onchange="updateInternalTransport(${it.id},'info',this.value)">${esc(it.info||'')}</textarea>
      </div>`).join('') + '</div>';
  }

  c.innerHTML=html;
  setTimeout(initMobileCollapse, 0);
}

// ── ACCOMMODATION ──
function addHotel() {
  const modal  = document.getElementById('editModal');
  const titleEl= document.getElementById('editModalTitle');
  const bodyEl = document.getElementById('editModalBody');
  if (!modal || !bodyEl) return;
  editState = { type: 'hotel-new', id: null };
  const blank = { name: '', address: '', phone: '', pricePerNight: 0, personsPerRoom: 2, bookingLink: '', notes: '', inComplex: false };
  if (titleEl) titleEl.textContent = 'Dodaj hotel';
  bodyEl.innerHTML = _hotelForm(blank);
  modal.style.display = 'flex';
}
function updateHotel(id,field,value) {
  const h=hotels.find(x=>x.id===id); if(!h) return;
  const numFields=['pricePerNight','personsPerRoom'];
  h[field] = numFields.includes(field) ? (parseFloat(value)||0) : value;
  renderAccommodation(); saveState();
}
function deleteHotel(id) {
  hotels=hotels.filter(x=>x.id!==id);
  guests.forEach(g=>{if(g.hotelId===id){g.hotelId=null;g.accommodationStatus=null;}});
  renderAccommodation(); saveState();
}
function updateGuestAccommodation(gId,field,value) {
  const g=guests.find(x=>x.id===gId); if(g){g[field]=value||null;renderAccommodation();saveState();}
}
function renderAccommodation() {
  const sum=document.getElementById('accomSummary');
  const c=document.getElementById('hotelsList'); if(!c) return;
  const needs=guests.filter(g=>g.needsAccommodation);
  const reserved=needs.filter(g=>g.accommodationStatus==='reserved');
  if(sum) sum.innerHTML=`
    <div class="sum-stat"><span class="sv">${needs.length}</span><span>Potrzebuje noclegu</span></div>
    <div class="sum-stat"><span class="sv">${reserved.length}</span><span>Zarezerwowane</span></div>
    <div class="sum-stat"><span class="sv">${needs.length-reserved.length}</span><span>Do zarezerwowania</span></div>`;
  let html='<div class="accom-section-hdr">Goście potrzebujący noclegu</div>';
  const stOpts=(cur)=>[{v:'reserved',l:'Zarezerwowany'},{v:'pending',l:'Do zarezerwowania'},{v:'self',l:'Sam rezerwuje'}]
    .map(s=>`<option value="${s.v}"${cur===s.v?' selected':''}>${s.l}</option>`).join('');
  const hOpts=hotels.filter(h=>h.name).map(h=>`<option value="${h.id}">${esc(h.name)}</option>`).join('');
  html+=needs.map(g=>`<div class="accom-guest-row">
    ${avatarHtml(g,'avatar-sm')}
    <span class="accom-gname">${esc(fullName(g))}</span>
    <select class="accom-hotel-sel" onchange="updateGuestAccommodation(${g.id},'hotelId',this.value?parseInt(this.value):null)">
      <option value="">Brak hotelu</option>${hOpts.replace(`value="${g.hotelId}"`,`value="${g.hotelId}" selected`)}
    </select>
    <select class="accom-status-sel" onchange="updateGuestAccommodation(${g.id},'accommodationStatus',this.value)">
      <option value="">Status…</option>${stOpts(g.accommodationStatus)}
    </select>
  </div>`).join('')||'<div class="empty-list">Brak gości z zaznaczonym noclegu.<br><small>Zaznacz "Nocleg" przy gościu w sekcji Stoły i goście.</small></div>';
  html+='<div class="accom-section-hdr" style="margin-top:20px">Hotele i miejsca noclegowe</div>';
  if(!hotels.length){html+='<div class="empty-list">Brak hoteli.</div>';}
  else html+='<div class="hotels-grid">'+hotels.map(h=>{
    const gc=guests.filter(g=>g.hotelId===h.id).length;
    return `<div class="hotel-card">
      <div class="hotel-hdr">
        <input class="hotel-field" type="text" value="${esc(h.name)}" placeholder="Nazwa hotelu" onchange="updateHotel(${h.id},'name',this.value)">
        ${h.inComplex ? `<span class="hotel-complex-badge" title="Hotel w kompleksie wesela">🏨 Kompleks</span>` : ''}
        <span class="hotel-guests-badge">${gc} gości</span>
        <button class="btn-row-edit" onclick="openEditModal('hotel',${h.id})" title="Edytuj">&#9998;</button>
        <button class="btn-row-del" onclick="deleteHotel(${h.id})">&#128465;</button>
      </div>
      <label class="hotel-complex-toggle"><input type="checkbox" ${h.inComplex?'checked':''} onchange="updateHotel(${h.id},'inComplex',this.checked)"> 🏨 Hotel w kompleksie wesela</label>
      <input class="hotel-field" type="text" value="${esc(h.address)}" placeholder="Adres" onchange="updateHotel(${h.id},'address',this.value)">
      <div class="h-row">
        ${h.phone?`<a href="tel:${esc(h.phone)}" class="hotel-phone-link">&#128222; ${esc(h.phone)}</a>`:''}
        <input class="hotel-field" type="tel" value="${esc(h.phone)}" placeholder="Telefon" onchange="updateHotel(${h.id},'phone',this.value)">
      </div>
      <div class="h-row h-price-row">
        <label class="h-lbl">Cena/os/noc:</label>
        <input class="hotel-price" type="number" value="${h.pricePerNight||0}" min="0" onchange="updateHotel(${h.id},'pricePerNight',parseFloat(this.value)||0)">
        <span class="currency-sm">zł</span>
        <span class="h-times">×</span>
        <input class="hotel-persons" type="number" value="${h.personsPerRoom||1}" min="1" max="20" onchange="updateHotel(${h.id},'personsPerRoom',parseInt(this.value)||1)">
        <span class="h-lbl-sm">os.</span>
        <span class="h-eq">=</span>
        <strong class="h-total">${((h.pricePerNight||0)*(h.personsPerRoom||1)).toLocaleString('pl-PL')} zł/noc</strong>
      </div>
      <input class="hotel-field" type="url" value="${esc(h.bookingLink)}" placeholder="Link rezerwacji" onchange="updateHotel(${h.id},'bookingLink',this.value)">
      <textarea class="hotel-notes" placeholder="Notatki…" onchange="updateHotel(${h.id},'notes',this.value)">${esc(h.notes)}</textarea>
    </div>`;
  }).join('')+'</div>';
  c.innerHTML=html;
  setTimeout(initMobileCollapse, 0);
}

// ── PAYMENTS ──
function addPayment() {
  payments.push({id:nextPaymentId++,name:'Nowa płatność',totalAmount:0,estimatedAmount:0,installments:[]});
  renderPayments(); saveState();
}
function updatePayment(id,field,value) {
  const p=payments.find(x=>x.id===id);
  const numFields=['totalAmount','estimatedAmount'];
  if(p){p[field]=numFields.includes(field)?(parseFloat(value)||0):value; renderPayments(); saveState();}
}
function addInstallment(paymentId) {
  const p=payments.find(x=>x.id===paymentId); if(!p) return;
  p.installments.push({id:nextInstallmentId++,amount:0,dueDate:'',paidBy:'both',status:'pending'});
  renderPayments(); saveState();
}
function updateInstallment(pId,iId,field,value) {
  const p=payments.find(x=>x.id===pId); if(!p) return;
  const inst=p.installments.find(i=>i.id===iId); if(!inst) return;
  inst[field]=field==='amount'?(parseFloat(value)||0):value;
  renderPayments(); saveState();
}
function deleteInstallment(pId,iId) {
  const p=payments.find(x=>x.id===pId); if(p){p.installments=p.installments.filter(i=>i.id!==iId);renderPayments();saveState();}
}
function deletePayment(id) { payments=payments.filter(x=>x.id!==id); renderPayments(); saveState(); }
function isInstallmentDueSoon(dueDate) {
  if(!dueDate) return false;
  const diff=(new Date(dueDate)-new Date())/86400000;
  return diff>=0&&diff<=7;
}
function isInstallmentOverdue(dueDate,status) {
  return dueDate&&status!=='paid'&&new Date(dueDate)<new Date();
}
// ── PAYMENTS UNIFIED ──

function setPayFilter(src) {
  paymentsSourceFilter = src;
  renderPayments();
}

function _payEffective(confirmed, estimated) {
  return (confirmed || 0) > 0 ? (confirmed || 0) : (estimated || 0);
}

function buildPaymentItems() {
  const items = [];

  // SALA — payments[]
  payments.forEach(p => {
    const paidSum = p.installments.filter(i => i.status === 'paid').reduce((s, i) => s + i.amount, 0);
    const confirmed = p.totalAmount || 0, estimated = p.estimatedAmount || 0;
    const effective = _payEffective(confirmed, estimated);
    const isPredicted = confirmed === 0 && estimated > 0;
    items.push({
      source: 'sala', type: 'vendor', id: p.id, name: p.name,
      confirmed, estimated, effective, isPredicted,
      paid: paidSum, remaining: Math.max(0, effective - paidSum),
      overdue: p.installments.some(i => isInstallmentOverdue(i.dueDate, i.status)),
      soon:    p.installments.some(i => i.status !== 'paid' && isInstallmentDueSoon(i.dueDate)),
      data: p,
    });
  });

  // WYDATKI — expenses[]
  budgetData.expenses.forEach(e => {
    const confirmed = e.planned || 0, estimated = e.estimatedAmount || 0;
    const effective = _payEffective(confirmed, estimated);
    const isPredicted = confirmed === 0 && estimated > 0;
    const dd = e.paymentDate || '';
    items.push({
      source: 'expenses', type: 'expense', id: e.id,
      name: (e.category === 'Inne' && e.customName) ? e.customName : e.category,
      confirmed, estimated, effective, isPredicted,
      paid: e.paid || 0, remaining: Math.max(0, effective - (e.paid || 0)),
      dueDate: dd,
      overdue: dd && (e.paid || 0) < effective && new Date(dd) < new Date(),
      soon:    dd && (e.paid || 0) < effective && isInstallmentDueSoon(dd),
      data: e,
    });
  });

  // PODRÓŻ POŚLUBNA
  const h = budgetData.honeymoon || {};
  const hInsts = h.installments || [];
  if (h.totalAmount > 0 || (h.estimatedAmount || 0) > 0 || hInsts.length > 0) {
    const paidSum = hInsts.filter(i => i.status === 'paid').reduce((s, i) => s + i.amount, 0);
    const confirmed = h.totalAmount || 0, estimated = h.estimatedAmount || 0;
    const effective = _payEffective(confirmed, estimated);
    const isPredicted = confirmed === 0 && estimated > 0;
    items.push({
      source: 'honeymoon', type: 'honeymoon', id: 'honeymoon',
      name: h.name || 'Podróż poślubna',
      confirmed, estimated, effective, isPredicted,
      paid: paidSum, remaining: Math.max(0, effective - paidSum),
      overdue: hInsts.some(i => isInstallmentOverdue(i.dueDate, i.status)),
      soon:    hInsts.some(i => i.status !== 'paid' && isInstallmentDueSoon(i.dueDate)),
      data: h,
    });
  }

  return items;
}

function _instRows(insts, vendorId, updateFn, deleteFn) {
  const rLabels = { groom: 'Pan Młody', bride: 'Panna Młoda', both: 'Oboje' };
  return insts.map(inst => {
    const overdue = isInstallmentOverdue(inst.dueDate, inst.status);
    const soon    = inst.status !== 'paid' && isInstallmentDueSoon(inst.dueDate);
    const cls     = inst.status === 'paid' ? 'inst-paid' : overdue ? 'inst-overdue' : soon ? 'inst-soon' : 'inst-pending';
    const stOpts  = ['paid','pending'].map(s => `<option value="${s}"${inst.status===s?' selected':''}>${s==='paid'?'✓ Zapłacona':'○ Do zapłaty'}</option>`).join('');
    const pbOpts  = Object.entries(rLabels).map(([v,l]) => `<option value="${v}"${inst.paidBy===v?' selected':''}>${l}</option>`).join('');
    return `<div class="installment-row ${cls}">
      <div class="inst-body">
        <input class="inst-amount" type="number" value="${inst.amount}" min="0" onchange="${updateFn}(${vendorId},${inst.id},'amount',this.value)">
        <span class="currency-sm">zł</span>
        <input type="date" class="inst-date" value="${esc(inst.dueDate)}" onchange="${updateFn}(${vendorId},${inst.id},'dueDate',this.value)">
        <select class="inst-sel" onchange="${updateFn}(${vendorId},${inst.id},'paidBy',this.value)">${pbOpts}</select>
        <select class="inst-sel" onchange="${updateFn}(${vendorId},${inst.id},'status',this.value)">${stOpts}</select>
        ${soon   ? '<span class="inst-soon-badge">wkrótce!</span>'   : ''}
        ${overdue ? '<span class="inst-overdue-badge">zaległa!</span>' : ''}
      </div>
      <button class="btn-row-del" onclick="${deleteFn}(${vendorId},${inst.id})">&#10005;</button>
    </div>`;
  }).join('');
}

function _progBar(paid, effective, color, isPredicted) {
  if (!effective) return '';
  const pct = Math.min(100, paid / effective * 100);
  return `<div class="payment-progress">
    <div class="pp-bg"><div class="pp-fill" style="width:${pct}%;background:${color}"></div></div>
    <span class="pp-lbl">${fmt(paid)} / ${isPredicted ? '~&thinsp;' : ''}${fmt(effective)} z&#322;</span>
  </div>`;
}

function _amtFields(confirmedVal, confirmedOnChange, estimatedVal, estimatedOnChange) {
  return `<div class="uni-amounts-row">
    <div class="uni-amt-col">
      <label>Kwota ostateczna</label>
      <div class="exp-input-wrap">
        <input type="number" class="uni-amt-input" value="${confirmedVal||''}" min="0" placeholder="—" onchange="${confirmedOnChange}">
        <span class="currency-sm">z&#322;</span>
      </div>
    </div>
    <div class="uni-amt-col uni-est-col">
      <label><span class="uni-tilde">~</span> Kwota planowana</label>
      <div class="exp-input-wrap">
        <input type="number" class="uni-amt-input" value="${estimatedVal||''}" min="0" placeholder="—" onchange="${estimatedOnChange}">
        <span class="currency-sm">z&#322;</span>
      </div>
    </div>
  </div>`;
}

function renderUnifiedPaymentCard(item) {
  const src = PAY_SOURCES[item.source];
  const srcBadge = `<span class="uni-src-badge" style="background:${src.light};color:${src.color};border-color:${src.color}">${src.icon} ${src.label}</span>`;
  const predBadge = item.isPredicted ? '<span class="uni-pred-badge">~ planowane</span>' : '';
  const cardCls = `uni-pay-card${item.isPredicted ? ' uni-predicted' : ''}${item.overdue ? ' uni-overdue' : ''}`;

  if (item.type === 'vendor') {
    const p = item.data;
    return `<div class="${cardCls}" style="--src-color:${src.color}">
      <div class="uni-card-hdr">
        ${srcBadge}
        <input class="payment-name uni-pay-name" type="text" value="${esc(p.name)}" onchange="updatePayment(${p.id},'name',this.value)">
        ${predBadge}
        <button class="btn-row-edit" onclick="openEditModal('payment',${p.id})" title="Edytuj">&#9998;</button>
        <button class="btn-row-del" onclick="deletePayment(${p.id})">&#128465;</button>
      </div>
      ${_amtFields(p.totalAmount, `updatePayment(${p.id},'totalAmount',parseFloat(this.value)||0)`,
                   p.estimatedAmount, `updatePayment(${p.id},'estimatedAmount',parseFloat(this.value)||0)`)}
      ${_progBar(item.paid, item.effective, src.color, item.isPredicted)}
      <div class="installments-list">${_instRows(p.installments, p.id, 'updateInstallment', 'deleteInstallment')}</div>
      <button class="btn btn-sm btn-outline" style="margin-top:8px" onclick="addInstallment(${p.id})">+ Dodaj rat&#281;</button>
    </div>`;
  }

  if (item.type === 'expense') {
    const e = item.data;
    const cfg = EXPENSE_CATEGORIES.find(c => c.name === e.category);
    return `<div class="${cardCls}" style="--src-color:${src.color}">
      <div class="uni-card-hdr">
        ${srcBadge}
        <span class="uni-pay-name">${cfg?.icon||''} ${esc(item.name)}</span>
        ${predBadge}
      </div>
      ${_amtFields(e.planned,          `updateExpense(${e.id},'planned',parseFloat(this.value)||0)`,
                   e.estimatedAmount,  `updateExpense(${e.id},'estimatedAmount',parseFloat(this.value)||0)`)}
      <div class="uni-amounts-row">
        <div class="uni-amt-col">
          <label>Opłacono</label>
          <div class="exp-input-wrap">
            <input type="number" class="uni-amt-input" value="${e.paid||''}" min="0" placeholder="—" onchange="updateExpense(${e.id},'paid',parseFloat(this.value)||0)">
            <span class="currency-sm">z&#322;</span>
          </div>
        </div>
        <div class="uni-amt-col">
          <label>Termin p&#322;atności</label>
          <input type="date" class="inst-date" value="${esc(e.paymentDate||'')}" onchange="updateExpense(${e.id},'paymentDate',this.value)">
        </div>
      </div>
      ${_progBar(item.paid, item.effective, src.color, item.isPredicted)}
    </div>`;
  }

  if (item.type === 'honeymoon') {
    const h = item.data;
    const instHtml = _instRows(h.installments || [], 0, 'updateHoneymoonInst', 'deleteHoneymoonInst');
    return `<div class="${cardCls}" style="--src-color:${src.color}">
      <div class="uni-card-hdr">
        ${srcBadge}
        <span class="uni-pay-name">${esc(h.name || 'Podróż poślubna')}</span>
        ${predBadge}
      </div>
      ${_amtFields(h.totalAmount,      `updateHoneymoon('totalAmount',parseFloat(this.value)||0)`,
                   h.estimatedAmount,  `updateHoneymoon('estimatedAmount',parseFloat(this.value)||0)`)}
      ${_progBar(item.paid, item.effective, src.color, item.isPredicted)}
      <div class="installments-list">${instHtml}</div>
      <button class="btn btn-sm btn-outline" style="margin-top:8px" onclick="addHoneymoonInst()">+ Dodaj rat&#281;</button>
    </div>`;
  }
  return '';
}

function renderPayments() {
  const alertsEl = document.getElementById('paymentAlerts');
  const c = document.getElementById('paymentsList');
  if (!c) return;

  const allItems = buildPaymentItems();
  const filtered = paymentsSourceFilter === 'all' ? allItems : allItems.filter(i => i.source === paymentsSourceFilter);

  // Alerty
  const overdueItems = filtered.filter(i => i.overdue);
  const soonItems    = filtered.filter(i => i.soon && !i.overdue);
  if (alertsEl) {
    let al = '';
    if (overdueItems.length) al += `<div class="pay-alert pay-alert-overdue">&#128680; Zaległe: ${overdueItems.length} płatności (${fmt(overdueItems.reduce((s,i)=>s+i.remaining,0))} zł)</div>`;
    if (soonItems.length)    al += `<div class="pay-alert pay-alert-soon">&#9200; Wkrótce: ${soonItems.length} płatności w ciągu 7 dni</div>`;
    alertsEl.innerHTML = al;
  }

  // Sumy
  const confirmedSum = filtered.reduce((s, i) => s + (i.isPredicted ? 0 : i.effective), 0);
  const predictedSum = filtered.reduce((s, i) => s + (i.isPredicted ? i.effective : 0), 0);
  const paidSum      = filtered.reduce((s, i) => s + i.paid, 0);
  const remSum       = Math.max(0, confirmedSum + predictedSum - paidSum);

  // Pasek filtrów
  const filterHtml = `<div class="pay-filter-bar">
    <button class="pay-fbtn ${paymentsSourceFilter==='all'?'pf-active':''}" onclick="setPayFilter('all')">Wszystkie (${allItems.length})</button>
    ${Object.entries(PAY_SOURCES).map(([src, cfg]) => {
      const cnt = allItems.filter(i => i.source === src).length;
      return `<button class="pay-fbtn pf-${src} ${paymentsSourceFilter===src?'pf-active':''}" onclick="setPayFilter('${src}')">${cfg.icon} ${cfg.label} (${cnt})</button>`;
    }).join('')}
    <button class="btn btn-sm btn-outline pf-add" onclick="addPayment()" style="margin-left:auto">+ Sala</button>
  </div>`;

  // Podsumowanie
  const summaryHtml = `<div class="pay-summary-bar">
    <div class="psb-item">
      <span class="psb-val psb-confirmed">&#10003; ${fmt(confirmedSum)} zł</span>
      <span class="psb-lbl">Potwierdzone</span>
    </div>
    <span class="psb-op">+</span>
    <div class="psb-item">
      <span class="psb-val psb-predicted">~ ${fmt(predictedSum)} zł</span>
      <span class="psb-lbl">Planowane</span>
    </div>
    <span class="psb-op">=</span>
    <div class="psb-item psb-total">
      <span class="psb-val">${fmt(confirmedSum + predictedSum)} zł</span>
      <span class="psb-lbl">Łącznie</span>
    </div>
    <span class="psb-sep"></span>
    <div class="psb-item">
      <span class="psb-val psb-green">${fmt(paidSum)} zł</span>
      <span class="psb-lbl">Opłacono</span>
    </div>
    <div class="psb-item">
      <span class="psb-val psb-orange">${fmt(remSum)} zł</span>
      <span class="psb-lbl">Pozostało</span>
    </div>
  </div>`;

  const itemsHtml = filtered.length
    ? filtered.map(renderUnifiedPaymentCard).join('')
    : '<div class="empty-list">Brak płatności dla wybranego filtra.</div>';

  c.innerHTML = filterHtml + summaryHtml + itemsHtml;
}

// ── CHART MODAL ──
function openChartModal(type) {
  const modal = document.getElementById('chartModal');
  const body  = document.getElementById('chartModalBody');
  const title = document.getElementById('chartModalTitle');
  if (!modal || !body) return;
  const titles = { pie:'📊 Podział wydatków', bar:'📊 Planowane vs opłacone', prog:'✅ Postęp płatności' };
  if (title) title.textContent = titles[type] || 'Wykres';

  if      (type === 'pie')  body.innerHTML = _pieModalHtml();
  else if (type === 'bar')  body.innerHTML = _barModalSvg();
  else if (type === 'prog') body.innerHTML = _progModalHtml();

  modal.style.display = 'flex';
}

// ── CHART MODAL RENDERERS ──

function _pieModalHtml() {
  const items = [];
  const cat = calcCateringTotal();
  if (cat > 0) items.push({ label: 'Catering', value: cat, color: '#1a56db' });
  const grouped = {};
  budgetData.expenses.forEach(e => {
    if (!grouped[e.category]) grouped[e.category] = 0;
    grouped[e.category] += (e.planned || 0);
  });
  Object.entries(grouped).forEach(([c, v]) => {
    if (v > 0) {
      const cfg = EXPENSE_CATEGORIES.find(x => x.name === c);
      items.push({ label: c, value: v, color: cfg?.color || '#94a3b8' });
    }
  });
  if (!items.length) return '<div class="chart-empty">Brak danych do wykresu</div>';

  // SVG z viewBox — CSS kontroluje wyświetlany rozmiar
  const SIZE = 400;
  const total = items.reduce((s, d) => s + d.value, 0);
  const cx = SIZE/2, cy = SIZE/2, r = SIZE/2 - 10, ri = r * 0.52;
  let angle = -Math.PI / 2;
  const paths = items.map(d => {
    if (!d.value) return '';
    const sl = (d.value / total) * 2 * Math.PI;
    const x1 = cx + r * Math.cos(angle), y1 = cy + r * Math.sin(angle);
    const ex = cx + r * Math.cos(angle+sl), ey = cy + r * Math.sin(angle+sl);
    const xi = cx + ri * Math.cos(angle), yi = cy + ri * Math.sin(angle);
    const xe = cx + ri * Math.cos(angle+sl), ye = cy + ri * Math.sin(angle+sl);
    const lg = sl > Math.PI ? 1 : 0;
    const p = `M${xi.toFixed(1)},${yi.toFixed(1)} L${x1.toFixed(1)},${y1.toFixed(1)} A${r},${r} 0 ${lg},1 ${ex.toFixed(1)},${ey.toFixed(1)} L${xe.toFixed(1)},${ye.toFixed(1)} A${ri},${ri} 0 ${lg},0 ${xi.toFixed(1)},${yi.toFixed(1)} Z`;
    angle += sl;
    return `<path d="${p}" fill="${d.color}" stroke="white" stroke-width="2"/>`;
  }).join('');
  const svg = `<svg class="cml-pie-svg" viewBox="0 0 ${SIZE} ${SIZE}" preserveAspectRatio="xMidYMid meet" xmlns="http://www.w3.org/2000/svg">${paths}</svg>`;

  const legend = items.map(d =>
    `<div class="cml-legend-row"><span class="legend-dot" style="background:${d.color}"></span><span class="cml-legend-label">${esc(d.label)}</span><span class="cml-legend-val">${fmt(d.value)} zł</span></div>`
  ).join('');

  return `<div class="cml-pie-wrap">${svg}</div><div class="cml-legend">${legend}</div>`;
}

function _barModalSvg() {
  const data = budgetData.expenses
    .filter(e => e.planned || e.paid)
    .slice(0, 12)
    .map(e => {
      const cfg = EXPENSE_CATEGORIES.find(c => c.name === e.category);
      const lbl = e.category.length > 10 ? e.category.substring(0, 9) + '…' : e.category;
      return { label: lbl, planned: e.planned || 0, paid: e.paid || 0, color: cfg?.color || '#94a3b8' };
    });
  if (!data.length) return '<div class="chart-empty">Brak danych do wykresu</div>';

  // Duże wymiary wewnętrzne — CSS skaluje SVG do kontenera
  const W = 820, H = 460, ml = 70, mr = 20, mt = 20, mb = 80;
  const pw = W - ml - mr, ph = H - mt - mb;
  const maxVal = Math.max(...data.flatMap(d => [d.planned, d.paid]), 1);
  const gw = pw / data.length;
  const bw = Math.min(gw * 0.32, 40);
  let s = '';

  for (let i = 0; i <= 5; i++) {
    const y = mt + ph - (ph * i / 5);
    const v = maxVal * i / 5;
    s += `<line x1="${ml}" y1="${y.toFixed(1)}" x2="${ml+pw}" y2="${y.toFixed(1)}" stroke="#e2ecfa" stroke-width="1.5"/>`;
    s += `<text x="${(ml-8).toFixed(0)}" y="${(y+4).toFixed(0)}" text-anchor="end" font-size="13" fill="#8ba8d8">${v>=1000?(v/1000).toFixed(1)+'k':Math.round(v)}</text>`;
  }
  data.forEach((d, i) => {
    const cx = ml + i * gw + gw / 2;
    const h1 = (d.planned / maxVal) * ph, h2 = (d.paid / maxVal) * ph;
    s += `<rect x="${(cx-bw-3).toFixed(1)}" y="${(mt+ph-h1).toFixed(1)}" width="${bw}" height="${h1.toFixed(1)}" fill="#76b5f7" rx="3"/>`;
    s += `<rect x="${(cx+3).toFixed(1)}"     y="${(mt+ph-h2).toFixed(1)}" width="${bw}" height="${h2.toFixed(1)}" fill="#1a56db" rx="3"/>`;
    const words = d.label.split('/');
    words.forEach((w, wi) => {
      s += `<text x="${cx.toFixed(0)}" y="${(H-mb+22+wi*16).toFixed(0)}" text-anchor="middle" font-size="12" fill="#5a6a8a">${esc(w.trim())}</text>`;
    });
  });
  s += `<line x1="${ml}" y1="${(mt+ph).toFixed(1)}" x2="${(ml+pw).toFixed(1)}" y2="${(mt+ph).toFixed(1)}" stroke="#c5d8f6" stroke-width="2"/>`;
  s += `<rect x="${W-130}" y="8"  width="14" height="14" fill="#76b5f7" rx="3"/><text x="${W-112}" y="19" font-size="13" fill="#5a6a8a">Planowane</text>`;
  s += `<rect x="${W-130}" y="28" width="14" height="14" fill="#1a56db" rx="3"/><text x="${W-112}" y="39" font-size="13" fill="#5a6a8a">Opłacone</text>`;

  return `<svg class="cml-bar-svg" viewBox="0 0 ${W} ${H}" preserveAspectRatio="xMidYMid meet" xmlns="http://www.w3.org/2000/svg">${s}</svg>`;
}

function _progModalHtml() {
  const items = budgetData.expenses.filter(e => e.planned || e.paid);
  if (!items.length) return '<div class="chart-empty">Brak danych do wykresu</div>';
  return '<div class="cml-prog-list">' + items.map(e => {
    const plan = e.planned || 0, paid = e.paid || 0;
    const pct  = plan > 0 ? Math.min(100, (paid / plan) * 100) : 0;
    const fillCls = pct >= 100 ? 'prog-fill-full' : pct > 0 ? 'prog-fill-partial' : 'prog-fill-zero';
    const cfg = EXPENSE_CATEGORIES.find(c => c.name === e.category);
    const lbl = e.category.length > 22 ? e.category.substring(0, 20) + '…' : e.category;
    return `<div class="cml-prog-item">
      <div class="cml-prog-label">
        <span>${cfg?.icon || ''} ${esc(lbl)}</span>
        <span class="cml-prog-pct">${Math.round(pct)}% — ${fmt(paid)} / ${fmt(plan)} zł</span>
      </div>
      <div class="prog-bg cml-prog-bg"><div class="prog-fill ${fillCls}" style="width:${pct}%"></div></div>
    </div>`;
  }).join('') + '</div>';
}
function closeChartModal(event) {
  const modal=document.getElementById('chartModal');
  if(!modal) return;
  if(!event||event.target===modal) modal.style.display='none';
}
function closeChartModalDirect() { const m=document.getElementById('chartModal'); if(m) m.style.display='none'; }

// ── PODRÓŻ POŚLUBNA ──
function updateHoneymoon(field, value) {
  if (!budgetData.honeymoon) budgetData.honeymoon = { name:'', link:'', totalAmount:0, installments:[] };
  budgetData.honeymoon[field] = value;
  renderHoneymoon();
  renderCostBreakdown();
  renderCostPerTable();
  renderBudgetOverview();
  saveState();
}

function addHoneymoonInst() {
  if (!budgetData.honeymoon) budgetData.honeymoon = { name:'', link:'', totalAmount:0, installments:[] };
  budgetData.honeymoon.installments.push({
    id: nextHoneymoonInstId++, amount: 0, dueDate: '', paidBy: 'both', status: 'pending'
  });
  renderHoneymoon();
  renderCostBreakdown();
  saveState();
}

function updateHoneymoonInst(_ignored, instId, field, value) {
  const inst = ((budgetData.honeymoon || {}).installments || []).find(i => i.id === instId);
  if (!inst) return;
  inst[field] = field === 'amount' ? (parseFloat(value) || 0) : value;
  renderHoneymoon();
  renderCostBreakdown();
  renderBudgetOverview();
  saveState();
}

function deleteHoneymoonInst(_ignored, instId) {
  if (!budgetData.honeymoon) return;
  budgetData.honeymoon.installments = budgetData.honeymoon.installments.filter(i => i.id !== instId);
  renderHoneymoon();
  renderCostBreakdown();
  saveState();
}

function toggleVirtualInCalc(checked) {
  budgetData.includeVirtualInCalc = checked;
  renderTableCosts();      // info w dodatki do menu + podsumowanie cateringu
  renderCostBreakdown();   // podział kosztów
  renderCostPerTable();    // koszt na osobę
  renderBudgetOverview();  // pasek budżetu i statystyki
  renderCharts();          // wykresy kołowy, słupkowy, progress
  saveState();
}

function renderHoneymoon() {
  const card = document.getElementById('honeymoonCard');
  if (!card) return;

  const h    = budgetData.honeymoon || {};
  const inst = h.installments || [];
  const paid = inst.filter(i => i.status === 'paid').reduce((s, i) => s + (i.amount || 0), 0);
  const total = h.totalAmount || 0;
  const estAmt = h.estimatedAmount || 0;
  const effective = _payEffective(total, estAmt);
  const isPred = total === 0 && estAmt > 0;
  const remaining = Math.max(0, effective - paid);
  const hmDiff = total > 0 && estAmt > 0 ? total - estAmt : null;

  const rLabels = { groom:'Pan Młody', bride:'Panna Młoda', both:'Oboje' };

  const instHtml = inst.map(i => {
    const isPaid = i.status === 'paid';
    const pbOpts = Object.entries(rLabels).map(([v,l]) =>
      `<option value="${v}" ${i.paidBy===v?'selected':''}>${l}</option>`).join('');
    const stOpts = [['paid','✓ Zapłacona'],['pending','○ Do zapłaty']].map(([v,l]) =>
      `<option value="${v}" ${i.status===v?'selected':''}>${l}</option>`).join('');
    return `<div class="hm-inst-row${isPaid?' hm-inst-paid':''}">
      <input class="hm-inst-amount" type="number" value="${i.amount||0}" min="0"
             onchange="updateHoneymoonInst(${i.id},'amount',this.value)">
      <span class="currency-sm">zł</span>
      <input type="date" class="hm-inst-date" value="${esc(i.dueDate||'')}"
             onchange="updateHoneymoonInst(${i.id},'dueDate',this.value)">
      <select class="hm-inst-sel" onchange="updateHoneymoonInst(${i.id},'paidBy',this.value)">${pbOpts}</select>
      <select class="hm-inst-sel" onchange="updateHoneymoonInst(${i.id},'status',this.value)">${stOpts}</select>
      <button class="btn-row-del" onclick="deleteHoneymoonInst(${i.id})">✕</button>
    </div>`;
  }).join('');

  card.innerHTML = `
    <div class="extra-card-header">&#9992; Podróż Poślubna</div>
    <div class="extra-card-body">
      <input class="hm-name-input" type="text" value="${esc(h.name||'')}" placeholder="Nazwa / cel podróży…"
             onchange="updateHoneymoon('name',this.value)">
      <div class="hm-link-row">
        ${h.link ? `<a href="${esc(h.link)}" target="_blank" rel="noopener" class="hm-link-btn">&#128279; Otwórz ofertę</a>` : ''}
        <input class="hm-link-input" type="url" value="${esc(h.link||'')}" placeholder="Link do oferty (opcjonalnie)…"
               onchange="updateHoneymoon('link',this.value)">
      </div>
      <div class="hm-amounts-row">
        <div class="hm-total-row">
          <label>Kwota ostateczna:</label>
          <input type="number" class="hm-total-input" value="${total||''}" min="0" placeholder="—"
                 onchange="updateHoneymoon('totalAmount',parseFloat(this.value)||0)">
          <span class="currency-sm">zł</span>
        </div>
        <div class="hm-total-row hm-est-row">
          <label><span class="exp-tilde">~</span> Przewidywana:${hmDiff !== null ? `<span class="exp-est-diff ${hmDiff < 0 ? 'eed-over' : 'eed-under'}">${hmDiff > 0 ? '−' : '+'}${fmt(Math.abs(hmDiff))} zł</span>` : ''}</label>
          <input type="number" class="hm-total-input${isPred ? ' exp-est-only' : ''}" value="${estAmt||''}" min="0" placeholder="—"
                 onchange="updateHoneymoon('estimatedAmount',parseFloat(this.value)||0)">
          <span class="currency-sm">zł</span>
        </div>
      </div>
      <div class="hm-summary-row">
        <span class="hm-sum-item"><span>Zapłacono:</span> <strong class="bval-green">${fmt(paid)} zł</strong></span>
        <span class="hm-sum-item"><span>Pozostało:</span> <strong class="bval-orange">${fmt(remaining)} zł${isPred ? ' <span class="hm-est-badge">~</span>' : ''}</strong></span>
      </div>
      <div class="hm-insts">${instHtml || '<div class="hm-no-inst">Brak rat — dodaj harmonogram płatności.</div>'}</div>
      <button class="btn btn-sm btn-outline" onclick="addHoneymoonInst()" style="margin-top:8px">+ Dodaj ratę</button>
    </div>`;
}

function renderCostBreakdown() {
  const card = document.getElementById('costBreakdownCard');
  if (!card) return;

  const paid    = [];
  const toPay   = [];
  const planned = [];
  const virtCount = getVirtualGuests();
  const effCount  = getEffectiveGuestCount();

  // Wydatki
  budgetData.expenses.forEach(e => {
    const nm = _expenseLabel(e);
    const p = e.paid || 0;
    if (p > 0) paid.push({ name: nm, amount: p, date: e.paymentDate || null });
    const rem = (e.planned || 0) - p;
    if (rem > 0) {
      if (e.paymentDate) toPay.push({ name: nm, amount: rem, date: e.paymentDate });
      else               planned.push({ name: nm, amount: rem });
    }
  });

  // Alkohol
  const alcTotal = calcAlcoholTotal();
  if (alcTotal > 0) planned.push({ name: '🍾 Alkohol', amount: alcTotal });

  // Raty podróży
  ((budgetData.honeymoon || {}).installments || []).forEach(i => {
    if (i.status === 'paid') {
      paid.push({ name: '✈ Podróż poślubna', amount: i.amount || 0, date: i.dueDate || null });
    } else {
      if (i.dueDate) toPay.push({ name: '✈ Podróż poślubna', amount: i.amount || 0, date: i.dueDate });
      else           planned.push({ name: '✈ Podróż poślubna', amount: i.amount || 0 });
    }
  });

  // Sortuj "do zapłaty" od najbliższego terminu
  toPay.sort((a, b) => new Date(a.date) - new Date(b.date));

  const sumPaid    = paid.reduce((s, i) => s + i.amount, 0);
  const sumToPay   = toPay.reduce((s, i) => s + i.amount, 0);
  const sumPlanned = planned.reduce((s, i) => s + i.amount, 0);
  const sumTotal   = sumToPay + sumPlanned;

  const fmtDate = d => d ? new Date(d).toLocaleDateString('pl-PL', { day:'numeric', month:'short', year:'numeric' }) : '';
  const row = (i, cls) => `<div class="cb-row ${cls}">
    <span class="cb-name">${esc(i.name)}</span>
    <span class="cb-date">${fmtDate(i.date)}</span>
    <strong class="cb-amt">${fmt(i.amount)} zł</strong>
  </div>`;
  const dueCls = i => {
    if (isInstallmentOverdue(i.date, 'pending')) return 'cb-overdue';
    if (isInstallmentDueSoon(i.date))            return 'cb-soon';
    return '';
  };

  card.innerHTML = `
    <div class="extra-card-header">&#128203; Podział kosztów</div>
    <div class="extra-card-body">
      <label class="cb-virtual-label">
        <input type="checkbox" ${budgetData.includeVirtualInCalc ? 'checked' : ''}
               onchange="toggleVirtualInCalc(this.checked)">
        Uwzględnij gości wirtualnych (${virtCount}) w obliczeniach
        <span class="cb-hint">&rarr; ${effCount} os.</span>
      </label>
      <div class="cb-section">
        <div class="cb-hdr cb-hdr-paid">&#10003; Opłacone &mdash; ${fmt(sumPaid)} zł</div>
        ${paid.length ? paid.map(i => row(i, 'cb-paid')).join('') : '<div class="cb-empty">Brak opłaconych pozycji</div>'}
      </div>
      <div class="cb-section">
        <div class="cb-hdr cb-hdr-topay">&#9200; Do zapłaty &mdash; ${fmt(sumToPay)} zł</div>
        ${toPay.length ? toPay.map(i => row(i, 'cb-topay ' + dueCls(i))).join('') : '<div class="cb-empty">Brak pozycji z terminem</div>'}
      </div>
      <div class="cb-section">
        <div class="cb-hdr cb-hdr-planned">&#9633; Planowane &mdash; ${fmt(sumPlanned)} zł</div>
        ${planned.length ? planned.map(i => row(i, 'cb-planned')).join('') : '<div class="cb-empty">Brak pozycji bez terminu</div>'}
      </div>
      <div class="cb-total-row">
        <span>Łącznie pozostało:</span>
        <strong class="bval-orange">${fmt(sumTotal)} zł</strong>
      </div>
    </div>`;
}

// ── BUDGET SUB-TABS ──
function switchBudgetTab(tab) {
  const isMobile = window.innerWidth <= 768;
  const tabs = ['catering', 'expenses', 'honeymoon', 'payments', 'summary'];
  tabs.forEach(t => {
    const panel = document.getElementById('btabPanel-' + t);
    const btn   = document.getElementById('btab-' + t);
    if (panel) panel.style.display = isMobile ? '' : (t === tab ? 'flex' : 'none');
    if (btn)   btn.classList.toggle('active', t === tab);
  });
  currentBudgetTab = tab;
}

// ── EDIT MODAL ──
let editState = null;

// Helper: get value of edit field
function _efv(id) { return (document.getElementById('ef_' + id)?.value ?? '').trim(); }
function _efn(id) { return parseFloat(document.getElementById('ef_' + id)?.value) || 0; }
function _efb(id) { return !!(document.getElementById('ef_' + id)?.checked); }

// Helper: build a field row
function _ef(id, label, inputTag) {
  return `<div class="ef-field"><label>${label}</label>${inputTag}</div>`;
}
function _efi(id, label, type, val, extra) {
  return _ef(id, label, `<input type="${type}" id="ef_${id}" value="${esc(String(val ?? ''))}" ${extra ?? ''}>`);
}
function _efs(id, label, pairs, cur) {
  const opts = pairs.map(([v,l]) => `<option value="${esc(v)}"${v===cur?' selected':''}>${l}</option>`).join('');
  return _ef(id, label, `<select id="ef_${id}">${opts}</select>`);
}
function _eft(id, label, val) {
  return _ef(id, label, `<textarea id="ef_${id}" class="ef-textarea">${esc(String(val ?? ''))}</textarea>`);
}

function _guestForm(g) {
  const cats  = [['Państwo Młodzi','Państwo Młodzi'],['Świadkowie','Świadkowie'],['Rodzice','Rodzice'],['Rodzina','Rodzina'],['Znajomi','Znajomi'],['Praca','Praca'],['Inne','Inne']];
  const dietV = g.diet || 'standard';
  return `<div class="ef-grid">
    ${_efi('firstName','Imię','text',g.firstName)}
    ${_efi('lastName','Nazwisko','text',g.lastName)}
    ${_efs('category','Kategoria',cats,g.category)}
    ${_efs('gender','Płeć',[['K','♀ Kobieta'],['M','♂ Mężczyzna'],['N','⚧ Niebinarna']],g.gender)}
    ${_efs('invitedBy','Zaproszony przez',[['','—'],['groom','🤝 Pan Młody'],['bride','💝 Panna Młoda']],g.invitedBy||'')}
    ${_efs('witness','Rola',[['','Brak roli'],['witness_groom','Świadek Pana'],['witness_bride','Świadkowa Panny']],g.witness||'')}
    ${_efs('diet','Dieta',[['standard','Standardowa'],['vegetarian','Wegetariańska'],['vegan','Wegańska'],['glutenfree','Bezglutenowa'],['other','Inne']],dietV)}
    <div class="ef-field" id="ef_dietOtherField" style="${dietV==='other'?'':'display:none'}">
      <label>Opis diety</label><input type="text" id="ef_dietOther" value="${esc(g.dietOther||'')}">
    </div>
    ${_efi('photo','URL zdjęcia','url',g.photo||'')}
    ${_ef('needsAccommodation','Nocleg', `<label class="ef-check"><input type="checkbox" id="ef_needsAccommodation" ${g.needsAccommodation?'checked':''}> Potrzebuje noclegu</label>`)}
  </div>`;
}
function _tableForm(t) {
  const isRect = t.shape === 'rect';
  return `<div class="ef-grid">
    ${_efi('name','Nazwa stołu','text',t.name)}
    <div class="ef-field"><label>Kształt</label>
      <select id="ef_shape" onchange="_toggleTableShapeFields(this.value)">
        <option value="round"${!isRect?' selected':''}>⬤ Okrągły</option>
        <option value="rect"${isRect?' selected':''}>▬ Prostokątny</option>
      </select>
    </div>
    ${_efi('seats','Liczba miejsc','number',t.seats,'min="1" max="30"')}
    <div class="ef-field" id="ef_diamField" style="${isRect?'display:none':''}">
      <label>Średnica (m)</label>
      <input type="number" id="ef_diamM" value="${t.diamM||''}" min="0" step="0.1" placeholder="auto">
    </div>
    <div class="ef-field" id="ef_rectWField" style="${isRect?'':'display:none'}">
      <label>Szerokość (m)</label>
      <input type="number" id="ef_rectWM" value="${t.rectWM||''}" min="0" step="0.1" placeholder="auto">
    </div>
    <div class="ef-field" id="ef_rectLField" style="${isRect?'':'display:none'}">
      <label>Długość (m)</label>
      <input type="number" id="ef_rectLM" value="${t.rectLM||''}" min="0" step="0.1" placeholder="auto">
    </div>
  </div>`;
}
// Pokazuje pola wymiarów zależnie od kształtu stołu (okrągły = średnica, prostokątny = szer.+dł.)
function _toggleTableShapeFields(shape) {
  const rect = shape === 'rect';
  const set = (id, show) => { const el = document.getElementById(id); if (el) el.style.display = show ? '' : 'none'; };
  set('ef_diamField', !rect);
  set('ef_rectWField', rect);
  set('ef_rectLField', rect);
}
// Buduje <option>-y z par [wartość, etykieta]
function _optsHtml(pairs, cur) {
  return pairs.map(([v, l]) => `<option value="${esc(v)}"${v === cur ? ' selected' : ''}>${esc(l)}</option>`).join('');
}
function _taskForm(t) {
  const prio = TASK_PRIORITIES.map(p => [p.value, p.icon + ' ' + p.label]);

  // „Przypisz do" — osoby z konfiguracji + osoby użyte w innych zadaniach + opcja własna
  const aNames = [];
  (budgetData.coupleNames || []).forEach(n => { const v = (n || '').trim(); if (v && !aNames.includes(v)) aNames.push(v); });
  tasks.forEach(x => { if (x.assigneeName && !aNames.includes(x.assigneeName)) aNames.push(x.assigneeName); });
  const aCur  = t.assigneeName || '';
  const aOpts = [['', '— nikt —'], ...aNames.map(n => [n, '👤 ' + n]), ['__custom__', '➕ Dodaj inną osobę…']];

  // Powiązania-referencje: dostawca / prezent
  const vOpts = [['', '— brak —'], ...vendors.map(v => [String(v.id), '👨‍🍳 ' + vendorLabel(v)])];
  const vCur  = t.vendorId != null ? String(t.vendorId) : '';
  const gOpts = [['', '— brak —'], ...gifts.map(g => [String(g.id), '🎁 ' + (g.description || g.from || 'Prezent')])];
  const gCur  = t.giftId != null ? String(t.giftId) : '';

  const bcats  = [['Sala','Sala'],['Strój','Strój'],['Dokumenty','Dokumenty'],['Dekoracje','Dekoracje'],['Inne','Inne']];
  const linked = !!t.isBudgetLinked;

  return `<div class="ef-grid">
    ${_efi('name','Nazwa zadania','text',t.name)}
    ${_efs('status','Status',[['todo','Do zrobienia'],['inprogress','W trakcie'],['done','Zrobione'],['cancelled','Anulowane']],t.status)}
    ${_efs('priority','Priorytet',prio,t.priority||'med')}
    ${_efs('responsible','Odpowiedzialny',[['groom','Pan Młody'],['bride','Panna Młoda'],['both','Oboje']],t.responsible)}
    <div class="ef-field"><label>Przypisz do</label>
      <select id="ef_assignee" onchange="document.getElementById('ef_assigneeCustomField').style.display=this.value==='__custom__'?'':'none'">${_optsHtml(aOpts, aCur)}</select>
    </div>
    <div class="ef-field" id="ef_assigneeCustomField" style="${aCur==='__custom__'?'':'display:none'}">
      <label>Imię osoby</label><input type="text" id="ef_assigneeCustom" placeholder="np. Świadek, Mama">
    </div>
    ${_ef('startDate','Data rozpoczęcia',`<input type="date" id="ef_startDate" value="${esc(t.startDate||'')}">`)}
    ${_ef('endDate','Data zakończenia',`<input type="date" id="ef_endDate" value="${esc(t.endDate||'')}">`)}
    ${_ef('dueDate','Termin',`<input type="date" id="ef_dueDate" value="${esc(t.dueDate||'')}">`)}
    <div class="ef-field"><label>Dostawca</label><select id="ef_vendorId">${_optsHtml(vOpts, vCur)}</select></div>
    <div class="ef-field"><label>Prezent</label><select id="ef_giftId">${_optsHtml(gOpts, gCur)}</select></div>
    <div class="ef-field ef-field-full">
      <label class="ef-check"><input type="checkbox" id="ef_isBudgetLinked" ${linked?'checked':''} onchange="document.getElementById('ef_budgetSection').style.display=this.checked?'':'none'"> 💰 Powiąż z budżetem</label>
    </div>
    <div class="ef-grid ef-field-full task-budget-section" id="ef_budgetSection" style="${linked?'':'display:none'}">
      ${_efi('estimatedCost','Szacowany koszt (zł)','number',t.estimatedCost||0,'min="0" step="50"')}
      ${_efs('budgetCategory','Kategoria budżetowa',bcats,t.budgetCategory||'Sala')}
    </div>
  </div>`;
}
function _vendorForm(v) {
  const cats = ['Fotograf','Kamerzysta','Muzyka','Kwiaty','Tort','Catering','Transport','Inne'].map(c=>[c,c]);
  const sts  = VENDOR_STATUSES.map(s=>[s.value,s.label]);
  const bcats  = [['Sala','Sala'],['Strój','Strój'],['Dokumenty','Dokumenty'],['Dekoracje','Dekoracje'],['Inne','Inne']];
  const linked = !!v.isBudgetLinked;
  const cAmount = v.contractAmount || v.price || 0;   // domyślnie kwota = cena, jeśli nie ustawiono
  return `<div class="ef-grid">
    ${_efs('category','Kategoria',cats,v.category)}
    ${_efi('companyName','Nazwa firmy','text',v.companyName||'')}
    ${_efi('contactName','Osoba kontaktowa','text',v.contactName||'')}
    ${_efi('phone','Telefon','tel',v.phone||'')}
    ${_efi('email','Email','email',v.email||'')}
    ${_efi('price','Cena (zł)','number',v.price||0)}
    ${_efs('paymentStatus','Status płatności',sts,v.paymentStatus)}
    ${_efi('mapUrl','Link do Google Maps','url',v.mapUrl||'')}
    ${_eft('notes','Notatki',v.notes||'')}
    <div class="ef-field ef-field-full">
      <label class="ef-check"><input type="checkbox" id="ef_isBudgetLinked" ${linked?'checked':''} onchange="document.getElementById('ef_budgetSection').style.display=this.checked?'':'none'"> 💰 Powiąż z budżetem</label>
    </div>
    <div class="ef-grid ef-field-full task-budget-section" id="ef_budgetSection" style="${linked?'':'display:none'}">
      ${_efi('contractAmount','Kwota umowy / szac. koszt (zł)','number',cAmount,'min="0" step="50"')}
      ${_efs('budgetCategory','Kategoria budżetowa',bcats,v.budgetCategory||'Sala')}
    </div>
  </div>`;
}
function _giftForm(g) {
  return `<div class="ef-grid">
    ${_efi('from','Od kogo','text',g.from||'')}
    ${_efi('description','Opis prezentu','text',g.description||'')}
    ${_efi('value','Wartość (zł)','number',g.value ?? '')}
    ${_ef('thanked','Podziękowanie',`<label class="ef-check"><input type="checkbox" id="ef_thanked" ${g.thanked?'checked':''}> Tak, podziękowano</label>`)}
  </div>`;
}
function _vehicleForm(v) {
  const types = VEHICLE_TYPES.map(t=>[t,t]);
  return `<div class="ef-grid">
    ${_efs('type','Typ pojazdu',types,v.type)}
    ${_efi('description','Opis/Nazwa','text',v.description||'')}
    ${_efi('driver','Kierowca','text',v.driver||'')}
    ${_efi('seats','Liczba miejsc','number',v.seats||4,'min="1" max="60"')}
    ${_efi('route','Trasa','text',v.route||'')}
    ${_ef('departureTime','Godzina odjazdu',`<input type="time" id="ef_departureTime" value="${esc(v.departureTime||'')}">`)}
    ${_efi('cost','Koszt (zł)','number',v.cost||0,'min="0" step="50"')}
  </div>`;
}
function _hotelForm(h) {
  const vendorPick = vendors.length
    ? _ef('vendorPick', 'Wybierz z dostawców', `<select id="ef_vendorPick" onchange="_prefillHotelFromVendor(this.value)">${_vendorOptionsHtml('— nowy hotel —')}</select>`)
    : '';
  return `<div class="ef-grid">
    ${vendorPick}
    ${_efi('name','Nazwa hotelu','text',h.name||'')}
    ${_efi('address','Adres','text',h.address||'')}
    ${_efi('phone','Telefon','tel',h.phone||'')}
    ${_efi('pricePerNight','Cena za osobę za noc (zł)','number',h.pricePerNight||0)}
    ${_efi('personsPerRoom','Liczba osób w pokoju','number',h.personsPerRoom||2,'min="1" max="20"')}
    ${_ef('inComplex','Lokalizacja', `<label class="ef-check"><input type="checkbox" id="ef_inComplex" ${h.inComplex?'checked':''}> 🏨 Hotel w kompleksie wesela</label>`)}
    ${_efi('bookingLink','Link rezerwacji','url',h.bookingLink||'')}
    ${_eft('notes','Notatki',h.notes||'')}
  </div>`;
}
function _paymentForm(p) {
  return `<div class="ef-grid">
    ${_efi('name','Nazwa płatności','text',p.name||'')}
    ${_efi('totalAmount','Kwota całkowita (zł)','number',p.totalAmount||0)}
  </div>`;
}
function _expenseForm(e) {
  const cats = getExpenseCategories().map(name => [name, _expenseCatIcon(name) + ' ' + name]);
  return `<div class="ef-grid">
    ${_efs('category','Kategoria',cats,e.category)}
    ${_efi('planned','Planowane (zł)','number',e.planned||0)}
    ${_efi('paid','Opłacono (zł)','number',e.paid||0)}
    ${_ef('paymentDate','Data płatności',`<input type="date" id="ef_paymentDate" value="${esc(e.paymentDate||'')}">`)}
    ${_efi('note','Notatka','text',e.note||'')}
  </div>`;
}
function _scheduleForm(ev) {
  const cats = SCHED_CATS.map(c=>[c.name, c.icon + ' ' + c.name]);
  return `<div class="ef-grid">
    <div class="ef-row">
      ${_efi('hour','Godz.','number',ev.hour,'min="0" max="23"')}
      ${_efi('minute','Min.','number',ev.minute,'min="0" max="59"')}
    </div>
    ${_efi('name','Nazwa','text',ev.name||'')}
    ${_efs('category','Kategoria',cats,ev.category)}
    ${_efi('description','Opis','text',ev.description||'')}
    ${_efi('location','Miejsce','text',ev.location||'')}
    ${_efi('responsible','Odpowiedzialny','text',ev.responsible||'')}
    ${_efi('locationUrl','Link do lokalizacji (URL)','url',ev.locationUrl||'')}
    <div class="ef-field">
      <label class="ef-check">
        <input type="checkbox" id="ef_showLinkToGuests" ${ev.showLinkToGuests ? 'checked' : ''}>
        &#128065; Pokaż link gościom na stronie /harmonogram
      </label>
    </div>
    <div class="ef-field">
      <label class="ef-check">
        <input type="checkbox" id="ef_private" ${ev.private ? 'checked' : ''}>
        &#128274; Prywatne — ukryj przed gośćmi na stronie /harmonogram
      </label>
    </div>
  </div>`;
}

function openEditModal(type, id) {
  const modal = document.getElementById('editModal');
  const body  = document.getElementById('editModalTitle');
  if (!modal) return;
  editState = { type, id };

  let title = 'Edytuj', html = '';
  try {
    if (type === 'guest') {
      const g = guests.find(x=>x.id===id); if (!g) return;
      title = 'Edytuj gościa: ' + fullName(g); html = _guestForm(g);
    } else if (type === 'table') {
      const t = tables.find(x=>x.id===id); if (!t) return;
      title = 'Edytuj stół: ' + t.name; html = _tableForm(t);
    } else if (type === 'task') {
      const t = tasks.find(x=>x.id===id); if (!t) return;
      title = 'Edytuj zadanie'; html = _taskForm(t);
    } else if (type === 'vendor') {
      const v = vendors.find(x=>x.id===id); if (!v) return;
      title = 'Edytuj dostawcę: ' + (v.companyName||v.category); html = _vendorForm(v);
    } else if (type === 'gift') {
      const g = gifts.find(x=>x.id===id); if (!g) return;
      title = 'Edytuj prezent'; html = _giftForm(g);
    } else if (type === 'vehicle') {
      const v = vehicles.find(x=>x.id===id); if (!v) return;
      title = 'Edytuj pojazd'; html = _vehicleForm(v);
    } else if (type === 'hotel') {
      const h = hotels.find(x=>x.id===id); if (!h) return;
      title = 'Edytuj hotel: ' + (h.name||''); html = _hotelForm(h);
    } else if (type === 'payment') {
      const p = payments.find(x=>x.id===id); if (!p) return;
      title = 'Edytuj płatność'; html = _paymentForm(p);
    } else if (type === 'expense') {
      const e = budgetData.expenses.find(x=>x.id===id); if (!e) return;
      title = 'Edytuj wydatek'; html = _expenseForm(e);
    } else if (type === 'schedule') {
      const ev = scheduleEvents.find(x=>x.id===id); if (!ev) return;
      title = 'Edytuj wydarzenie'; html = _scheduleForm(ev);
    }
  } catch(err) { console.error('openEditModal:', err); return; }

  if (body) body.textContent = title;
  const bodyEl = document.getElementById('editModalBody');
  if (bodyEl) bodyEl.innerHTML = html;

  // Diet change handler
  const dietSel = document.getElementById('ef_diet');
  if (dietSel) dietSel.addEventListener('change', () => {
    const f = document.getElementById('ef_dietOtherField');
    if (f) f.style.display = dietSel.value === 'other' ? '' : 'none';
  });

  modal.style.display = 'flex';
}

function saveEdit() {
  if (!editState) return;
  const { type, id } = editState;
  try {
    if (type === 'guest') {
      const g = guests.find(x=>x.id===id); if (!g) return;
      g.firstName  = _efv('firstName');
      g.lastName   = _efv('lastName');
      const _newCat = _efv('category') || 'Rodzina';
      // Para Młoda = dokładnie dwie osoby — nie pozwól oznaczyć trzeciej przy edycji
      if (_newCat === 'Państwo Młodzi' && g.category !== 'Państwo Młodzi'
          && _coupleMembers().filter(x => x.id !== id).length >= 2) {
        showToast('Para Młoda to dokładnie dwie osoby — nie można oznaczyć trzeciej.');
      } else {
        g.category = _newCat;
      }
      g.gender     = _efv('gender') || 'K';
      g.invitedBy  = _efv('invitedBy') || null;
      g.witness    = _efv('witness') || null;
      g.diet       = _efv('diet') || 'standard';
      g.dietOther  = _efv('dietOther');
      g.photo      = _efv('photo') || null;
      g.needsAccommodation = _efb('needsAccommodation');
      renderAll();
    } else if (type === 'table') {
      const t = tables.find(x=>x.id===id); if (!t) return;
      t.name  = _efv('name') || t.name;
      const newShape = _efv('shape');
      if (newShape && newShape !== t.shape) {
        t.shape = newShape;
        if (newShape === 'round') t.isHonorTable = false;
      }
      const newSeats = parseInt(document.getElementById('ef_seats')?.value) || t.seats;
      if (newSeats !== t.seats) {
        const occupied = t.seatsData.filter(x=>x!==null).length;
        const safe = Math.max(occupied, newSeats);
        if (safe > t.seats) t.seatsData.push(...new Array(safe - t.seats).fill(null));
        else t.seatsData = t.seatsData.slice(0, safe);
        t.seats = safe;
      }
      // Per-stół rozmiar (m) — 0/puste = automatyczny
      t.diamM  = Math.max(0, parseFloat(document.getElementById('ef_diamM')?.value)  || 0);
      t.rectWM = Math.max(0, parseFloat(document.getElementById('ef_rectWM')?.value) || 0);
      t.rectLM = Math.max(0, parseFloat(document.getElementById('ef_rectLM')?.value) || 0);
      _fitTableInRoom(t);   // po zmianie wymiarów: zmieść w sali i odsuń od kolizji
      renderTables();
      if (currentView === 'room') renderRoom();
    } else if (type === 'task') {
      const t = tasks.find(x=>x.id===id); if (!t) return;
      t.name = _efv('name') || t.name;
      t.status = _efv('status');
      t.priority = _efv('priority') || 'med';
      t.responsible = _efv('responsible');
      t.startDate = _efv('startDate');
      t.endDate = _efv('endDate');
      t.dueDate = _efv('dueDate');
      // Przypisanie do osoby (lista lub własna)
      let asg = _efv('assignee');
      if (asg === '__custom__') asg = _efv('assigneeCustom');
      t.assigneeName = asg || '';
      // Powiązania-referencje (ID, nie kopie)
      const vid = _efv('vendorId'); t.vendorId = vid ? parseInt(vid) : null;
      const gid = _efv('giftId');   t.giftId   = gid ? parseInt(gid) : null;
      // Powiązanie z budżetem — referencja do wpisu (bez duplikatów)
      t.isBudgetLinked = _efb('isBudgetLinked');
      if (t.isBudgetLinked) {
        t.estimatedCost  = _efn('estimatedCost');
        t.budgetCategory = _efv('budgetCategory') || 'Inne';
        let exp = t.budgetExpenseId != null ? budgetData.expenses.find(x => x.id === t.budgetExpenseId) : null;
        if (exp) {
          // edytuj TEN SAM wpis (nie twórz nowego)
          exp.category = t.budgetCategory;
          exp.customName = t.name;
          exp.estimatedAmount = t.estimatedCost;
        } else {
          // utwórz nowy wpis i zapamiętaj jego ID w zadaniu
          const newId = nextExpenseId++;
          budgetData.expenses.push({
            id: newId, category: t.budgetCategory, customName: t.name,
            planned: 0, estimatedAmount: t.estimatedCost, paid: 0, paymentDate: '',
            note: 'Utworzono z zadania: ' + t.name, splitP1: 0, splitP2: 0, sidePanel: false,
          });
          if (typeof expenseOrder !== 'undefined') expenseOrder.push(newId);
          t.budgetExpenseId = newId;
        }
        if (typeof renderBudgetOverview === 'function') renderBudgetOverview();
        if (currentView === 'budget' && typeof renderExpenses === 'function') renderExpenses();
      } else {
        // odłączenie od budżetu — czyść referencję (wpis w budżecie pozostaje)
        t.estimatedCost = 0; t.budgetCategory = ''; t.budgetExpenseId = null;
      }
      // legacy: wyczyść stare powiązanie ogólne
      t.linkType = ''; t.linkId = null;
      renderTasks();
    } else if (type === 'vendor') {
      const v = vendors.find(x=>x.id===id); if (!v) return;
      v.category = _efv('category');
      v.companyName = _efv('companyName');
      v.contactName = _efv('contactName');
      v.phone = _efv('phone');
      v.email = _efv('email');
      v.price = _efn('price');
      v.paymentStatus = _efv('paymentStatus');
      v.mapUrl = _efv('mapUrl');
      v.notes = _efv('notes');
      // Powiązanie z budżetem — referencja do wpisu (bez duplikatów)
      v.isBudgetLinked = _efb('isBudgetLinked');
      if (v.isBudgetLinked) {
        v.contractAmount = _efn('contractAmount');
        v.budgetCategory = _efv('budgetCategory') || 'Inne';
        let exp = v.budgetExpenseId != null ? budgetData.expenses.find(x => x.id === v.budgetExpenseId) : null;
        if (exp) {
          // edytuj TEN SAM wpis (nie twórz nowego)
          exp.category = v.budgetCategory;
          exp.customName = vendorLabel(v);
          exp.estimatedAmount = v.contractAmount;
          exp.vendorId = v.id;
        } else {
          // utwórz nowy wpis i zapamiętaj jego ID w dostawcy
          const newId = nextExpenseId++;
          budgetData.expenses.push({
            id: newId, category: v.budgetCategory, customName: vendorLabel(v),
            planned: 0, estimatedAmount: v.contractAmount, paid: 0, paymentDate: '',
            note: 'Dostawca: ' + vendorLabel(v), splitP1: 0, splitP2: 0, sidePanel: false, vendorId: v.id,
          });
          if (typeof expenseOrder !== 'undefined') expenseOrder.push(newId);
          v.budgetExpenseId = newId;
        }
        if (typeof renderBudgetOverview === 'function') renderBudgetOverview();
        if (currentView === 'budget' && typeof renderExpenses === 'function') renderExpenses();
      } else {
        // odłączenie od budżetu — czyść referencję (wpis w budżecie pozostaje)
        v.contractAmount = 0; v.budgetCategory = ''; v.budgetExpenseId = null;
      }
      renderVendors();
    } else if (type === 'gift') {
      const g = gifts.find(x=>x.id===id); if (!g) return;
      g.from = _efv('from');
      g.description = _efv('description');
      const vv = document.getElementById('ef_value')?.value;
      g.value = vv ? (parseFloat(vv)||null) : null;
      g.thanked = _efb('thanked');
      renderGifts();
    } else if (type === 'vehicle') {
      const v = vehicles.find(x=>x.id===id); if (!v) return;
      v.type = _efv('type');
      v.description = _efv('description');
      v.driver = _efv('driver');
      v.seats = Math.max(1, parseInt(document.getElementById('ef_seats')?.value)||1);
      v.route = _efv('route');
      v.departureTime = _efv('departureTime');
      v.cost = _efn('cost');
      renderTransport();
    } else if (type === 'hotel-new') {
      hotels.push({
        id: nextHotelId++,
        name:           _efv('name') || 'Hotel',
        address:        _efv('address'),
        phone:          _efv('phone'),
        pricePerNight:  _efn('pricePerNight'),
        personsPerRoom: Math.max(1, parseInt(document.getElementById('ef_personsPerRoom')?.value)||2),
        bookingLink:    _efv('bookingLink'),
        notes:          _efv('notes'),
        inComplex:      _efb('inComplex'),
      });
      saveState();
      renderAccommodation();
    } else if (type === 'hotel') {
      const h = hotels.find(x=>x.id===id); if (!h) return;
      h.name = _efv('name') || h.name;
      h.address = _efv('address');
      h.phone = _efv('phone');
      h.pricePerNight = _efn('pricePerNight');
      h.personsPerRoom = Math.max(1, parseInt(document.getElementById('ef_personsPerRoom')?.value)||2);
      h.bookingLink = _efv('bookingLink');
      h.notes = _efv('notes');
      h.inComplex = _efb('inComplex');
      renderAccommodation();
    } else if (type === 'payment') {
      const p = payments.find(x=>x.id===id); if (!p) return;
      p.name = _efv('name') || p.name;
      p.totalAmount = _efn('totalAmount');
      renderPayments();
    } else if (type === 'expense') {
      const e = budgetData.expenses.find(x=>x.id===id); if (!e) return;
      e.category = _efv('category');
      e.planned = _efn('planned');
      e.paid = _efn('paid');
      e.paymentDate = _efv('paymentDate');
      e.note = _efv('note');
      renderExpenses();
      renderBudgetOverview();
      renderCharts();
    } else if (type === 'schedule') {
      const ev = scheduleEvents.find(x=>x.id===id); if (!ev) return;
      ev.hour = parseInt(document.getElementById('ef_hour')?.value)||0;
      ev.minute = parseInt(document.getElementById('ef_minute')?.value)||0;
      ev.name = _efv('name') || ev.name;
      ev.description = _efv('description');
      ev.location = _efv('location');
      ev.responsible = _efv('responsible');
      ev.category = _efv('category');
      ev.locationUrl = _efv('locationUrl');
      ev.showLinkToGuests = _efb('showLinkToGuests');
      ev.private = _efb('private');
      renderSchedule();
    }
    saveState();
    showToast('Zmiany zapisane ✓');
  } catch(err) {
    console.error('saveEdit:', err);
    showToast('Błąd podczas zapisu');
  }
  closeEditModalDirect();
}

function closeEditModal(event) {
  const modal = document.getElementById('editModal');
  if (modal && (!event || event.target === modal)) modal.style.display = 'none';
}
function closeEditModalDirect() {
  const modal = document.getElementById('editModal');
  if (modal) modal.style.display = 'none';
  editState = null;
}

// ══════════════════════════════════════════════════════
//  KODY QR + GALERIA GOŚCI (panel organizatora)
// ══════════════════════════════════════════════════════

// Buduje pełny publiczny adres URL strony (np. dla kodu QR)
function _publicUrl(path) {
  const origin = (location.origin && location.origin !== 'null') ? location.origin : '';
  return origin + '/' + path;
}

// Generuje kod QR w kontenerze <div> (biblioteka qrcodejs)
function _renderQRCanvas(containerId, url) {
  const el = document.getElementById(containerId);
  if (!el) return;
  if (typeof QRCode === 'undefined') {
    // Biblioteka QR jeszcze się nie załadowała — spróbuj ponownie za chwilę
    setTimeout(() => _renderQRCanvas(containerId, url), 300);
    return;
  }
  el.innerHTML = ''; // wyczyść poprzedni kod (przy ponownym wejściu w widok)
  try {
    new QRCode(el, {
      text: url,
      width: 200,
      height: 200,
      colorDark: '#1040b0',
      colorLight: '#ffffff',
      correctLevel: QRCode.CorrectLevel.M,
    });
  } catch (e) { console.error('Błąd generowania QR:', e); }
}

// Ustawia adres (i opcjonalnie tekst) linku obok kodu QR
function _setQRLink(id, url, hrefOnly) {
  const el = document.getElementById(id);
  if (!el) return;
  el.href = url;
  if (!hrefOnly) el.textContent = url;
}

// Pobiera kod QR jako plik PNG
function downloadQR(containerId, filename) {
  const el = document.getElementById(containerId);
  if (!el) return;
  let dataUrl = '';
  const canvas = el.querySelector('canvas');
  if (canvas) {
    try { dataUrl = canvas.toDataURL('image/png'); } catch (_) {}
  }
  if (!dataUrl) {
    const img = el.querySelector('img');
    if (img && img.src) dataUrl = img.src;
  }
  if (!dataUrl) { console.error('Nie znaleziono kodu QR do pobrania'); return; }
  const a = document.createElement('a');
  a.href = dataUrl;
  a.download = filename || 'qr.png';
  document.body.appendChild(a);
  a.click();
  a.remove();
}

// QR — harmonogram dla gości
function renderScheduleQR() {
  const url = _publicUrl('harmonogram.html');
  _renderQRCanvas('qrSchedule', url);
  _setQRLink('qrScheduleLink', url);
  _setQRLink('qrScheduleOpen', url, true);
}

// QR — galeria zdjęć gości
function renderGalleryQR() {
  const url = _publicUrl('galeria.html');
  _renderQRCanvas('qrGallery', url);
  _setQRLink('qrGalleryLink', url);
  _setQRLink('qrGalleryOpen', url, true);
}

// ── Administracja galerią ──
let _galleryAdminItems = [];
let _galleryAdminUnsub = null;

// Stan filtrów i sortowania galerii (panel organizatora) — taki sam jak na /galeria
let _galFilterPerson = '';      // '' = wszyscy
let _galFilterType   = 'all';   // 'all' | 'image' | 'video'
let _galSortOrder    = 'newest';// 'newest' | 'oldest'

function renderGalleryView() {
  renderGalleryQR();
  _startGalleryAdminListener();
  renderGalleryAdminGrid();
}

function _startGalleryAdminListener() {
  if (_galleryAdminUnsub) return;
  if (!window.firebase || !firebase.firestore) return;
  try {
    _galleryAdminUnsub = firebase.firestore().collection('gallery')
      .orderBy('timestamp', 'desc')
      .onSnapshot(snap => {
        _galleryAdminItems = snap.docs.map(d => Object.assign({ id: d.id }, d.data()));
        renderGalleryAdminGrid();
      }, err => console.error('Nasłuch galerii (admin):', err));
  } catch (e) { console.error('Galeria admin:', e); }
}

// Formatuje rozmiar w bajtach do czytelnej postaci (MB / GB)
function _fmtSize(bytes) {
  const mb = (bytes || 0) / (1024 * 1024);
  if (mb >= 1024) return (mb / 1024).toFixed(2) + ' GB';
  return mb.toFixed(1) + ' MB';
}

// Aktualizuje licznik wykorzystanego miejsca (25 GB darmowego planu Cloudinary)
function _renderGalleryStorage() {
  const usageEl = document.getElementById('galleryStorageUsage');
  const barEl   = document.getElementById('galleryStorageBar');
  const total   = _galleryAdminItems.reduce((sum, it) => sum + (it.fileSize || 0), 0);
  const LIMIT   = 25 * 1024 * 1024 * 1024; // 25 GB
  if (usageEl) usageEl.textContent = `Wykorzystano: ${_fmtSize(total)} / 25 GB`;
  if (barEl) {
    const pct = Math.min(100, (total / LIMIT) * 100);
    barEl.style.width = pct.toFixed(2) + '%';
    barEl.classList.toggle('gs-bar-warn', pct >= 85);
  }
}

// Lista unikalnych imion osób, które dodały pliki (alfabetycznie)
function _galPersonsList() {
  const map = new Map();
  _galleryAdminItems.forEach(it => {
    const name = (it.uploadedBy || 'Gość').trim() || 'Gość';
    map.set(name.toLowerCase(), name);
  });
  return [...map.values()].sort((a, b) => a.localeCompare(b, 'pl'));
}

// Zastosuj filtry i sortowanie do listy plików
function _galApplyFiltersSort(items) {
  let out = items.slice();
  if (_galFilterPerson) {
    const fp = _galFilterPerson.toLowerCase();
    out = out.filter(it => ((it.uploadedBy || 'Gość').trim().toLowerCase()) === fp);
  }
  if (_galFilterType !== 'all') {
    out = out.filter(it => (it.type === 'video' ? 'video' : 'image') === _galFilterType);
  }
  out.sort((a, b) => _galSortOrder === 'newest'
    ? (b.timestamp || 0) - (a.timestamp || 0)
    : (a.timestamp || 0) - (b.timestamp || 0));
  return out;
}

// Funkcje wywoływane z UI filtrów
function setGalFilterPerson(v) { _galFilterPerson = v; renderGalleryAdminGrid(); }
function setGalFilterType(v)   { _galFilterType = v;   renderGalleryAdminGrid(); }
function setGalSortOrder(v)    { _galSortOrder = v;    renderGalleryAdminGrid(); }

// Pasek filtrów i sortowania (identyczny jak na /galeria)
function renderGalleryAdminFilters() {
  const bar = document.getElementById('galleryAdminFilters');
  if (!bar) return;
  if (!_galleryAdminItems.length) { bar.style.display = 'none'; return; }
  bar.style.display = 'flex';

  const persons = _galPersonsList();
  const personOpts = ['<option value="">&#128101; Wszyscy</option>']
    .concat(persons.map(n => `<option value="${esc(n)}" ${_galFilterPerson.toLowerCase() === n.toLowerCase() ? 'selected' : ''}>${esc(n)}</option>`))
    .join('');

  const typePill = (val, label) =>
    `<button class="gf-pill ${_galFilterType === val ? 'gf-on' : ''}" onclick="setGalFilterType('${val}')">${label}</button>`;
  const sortPill = (val, label) =>
    `<button class="gf-pill ${_galSortOrder === val ? 'gf-on' : ''}" onclick="setGalSortOrder('${val}')">${label}</button>`;

  bar.innerHTML = `
    <div class="gf-group">
      <span class="gf-lbl">Osoba</span>
      <select class="gf-select" onchange="setGalFilterPerson(this.value)">${personOpts}</select>
    </div>
    <div class="gf-group">
      <span class="gf-lbl">Typ</span>
      <div class="gf-pills">
        ${typePill('all', 'Wszystkie')}
        ${typePill('image', '📷 Zdjęcia')}
        ${typePill('video', '🎥 Filmy')}
      </div>
    </div>
    <div class="gf-group">
      <span class="gf-lbl">Sortuj</span>
      <div class="gf-pills">
        ${sortPill('newest', '⬇ Najnowsze')}
        ${sortPill('oldest', '⬆ Najstarsze')}
      </div>
    </div>`;
}

function renderGalleryAdminGrid() {
  const grid = document.getElementById('galleryAdminGrid');
  const countEl = document.getElementById('galleryAdminCount');
  if (!grid) return;

  _renderGalleryStorage();
  renderGalleryAdminFilters();

  if (!_galleryAdminItems.length) {
    if (countEl) countEl.textContent = '';
    grid.innerHTML = '<div class="empty-list">Brak zdjęć. Goście mogą dodawać zdjęcia i filmy skanując kod QR powyżej.</div>';
    return;
  }

  if (countEl) {
    const n = _galleryAdminItems.length;
    countEl.textContent = n + (n === 1 ? ' plik' : ' plików');
  }

  const displayed = _galApplyFiltersSort(_galleryAdminItems);

  if (!displayed.length) {
    grid.innerHTML = '<div class="empty-list">🔍 Brak plików dla wybranych filtrów.</div>';
    return;
  }

  grid.innerHTML = '<div class="gallery-admin-grid">' + displayed.map(it => {
    const thumb = it.type === 'video' ? it.url : _cldTransform(it.url, 'c_fill,g_auto,w_400,h_400,f_auto,q_auto');
    const media = it.type === 'video'
      ? `<video src="${esc(it.url)}" preload="metadata" muted playsinline></video><span class="ga-badge">▶ film</span>`
      : `<img src="${esc(thumb)}" alt="" loading="lazy">`;
    return `<div class="ga-tile">
      <div class="ga-media" onclick="window.open('${esc(it.url)}','_blank')">${media}</div>
      <div class="ga-name">&#128247; ${esc(it.uploadedBy || 'Gość')}</div>
      <div class="ga-actions">
        <button class="btn btn-sm" onclick="downloadGalleryItem('${it.id}')">&#11015; Pobierz</button>
        <button class="btn btn-sm btn-danger" onclick="deleteGalleryItem('${it.id}')">&#128465; Usuń</button>
      </div>
    </div>`;
  }).join('') + '</div>';
}

// Wstawia transformację (np. fl_attachment) do adresu Cloudinary
function _cldTransform(url, t) {
  if (!url || url.indexOf('/upload/') === -1) return url;
  return url.replace('/upload/', '/upload/' + t + '/');
}

function downloadGalleryItem(id) {
  const it = _galleryAdminItems.find(x => x.id === id);
  if (!it) return;
  // fl_attachment wymusza pobranie pliku z Cloudinary (Content-Disposition: attachment)
  const dlUrl = _cldTransform(it.url, 'fl_attachment');
  const a = document.createElement('a');
  a.href = dlUrl;
  a.download = '';
  a.target = '_blank';
  a.rel = 'noopener';
  document.body.appendChild(a);
  a.click();
  a.remove();
}

async function deleteGalleryItem(id) {
  const it = _galleryAdminItems.find(x => x.id === id);
  if (!it) return;
  if (!confirm('Usunąć ten plik z galerii? Zniknie z galerii gości. (Oryginał pozostaje na Cloudinary.)')) return;
  try {
    // Opcja A — kasujemy tylko wpis w Firestore, plik zostaje na Cloudinary
    await firebase.firestore().collection('gallery').doc(id).delete();
    // Lista odświeży się automatycznie przez nasłuch onSnapshot
  } catch (e) {
    console.error('Usuwanie pliku galerii:', e);
    alert('Nie udało się usunąć pliku. Spróbuj ponownie.');
  }
}

// ══════════════════════════════════════════════════════
//  ZARZĄDZANIE DOSTĘPEM (czarna lista emaili)
// ══════════════════════════════════════════════════════
let _blockedEmailsAdmin = [];
let _accessUnsub = null;

function renderAccessView() {
  _startAccessListener();
  renderAccessList();
}

function _accessRef() {
  return firebase.firestore().collection('accessControl').doc('main');
}

function _startAccessListener() {
  if (_accessUnsub) return;
  if (!window.firebase || !firebase.firestore) return;
  try {
    _accessUnsub = _accessRef().onSnapshot(doc => {
      const list = (doc.exists && doc.data().blockedEmails) || [];
      _blockedEmailsAdmin = list.map(e => (e || '').toLowerCase());
      renderAccessList();
    }, err => console.error('Nasłuch dostępu:', err));
  } catch (e) { console.error('Zarządzanie dostępem:', e); }
}

function _currentUserEmail() {
  try {
    return ((firebase.auth().currentUser || {}).email || '').toLowerCase();
  } catch (_) { return ''; }
}

// ══════════════════════════════════════════════════════
//  ONBOARDING — przewodnik krok po kroku dla nowego użytkownika
// ══════════════════════════════════════════════════════
// Pełna lista kroków. lvl:'b' = zakładka główna (tryb podstawowy i pełny),
// lvl:'s' = podzakładka/sekcja (tylko tryb pełny). sub() przełącza podzakładkę.
const ONB_ALL_STEPS = [
  { lvl:'b', view:'dashboard', openPlanning:true, target:'#planningGuideModalCard', title:'Od czego zacząć?', desc:'Zacznij tutaj: sugerowana kolejność planowania wesela. Odhaczaj ukończone kroki — pasek pokaże postęp. Otworzysz to okno w każdej chwili z menu Ustawień (trybik).' },
  { lvl:'b', view:'dashboard', target:'#navDashboard', title:'Dashboard', desc:'Twój pulpit dowodzenia — licznik dni do ślubu, skróty i najważniejsze statystyki w jednym miejscu.' },

  { lvl:'b', view:'tables', target:'#navTables', title:'Stoły i goście', desc:'Serce organizacji gości: lista zaproszonych, układ stołów i przypisanie miejsc.' },
  { lvl:'s', view:'tables', sub:()=>switchTablesTab('plan'),    target:'#ttab-plan',    title:'Plan stołów', desc:'Twórz stoły i przeciągaj na nie gości, aby zaplanować rozsadzenie.' },
  { lvl:'s', view:'tables', sub:()=>switchTablesTab('card'),    target:'#ttab-card',    title:'Kartoteka gości', desc:'Pełna lista gości z danymi, statusem potwierdzenia i preferencjami.' },
  { lvl:'s', view:'tables', sub:()=>switchTablesTab('summary'), target:'#ttab-summary', title:'Podsumowanie gości', desc:'Zbiorcze statystyki: liczba gości, potwierdzenia, dzieci i diety.' },

  { lvl:'b', view:'room', target:'#navRoom', title:'Plan sali', desc:'Rozmieść stoły i elementy sali na interaktywnym planie. Włącz „Edytuj plan", aby przeciągać i zmieniać rozmiary.' },

  { lvl:'b', view:'rsvp', target:'#navRsvp', title:'Potwierdzenia', desc:'Zarządzaj potwierdzeniami obecności (RSVP) i udostępniaj gościom formularz online.' },

  { lvl:'b', view:'budget', target:'#navBudget', title:'Budżet', desc:'Kontroluj wszystkie koszty wesela — od sali po napoje — w jednym, przejrzystym miejscu.' },
  { lvl:'s', view:'budget', sub:()=>switchBudgetTab('summary'),   target:'#btab-summary',   title:'Podsumowanie budżetu', desc:'Budżet całkowity kontra wydatki — szybki podgląd, ile już rozdysponowano.' },
  { lvl:'s', view:'budget', sub:()=>switchBudgetTab('catering'),  target:'#btab-catering',  title:'Sala', desc:'Koszt sali i cateringu — stawka za osobę automatycznie przelicza się z liczbą gości.' },
  { lvl:'s', view:'budget', sub:()=>switchBudgetTab('expenses'),  target:'#btab-expenses',  title:'Wydatki', desc:'Dodawaj pozostałe wydatki wesela i grupuj je w kategorie.' },
  { lvl:'s', view:'budget', sub:()=>switchBudgetTab('expenses'),  target:'#alcoholSection', title:'Alkohol', desc:'Osobny panel na alkohol — planuj rodzaje, ilości i koszty trunków.' },
  { lvl:'s', view:'budget', sub:()=>switchBudgetTab('expenses'),  target:'#softSection',    title:'Napoje bezalkoholowe', desc:'Analogiczny panel na napoje bezalkoholowe — woda, soki, napoje gazowane.' },
  { lvl:'s', view:'budget', sub:()=>switchBudgetTab('honeymoon'), target:'#btab-honeymoon', title:'Podróż poślubna', desc:'Zaplanuj budżet miesiąca miodowego osobno od kosztów wesela.' },
  { lvl:'s', view:'budget', sub:()=>switchBudgetTab('payments'),  target:'#btab-payments',  title:'Płatności', desc:'Harmonogram wpłat i zaliczek — pilnuj terminów i tego, co już zapłacone.' },

  { lvl:'b', view:'schedule', target:'#navSchedule', title:'Harmonogram', desc:'Rozpisz przebieg dnia ślubu — od ceremonii po ostatni taniec.' },
  { lvl:'s', view:'schedule', sub:()=>switchScheduleTab('plan'),      target:'#stab-plan',      title:'Harmonogram — wydarzenia', desc:'Dodawaj punkty programu z godzinami. Podgląd jako lista, kolumny lub wykres Gantta.' },
  { lvl:'s', view:'schedule', sub:()=>switchScheduleTab('checklist'), target:'#stab-checklist', title:'Checklista', desc:'Lista rzeczy do odhaczenia przed weselem i w jego trakcie.' },

  { lvl:'b', view:'tasks', target:'#navTasks', title:'Zadania', desc:'Rozpisz zadania, przypisz osoby i powiąż je z budżetem, dostawcą lub prezentem.' },

  { lvl:'b', view:'vendors', target:'#navVendors', title:'Dostawcy', desc:'Baza usługodawców — kontakty, umowy, raty płatności i powiązania z budżetem.' },

  { lvl:'b', view:'music', target:'#navMusic', title:'Muzyka', desc:'Twórz playlistę wesela i zbieraj propozycje utworów od gości.' },
  { lvl:'s', view:'music', sub:()=>switchMusicTab('list'),   target:'#mtab-list',   title:'Nasza lista', desc:'Wasza oficjalna lista utworów — to, co ma zagrać, i to, czego unikamy.' },
  { lvl:'s', view:'music', sub:()=>switchMusicTab('guests'), target:'#mtab-guests', title:'Propozycje gości', desc:'Utwory zaproponowane przez gości przez kod QR — zatwierdzaj je do listy.' },

  { lvl:'b', view:'gallery', target:'#navGallery', title:'Galeria & QR', desc:'Wspólna galeria zdjęć z wesela oraz kody QR do udostępniania gościom.' },

  { lvl:'b', view:'analytics', target:'#navAnalytics', title:'Analityka', desc:'Wykresy i statystyki organizacji — postępy, koszty i frekwencja na jednym ekranie.' },

  { lvl:'b', view:'transport', target:'#navTransport', title:'Transport', desc:'Zorganizuj dojazd gości — trasy, pojazdy i przypisanie pasażerów.' },

  { lvl:'b', view:'accommodation', target:'#navAccommodation', title:'Noclegi', desc:'Zarządzaj noclegami dla gości — obiekty, pokoje i rezerwacje.' },

  { lvl:'b', view:'gifts', target:'#navGifts', title:'Prezenty', desc:'Ewidencja prezentów otrzymanych, upominków dla gości i listy życzeń.' },
  { lvl:'s', view:'gifts', sub:()=>switchGiftsTab('received'),  target:'#gtab-received',  title:'Prezenty otrzymane', desc:'Zapisuj, co i od kogo dostaliście — przyda się przy podziękowaniach.' },
  { lvl:'s', view:'gifts', sub:()=>switchGiftsTab('forguests'), target:'#gtab-forguests', title:'Dla gości (upominki)', desc:'Planuj podziękowania i upominki, które wręczacie gościom.' },
  { lvl:'s', view:'gifts', sub:()=>switchGiftsTab('proposals'), target:'#gtab-proposals', title:'Propozycje (lista życzeń)', desc:'Wasza lista życzeń — podpowiedzcie gościom, co sprawi Wam radość.' },

  { lvl:'b', view:'config', target:'#settingsGearBtn', title:'Ustawienia / Konfiguracja', desc:'Tu ustawisz nazwę imprezy, datę, miejsca i pozostałe dane. Przewodnik wznowisz spod tego trybika. To już wszystko — powodzenia!' },
];
let _onbIndex = 0;
let _onbMode = 'full';      // 'basic' | 'full'
let _onbSteps = [];          // aktywna lista kroków (po filtrze trybu)

function _onboardingKey() {
  const email = (typeof _currentUserEmail === 'function' ? _currentUserEmail() : '') || 'anon';
  return 'weddingOnboardingDone:' + email;
}
function maybeStartOnboarding() {
  try { if (!localStorage.getItem(_onboardingKey())) startOnboarding(); } catch (_) {}
}
// Pokaż ekran powitalny z wyborem tempa
function startOnboarding() {
  const ov = document.getElementById('onboardingOverlay'); if (ov) ov.style.display = 'none';
  const intro = document.getElementById('onbIntro'); if (intro) intro.style.display = 'flex';
}
// Rozpocznij właściwy przewodnik w wybranym trybie
function onboardingBegin(mode) {
  _onbMode = (mode === 'basic') ? 'basic' : 'full';
  _onbSteps = ONB_ALL_STEPS.filter(s => _onbMode === 'full' ? true : s.lvl === 'b');
  _onbIndex = 0;
  const intro = document.getElementById('onbIntro'); if (intro) intro.style.display = 'none';
  _onbBindReposition();
  _onboardingShowStep();
}
function _onboardingShowStep() {
  const step = _onbSteps[_onbIndex];
  if (!step) { finishOnboarding(); return; }
  if (typeof closeSettingsMenu === 'function') try { closeSettingsMenu(); } catch (_) {}
  // Modal „Od czego zacząć?" — otwórz tylko na kroku, który go prezentuje; w innych krokach zamknij
  if (typeof closePlanningGuide === 'function') try { closePlanningGuide(); } catch (_) {}
  if (typeof switchView === 'function') try { switchView(step.view); } catch (_) {}
  if (step.sub) try { step.sub(); } catch (_) {}
  if (step.openPlanning && typeof openPlanningGuide === 'function') try { openPlanningGuide(); } catch (_) {}
  const set = (id, txt) => { const el = document.getElementById(id); if (el) el.textContent = txt; };
  set('onbTitle', step.title);
  set('onbDesc', step.desc);
  set('onbProgress', `Krok ${_onbIndex + 1} z ${_onbSteps.length}`);
  const prev = document.getElementById('onbPrevBtn'); if (prev) prev.style.display = _onbIndex > 0 ? '' : 'none';
  const next = document.getElementById('onbNextBtn'); if (next) next.innerHTML = (_onbIndex === _onbSteps.length - 1) ? 'Zakończ &#10003;' : 'Dalej &#8594;';
  const ov = document.getElementById('onboardingOverlay'); if (ov) ov.style.display = 'block';
  // Poczekaj na przerysowanie widoku/podzakładki, dopiero potem ustaw spotlight
  setTimeout(() => _onbPositionStep(step), 230);
}
function _onbPositionStep(step) {
  const spot = document.getElementById('onbSpotlight');
  const tip = document.getElementById('onbTooltip');
  if (!tip) return;
  const tEl = step.target ? document.querySelector(step.target) : null;
  const rect = tEl ? tEl.getBoundingClientRect() : null;
  const visible = !!(rect && rect.width > 2 && rect.height > 2 &&
                     rect.bottom > 0 && rect.right > 0 &&
                     rect.top < window.innerHeight && rect.left < window.innerWidth);
  if (!visible) {
    // Element niewidoczny (np. ukryty na wąskim ekranie) — wyśrodkuj dymek bez spotlightu
    if (spot) spot.style.display = 'none';
    tip.className = 'onb-tooltip onb-pos-center';
    tip.style.left = Math.max(12, (window.innerWidth - tip.offsetWidth) / 2) + 'px';
    tip.style.top = Math.max(12, (window.innerHeight - tip.offsetHeight) / 2) + 'px';
    return;
  }
  if (tEl.scrollIntoView) try { tEl.scrollIntoView({ block: 'center', inline: 'center', behavior: 'smooth' }); } catch (_) {}
  // Po ewentualnym przewinięciu zmierz ponownie i ustaw spotlight + dymek
  setTimeout(() => {
    const r = tEl.getBoundingClientRect();
    const pad = 6;
    if (spot) {
      spot.style.display = 'block';
      spot.style.left = (r.left - pad) + 'px';
      spot.style.top = (r.top - pad) + 'px';
      spot.style.width = (r.width + pad * 2) + 'px';
      spot.style.height = (r.height + pad * 2) + 'px';
    }
    _onbPlaceTooltip(r, tip);
  }, 240);
}
function _onbPlaceTooltip(r, tip) {
  const tw = tip.offsetWidth, th = tip.offsetHeight;
  const vw = window.innerWidth, vh = window.innerHeight;
  const gap = 16;
  const space = { right: vw - r.right, left: r.left, bottom: vh - r.bottom, top: r.top };
  let pos;
  if (space.right >= tw + gap) pos = 'right';
  else if (space.bottom >= th + gap) pos = 'bottom';
  else if (space.top >= th + gap) pos = 'top';
  else if (space.left >= tw + gap) pos = 'left';
  else pos = 'bottom';
  let left, top;
  if (pos === 'right') { left = r.right + gap; top = r.top + r.height / 2 - th / 2; }
  else if (pos === 'left') { left = r.left - gap - tw; top = r.top + r.height / 2 - th / 2; }
  else if (pos === 'bottom') { left = r.left + r.width / 2 - tw / 2; top = r.bottom + gap; }
  else { left = r.left + r.width / 2 - tw / 2; top = r.top - gap - th; }
  left = Math.max(12, Math.min(left, vw - tw - 12));
  top = Math.max(12, Math.min(top, vh - th - 12));
  tip.className = 'onb-tooltip onb-pos-' + pos;
  tip.style.left = left + 'px';
  tip.style.top = top + 'px';
  // Ustaw strzałkę tak, by wskazywała środek podświetlonego elementu (nawet po dosunięciu dymka)
  const arrow = document.getElementById('onbArrow');
  if (arrow) {
    if (pos === 'right' || pos === 'left') {
      let ay = (r.top + r.height / 2) - top;
      ay = Math.max(14, Math.min(ay, th - 14));
      arrow.style.top = ay + 'px'; arrow.style.marginTop = '-7px';
      arrow.style.left = ''; arrow.style.marginLeft = '';
    } else {
      let ax = (r.left + r.width / 2) - left;
      ax = Math.max(14, Math.min(ax, tw - 14));
      arrow.style.left = ax + 'px'; arrow.style.marginLeft = '-7px';
      arrow.style.top = ''; arrow.style.marginTop = '';
    }
  }
}
function onboardingNext() { if (_onbIndex >= _onbSteps.length - 1) finishOnboarding(); else { _onbIndex++; _onboardingShowStep(); } }
function onboardingPrev() { if (_onbIndex > 0) { _onbIndex--; _onboardingShowStep(); } }
function onboardingSkip() { finishOnboarding(); }
function finishOnboarding() {
  const ov = document.getElementById('onboardingOverlay'); if (ov) ov.style.display = 'none';
  const intro = document.getElementById('onbIntro'); if (intro) intro.style.display = 'none';
  const spot = document.getElementById('onbSpotlight'); if (spot) spot.style.display = 'none';
  if (typeof closePlanningGuide === 'function') try { closePlanningGuide(); } catch (_) {}
  _onbUnbindReposition();
  try { localStorage.setItem(_onboardingKey(), '1'); } catch (_) {}
}
// Reposycjonowanie spotlightu/dymka przy zmianie rozmiaru okna
let _onbRepoHandler = null;
function _onbBindReposition() {
  if (_onbRepoHandler) return;
  _onbRepoHandler = () => {
    const ov = document.getElementById('onboardingOverlay');
    if (!ov || ov.style.display === 'none') return;
    const step = _onbSteps[_onbIndex];
    if (step) _onbPositionStep(step);
  };
  window.addEventListener('resize', _onbRepoHandler);
}
function _onbUnbindReposition() {
  if (!_onbRepoHandler) return;
  window.removeEventListener('resize', _onbRepoHandler);
  _onbRepoHandler = null;
}

// ══════════════════════════════════════════════════════
//  PDF DO DRUKU — karty z kodami QR (galeria / harmonogram / połączony)
// ══════════════════════════════════════════════════════
// Osadzane fonty z polskimi znakami (TTF) — pobierane raz z CDN i cache'owane jako base64.
let _pdfFontReg = null;   // regular: null=nie próbowano, ''=nieudane, string=gotowy
let _pdfFontBold = null;  // bold
const _PDF_FONT_REG  = [
  'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/lato/Lato-Regular.ttf',
  'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/ptsans/PT_Sans-Web-Regular.ttf',
];
const _PDF_FONT_BOLD = [
  'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/lato/Lato-Bold.ttf',
  'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/ptsans/PT_Sans-Web-Bold.ttf',
];
function _abToBase64(buf) {
  let bin = ''; const bytes = new Uint8Array(buf); const CH = 0x8000;
  for (let i = 0; i < bytes.length; i += CH) bin += String.fromCharCode.apply(null, bytes.subarray(i, i + CH));
  return btoa(bin);
}
async function _fetchFontB64(urls) {
  for (const url of urls) {
    try { const res = await fetch(url); if (res.ok) return _abToBase64(await res.arrayBuffer()); } catch (_) {}
  }
  return '';
}
// Rejestruje fonty PL w dokumencie. Zwraca true jeśli przynajmniej regular dostępny.
async function _ensurePdfFont(doc) {
  if (_pdfFontReg === null)  _pdfFontReg  = await _fetchFontB64(_PDF_FONT_REG);
  if (_pdfFontBold === null) _pdfFontBold = await _fetchFontB64(_PDF_FONT_BOLD);
  let ok = false;
  if (_pdfFontReg) {
    try { doc.addFileToVFS('PLreg.ttf', _pdfFontReg); doc.addFont('PLreg.ttf', 'PL', 'normal'); ok = true; } catch (_) {}
  }
  if (_pdfFontBold) {
    try { doc.addFileToVFS('PLbold.ttf', _pdfFontBold); doc.addFont('PLbold.ttf', 'PL', 'bold'); } catch (_) {}
  }
  return ok;
}

// Standardowe fonty jsPDF nie wspierają polskich znaków — transliteracja na ASCII (fallback).
function _plAscii(s) {
  return String(s == null ? '' : s)
    .replace(/ą/g,'a').replace(/ć/g,'c').replace(/ę/g,'e').replace(/ł/g,'l').replace(/ń/g,'n')
    .replace(/ó/g,'o').replace(/ś/g,'s').replace(/ź/g,'z').replace(/ż/g,'z')
    .replace(/Ą/g,'A').replace(/Ć/g,'C').replace(/Ę/g,'E').replace(/Ł/g,'L').replace(/Ń/g,'N')
    .replace(/Ó/g,'O').replace(/Ś/g,'S').replace(/Ź/g,'Z').replace(/Ż/g,'Z');
}
const _PL_MONTHS_PDF = ['stycznia','lutego','marca','kwietnia','maja','czerwca','lipca','sierpnia','września','października','listopada','grudnia'];
function _printDateStr() {
  if (!weddingDate) return '';
  const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(weddingDate); if (!m) return '';
  return `${+m[3]} ${_PL_MONTHS_PDF[+m[2] - 1]} ${m[1]}`;
}
// Generuje data-URL kodu QR (przez bibliotekę qrcodejs) w tymczasowym, ukrytym elemencie
function _makeQrDataUrl(url, px) {
  return new Promise(resolve => {
    if (typeof QRCode === 'undefined') { resolve(null); return; }
    const tmp = document.createElement('div');
    tmp.style.cssText = 'position:fixed;left:-9999px;top:-9999px';
    document.body.appendChild(tmp);
    try { new QRCode(tmp, { text: url, width: px, height: px, correctLevel: QRCode.CorrectLevel.M }); } catch (_) {}
    setTimeout(() => {
      let data = null;
      const c = tmp.querySelector('canvas');
      if (c) { try { data = c.toDataURL('image/png'); } catch (_) {} }
      if (!data) { const img = tmp.querySelector('img'); if (img) data = img.src; }
      try { document.body.removeChild(tmp); } catch (_) {}
      resolve(data);
    }, 90);
  });
}
async function generatePrintPdf(variantArg, sizeArg) {
  if (!window.jspdf || !window.jspdf.jsPDF) { showToast('Biblioteka PDF nie została wczytana — sprawdź połączenie z internetem.'); return; }
  const variant = variantArg || document.getElementById('pdfVariant')?.value || 'gallery';
  const size    = ((sizeArg || document.getElementById('pdfSize')?.value) === 'a5') ? 'a5' : 'a4';
  const galUrl  = new URL('galeria.html', location.href).href;
  const schUrl  = new URL('harmonogram.html', location.href).href;
  const musUrl  = new URL('muzyka.html', location.href).href;

  showToast('Generuję PDF…');
  const items = [];
  if (variant === 'gallery' || variant === 'combined')
    items.push({ qr: await _makeQrDataUrl(galUrl, 640), title: 'Galeria zdjęć', cap: 'Zeskanuj i podziel się swoimi zdjęciami z naszego wesela' });
  if (variant === 'schedule' || variant === 'combined')
    items.push({ qr: await _makeQrDataUrl(schUrl, 640), title: 'Harmonogram dnia', cap: 'Zeskanuj i zobacz harmonogram naszego dnia' });
  if (variant === 'music' || variant === 'combined')
    items.push({ qr: await _makeQrDataUrl(musUrl, 640), title: 'Propozycje muzyki', cap: 'Zeskanuj i zaproponuj piosenki na nasze wesele' });
  // wariant „lista harmonogramu" — opcjonalny mały QR do pełnej wersji online
  const schListQr = (variant === 'scheduleList') ? await _makeQrDataUrl(schUrl, 420) : null;

  const { jsPDF } = window.jspdf;
  const doc = new jsPDF({ orientation: 'portrait', unit: 'mm', format: size });
  const pw  = doc.internal.pageSize.getWidth();
  const ph  = doc.internal.pageSize.getHeight();
  const big = (size === 'a4');
  const cx  = pw / 2;

  // Font z polskimi znakami (Lato); fallback do ASCII gdy brak internetu
  const plFont = await _ensurePdfFont(doc);
  const tx  = s => plFont ? String(s == null ? '' : s) : _plAscii(s);
  const F  = (bold) => { if (plFont) doc.setFont('PL', bold ? 'bold' : 'normal'); else doc.setFont(bold ? 'times' : 'helvetica', bold ? 'bold' : 'normal'); };

  const eventName = (appConfig && appConfig.eventName) || 'Nasze Wesele';
  const dateStr   = _printDateStr();
  const couple    = (budgetData && budgetData.coupleNames) || [];
  const realName  = v => { const s = (v || '').trim(); return (s && s !== 'Osoba 1' && s !== 'Osoba 2') ? s : ''; };
  const names     = [realName(couple[1]), realName(couple[0])].filter(Boolean).join(' & ');

  // ── Tło i ozdobne ramki ──
  doc.setFillColor(247, 251, 255); doc.rect(0, 0, pw, ph, 'F');                 // delikatne tło
  doc.setDrawColor(26, 86, 219);  doc.setLineWidth(0.9); doc.roundedRect(7, 7, pw - 14, ph - 14, 6, 6, 'S');   // ramka zewn.
  doc.setDrawColor(150, 195, 245); doc.setLineWidth(0.4); doc.roundedRect(11, 11, pw - 22, ph - 22, 4, 4, 'S'); // ramka wewn.
  // narożne ozdobniki (wektorowe — niezależne od glifów fontu)
  doc.setFillColor(150, 195, 245);
  [[17,17],[pw-17,17],[17,ph-17],[pw-17,ph-17]].forEach(([x,yy]) => { doc.circle(x, yy, 1.7, 'F'); });

  // ── Nagłówek ──
  let y = big ? 34 : 26;
  F(false); doc.setFontSize(big ? 12 : 10); doc.setTextColor(120, 150, 200);
  doc.text(tx('• Z radością zapraszamy •'), cx, y, { align: 'center' });
  y += big ? 14 : 11;
  F(true); doc.setFontSize(big ? 34 : 25); doc.setTextColor(16, 40, 80);
  doc.splitTextToSize(tx(eventName), pw - 40).forEach((ln, i) => { doc.text(ln, cx, y + i * (big ? 13 : 10), { align: 'center' }); });
  y += doc.splitTextToSize(tx(eventName), pw - 40).length * (big ? 13 : 10) + (big ? 2 : 1);
  if (names) { F(false); doc.setFontSize(big ? 15 : 12); doc.setTextColor(26, 86, 219); doc.text(tx(names), cx, y, { align: 'center' }); y += big ? 9 : 7; }
  if (dateStr) { F(false); doc.setFontSize(big ? 12 : 10); doc.setTextColor(110, 125, 155); doc.text(tx(dateStr), cx, y, { align: 'center' }); y += big ? 4 : 3; }
  // ozdobny separator z rombem
  doc.setDrawColor(150, 195, 245); doc.setLineWidth(0.5);
  doc.line(cx - (big?32:24), y + 4, cx - 5, y + 4); doc.line(cx + 5, y + 4, cx + (big?32:24), y + 4);
  doc.setFillColor(26, 86, 219); doc.triangle(cx, y + 2.5, cx - 2.2, y + 4, cx, y + 5.5, 'F'); doc.triangle(cx, y + 2.5, cx + 2.2, y + 4, cx, y + 5.5, 'F');
  y += big ? 14 : 11;

  // ── WARIANT: LISTA HARMONOGRAMU DLA GOŚCI (rzeczywiste wydarzenia, nie tylko QR) ──
  if (variant === 'scheduleList') {
    const _hexRgb = hex => { const m = /^#?([0-9a-f]{6})$/i.exec(hex || ''); if (!m) return [26, 86, 219]; const n = parseInt(m[1], 16); return [(n >> 16) & 255, (n >> 8) & 255, n & 255]; };
    const _newPage = () => {
      doc.addPage();
      doc.setFillColor(247, 251, 255); doc.rect(0, 0, pw, ph, 'F');
      doc.setDrawColor(26, 86, 219); doc.setLineWidth(0.9); doc.roundedRect(7, 7, pw - 14, ph - 14, 6, 6, 'S');
      return big ? 24 : 18;
    };
    const evs = (scheduleEvents || []).filter(ev => !ev.private).slice()
      .sort((a, b) => { const ah = a.hour < 6 ? a.hour + 24 : a.hour, bh = b.hour < 6 ? b.hour + 24 : b.hour; return (ah * 60 + a.minute) - (bh * 60 + b.minute); });
    F(true); doc.setFontSize(big ? 14 : 11); doc.setTextColor(26, 86, 219);
    doc.text(tx('Harmonogram dnia'), cx, y, { align: 'center' }); y += big ? 9 : 7;

    if (!evs.length) {
      F(false); doc.setFontSize(big ? 12 : 10); doc.setTextColor(110, 125, 155);
      doc.text(tx('Harmonogram zostanie wkrótce uzupełniony.'), cx, y, { align: 'center' });
    } else {
      const dotX = big ? 22 : 15, timeX = big ? 27 : 19, nameX = big ? 48 : 37;
      const rightW = pw - nameX - (big ? 18 : 12);
      const lineH = big ? 6.4 : 5.4;
      evs.forEach(ev => {
        const [r, g, b2] = _hexRgb((typeof SCHED_CATS !== 'undefined' && SCHED_CATS.find(c => c.name === ev.category) || {}).color);
        const hh = String(ev.hour).padStart(2, '0'), mm = String(ev.minute).padStart(2, '0');
        F(true); doc.setFontSize(big ? 11.5 : 9.5);
        const nameLines = doc.splitTextToSize(tx(ev.name || '(wydarzenie)'), rightW);
        const descLines = (ev.description || '').trim() ? doc.splitTextToSize(tx(ev.description), rightW) : [];
        const need = nameLines.length * lineH + descLines.length * (big ? 5 : 4.2) + (big ? 4 : 3);
        if (y + need > ph - 24) y = _newPage();
        doc.setFillColor(r, g, b2); doc.circle(dotX, y - 1.4, big ? 1.7 : 1.4, 'F');
        F(true); doc.setFontSize(big ? 11.5 : 9.5); doc.setTextColor(26, 86, 219); doc.text(`${hh}:${mm}`, timeX, y);
        F(true); doc.setTextColor(26, 40, 80); doc.text(nameLines, nameX, y);
        y += nameLines.length * lineH;
        if (descLines.length) { F(false); doc.setFontSize(big ? 9.5 : 8); doc.setTextColor(95, 110, 140); doc.text(descLines, nameX, y); y += descLines.length * (big ? 5 : 4.2); }
        y += (big ? 4 : 3);
      });
    }

    // opcjonalny mały QR do pełnej wersji online
    if (schListQr) {
      const q = big ? 30 : 24;
      if (y + q + 16 > ph - 16) y = _newPage();
      y += big ? 6 : 4;
      doc.setFillColor(255, 255, 255); doc.setDrawColor(150, 195, 245); doc.setLineWidth(0.5);
      doc.roundedRect(cx - q / 2 - 4, y, q + 8, q + 8, 3, 3, 'FD');
      try { doc.addImage(schListQr, 'PNG', cx - q / 2, y + 4, q, q); } catch (_) {}
      y += q + 10;
      F(false); doc.setFontSize(big ? 10 : 8.5); doc.setTextColor(110, 125, 155);
      doc.text(tx('Pełny harmonogram online — zeskanuj kod'), cx, y, { align: 'center' });
    }

    F(false); doc.setFontSize(big ? 10 : 8); doc.setTextColor(120, 140, 170);
    doc.text(tx(names ? `${names} • dziękujemy!` : 'Dziękujemy!'), cx, ph - 12, { align: 'center' });
    doc.save(`harmonogram-lista-${size}.pdf`);
    showToast(plFont ? 'PDF gotowy ✓' : 'PDF gotowy ✓ (font PL niedostępny — wersja ASCII)');
    return;
  }

  // ── Kody QR ──
  const two = items.length > 1;
  const qrSize  = items.length >= 3 ? (big ? 48 : 34) : two ? (big ? 66 : 46) : (big ? 92 : 64);
  const boxPad  = big ? 6 : 4;
  items.forEach(it => {
    if (two) { F(true); doc.setFontSize(big ? 14 : 11); doc.setTextColor(26, 86, 219); doc.text(tx(it.title), cx, y, { align: 'center' }); y += big ? 6 : 5; }
    // biała ramka pod QR (z subtelnym „cieniem")
    const bx = cx - qrSize / 2 - boxPad, by = y, bw = qrSize + boxPad * 2, bh = qrSize + boxPad * 2;
    doc.setFillColor(225, 234, 248); doc.roundedRect(bx + 1.2, by + 1.2, bw, bh, 3, 3, 'F');   // cień
    doc.setFillColor(255, 255, 255); doc.setDrawColor(150, 195, 245); doc.setLineWidth(0.5);
    doc.roundedRect(bx, by, bw, bh, 3, 3, 'FD');
    if (it.qr) { try { doc.addImage(it.qr, 'PNG', cx - qrSize / 2, by + boxPad, qrSize, qrSize); } catch (_) {} }
    y += bh + (big ? 7 : 5);
    F(false); doc.setFontSize(big ? 12 : 9.5); doc.setTextColor(50, 65, 95);
    const lines = doc.splitTextToSize(tx(it.cap), pw - (big ? 50 : 38));
    doc.text(lines, cx, y, { align: 'center' });
    y += lines.length * (big ? 5.6 : 4.6) + (big ? 12 : 9);
  });

  // ── Stopka ──
  F(false); doc.setFontSize(big ? 11 : 9); doc.setTextColor(150, 195, 245);
  doc.text('• • •', cx, ph - 20, { align: 'center' });
  F(false); doc.setFontSize(big ? 10 : 8); doc.setTextColor(120, 140, 170);
  doc.text(tx(names ? `${names} • dziękujemy!` : 'Dziękujemy!'), cx, ph - 14, { align: 'center' });

  doc.save(`${variant}-${size}.pdf`);
  showToast(plFont ? 'PDF gotowy ✓' : 'PDF gotowy ✓ (font PL niedostępny — wersja ASCII)');
}

function renderAccessList() {
  const cont = document.getElementById('accessList');
  if (!cont) return;
  const emails = (typeof ALLOWED_EMAILS !== 'undefined') ? ALLOWED_EMAILS : [];
  const me = _currentUserEmail();

  cont.innerHTML = emails.map(email => {
    const e = (email || '').toLowerCase();
    const blocked = _blockedEmailsAdmin.includes(e);
    const isMe = e === me;
    const statusBadge = blocked
      ? '<span class="acc-status acc-blocked">&#128683; Zablokowany</span>'
      : '<span class="acc-status acc-active">&#10003; Aktywny</span>';
    const meTag = isMe ? '<span class="acc-me">to Ty</span>' : '';

    let actionBtn;
    if (isMe) {
      actionBtn = '<button class="btn btn-sm" disabled title="Nie możesz zablokować własnego konta" style="opacity:.5;cursor:not-allowed">Zablokuj</button>';
    } else if (blocked) {
      actionBtn = `<button class="btn btn-sm btn-unblock" onclick="unblockEmail('${esc(e)}')">&#128275; Odblokuj</button>`;
    } else {
      actionBtn = `<button class="btn btn-sm btn-danger" onclick="blockEmail('${esc(e)}')">&#128683; Zablokuj</button>`;
    }

    return `<div class="acc-row ${blocked ? 'acc-row-blocked' : ''}">
      <div class="acc-info">
        <span class="acc-email">&#128231; ${esc(email)} ${meTag}</span>
        ${statusBadge}
      </div>
      <div class="acc-actions">${actionBtn}</div>
    </div>`;
  }).join('');
}

async function blockEmail(email) {
  const e = (email || '').toLowerCase();
  if (!e) return;
  if (e === _currentUserEmail()) { alert('Nie możesz zablokować własnego konta.'); return; }
  if (!confirm('Zablokować dostęp dla:\n' + email + '\n\nUżytkownik zostanie wylogowany i nie wejdzie do panelu, dopóki nie przywrócisz dostępu.')) return;
  try {
    await _accessRef().set({
      blockedEmails: firebase.firestore.FieldValue.arrayUnion(e),
    }, { merge: true });
    showToast('Dostęp zablokowany ✓');
  } catch (err) {
    console.error('Blokowanie emaila:', err);
    alert('Nie udało się zablokować. Spróbuj ponownie.');
  }
}

async function unblockEmail(email) {
  const e = (email || '').toLowerCase();
  if (!e) return;
  try {
    await _accessRef().set({
      blockedEmails: firebase.firestore.FieldValue.arrayRemove(e),
    }, { merge: true });
    showToast('Dostęp przywrócony ✓');
  } catch (err) {
    console.error('Odblokowanie emaila:', err);
    alert('Nie udało się odblokować. Spróbuj ponownie.');
  }
}

// ══════════════════════════════════════════════════════
//  KONFIGURACJA — edytowalne stałe napisy
// ══════════════════════════════════════════════════════
function cfg(key) {
  const v = appConfig && appConfig[key];
  return (v === undefined || v === null) ? (DEFAULT_APP_CONFIG[key] || '') : v;
}

// Zastosuj wartości konfiguracji w całej aplikacji (DOM)
function applyConfig() {
  const names    = cfg('displayNames') || 'Patrycji i Piotra';
  const eventNm  = cfg('eventName')    || DEFAULT_APP_CONFIG.eventName;
  const subtitle = cfg('subtitle')     || DEFAULT_APP_CONFIG.subtitle;

  // Tytuł karty
  document.title = eventNm;

  // Nagłówek aplikacji (z ikoną ślubną)
  const hdrTitle = document.getElementById('appHeaderTitle');
  if (hdrTitle) hdrTitle.innerHTML = WEDDING_ICON + ' ' + esc(eventNm) + ' ' + WEDDING_ICON;
  const hdrSub = document.getElementById('appHeaderSubtitle');
  if (hdrSub) hdrSub.textContent = subtitle;

  // Ekran logowania — „Ceremonia"
  const loginTitle = document.getElementById('loginTitle');
  if (loginTitle) loginTitle.innerHTML = 'Ceremonia<br>' + esc(names);
  const loginSub = document.getElementById('loginSubtitle');
  if (loginSub) loginSub.textContent = subtitle;

  // Tytuł w nawigacji mobilnej
  const navMobTitle = document.getElementById('navMobTitle');
  if (navMobTitle) navMobTitle.innerHTML = WEDDING_ICON + ' ' + esc(names);

  // Tytuł licznika na Dashboardzie
  const heroTitle = document.getElementById('dashboardTitle');
  if (heroTitle) heroTitle.innerHTML = WEDDING_ICON + ' ' + esc(WEDDING_HERO_TITLE);
}

function renderConfigView() {
  const c1 = (budgetData.coupleNames && budgetData.coupleNames[0]) || '';
  const c2 = (budgetData.coupleNames && budgetData.coupleNames[1]) || '';
  const set = (id, val) => { const el = document.getElementById(id); if (el) el.value = val; };
  set('cfgEventName',      cfg('eventName'));
  set('cfgPerson1',        c1);
  set('cfgPerson2',        c2);
  set('cfgWeddingDate',    weddingDate || '');
  set('cfgWeddingTime',    weddingTime || '16:00');
  set('cfgCeremonyPlace',  cfg('ceremonyPlace'));
  set('cfgReceptionPlace', cfg('receptionPlace'));
  set('cfgSubtitle',       cfg('subtitle'));
  set('cfgDisplayNames',   cfg('displayNames'));
  set('cfgMenuOptions',    (appConfig.menuOptions || []).join('\n'));
  set('cfgExpenseCategories', getExpenseCategories().join('\n'));
  try { renderBackupList(); } catch (_) {}
}

function saveConfig() {
  const val = id => (document.getElementById(id)?.value || '').trim();

  appConfig = Object.assign({}, appConfig, {
    eventName:      val('cfgEventName')      || DEFAULT_APP_CONFIG.eventName,
    subtitle:       val('cfgSubtitle')       || DEFAULT_APP_CONFIG.subtitle,
    displayNames:   val('cfgDisplayNames')   || DEFAULT_APP_CONFIG.displayNames,
    ceremonyPlace:  val('cfgCeremonyPlace'),
    receptionPlace: val('cfgReceptionPlace'),
    menuOptions:    (document.getElementById('cfgMenuOptions')?.value || '')
                      .split('\n').map(s => s.trim()).filter(Boolean),
    expenseCategories: (document.getElementById('cfgExpenseCategories')?.value || '')
                      .split('\n').map(s => s.trim()).filter(Boolean),
  });

  // Imiona Osoby 1/2 — wspólne ze splitem kosztów (budgetData.coupleNames)
  if (!budgetData.coupleNames) budgetData.coupleNames = ['Osoba 1', 'Osoba 2'];
  budgetData.coupleNames[0] = val('cfgPerson1') || 'Osoba 1';
  budgetData.coupleNames[1] = val('cfgPerson2') || 'Osoba 2';

  // Data i godzina ślubu — wpisywane tylko tutaj; licznik czyta globalne weddingDate / weddingTime
  weddingDate = val('cfgWeddingDate') || null;
  weddingTime = val('cfgWeddingTime') || '16:00';

  applyConfig();
  saveState();
  renderAll();
  if (typeof tickCountdown === 'function') tickCountdown();
  renderConfigView();
  showToast('Konfiguracja zapisana ✓');
}

// ── PODZAKŁADKI „STOŁY I GOŚCIE" (Plan stołów ↔ Kartoteka Gości ↔ Podsumowanie gości) ──
function switchTablesTab(tab) {
  currentTablesTab = (tab === 'card' || tab === 'summary') ? tab : 'plan';
  applyTablesTab();
}
function applyTablesTab() {
  const tab = currentTablesTab;
  const isMobile = window.innerWidth <= 768;
  const show = (el, on) => { if (el) el.style.display = on ? (isMobile ? 'block' : 'flex') : 'none'; };
  show(document.getElementById('tablesTabPlan'),    tab === 'plan');
  show(document.getElementById('tablesTabCard'),    tab === 'card');
  show(document.getElementById('tablesTabSummary'), tab === 'summary');
  document.getElementById('ttab-plan')?.classList.toggle('active',    tab === 'plan');
  document.getElementById('ttab-card')?.classList.toggle('active',    tab === 'card');
  document.getElementById('ttab-summary')?.classList.toggle('active', tab === 'summary');
  // Pasek statystyk pozostaje widoczny na każdej podzakładce (stałe miejsce pod nawigacją).
  if (tab !== 'plan' && typeof closeAllDrawers === 'function') closeAllDrawers(); // schowaj wysuwane panele par/personelu
  if (tab === 'card')    renderGuestCard();
  if (tab === 'summary') renderGuestSummary();
}

// ── KARTOTEKA GOŚCI (rozszerzone informacje) ──
// Przełącznik widoku: lista (jedna kolumna) ↔ kolumny (siatka 3 kolumn z pełnymi danymi).
function setGuestCardView(mode) {
  guestCardViewMode = (mode === 'cols') ? 'cols' : 'list';
  document.getElementById('gcvList')?.classList.toggle('active', guestCardViewMode === 'list');
  document.getElementById('gcvCols')?.classList.toggle('active', guestCardViewMode === 'cols');
  renderGuestCard();
}

function renderGuestCard() {
  const cont = document.getElementById('guestCardList');
  if (!cont) return;
  const cols = guestCardViewMode === 'cols';
  cont.className = cols ? 'guest-card-grid' : 'guest-card-list';
  if (!guests.length) {
    cont.innerHTML = '<div class="empty-list">Brak gości. Dodaj gości w podzakładce „Plan stołów".</div>';
    return;
  }
  const menuOpts = appConfig.menuOptions || [];
  const sorted = [...guests].sort((a, b) => fullName(a).localeCompare(fullName(b), 'pl'));
  cont.innerHTML = sorted.map(g => _guestCardHtml(g, menuOpts, cols)).join('');
}

// Buduje pojedynczą kartę gościa. W widoku kolumnowym dodaje blok z pełnymi danymi.
function _guestCardHtml(g, menuOpts, cols) {
  const opts = ['<option value="">— wybierz menu —</option>']
    .concat(menuOpts.map(m => `<option value="${esc(m)}"${g.menuChoice === m ? ' selected' : ''}>${esc(m)}</option>`)).join('');
  return `<div class="gcard${cols ? ' gcard-col' : ''}">
      <div class="gcard-hdr">
        ${avatarHtml(g, 'avatar-sm')}
        <div class="gcard-name">${esc(fullName(g))}</div>
        <span class="badge badge-cat">${esc(g.category)}</span>
      </div>
      ${cols ? _guestCardMeta(g) : ''}
      <div class="gcard-grid">
        <label class="gcard-field">
          <span>&#127869; Menu</span>
          <select onchange="updateGuestCardField(${g.id},'menuChoice',this.value)">${opts}</select>
        </label>
        <label class="gcard-field">
          <span>&#11088; Preferencje</span>
          <input type="text" value="${esc(g.preferences || '')}" placeholder="np. miejsce przy rodzinie" onchange="updateGuestCardField(${g.id},'preferences',this.value)">
        </label>
        <label class="gcard-field">
          <span>&#9888;&#65039; Alergie</span>
          <input type="text" value="${esc(g.allergies || '')}" placeholder="np. orzechy, gluten" onchange="updateGuestCardField(${g.id},'allergies',this.value)">
        </label>
        <label class="gcard-field gcard-field-wide">
          <span>&#128221; Notatki specjalne</span>
          <textarea rows="2" placeholder="Dodatkowe informacje…" onchange="updateGuestCardField(${g.id},'cardNotes',this.value)">${esc(g.cardNotes || '')}</textarea>
        </label>
      </div>
    </div>`;
}

// Blok pełnych danych gościa (tylko widok kolumnowy) — odczyt; edycja danych podstawowych w „Plan stołów".
function _guestCardMeta(g) {
  const inv = g.invitedBy === 'groom' ? '&#129309; Pan Młody'
            : g.invitedBy === 'bride'  ? '&#128144; Panna Młoda' : '';
  const table = g.tableId !== null
    ? (tables.find(t => t.id === g.tableId)?.name || 'Stół')
    : 'Nieprzypisany';
  const rows = [['&#127860; Stół', table]];
  if (inv)                                    rows.push(['&#128140; Zaproszenie', inv]);
  if (g.hasCompanion && (g.companionName || '').trim()) rows.push(['&#10133; Osoba towarzysząca', g.companionName.trim()]);
  if (g.witness)                              rows.push(['&#11088; Świadek', 'Tak']);
  if (g.needsAccommodation)                   rows.push(['&#127976; Nocleg', 'Potrzebny']);
  return `<div class="gcard-meta">${rows.map(([k, v]) =>
    `<div class="gcm-row"><span class="gcm-k">${k}</span><span class="gcm-v">${esc(v)}</span></div>`).join('')}</div>`;
}

function updateGuestCardField(id, field, value) {
  const g = guests.find(x => x.id === id);
  if (!g) return;
  g[field] = value;
  saveState();
}

// ══════════════════════════════════════════════════════════════════════
//  PODSUMOWANIE GOŚCI — preferencje i logistyka (tabela + filtry + eksport)
// ══════════════════════════════════════════════════════════════════════

// Status RSVP → etykieta + klasa „pigułki"
function _gsRsvp(gId) {
  const st = getGuestRsvpStatus(gId);
  if (st === 'attending')     return { key: 'attending',     label: 'Przyjdzie',       cls: 'gs-pill-yes' };
  if (st === 'not_attending') return { key: 'not_attending', label: 'Nie przyjdzie',   cls: 'gs-pill-no' };
  return { key: 'none', label: 'Brak odpowiedzi', cls: 'gs-pill-none' };
}
// „Z kim przychodzi": sam / z osobą towarzyszącą (imię) / w parze (z kim)
function _gsCompanion(g) {
  if (g.pairId != null) {
    const partner = guests.find(x => x.id !== g.id && x.pairId === g.pairId);
    return 'W parze' + (partner ? ` (${fullName(partner)})` : '');
  }
  if (g.hasCompanion) {
    const nm = (g.companionName || '').trim();
    return 'Z osobą towarzyszącą' + (nm ? ` (${nm})` : '');
  }
  return 'Sam';
}
// Transport: { has, own, label }
function _gsTransport(g) {
  if (g.ownTransport) return { has: true, own: true, label: 'Własny' };
  let v = (g.vehicleId != null) ? vehicles.find(x => x.id === g.vehicleId) : null;
  if (!v) v = vehicles.find(x => (x.guestIds || []).includes(g.id));
  if (v) {
    const desc = (v.description || '').trim();
    return { has: true, own: false, label: (v.type || 'Pojazd') + (desc ? ` (${desc})` : '') };
  }
  return { has: false, own: false, label: '—' };
}
// Nocleg: { needs, label }
function _gsAccom(g) {
  const hotel = (g.hotelId != null) ? hotels.find(h => h.id === g.hotelId) : null;
  if (hotel) return { needs: true, label: (hotel.name || 'Hotel') };
  if (g.needsAccommodation) return { needs: true, label: 'Potrzebuje (nieprzypisany)' };
  return { needs: false, label: '—' };
}
// Dieta specjalna / alergie (tekst)
function _gsDiet(g) {
  const parts = [];
  if (g.diet && g.diet !== 'standard') parts.push(dietLabel(g.diet, g.dietOther));
  if ((g.allergies || '').trim()) parts.push('Alergie: ' + g.allergies.trim());
  return parts.join(' · ');
}
// Stolik
function _gsTable(g) {
  if (g.tableId == null) return '—';
  const t = tables.find(x => x.id === g.tableId);
  return t ? (t.name || 'Stół') : '—';
}

// Lista gości po zastosowaniu filtrów (posortowana po nazwisku)
function _guestSummaryRows() {
  const f = guestSummaryFilters;
  const q = (f.search || '').trim().toLowerCase();
  return [...guests]
    .sort((a, b) => fullName(a).localeCompare(fullName(b), 'pl'))
    .filter(g => {
      if (q && !fullName(g).toLowerCase().includes(q)) return false;
      if (f.status !== 'all' && _gsRsvp(g.id).key !== f.status) return false;
      if (f.menu !== 'all') {
        const m = (g.menuChoice || '').trim();
        if (f.menu === '__none__') { if (m) return false; }
        else if (m !== f.menu) return false;
      }
      if (f.diet !== 'all') {
        const special = !!(g.diet && g.diet !== 'standard');
        if (f.diet === 'special'  && !special) return false;
        if (f.diet === 'standard' &&  special) return false;
      }
      if (f.transport !== 'all') {
        const t = _gsTransport(g);
        if (f.transport === 'own'       && !t.own) return false;
        if (f.transport === 'organized' && !(t.has && !t.own)) return false;
        if (f.transport === 'none'      &&  t.has) return false;
      }
      if (f.accom !== 'all') {
        const a = _gsAccom(g);
        if (f.accom === 'needs' && !a.needs) return false;
        if (f.accom === 'no'    &&  a.needs) return false;
      }
      return true;
    });
}

// Podsumowania zbiorcze (liczone po WSZYSTKICH gościach)
function _guestSummaryStats() {
  const s = { menu: {}, noMenu: 0, diets: {}, transOwn: 0, transOrg: 0, transNone: 0,
              accomNeeds: 0, accomAssigned: 0, att: 0, notAtt: 0, noRsvp: 0, total: guests.length };
  guests.forEach(g => {
    const m = (g.menuChoice || '').trim();
    if (m) s.menu[m] = (s.menu[m] || 0) + 1; else s.noMenu++;
    if (g.diet && g.diet !== 'standard') { const l = dietLabel(g.diet, g.dietOther); s.diets[l] = (s.diets[l] || 0) + 1; }
    const t = _gsTransport(g);
    if (t.own) s.transOwn++; else if (t.has) s.transOrg++; else s.transNone++;
    const a = _gsAccom(g);
    if (a.needs) { s.accomNeeds++; if (g.hotelId != null) s.accomAssigned++; }
    const st = _gsRsvp(g.id).key;
    if (st === 'attending') s.att++; else if (st === 'not_attending') s.notAtt++; else s.noRsvp++;
  });
  return s;
}

function _gsSel(v, cur) { return v === cur ? ' selected' : ''; }

// Renderuje całość: karty zbiorcze + pasek filtrów/eksport + tabelę
function renderGuestSummary() {
  const wrap = document.getElementById('guestSummaryContent');
  if (!wrap) return;
  _fillPlaceCardTableSelect();
  if (!guests.length) {
    wrap.innerHTML = '<div class="empty-list">Brak gości. Dodaj gości w podzakładce „Plan stołów".</div>';
    return;
  }
  const s = _guestSummaryStats();
  const f = guestSummaryFilters;

  const li = (label, n, muted) => `<li${muted ? ' class="gs-muted"' : ''}><span>${esc(label)}</span><b>${n}&times;</b></li>`;
  const menuItems = Object.keys(s.menu).sort((a, b) => a.localeCompare(b, 'pl')).map(k => li(k, s.menu[k])).join('')
    + (s.noMenu ? li('Bez wyboru menu', s.noMenu, true) : '')
    || '<li class="gs-muted"><span>Brak danych</span><b>0&times;</b></li>';
  const dietKeys = Object.keys(s.diets);
  const dietItems = dietKeys.length
    ? dietKeys.sort((a, b) => a.localeCompare(b, 'pl')).map(k => li(k, s.diets[k])).join('')
    : '<li class="gs-muted"><span>Brak diet specjalnych</span><b>0&times;</b></li>';

  const aggregates = `
    <div class="gs-aggregates">
      <div class="gs-agg-card">
        <div class="gs-agg-head">&#127869; Menu (co je)</div>
        <ul class="gs-agg-list">${menuItems}</ul>
      </div>
      <div class="gs-agg-card">
        <div class="gs-agg-head">&#129382; Diety specjalne <span class="gs-agg-badge">${s.total ? dietKeys.reduce((a, k) => a + s.diets[k], 0) : 0}</span></div>
        <ul class="gs-agg-list">${dietItems}</ul>
      </div>
      <div class="gs-agg-card">
        <div class="gs-agg-head">&#128663; Transport</div>
        <ul class="gs-agg-list">
          ${li('Własny', s.transOwn)}
          ${li('Zorganizowany', s.transOrg)}
          ${li('Bez transportu', s.transNone, true)}
        </ul>
      </div>
      <div class="gs-agg-card">
        <div class="gs-agg-head">&#127976; Nocleg</div>
        <ul class="gs-agg-list">
          ${li('Potrzebuje', s.accomNeeds)}
          ${li('Przypisani do hotelu', s.accomAssigned, true)}
        </ul>
      </div>
      <div class="gs-agg-card">
        <div class="gs-agg-head">&#9993; Potwierdzenia</div>
        <ul class="gs-agg-list">
          ${li('Przyjdzie', s.att)}
          ${li('Nie przyjdzie', s.notAtt)}
          ${li('Brak odpowiedzi', s.noRsvp, true)}
        </ul>
      </div>
    </div>`;

  const menuOpts = (appConfig.menuOptions || []);
  const menuSelOpts = ['<option value="all">Menu: wszystkie</option>']
    .concat(menuOpts.map(m => `<option value="${esc(m)}"${_gsSel(m, f.menu)}>${esc(m)}</option>`))
    .concat([`<option value="__none__"${_gsSel('__none__', f.menu)}>Bez wyboru menu</option>`]).join('');

  const toolbar = `
    <div class="gs-toolbar">
      <input type="text" class="gs-search" id="gsSearch" placeholder="&#128269; Szukaj po nazwisku…"
             value="${esc(f.search)}" oninput="setGuestSummaryFilter('search', this.value)">
      <select onchange="setGuestSummaryFilter('status', this.value)">
        <option value="all"${_gsSel('all', f.status)}>Status: wszyscy</option>
        <option value="attending"${_gsSel('attending', f.status)}>Przyjdzie</option>
        <option value="not_attending"${_gsSel('not_attending', f.status)}>Nie przyjdzie</option>
        <option value="none"${_gsSel('none', f.status)}>Brak odpowiedzi</option>
      </select>
      <select onchange="setGuestSummaryFilter('menu', this.value)">${menuSelOpts}</select>
      <select onchange="setGuestSummaryFilter('diet', this.value)">
        <option value="all"${_gsSel('all', f.diet)}>Dieta: wszystkie</option>
        <option value="special"${_gsSel('special', f.diet)}>Tylko specjalne</option>
        <option value="standard"${_gsSel('standard', f.diet)}>Tylko standardowa</option>
      </select>
      <select onchange="setGuestSummaryFilter('transport', this.value)">
        <option value="all"${_gsSel('all', f.transport)}>Transport: wszyscy</option>
        <option value="own"${_gsSel('own', f.transport)}>Własny</option>
        <option value="organized"${_gsSel('organized', f.transport)}>Zorganizowany</option>
        <option value="none"${_gsSel('none', f.transport)}>Bez transportu</option>
      </select>
      <select onchange="setGuestSummaryFilter('accom', this.value)">
        <option value="all"${_gsSel('all', f.accom)}>Nocleg: wszyscy</option>
        <option value="needs"${_gsSel('needs', f.accom)}>Potrzebuje</option>
        <option value="no"${_gsSel('no', f.accom)}>Bez noclegu</option>
      </select>
      <button class="btn btn-sm gs-reset-btn" onclick="resetGuestSummaryFilters()">&#10006; Wyczyść</button>
      <button class="btn btn-primary btn-sm gs-export-btn" onclick="exportGuestSummaryCSV()">&#11015; Eksportuj CSV</button>
    </div>
    <div id="gsTableHost"></div>`;

  wrap.innerHTML = aggregates + toolbar;
  renderGuestSummaryTable();
}

// Renderuje samą tabelę (wywoływane przy zmianie filtrów — nie resetuje pól filtrów ani fokusu)
function renderGuestSummaryTable() {
  const host = document.getElementById('gsTableHost');
  if (!host) return;
  const rows = _guestSummaryRows();
  const count = `<div class="gs-count">Wyświetlono <b>${rows.length}</b> z ${guests.length} gości</div>`;
  if (!rows.length) {
    host.innerHTML = count + '<div class="empty-list">Brak gości spełniających wybrane filtry.</div>';
    return;
  }
  const trs = rows.map(g => {
    const r = _gsRsvp(g.id);
    return `<tr>
      <td class="gs-name">${esc(fullName(g))}</td>
      <td><span class="gs-pill ${r.cls}">${r.label}</span></td>
      <td>${esc(_gsCompanion(g))}</td>
      <td>${esc((g.menuChoice || '').trim() || '—')}</td>
      <td>${esc(_gsDiet(g) || '—')}</td>
      <td>${esc(_gsTransport(g).label)}</td>
      <td>${esc(_gsAccom(g).label)}</td>
      <td>${esc(_gsTable(g))}</td>
    </tr>`;
  }).join('');
  host.innerHTML = count + `
    <div class="gs-table-wrap">
      <table class="gs-table">
        <thead><tr>
          <th>Imię i nazwisko</th><th>Status</th><th>Z kim przychodzi</th><th>Menu (co je)</th>
          <th>Dieta / alergie</th><th>Transport</th><th>Nocleg</th><th>Stolik</th>
        </tr></thead>
        <tbody>${trs}</tbody>
      </table>
    </div>`;
}

function setGuestSummaryFilter(key, value) {
  guestSummaryFilters[key] = value;
  renderGuestSummaryTable();
}
function resetGuestSummaryFilters() {
  guestSummaryFilters = { search: '', status: 'all', menu: 'all', diet: 'all', transport: 'all', accom: 'all' };
  renderGuestSummary();
}

// Eksport bieżącej (przefiltrowanej) listy do pliku CSV (separator „;", BOM dla Excela)
function _csvCell(v) {
  const sStr = String(v == null ? '' : v);
  return /[";\r\n]/.test(sStr) ? '"' + sStr.replace(/"/g, '""') + '"' : sStr;
}
function exportGuestSummaryCSV() {
  const rows = _guestSummaryRows();
  if (!rows.length) { showToast('Brak gości do wyeksportowania'); return; }
  const headers = ['Imię i nazwisko', 'Status potwierdzenia', 'Z kim przychodzi', 'Menu (co je)',
                   'Dieta / alergie', 'Transport', 'Nocleg', 'Stolik'];
  const data = rows.map(g => [
    fullName(g), _gsRsvp(g.id).label, _gsCompanion(g),
    (g.menuChoice || '').trim() || '—', _gsDiet(g) || '—',
    _gsTransport(g).label, _gsAccom(g).label, _gsTable(g),
  ]);
  const csv = [headers, ...data].map(r => r.map(_csvCell).join(';')).join('\r\n');
  const blob = new Blob(['﻿' + csv], { type: 'text/csv;charset=utf-8;' });
  const url  = URL.createObjectURL(blob);
  const d = new Date(); const pad = n => String(n).padStart(2, '0');
  const a = document.createElement('a');
  a.href = url;
  a.download = `podsumowanie-gosci_${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}.csv`;
  document.body.appendChild(a); a.click(); document.body.removeChild(a);
  setTimeout(() => URL.revokeObjectURL(url), 2000);
  showToast('📄 Wyeksportowano listę gości do CSV');
}

// ── LOCALSTORAGE ──
const STORAGE_KEY = 'wedding-planner-v2';

// Serializuje stan bieżącego (aktywnego) eventu
function _serializeState() {
  return {
    guests, tables, pairs, staffTables,
    nextGuestId, nextTableId, nextPairId,
    nextAddonId, nextMenuAddonId, nextExpenseId,
    nextScheduleId, nextTaskId, nextVendorId, nextRsvpId,
    nextGiftId, nextVehicleId, nextHotelId, nextPaymentId, nextInstallmentId,
    nextTableDecoId, nextStaffTableId, expenseOrder,
    roomName, roomMeta, roomElements, nextRoomElementId, budgetData, weddingDate, weddingTime, appConfig,
    scheduleEvents, tasks, vendors, rsvpEntries, gifts,
    giftsForGuests, nextGiftForId, giftProposals, nextProposalId, giftProposalsPublic, giftForGuestsBasis,
    vehicles, hotels, payments, transportNotes,
    internalTransport, nextInternalTransportId,
    locationLinksSeeded,
    songs, nextSongId, checklist, nextChecklistId,
    planningSteps, nextPlanningStepId,
  };
}

function saveState() {
  try {
    // Nie zapisuj, dopóki stan nie został w pełni wczytany — chroni stare dane przed nadpisaniem pustym stanem
    if (!_stateReady) return;
    // KLUCZOWE: nie zapisuj zmian, które właśnie przyszły z chmury (zdalnych).
    // renderAll() kończy się saveState(); gdyby zadziałał w trakcie stosowania zmiany
    // zdalnej, odesłałby ją z powrotem do Firestore → pętla/ping-pong między urządzeniami.
    if (window.__applyingRemote) return;
    // Pojedynczy, „płaski" zestaw danych aplikacji weselnej (bez podziału na eventy).
    const flat = _serializeState();
    flat._savedAt   = Date.now();
    flat._app       = 'wedding-planner';
    localStorage.setItem(STORAGE_KEY, JSON.stringify(flat));
    if (typeof firestoreSave === 'function') firestoreSave(flat);
  } catch (_) {}
}

// ── MENU USTAWIEŃ (prawy górny róg — trybik) ──
function toggleSettingsMenu() {
  const wrap = document.getElementById('settingsMenu');
  const bd = document.getElementById('settingsBackdrop');
  if (!wrap) return;
  const open = wrap.classList.toggle('open');
  if (bd) bd.classList.toggle('settings-bd-open', open);
}
function closeSettingsMenu() {
  const wrap = document.getElementById('settingsMenu');
  const bd = document.getElementById('settingsBackdrop');
  if (wrap) wrap.classList.remove('open');
  if (bd) bd.classList.remove('settings-bd-open');
}
function openSettingsView(view) {
  closeSettingsMenu();
  switchView(view);
}

// ── ROZWIJANE GRUPY NAWIGACJI (wąskie ekrany) ──
// Na niższych rozdzielczościach kategorie (Goście, Budżet, Organizacja, Logistyka)
// działają jak rozwijane listy — klik w nazwę kategorii pokazuje jej zakładki.
function toggleNavGroup(labelEl) {
  const group = labelEl.closest('.nav-group');
  if (!group) return;
  const willOpen = !group.classList.contains('nav-group-open');
  closeNavGroups();
  if (willOpen) group.classList.add('nav-group-open');
}
function closeNavGroups() {
  document.querySelectorAll('.nav-group.nav-group-open')
    .forEach(g => g.classList.remove('nav-group-open'));
}

// ── MENU KONTA (zwinięte dane logowania → avatar) ──
function toggleUserMenu() {
  const panel = document.getElementById('navUserPanel');
  if (!panel) return;
  const open = panel.classList.toggle('user-open');
  if (open) {
    const nm = document.getElementById('navUserName');
    const pn = document.getElementById('navUserPopName');
    if (nm && pn) pn.textContent = nm.textContent;
    closeSettingsMenu();
  }
}
function closeUserMenu() {
  const panel = document.getElementById('navUserPanel');
  if (panel) panel.classList.remove('user-open');
}

// Zamknij rozwinięte menu nawigacji/konta po kliknięciu poza nimi
document.addEventListener('click', (e) => {
  if (!e.target.closest('.nav-group'))   closeNavGroups();
  const panel = document.getElementById('navUserPanel');
  if (panel && panel.classList.contains('user-open') && !panel.contains(e.target)) closeUserMenu();
}, true);

const LEGACY_BACKUP_KEY = 'wedding-planner-v2:legacy';

// Czy stan zawiera jakiekolwiek istotne dane?
function _eventHasData(s) {
  if (!s || typeof s !== 'object') return false;
  const len = a => Array.isArray(a) && a.length;
  return len(s.guests) || len(s.tables) || len(s.scheduleEvents) || len(s.tasks) || len(s.vendors) ||
    len(s.gifts) || len(s.vehicles) || len(s.hotels) || len(s.staffTables) ||
    (s.budgetData && len(s.budgetData.expenses)) ||
    !!(s.appConfig && s.appConfig.eventName) || !!s.weddingDate;
}

// Wyodrębnia pojedynczy, „płaski" zestaw danych z dowolnego zapisu.
// Obsługuje stary kontener wielu eventów { events: {id: stan}, activeEventId } —
// migrując dane z eventu „default" (a w razie braku z aktywnego / dowolnego z danymi).
function _extractFlatState(obj) {
  if (!obj || typeof obj !== 'object') return {};
  if (obj.events && typeof obj.events === 'object') {
    const ev = obj.events;
    return (ev['default'] && _eventHasData(ev['default']) && ev['default'])
        || (ev[obj.activeEventId] && _eventHasData(ev[obj.activeEventId]) && ev[obj.activeEventId])
        || Object.values(ev).find(_eventHasData)
        || ev['default'] || ev[obj.activeEventId] || Object.values(ev)[0] || {};
  }
  return obj; // już płaski (pojedynczy zestaw danych)
}

function loadState() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) { _stateReady = true; return; } // brak danych — świeży start, można zapisywać

    let parsed;
    try { parsed = JSON.parse(raw); } catch (_) { _stateReady = true; return; }

    // Przed JAKĄKOLWIEK migracją utwórz datowaną kopię zapasową bieżących danych.
    if (_anyHasData(parsed)) { try { _backupBeforeMigration(raw); } catch (_) {} }

    const wasContainer = !!(parsed && parsed.events && typeof parsed.events === 'object');
    let flat = _extractFlatState(parsed);

    // Odzyskiwanie: jeśli wyodrębniony stan jest pusty, a istnieje kopia zapasowa danych — użyj jej.
    let _recovered = false;
    if (!_eventHasData(flat)) {
      try {
        const legacyRaw = localStorage.getItem(LEGACY_BACKUP_KEY);
        const legacyFlat = _extractFlatState(legacyRaw ? JSON.parse(legacyRaw) : null);
        if (_eventHasData(legacyFlat)) { flat = legacyFlat; _recovered = true; }
      } catch (_) {}
    }

    _applyEventState(flat || {});

    // Jeśli wczytano stary kontener wielu eventów lub odzyskano dane — utrwal w płaskiej strukturze,
    // by struktura eventów nie wróciła i pusty zapis nie nadpisał danych przy przeładowaniu.
    if (wasContainer || _recovered) { try { saveState(); } catch (_) {} }
  } catch (_) {
    // Awaryjny fallback: jeśli wczytanie zawiedzie, spróbuj odczytać dane bezpośrednio.
    try { _loadFlatFallback(); } catch (_) {}
  }
}

// Awaryjne wczytanie danych z kopii zapasowej lub głównego klucza (omija pełną logikę load).
function _loadFlatFallback() {
  let flat = null;
  for (const key of [LEGACY_BACKUP_KEY, STORAGE_KEY]) {
    try {
      const raw = localStorage.getItem(key);
      const cand = _extractFlatState(raw ? JSON.parse(raw) : null);
      if (_eventHasData(cand)) { flat = cand; break; }
    } catch (_) {}
  }
  if (!flat) { _stateReady = true; return; } // brak czegokolwiek do odzyskania
  _applyEventState(flat); // ustawia _stateReady = true po pełnym wczytaniu
  console.warn('[wedding-planner] Awaryjne wczytanie: użyto kopii zapasowej danych weselnych.');
}

// ════════════════════════════════════════════════════════════════════════
//  DIAGNOSTYKA, ODZYSKIWANIE I KOPIE ZAPASOWE DANYCH
//  Dostępne też z konsoli: scanLocalStorage(), scanFirestore(), recoverData()
// ════════════════════════════════════════════════════════════════════════
const BACKUP_PREFIX = 'backup_';
const MAX_BACKUPS    = 8;

// Czy obiekt (kontener wielu eventów LUB stary płaski zapis) zawiera jakiekolwiek dane?
function _anyHasData(obj) {
  if (!obj || typeof obj !== 'object') return false;
  if (obj.events && typeof obj.events === 'object') {
    return Object.keys(obj.events).some(id => _eventHasData(obj.events[id]));
  }
  return _eventHasData(obj);
}

// Krótki opis zawartości zapisu (do logów i listy kopii)
function _describeData(obj) {
  const s = (obj && obj.events && typeof obj.events === 'object')
    ? (obj.events[obj.activeEventId] || Object.values(obj.events).find(_eventHasData) || {})
    : (obj || {});
  const n = a => Array.isArray(a) ? a.length : 0;
  const exp = (s.budgetData && Array.isArray(s.budgetData.expenses)) ? s.budgetData.expenses.length : 0;
  const name = (s.appConfig && s.appConfig.eventName) || '';
  return `${name ? '„' + name + '" — ' : ''}gości:${n(s.guests)} stołów:${n(s.tables)} zadań:${n(s.tasks)} wydatków:${exp}`;
}

// WYMÓG 2: skanuje WSZYSTKIE klucze localStorage, loguje je i zwraca kandydatów z danymi.
function scanLocalStorage() {
  const all = [];
  const candidates = [];
  for (let i = 0; i < localStorage.length; i++) {
    const key = localStorage.key(i);
    const raw = localStorage.getItem(key);
    let parsed = null;
    try { parsed = JSON.parse(raw); } catch (_) {}
    const hasData = _anyHasData(parsed);
    if (hasData) candidates.push({ key, parsed, ts: _candidateTs(key, parsed) });
    all.push({ klucz: key, bajty: (raw || '').length, dane: hasData ? '✓ ' + _describeData(parsed) : '—' });
  }
  console.group('%c[wedding-planner] Skan localStorage — znaleziono ' + all.length + ' kluczy', 'font-weight:bold;color:#1a56db');
  try { console.table(all); } catch (_) { console.log(all); }
  console.log('Wszystkie klucze:', all.map(x => x.klucz));
  console.log('Klucze z danymi plannera:', candidates.map(c => c.key));
  console.groupEnd();
  return candidates;
}

// Wczytuje dowolny znaleziony zapis (płaski lub stary kontener eventów) jako główne dane aplikacji.
function _migrateParsedIntoEvents(parsed, sourceLabel) {
  _applyEventState(_extractFlatState(parsed));
  saveState();
  try { renderAll(); } catch (_) {}
  console.log('[wedding-planner] Wczytano dane ze źródła:', sourceLabel);
}

// Efektywny znacznik czasu kandydata: dla kluczy „backup_[timestamp]" bierzemy
// timestamp z nazwy klucza, w pozostałych przypadkach pole _savedAt zapisu.
function _candidateTs(key, parsed) {
  if (key && key.indexOf(BACKUP_PREFIX) === 0) {
    const t = parseInt(key.slice(BACKUP_PREFIX.length), 10);
    if (t) return t;
  }
  return (parsed && parsed._savedAt) || 0;
}

// WYMÓG 3: szuka danych wszędzie (localStorage → Firestore) i przywraca je; w razie braku — komunikat.
async function recoverData() {
  // 1) localStorage — niezależnie od nazwy klucza; wybierz zapis z NAJNOWSZYM
  //    znacznikiem czasu spośród tych z NIEPUSTYMI danymi (w tym kopie backup_*).
  const cands = scanLocalStorage();
  if (cands.length) {
    cands.sort((a, b) => b.ts - a.ts);
    const best = cands[0];
    try { _backupBeforeMigration(localStorage.getItem(STORAGE_KEY)); } catch (_) {}
    _migrateParsedIntoEvents(best.parsed, 'localStorage:' + best.key);
    const when = best.key.indexOf(BACKUP_PREFIX) === 0 ? new Date(best.ts).toLocaleString('pl-PL') : best.key;
    showToast('Przywrócono dane z: ' + best.key + (best.key.indexOf(BACKUP_PREFIX) === 0 ? ' (' + when + ')' : ''));
    return true;
  }
  // 2) Firestore — sprawdź główną i ewentualne inne ścieżki
  if (typeof scanFirestore === 'function') {
    try {
      const remote = await scanFirestore();
      if (_anyHasData(remote)) {
        _migrateParsedIntoEvents(remote, 'Firestore');
        showToast('Przywrócono dane z Firestore');
        return true;
      }
    } catch (_) {}
  }
  // 3) Nigdzie nie ma danych
  const msg = 'Brak danych - możliwe że zostały usunięte podczas migracji';
  console.warn('[wedding-planner] ' + msg);
  showToast(msg);
  return false;
}

// ── Kopie zapasowe (WYMÓG 4) ──
// Tworzy datowaną kopię zapasową „backup_[timestamp]" przed migracją (z deduplikacją i przycinaniem).
// Tworzymy kopię TYLKO gdy zapis faktycznie zawiera dane — pusty zapis nie może
// wyprzeć (przez przycinanie) starszej kopii z prawdziwymi danymi.
function _backupBeforeMigration(raw) {
  if (!raw) return;
  let parsed = null; try { parsed = JSON.parse(raw); } catch (_) {}
  if (!_anyHasData(parsed)) return; // nie archiwizuj pustego stanu
  const existing = _listBackups();
  if (existing.some(b => localStorage.getItem(b.key) === raw)) return; // identyczna kopia już jest
  try {
    localStorage.setItem(BACKUP_PREFIX + Date.now(), raw);
  } catch (_) {
    // Brak miejsca — usuń najstarszą kopię i spróbuj ponownie
    const all = _listBackups();
    if (all.length) { try { localStorage.removeItem(all[all.length - 1].key); localStorage.setItem(BACKUP_PREFIX + Date.now(), raw); } catch (_) {} }
  }
  _pruneBackups();
}
function _listBackups() {
  const out = [];
  for (let i = 0; i < localStorage.length; i++) {
    const k = localStorage.key(i);
    if (k && k.indexOf(BACKUP_PREFIX) === 0) out.push({ key: k, ts: parseInt(k.slice(BACKUP_PREFIX.length), 10) || 0 });
  }
  return out.sort((a, b) => b.ts - a.ts); // najnowsze pierwsze
}
function _pruneBackups() {
  _listBackups().slice(MAX_BACKUPS).forEach(b => { try { localStorage.removeItem(b.key); } catch (_) {} });
}

// Renderuje listę kopii zapasowych w Konfiguracji
function renderBackupList() {
  const box = document.getElementById('backupList');
  if (!box) return;
  const backups = _listBackups().slice(0, 3);   // pokazuj tylko 3 ostatnie zapisy
  if (!backups.length) { box.innerHTML = '<p class="backup-empty">Brak kopii zapasowych. Powstają automatycznie przed migracją danych.</p>'; return; }
  box.innerHTML = backups.map(b => {
    const d = new Date(b.ts);
    const when = isNaN(d.getTime()) ? b.key : d.toLocaleString('pl-PL');
    let summary = '';
    try { summary = _describeData(JSON.parse(localStorage.getItem(b.key))); } catch (_) {}
    return `<div class="backup-row">
      <div class="backup-info"><span class="backup-when">&#128190; ${esc(when)}</span><span class="backup-sum">${esc(summary)}</span></div>
      <button type="button" class="btn btn-sm" onclick="restoreBackup('${esc(b.key)}')">Przywróć</button>
    </div>`;
  }).join('');
}

// Przywraca wskazaną kopię zapasową (z UI „Przywróć kopię zapasową")
function restoreBackup(key) {
  const raw = localStorage.getItem(key);
  if (!raw) { showToast('Kopia nie istnieje'); renderBackupList(); return; }
  if (!confirm('Przywrócić kopię zapasową z „' + key + '"?\nBieżące dane zostaną zastąpione (najpierw powstanie ich kopia).')) return;
  let parsed;
  try { parsed = JSON.parse(raw); } catch (_) { showToast('Uszkodzona kopia zapasowa'); return; }
  try { _backupBeforeMigration(localStorage.getItem(STORAGE_KEY)); } catch (_) {}
  _migrateParsedIntoEvents(parsed, 'backup:' + key);
  showToast('Przywrócono kopię zapasową');
  renderBackupList();
}

// WYMÓG 2: znajdź najnowszą kopię „backup_[timestamp]" z NIEPUSTYMI danymi i przywróć ją.
function restoreLatestBackup() {
  const withData = _listBackups().filter(b => {  // _listBackups jest już posortowane malejąco po ts
    try { return _anyHasData(JSON.parse(localStorage.getItem(b.key))); } catch (_) { return false; }
  });
  if (!withData.length) {
    const msg = 'Brak kopii zapasowej z danymi - możliwe że dane zostały usunięte podczas migracji';
    console.warn('[wedding-planner] ' + msg);
    showToast(msg);
    return false;
  }
  const best = withData[0]; // największy timestamp z niepustymi danymi
  let parsed; try { parsed = JSON.parse(localStorage.getItem(best.key)); } catch (_) { return false; }
  try { _backupBeforeMigration(localStorage.getItem(STORAGE_KEY)); } catch (_) {}
  _migrateParsedIntoEvents(parsed, 'najnowsza kopia ' + best.key);
  showToast('Przywrócono najnowszą kopię z danymi (' + new Date(best.ts).toLocaleString('pl-PL') + ')');
  try { renderBackupList(); } catch (_) {}
  return true;
}

// ════════ EKSPORT / IMPORT DANYCH (lokalna kopia na dysku) ════════
// Eksport i import są dostępne wyłącznie jako przyciski w zakładce Konfiguracja —
// bez żadnych automatycznych powiadomień ani pop-upów.
const APP_VERSION = '2026.06.13-3';

// Buduje pełny, płaski zestaw danych aplikacji do eksportu/zapisu.
function _exportContainer() {
  const flat = _serializeState();
  flat._savedAt    = Date.now();
  flat._exportedAt = Date.now();
  flat._app        = 'wedding-planner';
  return flat;
}

// 1) Eksport wszystkich danych do pliku JSON na dysku
function exportData() {
  const json = JSON.stringify(_exportContainer(), null, 2);
  const blob = new Blob([json], { type: 'application/json' });
  const url  = URL.createObjectURL(blob);
  const d = new Date(); const pad = n => String(n).padStart(2, '0');
  const a = document.createElement('a');
  a.href = url;
  a.download = `wedding-planner_${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}_${pad(d.getHours())}${pad(d.getMinutes())}.json`;
  document.body.appendChild(a); a.click(); document.body.removeChild(a);
  setTimeout(() => URL.revokeObjectURL(url), 2000);
  showToast('💾 Wyeksportowano dane do pliku JSON');
}

// 2) Import danych z pliku JSON
function importData() {
  const inp = document.getElementById('importFileInput');
  if (inp) { inp.value = ''; inp.click(); }
}
function _handleImportFile(ev) {
  const file = ev.target.files && ev.target.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onerror = () => showToast('Nie udało się odczytać pliku');
  reader.onload = () => {
    let parsed;
    try { parsed = JSON.parse(reader.result); } catch (_) { showToast('Nieprawidłowy plik JSON'); return; }
    if (!parsed || typeof parsed !== 'object') { showToast('Plik nie zawiera danych aplikacji'); return; }
    const desc = _anyHasData(parsed) ? _describeData(parsed) : 'plik nie zawiera danych plannera';
    if (!confirm('Zaimportować dane z pliku „' + file.name + '"?\n' + desc + '\n\nBieżące dane zostaną zastąpione (najpierw powstanie ich kopia zapasowa).')) return;
    try { _backupBeforeMigration(localStorage.getItem(STORAGE_KEY)); } catch (_) {}
    _migrateParsedIntoEvents(parsed, 'import:' + file.name);
    showToast('📂 Zaimportowano dane z pliku');
    try { renderBackupList(); } catch (_) {}
  };
  reader.readAsText(file);
}

// Uruchamia pełną diagnostykę + próbę odzyskania (przycisk w Konfiguracji)
function runDataRecovery() {
  console.log('%c[wedding-planner] Diagnostyka danych — start', 'font-weight:bold;color:#059669');
  recoverData().then(() => renderBackupList());
}

// Udostępnij narzędzia z konsoli przeglądarki
try {
  window.scanLocalStorage    = scanLocalStorage;
  window.recoverData         = recoverData;
  window.restoreLatestBackup = restoreLatestBackup;
  window.exportData          = exportData;
  window.importData          = importData;
} catch (_) {}

// Wczytuje stan jednego eventu do zmiennych globalnych
function _applyEventState(s) {
  try {
    guests      = s.guests      || [];
    tables      = s.tables      || [];
    pairs       = s.pairs       || [];
    appConfig   = Object.assign({}, DEFAULT_APP_CONFIG, s.appConfig || {});
    nextGuestId     = s.nextGuestId     || 1;
    nextTableId     = s.nextTableId     || 1;
    nextPairId      = s.nextPairId      || 1;
    nextAddonId     = s.nextAddonId     || 1;
    nextMenuAddonId = s.nextMenuAddonId || 1;
    nextExpenseId   = s.nextExpenseId   || 1;
    roomName        = s.roomName        || 'Sala weselna';
    roomMeta        = Object.assign({ widthM: 0, lengthM: 0, tableDiameterM: 0 }, s.roomMeta || {});
    roomElements    = s.roomElements    || [];
    roomElements.forEach(el => {
      if (el.rotation === undefined) el.rotation = 0;
      if (el.type === undefined)     el.type = _elementType(el.name);
    });
    nextRoomElementId = s.nextRoomElementId || (roomElements.reduce((m, e) => Math.max(m, e.id + 1), 1));
    budgetData = s.budgetData || {
      total: 0, pricePerPerson: 0, venueMinGuests: 0,
      menuAddons: [], coupleNames: ['Osoba 1', 'Osoba 2'], expenses: []
    };
    if (budgetData.pricePerPerson === undefined)    budgetData.pricePerPerson = 0;
    if (budgetData.venueMinGuests === undefined)    budgetData.venueMinGuests = 0;
    if (!budgetData.menuAddons)                    budgetData.menuAddons   = [];
    if (!budgetData.coupleNames)                   budgetData.coupleNames  = ['Osoba 1', 'Osoba 2'];
    if (budgetData.includeVirtualInCalc === undefined) budgetData.includeVirtualInCalc = false;
    if (!budgetData.honeymoon) budgetData.honeymoon = { name:'', link:'', totalAmount:0, installments:[] };
    if (!budgetData.honeymoon.installments) budgetData.honeymoon.installments = [];
    nextHoneymoonInstId = budgetData.honeymoon.installments.reduce((m, i) => Math.max(m, i.id + 1), 1);
    expenseOrder = s.expenseOrder || [];
    budgetData.expenses.forEach(e => {
      if (e.splitP1        === undefined) e.splitP1        = 0;
      if (e.splitP2        === undefined) e.splitP2        = 0;
      if (e.customName     === undefined) e.customName     = '';
      if (e.estimatedAmount=== undefined) e.estimatedAmount= 0;
      if (e.sidePanel      === undefined) e.sidePanel       = false;
      if (!expenseOrder.includes(e.id))   expenseOrder.push(e.id);
    });
    expenseOrder = expenseOrder.filter(id => budgetData.expenses.some(e => e.id === id));
    payments.forEach(p => {
      if (p.estimatedAmount === undefined) p.estimatedAmount = 0;
    });
    if (budgetData.honeymoon.estimatedAmount === undefined) budgetData.honeymoon.estimatedAmount = 0;

    const bi = document.getElementById('budgetTotalInput');
    if (bi && budgetData.total) bi.value = budgetData.total;

    // Back-fill positions and new fields for tables saved without them
    tables.forEach((t, i) => {
      if (t.posX === undefined || t.posY === undefined) {
        const p = autoTablePos(i);
        t.posX = p.x;
        t.posY = p.y;
      }
      if (t.isHonorTable === undefined) t.isHonorTable = false;
      if (t.diamM === undefined)  t.diamM = 0;
      if (t.rectWM === undefined) t.rectWM = 0;
      if (t.rectLM === undefined) t.rectLM = 0;
    });

    // Back-fill new fields
    guests.forEach(g => {
      if (g.invitedBy === undefined)           g.invitedBy = null;
      if (g.witness === undefined)             g.witness = null;
      if (g.diet === undefined)                g.diet = 'standard';
      if (g.dietOther === undefined)           g.dietOther = '';
      if (g.hasCompanion === undefined)        g.hasCompanion = false;
      if (g.companionName === undefined)       g.companionName = '';
      if (g.needsAccommodation === undefined)  g.needsAccommodation = false;
      if (g.vehicleId === undefined)           g.vehicleId = null;
      if (g.ownTransport === undefined)        g.ownTransport = false;
      if (g.hotelId === undefined)             g.hotelId = null;
      if (g.accommodationStatus === undefined) g.accommodationStatus = null;
      if (g.menuChoice === undefined)          g.menuChoice = '';
      if (g.preferences === undefined)         g.preferences = '';
      if (g.allergies === undefined)           g.allergies = '';
      if (g.cardNotes === undefined)           g.cardNotes = '';
    });
    if (!Array.isArray(appConfig.menuOptions)) appConfig.menuOptions = DEFAULT_APP_CONFIG.menuOptions.slice();

    // Load new sections
    weddingDate    = s.weddingDate    || null;
    weddingTime    = s.weddingTime    || '16:00';
    scheduleEvents = s.scheduleEvents || [];
    tasks          = s.tasks          || [];
    tasks.forEach(t => {
      if (t.startDate === undefined) t.startDate = '';
      if (t.endDate === undefined)   t.endDate = '';
      if (t.priority === undefined)  t.priority = 'med';
      if (t.linkType === undefined)  t.linkType = '';
      if (t.linkId === undefined)    t.linkId = null;
      if (t.status === undefined)    t.status = 'todo';
      // Nowe pola: przypisanie + referencje + budżet
      if (t.assigneeName === undefined)    t.assigneeName = '';
      if (t.vendorId === undefined)        t.vendorId = null;
      if (t.giftId === undefined)          t.giftId = null;
      if (t.isBudgetLinked === undefined)  t.isBudgetLinked = false;
      if (t.estimatedCost === undefined)   t.estimatedCost = 0;
      if (t.budgetCategory === undefined)  t.budgetCategory = '';
      if (t.budgetExpenseId === undefined) t.budgetExpenseId = null;
      // Migracja starego powiązania (linkType/linkId) → nowe pola
      if (t.linkType && t.linkId != null) {
        if (t.linkType === 'vendor' && t.vendorId == null) t.vendorId = t.linkId;
        else if (t.linkType === 'gift' && t.giftId == null) t.giftId = t.linkId;
        else if (t.linkType === 'budget' && t.budgetExpenseId == null) {
          t.isBudgetLinked = true;
          t.budgetExpenseId = t.linkId;
          const e = (budgetData.expenses || []).find(x => x.id === t.linkId);
          if (e) { t.estimatedCost = e.estimatedAmount || e.planned || 0; t.budgetCategory = e.category || 'Inne'; }
        }
        t.linkType = ''; t.linkId = null;
      }
    });
    vendors        = s.vendors        || [];
    rsvpEntries    = s.rsvpEntries    || [];
    rsvpEntries.forEach(e => { if (e.companionName === undefined) e.companionName = ''; });
    gifts          = s.gifts          || [];
    // Upominki dla gości + propozycje (lista życzeń)
    giftsForGuests = Array.isArray(s.giftsForGuests) ? s.giftsForGuests : [];
    giftsForGuests.forEach(it => { if (!Array.isArray(it.guestIds)) it.guestIds = []; if (it.qty === undefined) it.qty = 1; if (it.cost === undefined) it.cost = 0; });
    nextGiftForId  = s.nextGiftForId  || (giftsForGuests.reduce((m, x) => Math.max(m, (x.id || 0) + 1), 1));
    giftForGuestsBasis = (s.giftForGuestsBasis === 'real' || s.giftForGuestsBasis === 'realvirtual') ? s.giftForGuestsBasis : '';
    giftProposals  = Array.isArray(s.giftProposals) ? s.giftProposals : [];
    giftProposalsPublic = !!s.giftProposalsPublic;
    // Widoczność per propozycja — migracja ze starej globalnej flagi
    giftProposals.forEach(p => { if (p.showToGuests === undefined) p.showToGuests = giftProposalsPublic; });
    nextProposalId = s.nextProposalId || (giftProposals.reduce((m, x) => Math.max(m, (x.id || 0) + 1), 1));
    vehicles       = s.vehicles       || [];
    vehicles.forEach(v => { if (v.cost === undefined) v.cost = 0; });
    hotels         = s.hotels         || [];
    payments       = s.payments       || [];
    transportNotes = s.transportNotes || { weddingCar: '', parking: '' };
    internalTransport = s.internalTransport || [];
    nextInternalTransportId = s.nextInternalTransportId || (internalTransport.reduce((m, i) => Math.max(m, i.id + 1), 1));

    nextScheduleId    = s.nextScheduleId    || 1;
    nextTaskId        = s.nextTaskId        || 1;
    nextVendorId      = s.nextVendorId      || 1;
    nextRsvpId        = s.nextRsvpId        || 1;
    nextGiftId        = s.nextGiftId        || 1;
    nextVehicleId     = s.nextVehicleId     || 1;
    nextHotelId       = s.nextHotelId       || 1;
    nextPaymentId     = s.nextPaymentId     || 1;
    nextInstallmentId = s.nextInstallmentId || 1;
    nextTableDecoId   = s.nextTableDecoId   || 1;
    nextStaffTableId  = s.nextStaffTableId  || 1;
    staffTables       = s.staffTables       || [];
    staffTables.forEach((t, i) => {
      if (t.posX === undefined || t.posY === undefined) { const p = autoStaffTablePos(i); t.posX = p.x; t.posY = p.y; }
      if (t.includeInCost === undefined) t.includeInCost = false;
    });

    if (!budgetData.alcoholItems)                    budgetData.alcoholItems    = [];
    if (budgetData.alcoholPanelHidden === undefined) budgetData.alcoholPanelHidden = false;
    if (!budgetData.nextAlcoholId)                   budgetData.nextAlcoholId   = 1;
    if (budgetData.alcoholSplitP1 === undefined)     budgetData.alcoholSplitP1  = 0;
    if (budgetData.alcoholSplitP2 === undefined)     budgetData.alcoholSplitP2  = 0;
    if (budgetData.alcoholPerPersonVirtual === undefined) budgetData.alcoholPerPersonVirtual = false;
    // Napoje bezalkoholowe
    if (!Array.isArray(budgetData.softItems))        budgetData.softItems       = [];
    if (!budgetData.nextSoftId)                      budgetData.nextSoftId      = 1;
    if (budgetData.softSplitP1 === undefined)        budgetData.softSplitP1     = 0;
    if (budgetData.softSplitP2 === undefined)        budgetData.softSplitP2     = 0;
    if (budgetData.softPerPersonVirtual === undefined) budgetData.softPerPersonVirtual = false;
    if (!budgetData.tableDeco) budgetData.tableDeco = { honorAddons: [], regularAddons: [] };
    if (budgetData.includeStaffInCalc === undefined) budgetData.includeStaffInCalc = false;
    if (!budgetData.tableDeco.honorAddons)   budgetData.tableDeco.honorAddons   = [];
    if (!budgetData.tableDeco.regularAddons) budgetData.tableDeco.regularAddons = [];

    scheduleEvents.forEach(ev => {
      if (ev.duration === undefined) ev.duration = 60;
      if (ev.private === undefined) ev.private = false;
      if (ev.locationUrl === undefined) ev.locationUrl = '';
      if (ev.showLinkToGuests === undefined) ev.showLinkToGuests = false;
    });
    locationLinksSeeded = s.locationLinksSeeded || false;

    // Muzyka: lista piosenek
    songs = Array.isArray(s.songs) ? s.songs : [];
    songs.forEach(sg => {
      if (sg.moment === undefined) sg.moment = 'Inne';
      if (sg.status === undefined) sg.status = 'proposal';
      if (sg.genre === undefined)  sg.genre = '';
      if (sg.fromGuest === undefined) sg.fromGuest = false;
      if (sg.unmatched === undefined) sg.unmatched = false;   // utwór bez dopasowania w Deezer (do weryfikacji)
    });
    nextSongId = s.nextSongId || (songs.reduce((m, x) => Math.max(m, (x.id || 0) + 1), 1));

    // Checklista na dzień ślubu
    checklist = Array.isArray(s.checklist) ? s.checklist : [];
    checklist.forEach(it => { if (it.done === undefined) it.done = false; if (!it.category) it.category = CHECKLIST_CATEGORIES[0]; });
    nextChecklistId = s.nextChecklistId || (checklist.reduce((m, x) => Math.max(m, (x.id || 0) + 1), 1));

    // „Od czego zacząć?" — sugerowana kolejność planowania (z domyślną listą przy pierwszym uruchomieniu)
    if (Array.isArray(s.planningSteps)) {
      planningSteps = s.planningSteps;
    } else {
      planningSteps = DEFAULT_PLANNING_STEPS.map((d, i) => ({ id: i + 1, label: d.label, note: d.note || '', done: false }));
    }
    planningSteps.forEach(st => { if (st.done === undefined) st.done = false; if (st.note === undefined) st.note = ''; });
    nextPlanningStepId = s.nextPlanningStepId || (planningSteps.reduce((m, x) => Math.max(m, (x.id || 0) + 1), 1));
    vendors.forEach(v => {
      if (v.customCategory === undefined) v.customCategory = '';
      if (v.mapUrl === undefined) v.mapUrl = '';
      if (v.isBudgetLinked === undefined)  v.isBudgetLinked = false;
      if (v.contractAmount === undefined)  v.contractAmount = 0;
      if (v.budgetCategory === undefined)  v.budgetCategory = '';
      if (v.budgetExpenseId === undefined) v.budgetExpenseId = null;
      if (!Array.isArray(v.installments))  v.installments = [];
    });
    hotels.forEach(h => { if (h.personsPerRoom === undefined) h.personsPerRoom = 2; if (h.inComplex === undefined) h.inComplex = false; });

    // Data ślubu — odśwież licznik (edytowana wyłącznie w Konfiguracji)
    if (typeof tickCountdown === 'function') tickCountdown();

    // Restore transport notes
    const carNote  = document.getElementById('weddingCarNote');
    const parkNote = document.getElementById('parkingNote');
    if (carNote)  carNote.value  = transportNotes.weddingCar  || '';
    if (parkNote) parkNote.value = transportNotes.parking || '';

    const input = document.getElementById('roomNameInput');
    if (input) input.value = roomName;
    // Przywróć wymiary sali / średnicę stołów
    const _setVal = (id, v) => { const el = document.getElementById(id); if (el) el.value = v || ''; };
    _setVal('roomWidthInput',  roomMeta.widthM        || '');
    _setVal('roomLengthInput', roomMeta.lengthM       || '');
    _setVal('roomTableDiamInput', roomMeta.tableDiameterM || '');

    // Migracja linków do map (raz na zestaw danych — także po synchronizacji z Firestore)
    try { seedLocationLinks(); } catch (_) {}

    // Zastosuj konfigurowalne napisy w całej aplikacji
    try { applyConfig(); } catch (_) {}

    _stateReady = true; // stan w pełni wczytany — bezpiecznie można zapisywać
  } catch (_) {}
}

// ══════════════════════════════════════════════════════════════════════
//  ANALITYKA — wykresy Chart.js (klikalne, otwierają się w powiększeniu)
// ══════════════════════════════════════════════════════════════════════
const ANALYTICS_BLUES = ['#1a56db','#3b82f6','#76b5f7','#1040b0','#60a5fa','#2563eb','#93c5fd','#0ea5e9','#6366f1','#818cf8','#38bdf8','#a5b4fc'];
let _analyticsCharts = {};   // id canvasa → instancja Chart.js
let _analyticsModalChart = null;

// Dane do wykresów — wspólne źródło dla kafelków i powiększenia
function _analyticsData(type) {
  if (type === 'expenseCat') {
    const grouped = {};
    const add = (cat, v) => { if (v > 0) grouped[cat] = (grouped[cat] || 0) + v; };
    add('Catering', calcCateringTotal());
    budgetData.expenses.forEach(e => add(_expenseLabel(e), e.planned || _payEffective(0, e.estimatedAmount || 0)));
    add('Alkohol', calcAlcoholTotal());
    add('Napoje', calcSoftTotal());
    const h = budgetData.honeymoon || {};
    add('Podróż poślubna', h.totalAmount || h.estimatedAmount || 0);
    add('Hotele', calcHotelsTotal());
    add('Transport', calcTransportTotal());
    add('Dostawcy', calcVendorsExternalTotal());
    const labels = Object.keys(grouped).filter(k => grouped[k] > 0);
    return { labels, values: labels.map(k => grouped[k]) };
  }
  if (type === 'guestStatus') {
    let att = 0, no = 0, none = 0;
    guests.forEach(g => { const k = getGuestRsvpStatus(g.id); if (k === 'attending') att++; else if (k === 'not_attending') no++; else none++; });
    return { labels: ['Przyjdzie', 'Nie przyjdzie', 'Brak odpowiedzi'], values: [att, no, none], colors: ['#16a34a', '#dc2626', '#94a3b8'] };
  }
  if (type === 'menu') {
    const m = {};
    guests.forEach(g => { const c = (g.menuChoice || '').trim() || 'Bez wyboru'; m[c] = (m[c] || 0) + 1; });
    const labels = Object.keys(m);
    return { labels, values: labels.map(k => m[k]) };
  }
  if (type === 'diet') {
    const d = {};
    guests.forEach(g => { if (g.diet && g.diet !== 'standard') { const l = dietLabel(g.diet, g.dietOther); d[l] = (d[l] || 0) + 1; } });
    const std = guests.filter(g => !g.diet || g.diet === 'standard').length;
    if (std) d['Standardowa'] = std;
    const labels = Object.keys(d);
    return { labels, values: labels.map(k => d[k]) };
  }
  if (type === 'payTimeline') {
    // Suma opłat wg miesiąca (z wydatków: paymentDate; z płatności: date)
    const byMonth = {};
    const addD = (dateStr, amt) => {
      if (!dateStr || !amt) return;
      const m = /^(\d{4})-(\d{2})/.exec(dateStr);
      const key = m ? `${m[1]}-${m[2]}` : dateStr;
      byMonth[key] = (byMonth[key] || 0) + amt;
    };
    budgetData.expenses.forEach(e => addD(e.paymentDate, e.paid || 0));
    (payments || []).forEach(p => addD(p.date, p.amount || 0));
    (budgetData.honeymoon?.installments || []).forEach(i => addD(i.date, i.amount || 0));
    const labels = Object.keys(byMonth).sort();
    // skumulowane
    let cum = 0;
    const values = labels.map(k => (cum += byMonth[k]));
    return { labels, values, raw: labels.map(k => byMonth[k]) };
  }
  if (type === 'budgetCompare') {
    const catering = calcCateringTotal();
    const ext = calcExternalTotal();
    const planned   = catering + calcExpensesPlanned()   + (budgetData.honeymoon?.totalAmount || 0) + ext;
    const effective = catering + calcExpensesEffective() + _payEffective(budgetData.honeymoon?.totalAmount || 0, budgetData.honeymoon?.estimatedAmount || 0) + ext;
    const paid      = calcExpensesPaid() + calcHoneymoonPaid() + calcVendorsExternalPaid();
    return { labels: ['Planowany', 'Opłacony', 'Przewidywany'], values: [planned, paid, effective], colors: ['#1a56db', '#16a34a', '#f59e0b'] };
  }
  return { labels: [], values: [] };
}

// Konfiguracja wykresu Chart.js dla danego typu
function _analyticsChartConfig(type, big) {
  const d = _analyticsData(type);
  const isMoney = (type === 'expenseCat' || type === 'payTimeline' || type === 'budgetCompare');
  const colors = d.colors || d.labels.map((_, i) => ANALYTICS_BLUES[i % ANALYTICS_BLUES.length]);
  const moneyTip = (ctx) => `${ctx.label}: ${fmt(ctx.parsed.y ?? ctx.parsed)} zł`;
  const common = {
    responsive: true, maintainAspectRatio: false,
    plugins: { legend: { display: false } },
  };
  if (type === 'expenseCat' || type === 'guestStatus' || type === 'menu' || type === 'diet') {
    return {
      type: 'doughnut',
      data: { labels: d.labels, datasets: [{ data: d.values, backgroundColor: colors, borderColor: '#fff', borderWidth: 2 }] },
      options: Object.assign({}, common, {
        plugins: {
          legend: { display: true, position: big ? 'right' : 'bottom', labels: { boxWidth: 12, font: { size: big ? 14 : 11 } } },
          tooltip: { callbacks: { label: ctx => isMoney ? `${ctx.label}: ${fmt(ctx.parsed)} zł` : `${ctx.label}: ${ctx.parsed}` } },
        },
      }),
    };
  }
  if (type === 'payTimeline') {
    return {
      type: 'line',
      data: { labels: d.labels, datasets: [
        { label: 'Skumulowane opłaty', data: d.values, borderColor: '#1a56db', backgroundColor: 'rgba(26,86,219,0.12)', fill: true, tension: 0.25, pointRadius: big ? 4 : 2 },
      ] },
      options: Object.assign({}, common, {
        plugins: { legend: { display: true, position: 'top' }, tooltip: { callbacks: { label: moneyTip } } },
        scales: { y: { ticks: { callback: v => v >= 1000 ? (v/1000) + 'k' : v } } },
      }),
    };
  }
  // budgetCompare — słupkowy
  return {
    type: 'bar',
    data: { labels: d.labels, datasets: [{ data: d.values, backgroundColor: colors, borderRadius: 6 }] },
    options: Object.assign({}, common, {
      plugins: { legend: { display: false }, tooltip: { callbacks: { label: moneyTip } } },
      scales: { y: { ticks: { callback: v => v >= 1000 ? (v/1000) + 'k' : v } } },
    }),
  };
}

function _renderAnalyticsChart(canvasId, type) {
  const cv = document.getElementById(canvasId);
  if (!cv || typeof Chart === 'undefined') return;
  if (_analyticsCharts[canvasId]) { _analyticsCharts[canvasId].destroy(); delete _analyticsCharts[canvasId]; }
  const d = _analyticsData(type);
  const hasData = d.values.some(v => v > 0);
  const wrap = cv.closest('.analytics-canvas-wrap');
  let empty = wrap ? wrap.querySelector('.chart-empty') : null;
  if (!hasData) {
    cv.style.display = 'none';
    if (wrap && !empty) { empty = document.createElement('div'); empty.className = 'chart-empty'; empty.textContent = 'Brak danych'; wrap.appendChild(empty); }
    return;
  }
  cv.style.display = '';
  if (empty) empty.remove();
  _analyticsCharts[canvasId] = new Chart(cv.getContext('2d'), _analyticsChartConfig(type, false));
}

function renderAnalytics() {
  if (typeof Chart === 'undefined') {
    const grid = document.getElementById('analyticsGrid');
    if (grid) grid.innerHTML = '<div class="chart-empty">Biblioteka wykresów nie została wczytana (sprawdź połączenie z internetem).</div>';
    return;
  }
  // Statystyki liczbowe na górze
  const statsEl = document.getElementById('analyticsStats');
  if (statsEl) {
    const guestCount = guests.length || 0;
    const catering = calcCateringTotal();
    const totalPlanned = catering + calcExpensesPlanned() + (budgetData.honeymoon?.totalAmount || 0) + calcExternalTotal();
    const totalEffective = catering + calcExpensesEffective() + _payEffective(budgetData.honeymoon?.totalAmount || 0, budgetData.honeymoon?.estimatedAmount || 0) + calcExternalTotal();
    const perGuest = guestCount ? totalPlanned / guestCount : 0;
    const att = guests.filter(g => getGuestRsvpStatus(g.id) === 'attending').length;
    const stat = (icon, label, val) => `<div class="analytics-stat"><div class="as-icon">${icon}</div><div class="as-body"><div class="as-val">${val}</div><div class="as-label">${label}</div></div></div>`;
    statsEl.innerHTML =
      stat('👥', 'Gości na liście', guestCount) +
      stat('✅', 'Potwierdzonych', att) +
      stat('💰', 'Koszt / gość', fmt(perGuest) + ' zł') +
      stat('📊', 'Budżet planowany', fmt(totalPlanned) + ' zł') +
      stat('🔮', 'Prognoza końcowa', fmt(totalEffective) + ' zł');
  }
  _renderAnalyticsChart('acExpenseCat', 'expenseCat');
  _renderAnalyticsChart('acBudgetCompare', 'budgetCompare');
  _renderAnalyticsChart('acPayTimeline', 'payTimeline');
  _renderAnalyticsChart('acGuestStatus', 'guestStatus');
  _renderAnalyticsChart('acMenu', 'menu');
  _renderAnalyticsChart('acDiet', 'diet');
}

const ANALYTICS_TITLES = {
  expenseCat: '🥧 Wydatki wg kategorii',
  budgetCompare: '📊 Planowany vs realny vs przewidywany',
  payTimeline: '💵 Płatności w czasie (skumulowane)',
  guestStatus: '👥 Potwierdzenia gości',
  menu: '🍽 Rozkład menu',
  diet: '🥗 Diety specjalne',
};

function openAnalyticsModal(type) {
  const modal = document.getElementById('analyticsModal');
  const title = document.getElementById('analyticsModalTitle');
  const cv = document.getElementById('analyticsModalCanvas');
  if (!modal || !cv || typeof Chart === 'undefined') return;
  if (title) title.textContent = ANALYTICS_TITLES[type] || 'Wykres';
  if (_analyticsModalChart) { _analyticsModalChart.destroy(); _analyticsModalChart = null; }
  const d = _analyticsData(type);
  if (!d.values.some(v => v > 0)) { return; }
  modal.style.display = 'flex';
  // canvas potrzebuje rozmiaru po pokazaniu modala
  setTimeout(() => { _analyticsModalChart = new Chart(cv.getContext('2d'), _analyticsChartConfig(type, true)); }, 30);
}
function closeAnalyticsModal(event) {
  const modal = document.getElementById('analyticsModal');
  if (!modal) return;
  if (!event || event.target === modal) closeAnalyticsModalDirect();
}
function closeAnalyticsModalDirect() {
  const modal = document.getElementById('analyticsModal');
  if (modal) modal.style.display = 'none';
  if (_analyticsModalChart) { _analyticsModalChart.destroy(); _analyticsModalChart = null; }
}

// ══════════════════════════════════════════════════════════════════════
//  MUZYKA — lista piosenek + wyszukiwanie Deezer + propozycje gości
// ══════════════════════════════════════════════════════════════════════

// Wyszukiwanie Deezer przez JSONP (api.deezer.com obsługuje &output=jsonp, bez klucza API).
let _deezerResults = [];
function _deezerSearch(query, cb) {
  const cbName = '_dzCb_' + Math.random().toString(36).slice(2);
  const s = document.createElement('script');
  let done = false;
  const cleanup = () => { try { delete window[cbName]; } catch (_) { window[cbName] = undefined; } if (s.parentNode) s.parentNode.removeChild(s); };
  window[cbName] = (data) => { if (done) return; done = true; cleanup(); cb(data && data.data ? data.data : []); };
  s.onerror = () => { if (done) return; done = true; cleanup(); cb(null); };
  s.src = `https://api.deezer.com/search?q=${encodeURIComponent(query)}&limit=15&output=jsonp&callback=${cbName}`;
  document.body.appendChild(s);
  // timeout bezpieczeństwa
  setTimeout(() => { if (!done) { done = true; cleanup(); cb(null); } }, 8000);
}

function searchDeezer() {
  const input = document.getElementById('musicSearchInput');
  const box   = document.getElementById('musicSearchResults');
  if (!input || !box) return;
  const q = input.value.trim();
  if (!q) { box.innerHTML = ''; return; }
  box.innerHTML = '<div class="music-loading">Szukam w Deezer…</div>';
  _deezerSearch(q, (results) => {
    const addUnmatchedBtn = `<div class="music-noresult">
      <span>Nie znaleziono w Deezer.</span>
      <button class="btn btn-sm btn-primary" onclick="addUnmatchedFromQuery()">&#10133; Dodaj „${esc(q)}" do weryfikacji</button>
    </div>`;
    if (results === null) { box.innerHTML = '<div class="chart-empty">Nie udało się połączyć z Deezer (sprawdź internet).</div>' + addUnmatchedBtn; return; }
    _deezerResults = results;
    if (!results.length) { box.innerHTML = addUnmatchedBtn; return; }
    box.innerHTML = results.map((t, i) => {
      const cover = (t.album && t.album.cover_small) || '';
      const prev = t.preview ? `<audio class="music-preview" controls preload="none" src="${esc(t.preview)}"></audio>` : '';
      return `<div class="music-result">
        ${cover ? `<img class="music-cover" src="${esc(cover)}" alt="">` : '<div class="music-cover music-cover-ph">🎵</div>'}
        <div class="music-result-info">
          <div class="music-result-title">${esc(t.title || '')}</div>
          <div class="music-result-artist">${esc((t.artist && t.artist.name) || '')}</div>
          ${prev}
        </div>
        <button class="btn btn-primary btn-sm" onclick="addSongFromDeezer(${i})">&#10133; Dodaj</button>
      </div>`;
    }).join('');
  });
}

// Dodaj wpisaną frazę jako utwór niedopasowany (gdy Deezer nic nie znalazł)
function addUnmatchedFromQuery() {
  const input = document.getElementById('musicSearchInput');
  const q = (input?.value || '').trim();
  if (!q) return;
  // obsłuż „Tytuł - Wykonawca"
  const m = q.split(/\s+[—–-]\s+/);
  const title = (m[0] || q).trim();
  const artist = (m[1] || '').trim();
  songs.push({ id: nextSongId++, title, artist, cover: '', preview: '', moment: 'Inne', genre: '', status: 'proposal', fromGuest: false, guestName: '', unmatched: true });
  if (input) input.value = '';
  const box = document.getElementById('musicSearchResults'); if (box) box.innerHTML = '';
  renderMusicList(); saveState();
  showToast('Dodano do sekcji „Niedopasowane / do weryfikacji"');
}

function addSongFromDeezer(idx) {
  const t = _deezerResults[idx];
  if (!t) return;
  songs.push({
    id: nextSongId++,
    title: t.title || '',
    artist: (t.artist && t.artist.name) || '',
    cover: (t.album && (t.album.cover_medium || t.album.cover_small)) || '',
    preview: t.preview || '',
    moment: 'Inne', genre: '', status: 'proposal', fromGuest: false, guestName: '', unmatched: false,
  });
  renderMusicList();
  saveState();
  showToast(`Dodano: ${t.title}`);
}

function openManualSongForm()  { const f = document.getElementById('musicManualForm'); if (f) f.style.display = 'flex'; }
function closeManualSongForm() { const f = document.getElementById('musicManualForm'); if (f) f.style.display = 'none'; }
function addManualSong() {
  const title  = (document.getElementById('manualSongTitle')?.value || '').trim();
  const artist = (document.getElementById('manualSongArtist')?.value || '').trim();
  if (!title) { showToast('Podaj tytuł utworu'); return; }
  // Dodany ręcznie (bez okładki z API) → trafia do sekcji „Niedopasowane / do weryfikacji"
  songs.push({ id: nextSongId++, title, artist, cover: '', preview: '', moment: 'Inne', genre: '', status: 'proposal', fromGuest: false, guestName: '', unmatched: true });
  document.getElementById('manualSongTitle').value = '';
  document.getElementById('manualSongArtist').value = '';
  closeManualSongForm();
  renderMusicList(); saveState();
  showToast(`Dodano: ${title}`);
}

function updateSong(id, field, value) {
  const sg = songs.find(x => x.id === id); if (!sg) return;
  sg[field] = value;
  renderMusicList(); saveState();
}
function deleteSong(id) {
  songs = songs.filter(x => x.id !== id);
  renderMusicList(); saveState();
}

function setMusicFilter(field, val) { musicFilters[field] = val; renderMusicList(); }
function setMusicSort(val) { musicSort = val; renderMusicList(); }

function switchMusicTab(tab) {
  musicTab = tab;
  document.getElementById('mtab-list')?.classList.toggle('music-tab-active', tab === 'list');
  document.getElementById('mtab-guests')?.classList.toggle('music-tab-active', tab === 'guests');
  const pl = document.getElementById('musicPanelList');
  const pg = document.getElementById('musicPanelGuests');
  if (pl) pl.style.display = tab === 'list' ? '' : 'none';
  if (pg) pg.style.display = tab === 'guests' ? '' : 'none';
  if (tab === 'guests') { renderGuestProposals(); renderMusicQR(); }
}

function _filteredSortedSongs() {
  const f = musicFilters;
  const g = (f.genre || '').trim().toLowerCase();
  let list = songs.filter(sg => {
    if (f.moment !== 'all' && sg.moment !== f.moment) return false;
    if (f.status !== 'all' && sg.status !== f.status) return false;
    if (g && !((sg.genre || '').toLowerCase().includes(g))) return false;
    return true;
  });
  const momIdx = m => { const i = MUSIC_MOMENTS.indexOf(m); return i < 0 ? 99 : i; };
  if (musicSort === 'title')  list = [...list].sort((a, b) => (a.title || '').localeCompare(b.title || '', 'pl'));
  else if (musicSort === 'artist') list = [...list].sort((a, b) => (a.artist || '').localeCompare(b.artist || '', 'pl'));
  else if (musicSort === 'moment') list = [...list].sort((a, b) => momIdx(a.moment) - momIdx(b.moment));
  else if (musicSort === 'status') list = [...list].sort((a, b) => (a.status || '').localeCompare(b.status || ''));
  return list;
}

function _momentOptions(sel) {
  return MUSIC_MOMENTS.map(m => `<option value="${esc(m)}"${m === sel ? ' selected' : ''}>${esc(m)}</option>`).join('');
}
function _statusOptions(sel) {
  return Object.entries(MUSIC_STATUSES).map(([k, v]) => `<option value="${k}"${k === sel ? ' selected' : ''}>${v.icon} ${esc(v.label)}</option>`).join('');
}

function _songRowHtml(sg) {
  const st = MUSIC_STATUSES[sg.status] || MUSIC_STATUSES.proposal;
  const cover = sg.cover ? `<img class="music-cover" src="${esc(sg.cover)}" alt="">` : '<div class="music-cover music-cover-ph">🎵</div>';
  const prev = sg.preview ? `<audio class="music-preview" controls preload="none" src="${esc(sg.preview)}"></audio>` : '';
  const guestBadge = sg.fromGuest ? `<span class="music-guest-badge" title="Propozycja od gościa">👤 od gościa${sg.guestName ? ': ' + esc(sg.guestName) : ''}</span>` : '';
  return `<div class="music-item">
    ${cover}
    <div class="music-item-main">
      <div class="music-item-title">${esc(sg.title || 'Bez tytułu')} ${guestBadge}</div>
      <div class="music-item-artist">${esc(sg.artist || '—')}</div>
      ${prev}
      <div class="music-item-controls">
        <select class="music-sel" onchange="updateSong(${sg.id},'moment',this.value)" title="Moment imprezy">${_momentOptions(sg.moment)}</select>
        <input class="music-genre-input" type="text" value="${esc(sg.genre || '')}" placeholder="Gatunek/gust" onchange="updateSong(${sg.id},'genre',this.value)">
        <select class="music-sel music-status-sel ${st.cls}" onchange="updateSong(${sg.id},'status',this.value)" title="Status">${_statusOptions(sg.status)}</select>
      </div>
    </div>
    <button class="btn-row-del" onclick="deleteSong(${sg.id})" title="Usuń utwór">&#128465;</button>
  </div>`;
}

// Wiersz utworu niedopasowanego (do weryfikacji) — edytowalny tytuł/wykonawca + akcje
function _songRowUnmatchedHtml(sg) {
  const guestBadge = sg.fromGuest ? `<span class="music-guest-badge" title="Propozycja od gościa">👤 od gościa${sg.guestName ? ': ' + esc(sg.guestName) : ''}</span>` : '';
  return `<div class="music-item music-item-unmatched">
    <div class="music-cover music-cover-ph music-cover-warn">❓</div>
    <div class="music-item-main">
      <div class="music-item-title">${guestBadge}<span class="music-verify-tag">do weryfikacji</span></div>
      <div class="music-unmatched-edit">
        <input type="text" class="music-genre-input mu-title" value="${esc(sg.title || '')}" placeholder="Tytuł" onchange="updateSong(${sg.id},'title',this.value)">
        <input type="text" class="music-genre-input mu-artist" value="${esc(sg.artist || '')}" placeholder="Wykonawca" onchange="updateSong(${sg.id},'artist',this.value)">
      </div>
      <div class="music-item-controls">
        <select class="music-sel" onchange="updateSong(${sg.id},'moment',this.value)" title="Moment imprezy">${_momentOptions(sg.moment)}</select>
        <button class="btn btn-sm" onclick="searchDeezerForSong(${sg.id})" title="Spróbuj dopasować w Deezer">🔍 Szukaj w Deezer</button>
        <button class="btn btn-sm btn-primary" onclick="confirmSong(${sg.id})" title="Przenieś do głównej listy">✓ Potwierdź</button>
      </div>
    </div>
    <button class="btn-row-del" onclick="deleteSong(${sg.id})" title="Usuń utwór">&#128465;</button>
  </div>`;
}

// Potwierdzenie utworu niedopasowanego → przenosi do głównej listy
function confirmSong(id) {
  const sg = songs.find(x => x.id === id); if (!sg) return;
  if (!(sg.title || '').trim()) { showToast('Podaj tytuł utworu przed potwierdzeniem'); return; }
  sg.unmatched = false;
  renderMusicList(); saveState();
  showToast('Przeniesiono do głównej listy ✓');
}

// Próba dopasowania niedopasowanego utworu do Deezer (uzupełnia okładkę/podgląd)
function searchDeezerForSong(id) {
  const sg = songs.find(x => x.id === id); if (!sg) return;
  const q = [sg.title, sg.artist].filter(Boolean).join(' ').trim();
  if (!q) { showToast('Podaj tytuł, aby wyszukać'); return; }
  showToast('Szukam w Deezer…');
  _deezerSearch(q, (results) => {
    if (!results || !results.length) { showToast('Brak dopasowania w Deezer — możesz potwierdzić ręcznie.'); return; }
    const t = results[0];
    sg.title   = t.title || sg.title;
    sg.artist  = (t.artist && t.artist.name) || sg.artist;
    sg.cover   = (t.album && (t.album.cover_medium || t.album.cover_small)) || '';
    sg.preview = t.preview || '';
    sg.unmatched = false;
    renderMusicList(); saveState();
    showToast(`Dopasowano: ${sg.title} ✓`);
  });
}

function renderMusic() {
  // wypełnij filtr momentów
  const momSel = document.querySelector('#musicFilters select');
  if (momSel && momSel.options.length <= 1) {
    momSel.innerHTML = '<option value="all">Moment: wszystkie</option>' + MUSIC_MOMENTS.map(m => `<option value="${esc(m)}">${esc(m)}</option>`).join('');
  }
  startMusicProposalsListener();
  switchMusicTab(musicTab);
  renderMusicList();
  updateMusicGuestBadge();
}

function renderMusicList() {
  const c = document.getElementById('musicList'); if (!c) return;
  if (!songs.length) { c.innerHTML = '<div class="empty-list">Brak utworów. Wyszukaj w Deezer, dodaj ręcznie lub zaimportuj listę, aby zbudować playlistę dla DJa.</div>'; return; }
  const list = _filteredSortedSongs();
  const matched   = list.filter(sg => !sg.unmatched);
  const unmatched = list.filter(sg => sg.unmatched);

  // grupowanie dopasowanych po momencie
  const byMoment = {};
  matched.forEach(sg => { const m = sg.moment || 'Inne'; (byMoment[m] = byMoment[m] || []).push(sg); });
  const order = MUSIC_MOMENTS.filter(m => byMoment[m]);
  let html = order.map(m => `
    <div class="music-group">
      <div class="music-group-hdr">${esc(m)} <span class="music-group-count">${byMoment[m].length}</span></div>
      ${byMoment[m].map(_songRowHtml).join('')}
    </div>`).join('');

  // sekcja niedopasowanych / do weryfikacji
  if (unmatched.length) {
    html += `<div class="music-group music-group-unmatched">
      <div class="music-group-hdr music-group-hdr-warn">❓ Niedopasowane / do weryfikacji <span class="music-group-count">${unmatched.length}</span></div>
      <p class="music-unmatched-note">Te utwory nie mają okładki z Deezer (dodane ręcznie lub z importu). Sprawdź pisownię, spróbuj dopasować w Deezer albo potwierdź ręcznie, aby przenieść je do głównej listy.</p>
      ${unmatched.map(_songRowUnmatchedHtml).join('')}
    </div>`;
  }

  if (!matched.length && !unmatched.length) { c.innerHTML = '<div class="empty-list">Brak utworów spełniających filtry.</div>'; return; }
  c.innerHTML = html;
}

// ── Propozycje gości (kolekcja Firestore /musicProposals) ──
function startMusicProposalsListener() {
  if (_musicProposalsUnsub) return;
  try {
    if (typeof firebase === 'undefined' || !firebase.apps || !firebase.apps.length) return;
    _musicProposalsUnsub = firebase.firestore().collection('musicProposals').orderBy('timestamp', 'desc')
      .onSnapshot(snap => {
        _guestProposals = snap.docs.map(d => Object.assign({ _id: d.id }, d.data()));
        updateMusicGuestBadge();
        if (currentView === 'music' && musicTab === 'guests') renderGuestProposals();
      }, err => console.error('musicProposals listener:', err));
  } catch (e) { console.error('startMusicProposalsListener:', e); }
}

function updateMusicGuestBadge() {
  const b = document.getElementById('musicGuestBadge');
  if (!b) return;
  const pending = _guestProposals.filter(p => !p.status || p.status === 'proposal').length;
  if (pending > 0) { b.style.display = ''; b.textContent = pending; }
  else b.style.display = 'none';
}

function _guestProposalRowHtml(p) {
  const st = MUSIC_STATUSES[p.status] || MUSIC_STATUSES.proposal;
  const isUnmatched = !p.cover;
  const cover = p.cover
    ? `<img class="music-cover" src="${esc(p.cover)}" alt="">`
    : `<div class="music-cover music-cover-ph${isUnmatched ? ' music-cover-warn' : ''}">${isUnmatched ? '❓' : '🎵'}</div>`;
  const prev = p.preview ? `<audio class="music-preview" controls preload="none" src="${esc(p.preview)}"></audio>` : '';
  const verifyTag = isUnmatched ? '<span class="music-verify-tag">do weryfikacji</span>' : '';
  return `<div class="music-item${isUnmatched ? ' music-item-unmatched' : ''}">
    ${cover}
    <div class="music-item-main">
      <div class="music-item-title">${esc(p.title || 'Bez tytułu')} <span class="music-guest-badge">👤 od gościa${p.guestName ? ': ' + esc(p.guestName) : ''}</span>${verifyTag}</div>
      <div class="music-item-artist">${esc(p.artist || '—')}</div>
      ${prev}
      <div class="music-item-controls">
        <select class="music-sel music-status-sel ${st.cls}" onchange="setProposalStatus('${esc(p._id)}',this.value)" title="Status">${_statusOptions(p.status || 'proposal')}</select>
        <button class="btn btn-sm btn-primary" onclick="acceptProposalToList('${esc(p._id)}')" title="Dodaj do naszej listy">&#10133; Do naszej listy</button>
      </div>
    </div>
    <button class="btn-row-del" onclick="deleteProposal('${esc(p._id)}')" title="Usuń propozycję">&#128465;</button>
  </div>`;
}

function renderGuestProposals() {
  const c = document.getElementById('musicGuestList'); if (!c) return;
  if (!_guestProposals.length) { c.innerHTML = '<div class="empty-list">Brak propozycji od gości. Udostępnij im stronę /muzyka, aby zgłaszali piosenki.</div>'; return; }
  const matched   = _guestProposals.filter(p => p.cover);
  const unmatched = _guestProposals.filter(p => !p.cover);
  let html = '';
  if (matched.length) {
    html += `<div class="music-group">
      <div class="music-group-hdr">🎵 Z dopasowaniem (Deezer) <span class="music-group-count">${matched.length}</span></div>
      ${matched.map(_guestProposalRowHtml).join('')}
    </div>`;
  }
  if (unmatched.length) {
    html += `<div class="music-group music-group-unmatched">
      <div class="music-group-hdr music-group-hdr-warn">❓ Niedopasowane / do weryfikacji <span class="music-group-count">${unmatched.length}</span></div>
      <p class="music-unmatched-note">Te propozycje gości nie mają okładki z Deezer (dopisane ręcznie lub z importu). Zweryfikuj i ewentualnie dodaj do swojej listy.</p>
      ${unmatched.map(_guestProposalRowHtml).join('')}
    </div>`;
  }
  c.innerHTML = html;
}

function setProposalStatus(docId, status) {
  try {
    firebase.firestore().collection('musicProposals').doc(docId).update({ status });
  } catch (e) { console.error('setProposalStatus:', e); }
}
function deleteProposal(docId) {
  if (!confirm('Usunąć tę propozycję gościa?')) return;
  try { firebase.firestore().collection('musicProposals').doc(docId).delete(); }
  catch (e) { console.error('deleteProposal:', e); }
}
function acceptProposalToList(docId) {
  const p = _guestProposals.find(x => x._id === docId); if (!p) return;
  songs.push({
    id: nextSongId++, title: p.title || '', artist: p.artist || '', cover: p.cover || '', preview: p.preview || '',
    moment: 'Inne', genre: p.genre || '', status: 'approved', fromGuest: true, guestName: p.guestName || '',
    unmatched: !p.cover,   // propozycja gościa bez okładki z API → do weryfikacji
  });
  // oznacz propozycję jako zatwierdzoną
  setProposalStatus(docId, 'approved');
  renderMusicList(); saveState();
  showToast(`Dodano do listy: ${p.title || 'utwór'}`);
}

function renderMusicQR() {
  const url = _publicUrl('muzyka.html');
  _renderQRCanvas('qrMusic', url);
  _setQRLink('qrMusicLink', url);
  _setQRLink('qrMusicOpen', url, true);
}

// ── Import: modal z instrukcją formatu ──
function openMusicImportModal() {
  const m = document.getElementById('musicImportModal');
  if (m) m.style.display = 'flex';
}
function closeMusicImport(event) {
  const m = document.getElementById('musicImportModal');
  if (m && (!event || event.target === m)) m.style.display = 'none';
}
function closeMusicImportDirect() {
  const m = document.getElementById('musicImportModal');
  if (m) m.style.display = 'none';
}

// ── Eksport / import listy piosenek ──
function _songsForExport() {
  return _filteredSortedSongs().length ? _filteredSortedSongs() : songs;
}
function exportMusicCsv() {
  if (!songs.length) { showToast('Brak utworów do eksportu'); return; }
  const head = ['Tytuł', 'Wykonawca', 'Moment imprezy', 'Status', 'Gatunek', 'Od gościa'];
  const rows = songs.map(sg => [
    sg.title || '', sg.artist || '', sg.moment || '', (MUSIC_STATUSES[sg.status]?.label || sg.status || ''),
    sg.genre || '', sg.fromGuest ? (sg.guestName || 'tak') : '',
  ]);
  const csv = [head, ...rows].map(r => r.map(_csvCell).join(';')).join('\r\n');
  _downloadTextFile('lista-piosenek.csv', '﻿' + csv, 'text/csv;charset=utf-8');
}
function exportMusicTxt() {
  if (!songs.length) { showToast('Brak utworów do eksportu'); return; }
  const byMoment = {};
  songs.forEach(sg => { const m = sg.moment || 'Inne'; (byMoment[m] = byMoment[m] || []).push(sg); });
  let txt = 'LISTA PIOSENEK NA WESELE\r\n========================\r\n\r\n';
  MUSIC_MOMENTS.filter(m => byMoment[m]).forEach(m => {
    txt += `### ${m}\r\n`;
    byMoment[m].forEach(sg => {
      txt += `- ${sg.title || ''}${sg.artist ? ' — ' + sg.artist : ''}` +
             ` [${MUSIC_STATUSES[sg.status]?.label || ''}]` +
             `${sg.genre ? ' (' + sg.genre + ')' : ''}\r\n`;
    });
    txt += '\r\n';
  });
  _downloadTextFile('lista-piosenek.txt', txt, 'text/plain;charset=utf-8');
}
function _downloadTextFile(name, content, mime) {
  const blob = new Blob([content], { type: mime });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = name;
  document.body.appendChild(a); a.click();
  setTimeout(() => { URL.revokeObjectURL(a.href); a.remove(); }, 100);
}
function importMusicFile(event) {
  const file = event.target.files && event.target.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = (e) => {
    try { _parseImportedSongs(String(e.target.result || '')); }
    catch (err) { console.error('import muzyki:', err); showToast('Nie udało się wczytać pliku.'); }
    event.target.value = '';
    closeMusicImportDirect();
  };
  reader.readAsText(file, 'utf-8');
}

// Status po polskiej etykiecie (z importu) → klucz statusu
function _statusKeyFromLabel(s) {
  const t = (s || '').trim().toLowerCase();
  if (!t) return 'proposal';
  for (const [k, v] of Object.entries(MUSIC_STATUSES)) { if (k === t || v.label.toLowerCase() === t) return k; }
  if (t.includes('zatw'))  return 'approved';
  if (t.includes('odrzu')) return 'rejected';
  if (t.includes('dj'))    return 'dj';
  return 'proposal';
}

// Wspólny parser pliku z piosenkami — CSV (przecinek/średnik) lub tekst „Tytuł - Wykonawca".
// Zwraca tablicę { title, artist, moment, status, genre }. (Używany przez organizatora i gości.)
function _parseSongFile(text) {
  const lines = String(text || '').split(/\r?\n/).map(l => l.trim()).filter(Boolean);
  if (!lines.length) return [];
  const delim = lines.some(l => l.includes(';')) ? ';' : (lines.some(l => l.includes(',')) ? ',' : null);
  const headerIsCsv = !!delim && /tytu/i.test(lines[0]) && lines[0].includes(delim);
  const treatCsv = !!delim && (headerIsCsv || lines.filter(l => l.includes(delim)).length > lines.length / 2);
  const out = [];
  lines.forEach((line, i) => {
    if (/^#{1,3}\s/.test(line) || /^=+$/.test(line) || /^LISTA PIOSENEK/i.test(line)) return; // nagłówki sekcji tekstowych
    let title = '', artist = '', moment = 'Inne', status = 'proposal', genre = '';
    if (treatCsv && line.includes(delim)) {
      if (i === 0 && /tytu/i.test(line)) return;            // wiersz nagłówka CSV
      const cells = line.split(delim).map(c => c.replace(/^"|"$/g, '').trim());
      title = cells[0] || ''; artist = cells[1] || '';
      if (cells[2] && MUSIC_MOMENTS.includes(cells[2])) moment = cells[2];
      if (cells[3]) status = _statusKeyFromLabel(cells[3]);
      if (cells[4]) genre = cells[4];
    } else {
      // format tekstowy: „Tytuł - Wykonawca" (myślnik/półpauza/pauza), z opcjonalnym [Status] (gatunek)
      let l = line.replace(/^[-•*]\s*/, '').replace(/\s*\[[^\]]*\]/g, '').replace(/\s*\([^)]*\)\s*$/, '');
      const m = l.split(/\s+[—–-]\s+/);
      title = (m[0] || '').trim();
      artist = (m[1] || '').trim();
    }
    if (title) out.push({ title, artist, moment, status, genre });
  });
  return out;
}

function _parseImportedSongs(text) {
  const parsed = _parseSongFile(text);
  let added = 0;
  parsed.forEach(p => {
    // pomiń duplikaty (ten sam tytuł+wykonawca)
    if (songs.some(sg => (sg.title || '').toLowerCase() === p.title.toLowerCase() && (sg.artist || '').toLowerCase() === (p.artist || '').toLowerCase())) return;
    // import nie odpytuje Deezera → utwór trafia do „Niedopasowane / do weryfikacji"
    songs.push({ id: nextSongId++, title: p.title, artist: p.artist, cover: '', preview: '', moment: p.moment, genre: p.genre, status: p.status, fromGuest: false, guestName: '', unmatched: true });
    added++;
  });
  renderMusicList(); saveState();
  showToast(added ? `Zaimportowano ${added} utworów (do weryfikacji)` : 'Nie znaleziono nowych utworów w pliku');
}

// ══════════════════════════════════════════════════════════════════════
//  CHECKLISTA NA DZIEŃ ŚLUBU (podzakładka Harmonogramu)
// ══════════════════════════════════════════════════════════════════════
function switchScheduleTab(tab) {
  scheduleTab = tab;
  applyScheduleTab();
}
function applyScheduleTab() {
  const isPlan = scheduleTab !== 'checklist';
  document.getElementById('stab-plan')?.classList.toggle('music-tab-active', isPlan);
  document.getElementById('stab-checklist')?.classList.toggle('music-tab-active', !isPlan);
  const pp = document.getElementById('schedulePanelPlan');
  const pc = document.getElementById('schedulePanelChecklist');
  const tb = document.getElementById('scheduleToolbar');
  if (pp) pp.style.display = isPlan ? '' : 'none';
  if (pc) pc.style.display = isPlan ? 'none' : '';
  if (tb) tb.style.display = isPlan ? '' : 'none';
  if (!isPlan) renderChecklist();
}
function addChecklistItem(category) {
  checklist.push({ id: nextChecklistId++, category: category || CHECKLIST_CATEGORIES[0], text: '', done: false });
  renderChecklist(); saveState();
  // fokus na nowej pozycji
  setTimeout(() => { const el = document.querySelector(`#chk-${nextChecklistId - 1} .chk-text`); if (el) el.focus(); }, 30);
}
function updateChecklistItem(id, field, value) {
  const it = checklist.find(x => x.id === id); if (!it) return;
  it[field] = value;
  if (field === 'done') renderChecklist();
  _refreshChecklistProgress();
  saveState();
}
function deleteChecklistItem(id) {
  checklist = checklist.filter(x => x.id !== id);
  renderChecklist(); saveState();
}
function _refreshChecklistProgress() {
  const total = checklist.length;
  const done = checklist.filter(it => it.done).length;
  const pct = total ? Math.round(done / total * 100) : 0;
  const lbl = document.getElementById('checklistProgressLabel');
  const fill = document.getElementById('checklistProgressFill');
  if (lbl) lbl.textContent = `${done} / ${total} odhaczonych (${pct}%)`;
  if (fill) fill.style.width = pct + '%';
}
function renderChecklist() {
  const c = document.getElementById('checklistContent'); if (!c) return;
  c.innerHTML = CHECKLIST_CATEGORIES.map(cat => {
    const items = checklist.filter(it => it.category === cat);
    const rows = items.map(it => `
      <div class="chk-item${it.done ? ' chk-done' : ''}" id="chk-${it.id}">
        <label class="chk-check"><input type="checkbox" ${it.done ? 'checked' : ''} onchange="updateChecklistItem(${it.id},'done',this.checked)"></label>
        <input class="chk-text" type="text" value="${esc(it.text || '')}" placeholder="Wpisz pozycję…" onchange="updateChecklistItem(${it.id},'text',this.value)">
        <button class="btn-row-del" onclick="deleteChecklistItem(${it.id})" title="Usuń">&#128465;</button>
      </div>`).join('');
    return `<div class="chk-group">
      <div class="chk-group-hdr">${esc(cat)}</div>
      ${rows || '<div class="chk-empty">Brak pozycji</div>'}
      <button class="btn btn-sm chk-add-btn" onclick="addChecklistItem('${esc(cat)}')">&#10133; Dodaj pozycję</button>
    </div>`;
  }).join('');
  _refreshChecklistProgress();
}

// ══════════════════════════════════════════════════════════════════════
//  WINIETKI NA STOŁY — PDF do druku (jsPDF)
// ══════════════════════════════════════════════════════════════════════
function _placeCardTableName(g) {
  if (g.tableId == null) return 'Bez stołu';
  const t = tables.find(x => x.id === g.tableId);
  return t ? (t.name || 'Stół') : 'Bez stołu';
}
function generatePlaceCardsForSelectedTable() {
  const sel = document.getElementById('placeCardTableSel');
  const val = sel ? sel.value : '';
  generatePlaceCards(val === '' ? 'all' : parseInt(val));
}
// scope: 'all' | tableId (number)
function generatePlaceCards(scope) {
  const jspdfNS = window.jspdf || window.jsPDF;
  if (!jspdfNS || !(jspdfNS.jsPDF || jspdfNS)) { showToast('Biblioteka PDF nie została wczytana.'); return; }
  const JsPDF = jspdfNS.jsPDF || jspdfNS;
  let list = guests.slice();
  if (scope !== 'all') list = list.filter(g => g.tableId === scope);
  if (!list.length) { showToast('Brak gości do wygenerowania winietek.'); return; }
  list.sort((a, b) => (_placeCardTableName(a)).localeCompare(_placeCardTableName(b), 'pl') || fullName(a).localeCompare(fullName(b), 'pl'));

  const doc = new JsPDF({ orientation: 'portrait', unit: 'mm', format: 'a4' });
  const pageW = 210, pageH = 297;
  const cols = 2, rows = 4;            // 8 winietek na arkusz A4
  const mX = 12, mY = 12;
  const gap = 4;
  const cardW = (pageW - 2 * mX - (cols - 1) * gap) / cols;
  const cardH = (pageH - 2 * mY - (rows - 1) * gap) / rows;

  list.forEach((g, i) => {
    const onPage = i % (cols * rows);
    if (i > 0 && onPage === 0) doc.addPage();
    const col = onPage % cols;
    const row = Math.floor(onPage / cols);
    const x = mX + col * (cardW + gap);
    const y = mY + row * (cardH + gap);

    // ramka winietki (jasnoniebieski design)
    doc.setDrawColor(197, 216, 246);
    doc.setLineWidth(0.4);
    doc.roundedRect(x, y, cardW, cardH, 3, 3, 'S');
    // górny pasek dekoracyjny
    doc.setFillColor(26, 86, 219);
    doc.roundedRect(x, y, cardW, 9, 3, 3, 'F');
    doc.setFillColor(26, 86, 219);
    doc.rect(x, y + 5, cardW, 4, 'F');
    doc.setTextColor(255, 255, 255);
    doc.setFont('helvetica', 'italic');
    doc.setFontSize(8);
    doc.text(_plAscii(appConfig.displayNames || 'Nasze Wesele'), x + cardW / 2, y + 6, { align: 'center' });

    // imię i nazwisko gościa
    doc.setTextColor(16, 39, 80);
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(15);
    const name = _plAscii(fullName(g) || 'Gość');
    doc.text(name, x + cardW / 2, y + cardH / 2 + 1, { align: 'center', maxWidth: cardW - 8 });

    // stolik
    doc.setTextColor(26, 86, 219);
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(11);
    doc.text(_plAscii('Stolik: ' + _placeCardTableName(g)), x + cardW / 2, y + cardH - 8, { align: 'center', maxWidth: cardW - 8 });
  });

  const tag = scope === 'all' ? 'wszyscy' : ('stol-' + scope);
  doc.save(`winietki-${tag}.pdf`);
}

// Wypełnia <select> stołów dla winietek (wywoływane przy renderze podsumowania gości)
function _fillPlaceCardTableSelect() {
  const sel = document.getElementById('placeCardTableSel');
  if (!sel) return;
  const cur = sel.value;
  sel.innerHTML = '<option value="">— wybierz stół —</option>' +
    tables.map(t => `<option value="${t.id}">${esc(t.name || 'Stół')}</option>`).join('');
  if (cur) sel.value = cur;
}

// ── INIT ──
document.getElementById('guestFirstName').addEventListener('keydown', e => { if (e.key==='Enter') document.getElementById('guestLastName').focus(); });
document.getElementById('guestLastName').addEventListener('keydown',  e => { if (e.key==='Enter') addGuest(); });
document.getElementById('tableName').addEventListener('keydown',      e => { if (e.key==='Enter') addTable(); });

try { loadState(); } catch(e) { console.error('loadState:', e); }
// Diagnostyka startowa: pokaż w konsoli wszystkie klucze localStorage (WYMÓG 2).
try { scanLocalStorage(); } catch(e) { console.error('scanLocalStorage:', e); }
try { seedLocationLinks(); } catch(e) { console.error('seedLocationLinks:', e); }
try { renderAll(); } catch(e) { console.error('renderAll:', e); }
try { applyConfig(); } catch(e) { console.error('applyConfig:', e); }
switchView('dashboard');
startCountdown();
if (typeof initFirebaseSync === 'function') initFirebaseSync();
if (typeof initAuth === 'function') initAuth();
if (typeof initTouchDragDrop === 'function') initTouchDragDrop();
