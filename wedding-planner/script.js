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
  eventType:      'wedding',
  eventTypeCustom: '',
};

// ── TYPY EVENTÓW (kolory, ikony, dostępne sekcje) ──
const ALL_EVENT_VIEWS = ['tables','room','rsvp','budget','schedule','tasks','vendors','gifts','transport','accommodation','gallery'];
const EVENT_TYPES = {
  wedding:      { icon: '💍', label: 'Ślub',         heroTitle: 'Do Waszego Ślubu', sections: ALL_EVENT_VIEWS.slice() },
  baptism:      { icon: '👶', label: 'Chrzciny',     heroTitle: 'Do Chrzcin',       sections: ['tables','room','rsvp','budget','schedule','tasks','vendors','transport','accommodation'] },
  communion:    { icon: '🕊️', label: 'Komunia',      heroTitle: 'Do Komunii',       sections: ['tables','room','rsvp','budget','schedule','tasks','vendors','gifts'] },
  confirmation: { icon: '✝️', label: 'Bierzmowanie', heroTitle: 'Do Bierzmowania',  sections: ['tables','room','rsvp','budget','schedule','tasks'] },
  eighteenth:   { icon: '🎂', label: '18-stka',      heroTitle: 'Do Osiemnastki',   sections: ['tables','room','rsvp','budget','schedule','tasks','vendors','transport'] },
  birthday:     { icon: '🎉', label: 'Urodziny',     heroTitle: 'Do Urodzin',       sections: ['tables','room','rsvp','budget','schedule','tasks','vendors'] },
  other:        { icon: '🎊', label: 'Inne',         heroTitle: 'Do wydarzenia',    sections: ALL_EVENT_VIEWS.slice() },
};
// Widoki zawsze dostępne (zarządzanie aplikacją) niezależnie od typu eventu
const ALWAYS_VIEWS = ['dashboard', 'config', 'access', 'guestcard'];
function eventTypeKey() { return EVENT_TYPES[appConfig.eventType] ? appConfig.eventType : 'wedding'; }
function eventTypeInfo() { return EVENT_TYPES[eventTypeKey()]; }
function eventTypeLabel() {
  const k = eventTypeKey();
  return (k === 'other' && (appConfig.eventTypeCustom || '').trim()) ? appConfig.eventTypeCustom.trim() : EVENT_TYPES[k].label;
}
// Imiona Osoby 1/2 (podział kosztów) trzymane są w budgetData.coupleNames,
// a data ślubu w globalnym weddingDate — Konfiguracja edytuje te same źródła.
let appConfig = Object.assign({}, DEFAULT_APP_CONFIG);

// ── WIELE EVENTÓW: kontener { events: {id: stanEventu}, activeEventId } ──
let EVENTS = {};            // mapa id → pełny stan eventu (serializowany)
let activeEventId = 'default';
let _stateReady = false;    // true dopiero po udanym wczytaniu — chroni przed nadpisaniem danych pustym stanem
let nextGuestId = 1;
let nextTableId = 1;
let nextPairId  = 1;
let draggedGuestId = null;
let tvGuestDrag    = null; // { guestId, srcTableId } — table-view seat drag
let pairingGuestId = null;
let currentView          = 'dashboard';
let currentBudgetTab     = 'summary';
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
let roomElements = [];           // { id, name, wM, lM, posX, posY }
let nextRoomElementId = 1;
let roomElementDrag = null;      // { id, startMouseX, startMouseY, startPosX, startPosY }

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
  saveState();
}

// ── GUESTS ──
function openGuestForm() {
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

function addGuest() {
  const first = document.getElementById('guestFirstName').value.trim();
  const last  = document.getElementById('guestLastName').value.trim();
  if (!first && !last) { showToast('Podaj imię lub nazwisko gościa'); return; }

  const diet = document.getElementById('guestDiet')?.value || 'standard';
  guests.push({
    id: nextGuestId++,
    firstName:  first,
    lastName:   last,
    category:   document.getElementById('guestCategory').value,
    gender:     document.getElementById('guestGender').value,
    photo:      document.getElementById('guestPhoto').value.trim() || null,
    invitedBy:  document.getElementById('guestInvitedBy')?.value || null,
    witness:    document.getElementById('guestWitness')?.value || null,
    diet,
    dietOther:  diet === 'other' ? (document.getElementById('guestDietOther')?.value || '') : '',
    needsAccommodation: false,
    vehicleId:  null,
    ownTransport: false,
    hotelId:    null,
    accommodationStatus: null,
    tableId:    null,
    seatIndex:  null,
    pairId:     null,
    // Kartoteka gości (rozszerzone informacje)
    menuChoice: '',
    preferences: '',
    allergies:  '',
    cardNotes:  '',
  });

  document.getElementById('guestFirstName').value = '';
  document.getElementById('guestLastName').value  = '';
  document.getElementById('guestPhoto').value     = '';
  if (document.getElementById('guestInvitedBy')) document.getElementById('guestInvitedBy').value = '';
  if (document.getElementById('guestWitness'))   document.getElementById('guestWitness').value   = '';
  if (document.getElementById('guestDiet'))      document.getElementById('guestDiet').value      = 'standard';
  if (document.getElementById('guestDietOther')) document.getElementById('guestDietOther').value = '';
  closeGuestFormDirect();
  renderGuests();
  updateStats();
  saveState();
  showToast(`${first} ${last} dodany/a do listy`);
}

function removeGuest(guestId) {
  const g = guests.find(x => x.id === guestId);
  if (!g) return;
  if (g.tableId !== null) _unsetSeat(g);
  if (g.pairId  !== null) _breakPair(g.pairId, false);
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
  tables.push({ id: nextTableId++, name, shape, seats, seatsData: new Array(seats).fill(null), posX: pos.x, posY: pos.y });
  document.getElementById('tableName').value = '';
  renderTables();
  updateStats();
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
        title="${esc(fullName(g))}">
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

function calcExpensesPlanned()    { return budgetData.expenses.reduce((s, e) => s + (e.planned         || 0), 0) + calcAlcoholTotal(); }
function calcExpensesPaid()       { return budgetData.expenses.reduce((s, e) => s + (e.paid             || 0), 0); }
function calcExpensesEstimated()  { return budgetData.expenses.reduce((s, e) => s + (e.estimatedAmount  || 0), 0); }
function calcExpensesEffective()  { return budgetData.expenses.reduce((s, e) => s + _payEffective(e.planned || 0, e.estimatedAmount || 0), 0) + calcAlcoholTotal(); }

// ── BUDGET VIEW ──
function renderBudget() {
  renderTableCosts();
  renderExpenses();
  renderAlcohol();
  renderHoneymoon();
  renderCostBreakdown();
  renderCoupleSummary();
  renderCostPerTable();
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
  const totalConfirmed   = catering + expConfirmed + hmConfirmed;
  const totalEffective   = catering + expEffective + hmEffective;
  const totalPaid        = expPaid + honeymoonPaid;
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
  const opts = EXPENSE_CATEGORIES.map(c =>
    `<option value="${esc(c.name)}" ${e.category === c.name ? 'selected' : ''}>${c.icon} ${esc(c.name)}</option>`
  ).join('');
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
    .concat(EXPENSE_CATEGORIES.map(c =>
      `<option value="${esc(c.name)}"${expenseFilters.category===c.name?' selected':''}>${c.icon} ${esc(c.name)}</option>`
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
  const selectedCatOpts = EXPENSE_CATEGORIES.map(c =>
    `<option value="${esc(c.name)}" ${c.name===e.category?'selected':''}>${c.icon} ${esc(c.name)}</option>`
  ).join('');

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
    </div>
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
      const lbl = e.category.length > 16 ? e.category.substring(0, 14) + '…' : e.category;
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
    guestcard: 'viewGuestCard',
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
    access: 'navAccess', config: 'navConfig', guestcard: 'navGuestCard',
  };
  const navBtn = document.getElementById(navIds[view]);
  if (navBtn) navBtn.classList.add('active');

  // Show stats bar only for tables view
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
      break;
    case 'room':          renderRoom();          break;
    case 'budget':        renderBudget(); renderPayments(); break;
    case 'dashboard':     renderDashboard();     break;
    case 'schedule':      renderSchedule(); renderScheduleQR(); break;
    case 'gallery':       renderGalleryView();   break;
    case 'access':        renderAccessView();    break;
    case 'config':        renderConfigView();    break;
    case 'guestcard':     renderGuestCard();     break;
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
  if (t.shape === 'round') {
    // Gdy podano średnicę stołów i szerokość sali — rysuj w skali (metry → px)
    if (roomMeta.tableDiameterM > 0 && roomMeta.widthM > 0) {
      const d = Math.max(50, Math.min(400, roomMeta.tableDiameterM * roomPxPerMeter()));
      return { tw: d, th: d };
    }
    const d = Math.max(86, 58 + t.seats * 5);
    return { tw: d, th: d };
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

  return `<div class="rt-wrap" data-id="${t.id}"
    style="left:${t.posX}px;top:${t.posY}px;width:${wrapW}px;height:${wrapH}px"
    onmousedown="startRoomTableDrag(event,${t.id})">
    ${shapeHtml}
    ${dotsHtml}
    <div class="rt-delete" onclick="event.stopPropagation();deleteTable(${t.id})" title="Usuń stół">&#10005;</div>
  </div>`;
}

// ── ROOM GUEST DRAG & DROP (event delegation on #roomCanvas) ──
function roomGuestDragStart(event, guestId, srcTableId) {
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
}

// Renderuje własny element sali (Orkiestra, DJ, Bar, Scena, Parkiet, własny) jako blok z podpisem
function renderRoomElement(el) {
  const ppm = roomPxPerMeter();
  const tw = Math.max(46, Math.round((el.wM || 1) * ppm));
  const th = Math.max(36, Math.round((el.lM || 1) * ppm));
  const PAD = 6;
  const wrapW = tw + PAD * 2, wrapH = th + PAD * 2;
  const dims = (el.wM && el.lM) ? `${el.wM}×${el.lM} m` : '';
  return `<div class="rt-wrap rt-element-wrap" data-element-id="${el.id}"
    style="left:${el.posX}px;top:${el.posY}px;width:${wrapW}px;height:${wrapH}px"
    onmousedown="startRoomElementDrag(event,${el.id})">
    <div class="rt-shape rt-rect rt-element" style="width:${tw}px;height:${th}px;left:${PAD}px;top:${PAD}px">
      <div class="rt-label">
        <div class="rt-name">${esc(el.name)}</div>
        ${dims ? `<div class="rt-count">${dims}</div>` : ''}
      </div>
    </div>
    <div class="rt-delete" onclick="event.stopPropagation();deleteRoomElement(${el.id})" title="Usuń element">&#10005;</div>
  </div>`;
}

function startRoomElementDrag(e, id) {
  if (e.button !== 0) return;
  e.preventDefault();
  const el = roomElements.find(x => x.id === id);
  if (!el) return;
  roomElementDrag = { id, startMouseX: e.clientX, startMouseY: e.clientY, startPosX: el.posX, startPosY: el.posY };
  document.querySelector(`.rt-element-wrap[data-element-id="${id}"]`)?.classList.add('rt-dragging');
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
  roomElements.push({
    id: nextRoomElementId++, name, wM, lM,
    posX: 40 + (idx % 6) * 130, posY: 40 + Math.floor(idx / 6) * 110,
  });
  if (cust) { cust.value = ''; cust.style.display = 'none'; }
  renderRoom();
  saveState();
  showToast('Dodano element: ' + name);
}
function deleteRoomElement(id) {
  roomElements = roomElements.filter(x => x.id !== id);
  renderRoom();
  saveState();
}
function updateRoomMeta(field, val) {
  roomMeta[field] = Math.max(0, parseFloat(val) || 0);
  renderRoom();
  renderTables();
  saveState();
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

  tip.innerHTML =
    `<div class="rtt-name">${esc(fullName(g))}</div>` +
    `<div class="rtt-cat">${esc(g.category)}</div>` +
    (invLabel ? `<div class="rtt-invited">Zaproszony przez: ${invLabel}</div>` : '');

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
  if (roomDrag) {
    const t  = tables.find(x => x.id === roomDrag.tableId);
    const el = document.querySelector(`.rt-wrap[data-id="${roomDrag.tableId}"]`);
    if (t && el) {
      const dx = e.clientX - roomDrag.startMouseX;
      const dy = e.clientY - roomDrag.startMouseY;
      t.posX = Math.max(0, Math.min(CANVAS_W - el.offsetWidth,  roomDrag.startPosX + dx));
      t.posY = Math.max(0, Math.min(roomCanvasH - el.offsetHeight, roomDrag.startPosY + dy));
      el.style.left = t.posX + 'px';
      el.style.top  = t.posY + 'px';
    }
  }
  if (roomStaffDrag) {
    const t  = staffTables.find(x => x.id === roomStaffDrag.id);
    const el = document.querySelector(`.rt-staff-wrap[data-staff-id="${roomStaffDrag.id}"]`);
    if (t && el) {
      const dx = e.clientX - roomStaffDrag.startMouseX;
      const dy = e.clientY - roomStaffDrag.startMouseY;
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
      const dx = e.clientX - roomElementDrag.startMouseX;
      const dy = e.clientY - roomElementDrag.startMouseY;
      t.posX = Math.max(0, Math.min(CANVAS_W - el.offsetWidth,  roomElementDrag.startPosX + dx));
      t.posY = Math.max(0, Math.min(roomCanvasH - el.offsetHeight, roomElementDrag.startPosY + dy));
      el.style.left = t.posX + 'px';
      el.style.top  = t.posY + 'px';
    }
  }
});

document.addEventListener('mouseup', e => {
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
  renderDashboardWidgets();
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
    body: () => ({
      num: fmt(calcAlcoholTotal()) + ' zł',
      sub: `${calcAlcoholBottles()} butelek`,
    }),
  },
  honeymoon: {
    icon: '✈️', title: 'Podróż poślubna', view: 'budget',
    body: () => {
      const h = budgetData.honeymoon || {};
      return { num: fmt(h.totalAmount || 0) + ' zł', sub: (h.name || '').trim() || 'Podróż poślubna' };
    },
  },
  payments: {
    icon: '💳', title: 'Płatności', view: 'budget',
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
    const onclick = dashEditMode ? '' : `onclick="switchView('${def.view}')"`;
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
    responsible:'both', status:'todo', priority:'med', linkType:'', linkId:null });
  renderTasks(); saveState();
}

// Etykieta i link powiązanego obiektu (Dostawca/Budżet/Prezent)
function taskLinkLabel(t) {
  if (!t.linkType || t.linkId == null) return null;
  if (t.linkType === 'vendor') { const v = vendors.find(x=>x.id===t.linkId); return v ? { icon:'👨‍🍳', text: vendorLabel(v), view:'vendors' } : null; }
  if (t.linkType === 'budget') { const e = budgetData.expenses.find(x=>x.id===t.linkId); return e ? { icon:'💰', text:(e.category==='Inne'?(e.customName||'Wydatek'):e.category), view:'budget' } : null; }
  if (t.linkType === 'gift')   { const g = gifts.find(x=>x.id===t.linkId); return g ? { icon:'🎁', text:(g.description||g.from||'Prezent'), view:'gifts' } : null; }
  return null;
}
function _taskLinkOptions(t) {
  const cur = (t.linkType && t.linkId != null) ? `${t.linkType}:${t.linkId}` : '';
  const groups = [['', '— brak —']];
  vendors.forEach(v => groups.push([`vendor:${v.id}`, '👨‍🍳 ' + vendorLabel(v)]));
  budgetData.expenses.forEach(e => groups.push([`budget:${e.id}`, '💰 ' + (e.category==='Inne'?(e.customName||'Wydatek'):e.category)]));
  gifts.forEach(g => groups.push([`gift:${g.id}`, '🎁 ' + (g.description||g.from||'Prezent')]));
  return { groups, cur };
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
  tasks=tasks.filter(x=>x.id!==id); renderTasks(); saveState();
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
  const link = taskLinkLabel(t);
  const linkStr = link
    ? `<span class="kcard-link" title="Powiązanie" onclick="event.stopPropagation();switchView('${link.view}')">${link.icon} ${esc(link.text)}</span>`
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
    </div>
    <div class="kcard-footer">
      <span class="kcard-person" style="background:${pc}22;color:${pc}">${pl}</span>
      ${dateStr}
      ${linkStr}
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
    if (taskFilters.link === 'none' && t.linkType) return false;
    if (['vendor','budget','gift'].includes(taskFilters.link) && t.linkType !== taskFilters.link) return false;
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
  vendors.push({id:nextVendorId++,category:'Fotograf',customCategory:'',companyName:'',contactName:'',phone:'',email:'',price:0,paymentStatus:'contacted',notes:'',mapUrl:''});
  renderVendors(); saveState();
}
function updateVendor(id,field,value) {
  const v=vendors.find(x=>x.id===id);
  if(v){v[field]=field==='price'?(parseFloat(value)||0):value; renderVendors(); saveState();}
}
function deleteVendor(id) { vendors=vendors.filter(x=>x.id!==id); renderVendors(); saveState(); }

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
    return `<div class="vendor-card">
      <div class="vendor-hdr">
        <select class="vendor-cat" onchange="updateVendor(${v.id},'category',this.value)">${catOpts}</select>
        <span class="vendor-badge" style="background:${st.color}22;color:${st.color}">${st.label}</span>
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
  const noReply   = guests.filter(g => !rsvpEntries.some(e => e.guestId === g.id)).length;
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
function deleteGift(id) { gifts=gifts.filter(x=>x.id!==id); renderGifts(); saveState(); }
function _refreshGiftsSummary() {
  const s=document.getElementById('giftsSummary'); if(!s) return;
  const total=gifts.reduce((sum,g)=>sum+(g.value||0),0);
  const thanked=gifts.filter(g=>g.thanked).length;
  s.innerHTML=`<div class="sum-stat"><span class="sv">${gifts.length}</span><span>Prezentów</span></div>
    <div class="sum-stat"><span class="sv">${fmt(total)} zł</span><span>Łączna wartość</span></div>
    <div class="sum-stat"><span class="sv">${thanked}/${gifts.length}</span><span>Podziękowano</span></div>`;
}
function renderGifts() {
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

// ── TRANSPORT ──
const VEHICLE_TYPES=['Auto wynajęte','Auto własne','Auto rodziców Pana Młodego','Auto rodziców Panny Młodej','Bus','Taxi/Uber','Inne'];
function addVehicle() {
  vehicles.push({id:nextVehicleId++,type:'Auto własne',description:'',driver:'',seats:4,route:'',departureTime:'',guestIds:[]});
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
  const blank = { name: '', address: '', phone: '', pricePerNight: 0, personsPerRoom: 2, bookingLink: '', notes: '' };
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
        <span class="hotel-guests-badge">${gc} gości</span>
        <button class="btn-row-edit" onclick="openEditModal('hotel',${h.id})" title="Edytuj">&#9998;</button>
        <button class="btn-row-del" onclick="deleteHotel(${h.id})">&#128465;</button>
      </div>
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
    const p = e.paid || 0;
    if (p > 0) paid.push({ name: e.category, amount: p, date: e.paymentDate || null });
    const rem = (e.planned || 0) - p;
    if (rem > 0) {
      if (e.paymentDate) toPay.push({ name: e.category, amount: rem, date: e.paymentDate });
      else               planned.push({ name: e.category, amount: rem });
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
  const cats  = [['Państwo Młodzi','Państwo Młodzi'],['Świadkowie','Świadkowie'],['Rodzice','Rodzice'],['Rodzina','Rodzina'],['Znajomi','Znajomi'],['Praca','Praca']];
  const dietV = g.diet || 'standard';
  return `<div class="ef-grid">
    ${_efi('firstName','Imię','text',g.firstName)}
    ${_efi('lastName','Nazwisko','text',g.lastName)}
    ${_efs('category','Kategoria',cats,g.category)}
    ${_efs('gender','Płeć',[['K','♀ Kobieta'],['M','♂ Mężczyzna']],g.gender)}
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
  return `<div class="ef-grid">
    ${_efi('name','Nazwa stołu','text',t.name)}
    ${_efs('shape','Kształt',[['round','⬤ Okrągły'],['rect','▬ Prostokątny']],t.shape)}
    ${_efi('seats','Liczba miejsc','number',t.seats,'min="1" max="30"')}
  </div>`;
}
function _taskForm(t) {
  const link = _taskLinkOptions(t);
  const prio = TASK_PRIORITIES.map(p => [p.value, p.icon + ' ' + p.label]);
  return `<div class="ef-grid">
    ${_efi('name','Nazwa zadania','text',t.name)}
    ${_efs('status','Status',[['todo','Do zrobienia'],['inprogress','W trakcie'],['done','Zrobione'],['cancelled','Anulowane']],t.status)}
    ${_efs('priority','Priorytet',prio,t.priority||'med')}
    ${_efs('responsible','Odpowiedzialny',[['groom','Pan Młody'],['bride','Panna Młoda'],['both','Oboje']],t.responsible)}
    ${_ef('startDate','Data rozpoczęcia',`<input type="date" id="ef_startDate" value="${esc(t.startDate||'')}">`)}
    ${_ef('endDate','Data zakończenia',`<input type="date" id="ef_endDate" value="${esc(t.endDate||'')}">`)}
    ${_ef('dueDate','Termin',`<input type="date" id="ef_dueDate" value="${esc(t.dueDate||'')}">`)}
    ${_efs('taskLink','Powiązanie (Dostawca/Budżet/Prezent)',link.groups,link.cur)}
  </div>`;
}
function _vendorForm(v) {
  const cats = ['Fotograf','Kamerzysta','Muzyka','Kwiaty','Tort','Catering','Transport','Inne'].map(c=>[c,c]);
  const sts  = VENDOR_STATUSES.map(s=>[s.value,s.label]);
  return `<div class="ef-grid">
    ${_efs('category','Kategoria',cats,v.category)}
    ${_efi('companyName','Nazwa firmy','text',v.companyName||'')}
    ${_efi('contactName','Imię kontaktu','text',v.contactName||'')}
    ${_efi('phone','Telefon','tel',v.phone||'')}
    ${_efi('email','Email','email',v.email||'')}
    ${_efi('price','Cena (zł)','number',v.price||0)}
    ${_efs('paymentStatus','Status płatności',sts,v.paymentStatus)}
    ${_efi('mapUrl','Link do Google Maps','url',v.mapUrl||'')}
    ${_eft('notes','Notatki',v.notes||'')}
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
  const cats = EXPENSE_CATEGORIES.map(c=>[c.name, c.icon + ' ' + c.name]);
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
      g.category   = _efv('category') || 'Rodzina';
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
      const lk = _efv('taskLink');
      if (lk) { const [lt, lid] = lk.split(':'); t.linkType = lt; t.linkId = parseInt(lid); }
      else { t.linkType = ''; t.linkId = null; }
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
  const ti       = eventTypeInfo();
  const isWedding = eventTypeKey() === 'wedding';

  // Kolory i widoczne sekcje zależne od typu eventu
  applyEventTheme();
  applyEventSections();

  // Tytuł karty
  document.title = eventNm;

  // Nagłówek aplikacji (z ikoną typu)
  const hdrTitle = document.getElementById('appHeaderTitle');
  if (hdrTitle) hdrTitle.innerHTML = ti.icon + ' ' + esc(eventNm) + ' ' + ti.icon;
  const hdrSub = document.getElementById('appHeaderSubtitle');
  if (hdrSub) hdrSub.textContent = subtitle;

  // Ekran logowania — dla ślubu „Ceremonia", dla innych typów nazwa eventu
  const loginTitle = document.getElementById('loginTitle');
  if (loginTitle) loginTitle.innerHTML = isWedding ? ('Ceremonia<br>' + esc(names)) : esc(eventNm);
  const loginSub = document.getElementById('loginSubtitle');
  if (loginSub) loginSub.textContent = subtitle;

  // Tytuł w nawigacji mobilnej
  const navMobTitle = document.getElementById('navMobTitle');
  if (navMobTitle) navMobTitle.innerHTML = ti.icon + ' ' + esc(isWedding ? names : eventTypeLabel());

  // Tytuł licznika na Dashboardzie
  const heroTitle = document.getElementById('dashboardTitle');
  if (heroTitle) heroTitle.innerHTML = ti.icon + ' ' + esc(ti.heroTitle);

  // Przełącznik eventów
  if (typeof renderEventSwitcher === 'function') renderEventSwitcher();
}

// Zastosuj schemat kolorów typu eventu (przez atrybut data-event-theme na <html>)
function applyEventTheme() {
  document.documentElement.setAttribute('data-event-theme', eventTypeKey());
}

// Pokaż/ukryj zakładki nawigacji zależnie od typu eventu
const _VIEW_NAV_IDS = {
  dashboard:'navDashboard', tables:'navTables', room:'navRoom', rsvp:'navRsvp', budget:'navBudget',
  schedule:'navSchedule', tasks:'navTasks', vendors:'navVendors', gallery:'navGallery', access:'navAccess',
  config:'navConfig', guestcard:'navGuestCard', transport:'navTransport', accommodation:'navAccommodation', gifts:'navGifts',
};
function allowedViewSet() {
  return new Set([...(eventTypeInfo().sections || ALL_EVENT_VIEWS), ...ALWAYS_VIEWS]);
}
function applyEventSections() {
  const allowed = allowedViewSet();
  Object.entries(_VIEW_NAV_IDS).forEach(([view, navId]) => {
    const show = allowed.has(view);
    const btn = document.getElementById(navId);
    if (btn) btn.style.display = show ? '' : 'none';
    document.querySelectorAll(`.mob-nav-btn[onclick*="switchView('${view}')"]`).forEach(b => {
      b.style.display = show ? '' : 'none';
    });
  });
  // Jeśli bieżący widok został ukryty — wróć na Dashboard
  if (typeof currentView !== 'undefined' && !allowed.has(currentView)) {
    if (typeof switchView === 'function') switchView('dashboard');
  }
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
  set('cfgEventType',      eventTypeKey());
  set('cfgEventTypeCustom', appConfig.eventTypeCustom || '');
  _toggleEventTypeCustom();
  try { renderBackupList(); } catch (_) {}
}
// Pokazuje pole własnej nazwy tylko dla typu „Inne"
function _toggleEventTypeCustom() {
  const sel = document.getElementById('cfgEventType');
  const wrap = document.getElementById('cfgEventTypeCustomWrap');
  if (sel && wrap) wrap.style.display = sel.value === 'other' ? '' : 'none';
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
    eventType:      val('cfgEventType') || 'wedding',
    eventTypeCustom: val('cfgEventTypeCustom'),
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

// ── KARTOTEKA GOŚCI (rozszerzone informacje) ──
function renderGuestCard() {
  const cont = document.getElementById('guestCardList');
  if (!cont) return;
  if (!guests.length) {
    cont.innerHTML = '<div class="empty-list">Brak gości. Dodaj gości w sekcji „Stoły i goście".</div>';
    return;
  }
  const menuOpts = appConfig.menuOptions || [];
  const sorted = [...guests].sort((a, b) => fullName(a).localeCompare(fullName(b), 'pl'));
  cont.innerHTML = sorted.map(g => {
    const opts = ['<option value="">— wybierz menu —</option>']
      .concat(menuOpts.map(m => `<option value="${esc(m)}"${g.menuChoice === m ? ' selected' : ''}>${esc(m)}</option>`)).join('');
    return `<div class="gcard">
      <div class="gcard-hdr">
        ${avatarHtml(g, 'avatar-sm')}
        <div class="gcard-name">${esc(fullName(g))}</div>
        <span class="badge badge-cat">${esc(g.category)}</span>
      </div>
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
  }).join('');
}
function updateGuestCardField(id, field, value) {
  const g = guests.find(x => x.id === id);
  if (!g) return;
  g[field] = value;
  saveState();
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
    vehicles, hotels, payments, transportNotes,
    internalTransport, nextInternalTransportId,
    locationLinksSeeded,
  };
}

function saveState() {
  try {
    // Nie zapisuj, dopóki stan nie został w pełni wczytany — chroni stare dane przed nadpisaniem pustym stanem
    if (!_stateReady) return;
    if (!activeEventId) activeEventId = 'default';
    EVENTS[activeEventId] = _serializeState();
    const container = { events: EVENTS, activeEventId, _savedAt: Date.now() };
    localStorage.setItem(STORAGE_KEY, JSON.stringify(container));
    if (typeof firestoreSave === 'function') firestoreSave(container);
  } catch (_) {}
}

// ── ZARZĄDZANIE WIELOMA EVENTAMI ──
function _eventMeta(id) {
  const c = (id === activeEventId) ? appConfig : ((EVENTS[id] && EVENTS[id].appConfig) || {});
  const type = EVENT_TYPES[c.eventType] ? c.eventType : 'wedding';
  return { icon: EVENT_TYPES[type].icon, name: (c.eventName || '').trim() || EVENT_TYPES[type].label };
}
function renderEventSwitcher() {
  const sel = document.getElementById('eventSwitcherSel');
  if (!sel) return;
  const ids = Object.keys(EVENTS);
  if (!ids.length) { sel.innerHTML = ''; return; }
  sel.innerHTML = ids.map(id => {
    const m = _eventMeta(id);
    return `<option value="${id}"${id === activeEventId ? ' selected' : ''}>${m.icon} ${esc(m.name)}</option>`;
  }).join('');
}
function switchEvent(id) {
  if (!EVENTS[id] || id === activeEventId) return;
  EVENTS[activeEventId] = _serializeState();   // zapisz bieżący event
  activeEventId = id;
  _applyEventState(EVENTS[id] || {});          // wczytaj wybrany
  saveState();
  renderAll();
  switchView('dashboard');
  renderEventSwitcher();
  showToast('Przełączono na: ' + _eventMeta(id).name);
}
function createNewEvent() {
  const name = prompt('Nazwa nowego eventu:', 'Nowy event');
  if (name === null) return; // anulowano
  EVENTS[activeEventId] = _serializeState();   // zapisz bieżący
  const id = 'e' + Date.now().toString(36);
  EVENTS[id] = {};                             // pusty stan → backfill do domyślnych
  activeEventId = id;
  _applyEventState({});                        // domyślne wartości
  appConfig = Object.assign({}, DEFAULT_APP_CONFIG, { eventName: (name.trim() || 'Nowy event') });
  saveState();
  renderAll();
  switchView('config');
  renderEventSwitcher();
  showToast('Utworzono event: ' + appConfig.eventName);
}
function deleteActiveEvent() {
  const ids = Object.keys(EVENTS);
  if (ids.length <= 1) { alert('Nie można usunąć jedynego eventu.'); return; }
  if (!confirm('Usunąć ten event i wszystkie jego dane?\nTej operacji nie można cofnąć.')) return;
  delete EVENTS[activeEventId];
  activeEventId = Object.keys(EVENTS)[0];
  _applyEventState(EVENTS[activeEventId] || {});
  saveState();
  renderAll();
  switchView('dashboard');
  renderEventSwitcher();
  showToast('Event usunięty');
}

const LEGACY_BACKUP_KEY = 'wedding-planner-v2:legacy';

// Czy obiekt to stary, „płaski" zapis (sprzed systemu eventów)?
function _isFlatState(o) {
  return !!(o && typeof o === 'object' && !(o.events && o.activeEventId) &&
    (o.guests || o.scheduleEvents || o.appConfig || o.budgetData || o.tasks || o.vendors || o.tables));
}
// Czy stan eventu zawiera jakiekolwiek istotne dane?
function _eventHasData(s) {
  if (!s || typeof s !== 'object') return false;
  const len = a => Array.isArray(a) && a.length;
  return len(s.guests) || len(s.tables) || len(s.scheduleEvents) || len(s.tasks) || len(s.vendors) ||
    len(s.gifts) || len(s.vehicles) || len(s.hotels) || len(s.staffTables) ||
    (s.budgetData && len(s.budgetData.expenses)) ||
    !!(s.appConfig && s.appConfig.eventName) || !!s.weddingDate;
}

// Rozpakowuje zapis do kontenera wielu eventów (migruje stary, „płaski" zapis)
function _normalizeContainer(parsed) {
  if (parsed && parsed.events && typeof parsed.events === 'object' && parsed.activeEventId) {
    const events = parsed.events;
    let active = parsed.activeEventId;
    if (!Object.keys(events).length) events['default'] = {};
    if (!events[active]) active = Object.keys(events)[0];
    return { events, activeEventId: active };
  }
  // Stary zapis (pojedynczy event) → opakuj jako „default"
  return { events: { default: parsed || {} }, activeEventId: 'default' };
}

function loadState() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) { _stateReady = true; return; } // brak danych — świeży start, można zapisywać

    let parsed;
    try { parsed = JSON.parse(raw); } catch (_) { _stateReady = true; return; }

    // Wymóg 4: przed JAKĄKOLWIEK migracją utwórz datowaną kopię zapasową bieżących danych.
    if (_anyHasData(parsed)) { try { _backupBeforeMigration(raw); } catch (_) {} }

    // Stary, „płaski" zapis → zachowaj jednorazowo kopię zapasową, nim cokolwiek nadpiszemy
    if (_isFlatState(parsed)) {
      try { if (!localStorage.getItem(LEGACY_BACKUP_KEY)) localStorage.setItem(LEGACY_BACKUP_KEY, raw); } catch (_) {}
    }

    const container = _normalizeContainer(parsed);

    // Odzyskiwanie: jeśli aktywny event jest pusty, a istnieje kopia zapasowa starych danych —
    // przypisz je do domyślnego eventu (Ślub), aby nie zniknęły.
    let _recovered = false;
    if (!_eventHasData(container.events[container.activeEventId])) {
      try {
        const legacyRaw = localStorage.getItem(LEGACY_BACKUP_KEY);
        const legacy = legacyRaw ? JSON.parse(legacyRaw) : null;
        if (_isFlatState(legacy) && _eventHasData(legacy)) {
          container.events['default'] = legacy;
          container.activeEventId = 'default';
          _recovered = true;
        }
      } catch (_) {}
    }

    EVENTS = container.events;
    activeEventId = container.activeEventId;
    _applyEventState(EVENTS[activeEventId] || {});

    // Po odzyskaniu utrwal stan, by pusty kontener w localStorage/Firestore nie wracał przy przeładowaniu.
    if (_recovered) { try { saveState(); } catch (_) {} }
  } catch (_) {
    // Awaryjny fallback (wymóg 4): jeśli migracja do systemu eventów zawiedzie,
    // wczytaj dane „po staremu" (płaski zapis) bezpośrednio — tymczasowe rozwiązanie,
    // by użytkownik nie stracił dostępu do danych.
    try { _loadFlatFallback(); } catch (_) {}
  }
}

// Awaryjne wczytanie starego, „płaskiego" zapisu (sprzed systemu eventów).
// Szuka danych w kopii zapasowej, głównym kluczu lub wewnątrz kontenera eventów
// i ładuje je do domyślnego eventu „Ślub", omijając pełną logikę migracji.
function _loadFlatFallback() {
  let flat = null;
  for (const key of [LEGACY_BACKUP_KEY, STORAGE_KEY]) {
    try {
      const raw = localStorage.getItem(key);
      const obj = raw ? JSON.parse(raw) : null;
      if (_isFlatState(obj) && _eventHasData(obj)) { flat = obj; break; }
      if (obj && obj.events && typeof obj.events === 'object') {
        const id = Object.keys(obj.events).find(k => _eventHasData(obj.events[k]));
        if (id) { flat = obj.events[id]; break; }
      }
    } catch (_) {}
  }
  if (!flat) { _stateReady = true; return; } // brak czegokolwiek do odzyskania
  EVENTS = { default: flat };
  activeEventId = 'default';
  _applyEventState(flat); // ustawia _stateReady = true po pełnym wczytaniu
  console.warn('[wedding-planner] Awaryjny tryb płaski: migracja eventów zawiodła — wczytano stare dane do eventu „Ślub".');
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
    if (hasData) candidates.push({ key, parsed, savedAt: (parsed && parsed._savedAt) || 0 });
    all.push({ klucz: key, bajty: (raw || '').length, dane: hasData ? '✓ ' + _describeData(parsed) : '—' });
  }
  console.group('%c[wedding-planner] Skan localStorage — znaleziono ' + all.length + ' kluczy', 'font-weight:bold;color:#1a56db');
  try { console.table(all); } catch (_) { console.log(all); }
  console.log('Wszystkie klucze:', all.map(x => x.klucz));
  console.log('Klucze z danymi plannera:', candidates.map(c => c.key));
  console.groupEnd();
  return candidates;
}

// Migruje dowolny znaleziony zapis (płaski lub kontener) do systemu eventów (domyślny event „Ślub").
function _migrateParsedIntoEvents(parsed, sourceLabel) {
  const container = _normalizeContainer(parsed);
  EVENTS = container.events;
  activeEventId = container.activeEventId;
  _applyEventState(EVENTS[activeEventId] || {});
  saveState();
  try { renderAll(); } catch (_) {}
  try { renderEventSwitcher(); } catch (_) {}
  console.log('[wedding-planner] Zmigrowano dane do systemu eventów ze źródła:', sourceLabel);
}

// WYMÓG 3: szuka danych wszędzie (localStorage → Firestore) i przywraca je; w razie braku — komunikat.
async function recoverData() {
  // 1) localStorage — niezależnie od nazwy klucza
  const cands = scanLocalStorage();
  if (cands.length) {
    cands.sort((a, b) => b.savedAt - a.savedAt);
    const best = cands[0];
    try { _backupBeforeMigration(localStorage.getItem(STORAGE_KEY)); } catch (_) {}
    _migrateParsedIntoEvents(best.parsed, 'localStorage:' + best.key);
    showToast('Przywrócono dane z localStorage: ' + best.key);
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
function _backupBeforeMigration(raw) {
  if (!raw) return;
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
  const backups = _listBackups();
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

// Uruchamia pełną diagnostykę + próbę odzyskania (przycisk w Konfiguracji)
function runDataRecovery() {
  console.log('%c[wedding-planner] Diagnostyka danych — start', 'font-weight:bold;color:#059669');
  recoverData().then(() => renderBackupList());
}

// Udostępnij narzędzia z konsoli przeglądarki
try {
  window.scanLocalStorage = scanLocalStorage;
  window.recoverData      = recoverData;
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
    });

    // Back-fill new fields
    guests.forEach(g => {
      if (g.invitedBy === undefined)           g.invitedBy = null;
      if (g.witness === undefined)             g.witness = null;
      if (g.diet === undefined)                g.diet = 'standard';
      if (g.dietOther === undefined)           g.dietOther = '';
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
    });
    vendors        = s.vendors        || [];
    rsvpEntries    = s.rsvpEntries    || [];
    rsvpEntries.forEach(e => { if (e.companionName === undefined) e.companionName = ''; });
    gifts          = s.gifts          || [];
    vehicles       = s.vehicles       || [];
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
    vendors.forEach(v => { if (v.customCategory === undefined) v.customCategory = ''; if (v.mapUrl === undefined) v.mapUrl = ''; });
    hotels.forEach(h => { if (h.personsPerRoom === undefined) h.personsPerRoom = 2; });

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

// ── INIT ──
document.getElementById('guestFirstName').addEventListener('keydown', e => { if (e.key==='Enter') document.getElementById('guestLastName').focus(); });
document.getElementById('guestLastName').addEventListener('keydown',  e => { if (e.key==='Enter') addGuest(); });
document.getElementById('tableName').addEventListener('keydown',      e => { if (e.key==='Enter') addTable(); });
const _dietSel = document.getElementById('guestDiet');
if (_dietSel) _dietSel.addEventListener('change', function() {
  const row = document.getElementById('dietOtherRow');
  if (row) row.style.display = this.value === 'other' ? '' : 'none';
});

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
