// ══════════════════════════════════════════════════════
//  Firebase + Firestore — konfiguracja i synchronizacja
// ══════════════════════════════════════════════════════

const firebaseConfig = {
  apiKey:            'AIzaSyACTtQi2sl5e3mWvfpTGujWYU65z_rHhuc',
  authDomain:        'wedding-planner-27148.firebaseapp.com',
  projectId:         'wedding-planner-27148',
  storageBucket:     'wedding-planner-27148.firebasestorage.app',
  messagingSenderId: '719030954518',
  appId:             '1:719030954518:web:1e79e71d56cf86dfc8a337',
};

const FS_COLLECTION  = 'weddingPlanner';
const FS_DOC_ID      = 'main';
const FS_DEBOUNCE_MS = 3000;   // dłuższy debounce — mniej zapisów, mniej kolizji między urządzeniami
const LS_KEY         = 'wedding-planner-v2';

// Unikalny identyfikator urządzenia — pomija własne zapisy w słuchaczu
const _ownDevice = 'd' + Math.random().toString(36).slice(2) + Date.now();

let _db        = null;
let _saveTimer = null;
let _pendingRemote = null;          // zmiana zdalna odłożona, bo użytkownik właśnie edytuje pole
// Flaga: trwa stosowanie zmiany zdalnej (lokalny zapis ma być wtedy wstrzymany).
// Współdzielona ze script.js (saveState) przez window — przerywa pętlę zapis↔listener.
window.__applyingRemote = window.__applyingRemote || false;

// ── Wskaźnik synchronizacji ─────────────────────────────────────────────
function _badge(status) {
  const el = document.getElementById('syncStatusBadge');
  if (!el) return;
  const cfg = {
    loading: ['sync-loading', '…', 'Łączenie…'],
    syncing: ['sync-syncing', '⟳', 'Synchronizowanie…'],
    synced:  ['sync-ok',     '✓',  'Zsynchronizowano'],
    offline: ['sync-offline','○',  'Tryb offline'],
    error:   ['sync-error',  '!',  'Błąd synchronizacji'],
  }[status] || ['sync-offline', '○', 'Tryb offline'];
  el.className = 'sync-badge ' + cfg[0];
  el.innerHTML = `<span class="sync-icon">${cfg[1]}</span><span class="sync-label">${cfg[2]}</span>`;
}

// ── Inicjalizacja Firebase ───────────────────────────────────────────────
function initFirebaseSync() {
  if (!window.firebase) { _badge('offline'); return; }
  // Kopia zapasowa bieżących danych do localStorage PRZED jakąkolwiek synchronizacją
  try { _backupLocalData(); } catch (_) {}
  try {
    if (!firebase.apps.length) firebase.initializeApp(firebaseConfig);
    _db = firebase.firestore();

    // Pamięć podręczna offline (najlepszy wysiłek)
    _db.enablePersistence({ synchronizeTabs: true }).catch(() => {});

    _badge('loading');

    // Sprawdź czy Firestore ma nowsze dane niż localStorage
    _db.collection(FS_COLLECTION).doc(FS_DOC_ID).get()
      .then(doc => {
        if (doc.exists) {
          const remote  = doc.data();
          let localTs   = 0;
          try {
            const raw = localStorage.getItem(LS_KEY);
            localTs = raw ? (JSON.parse(raw)._savedAt || 0) : 0;
          } catch (_) {}

          if ((remote._savedAt || 0) > localTs) {
            // Zdalne dane są nowsze — zastosuj je, ALE nigdy nie nadpisuj
            // niepustych danych lokalnych pustym zapisem z chmury (ochrona przed
            // skasowaniem danych przez „pusty" kontener eventów).
            const clean = _stripMeta(remote);
            let localData = null;
            try { localData = JSON.parse(localStorage.getItem(LS_KEY) || 'null'); } catch (_) {}
            if (_payloadHasData(clean) || !_payloadHasData(localData)) {
              // stosujemy dane zdalne — wstrzymaj lokalny zapis (bez echa do chmury)
              window.__applyingRemote = true;
              try {
                localStorage.setItem(LS_KEY, JSON.stringify(clean));
                if (typeof loadState === 'function') try { loadState(); } catch (_) {}
                if (typeof renderAll === 'function') try { renderAll(); } catch (_) {}
              } finally {
                window.__applyingRemote = false;
              }
            } else if (typeof saveState === 'function') {
              // Chmura jest pusta, a mamy lokalne dane — odeślij je z powrotem (uzdrów chmurę).
              try { saveState(); } catch (_) {}
            }
          }
          // Jednorazowa migracja: jeśli chmura wciąż trzyma stary kontener wielu eventów,
          // odeślij dane w nowej, płaskiej strukturze (są już wczytane do pamięci aplikacji).
          if (remote && remote.events && typeof remote.events === 'object' && typeof saveState === 'function') {
            try { saveState(); } catch (_) {}
          }
        }
        _badge('synced');
        _startListener();
        // Diagnostyka: zaloguj zawartość Firestore w konsoli (WYMÓG 1).
        try { scanFirestore(); } catch (_) {}
      })
      .catch(() => { _badge('error'); _startListener(); });

  } catch (e) {
    console.error('Firebase init:', e);
    _badge('offline');
  }
}

// ── Słuchacz zmian w czasie rzeczywistym ────────────────────────────────
function _startListener() {
  if (!_db) return;
  _db.collection(FS_COLLECTION).doc(FS_DOC_ID)
    .onSnapshot(snap => {
      if (!snap.exists) return;
      const data = snap.data();

      // Pomiń własne zapisy (porównanie identyfikatora urządzenia)
      if (data._syncMeta && data._syncMeta.device === _ownDevice) return;

      // Jeśli użytkownik właśnie edytuje pole (aktywny input/select/textarea) —
      // NIE nadpisuj teraz; odłóż zmianę i zastosuj po zakończeniu edycji (blur).
      if (_isUserEditing()) {
        _pendingRemote = data;
        _badge('synced');
        return;
      }
      _applyRemoteData(data);
    }, () => _badge('error'));
}

// Czy użytkownik aktywnie edytuje pole formularza?
function _isUserEditing() {
  const el = document.activeElement;
  if (!el) return false;
  const tag = el.tagName;
  if (tag === 'TEXTAREA' || tag === 'SELECT') return true;
  if (tag === 'INPUT') {
    const t = (el.type || 'text').toLowerCase();
    return !['button','submit','checkbox','radio','file','range','color','reset','image'].includes(t);
  }
  return !!el.isContentEditable;
}

// Zastosuj dane zdalne (pod flagą __applyingRemote → bez echa zapisu do chmury)
function _applyRemoteData(data) {
  try {
    const clean = _stripMeta(data);
    // Nie pozwól, by pusty zapis zdalny skasował niepuste dane lokalne.
    let localData = null;
    try { localData = JSON.parse(localStorage.getItem(LS_KEY) || 'null'); } catch (_) {}
    if (!_payloadHasData(clean) && _payloadHasData(localData)) {
      if (typeof saveState === 'function') try { saveState(); } catch (_) {} // odeślij dobre dane do chmury
      _badge('synced');
      return;
    }
    window.__applyingRemote = true;
    try {
      localStorage.setItem(LS_KEY, JSON.stringify(clean));
      if (typeof loadState === 'function') loadState();
      if (typeof renderAll === 'function') renderAll();
    } finally {
      window.__applyingRemote = false;
    }
    _badge('synced');
    _showRemoteNotice();
  } catch (e) {
    console.error('Błąd zastosowania zmian zdalnych:', e);
  }
}

// Gdy użytkownik skończy edycję pola — zastosuj ewentualnie odłożoną zmianę zdalną
document.addEventListener('focusout', () => {
  setTimeout(() => {
    if (_pendingRemote && !_isUserEditing()) {
      const d = _pendingRemote;
      _pendingRemote = null;
      _applyRemoteData(d);
    }
  }, 60);
});

// ── Kopia zapasowa bieżących danych do localStorage (jednorazowo na sesję) ──
function _backupLocalData() {
  try {
    const raw = localStorage.getItem(LS_KEY);
    if (!raw) return;
    // Stała kopia „przed naprawą synchronizacji" — tworzona tylko raz, nigdy nie nadpisywana.
    if (!localStorage.getItem(LS_KEY + '__backup_presync')) {
      localStorage.setItem(LS_KEY + '__backup_presync', raw);
    }
    // Dodatkowa, rotacyjna kopia z bieżącej sesji (zawsze najświeższa lokalnie).
    localStorage.setItem(LS_KEY + '__backup_lastsession', raw);
  } catch (_) {}
}

// ── Zapis do Firestore (z debounce) ──────────────────────────────────────
function firestoreSave(data) {
  if (!_db) return;
  // Nie odsyłaj do chmury zmian, które właśnie z niej przyszły (ochrona przed pętlą)
  if (window.__applyingRemote) return;
  clearTimeout(_saveTimer);
  _badge('syncing');
  _saveTimer = setTimeout(() => {
    const payload = Object.assign({}, data, {
      _syncMeta: { device: _ownDevice, ts: Date.now() },
    });
    _db.collection(FS_COLLECTION).doc(FS_DOC_ID).set(payload)
      .then(() => _badge('synced'))
      .catch(() => _badge('error'));
  }, FS_DEBOUNCE_MS);
}

// ── Natychmiastowy zapis (dla potwierdzeń RSVP) ──────────────────────────
function firestoreSaveNow(data) {
  if (!_db) return Promise.resolve();
  const payload = Object.assign({}, data, {
    _syncMeta: { device: _ownDevice, ts: Date.now() },
  });
  return _db.collection(FS_COLLECTION).doc(FS_DOC_ID).set(payload)
    .catch(e => console.error('Firestore zapis natychmiastowy:', e));
}

// ── WYMÓG 1: diagnostyka Firestore ───────────────────────────────────────
// Skanuje kolekcję główną (oraz potencjalne stare ścieżki), loguje co znaleziono
// i zwraca dane głównego dokumentu (lub dowolnego dokumentu z danymi).
function scanFirestore() {
  if (!_db) { console.warn('[wedding-planner] Firestore niedostępny (offline / brak logowania).'); return Promise.resolve(null); }
  console.group('%c[wedding-planner] Skan Firestore', 'font-weight:bold;color:#7c3aed');
  const has = (typeof _payloadHasData === 'function') ? _payloadHasData : () => '?';
  return _db.collection(FS_COLLECTION).get()
    .then(snap => {
      console.log('Kolekcja /' + FS_COLLECTION + ' — dokumentów: ' + snap.size);
      let mainData = null, anyData = null;
      snap.forEach(doc => {
        const data = _stripMeta(doc.data() || {});
        const hd = has(data);
        console.log('  /' + FS_COLLECTION + '/' + doc.id, { _savedAt: data._savedAt, maDane: hd, klucze: Object.keys(data) });
        if (doc.id === FS_DOC_ID) mainData = data;
        if (hd && !anyData) anyData = data;
      });
      if (!snap.docs.some(d => d.id === FS_DOC_ID)) {
        console.warn('  ⚠ Brak głównego dokumentu /' + FS_COLLECTION + '/' + FS_DOC_ID);
      }
      console.groupEnd();
      // Zwróć główny dokument, a jeśli pusty/brak — pierwszy z danymi (stara ścieżka).
      return (mainData && has(mainData)) ? mainData : (anyData || mainData);
    })
    .catch(e => { console.error('[wedding-planner] Skan Firestore — błąd:', e); console.groupEnd(); return null; });
}

// ── Wczytaj z Firestore jednorazowo (dla rsvp.html) ──────────────────────
function firestoreLoad(callback) {
  if (!_db) { callback(null); return; }
  _db.collection(FS_COLLECTION).doc(FS_DOC_ID).get()
    .then(doc => callback(doc.exists ? _stripMeta(doc.data()) : null))
    .catch(() => callback(null));
}

// ── Usuń metadane synchronizacji z obiektu danych ────────────────────────
function _stripMeta(obj) {
  const { _syncMeta, ...rest } = obj;
  return rest;
}

// ── Czy zapis (kontener wielu eventów LUB stary płaski zapis) ma jakieś dane? ──
// Chroni przed nadpisywaniem realnych danych „pustym" stanem (w localStorage i Firestore).
function _payloadHasData(obj) {
  if (!obj || typeof obj !== 'object') return false;
  // Nowy kontener wielu eventów: { events: {id: stan}, activeEventId }
  if (obj.events && typeof obj.events === 'object') {
    return Object.keys(obj.events).some(id => _stateHasData(obj.events[id]));
  }
  // Stary, płaski zapis (pojedynczy event)
  return _stateHasData(obj);
}
function _stateHasData(s) {
  // Korzystaj z funkcji ze script.js, jeśli już załadowana; w przeciwnym razie minimalny wariant.
  if (typeof _eventHasData === 'function') return _eventHasData(s);
  if (!s || typeof s !== 'object') return false;
  const len = a => Array.isArray(a) && a.length;
  return len(s.guests) || len(s.tables) || len(s.scheduleEvents) || len(s.tasks) ||
    len(s.vendors) || len(s.gifts) || len(s.vehicles) || len(s.hotels) ||
    (s.budgetData && len(s.budgetData.expenses)) ||
    !!(s.appConfig && s.appConfig.eventName) || !!s.weddingDate;
}

// ── Powiadomienie o aktualizacji z innego urządzenia ────────────────────
function _showRemoteNotice() {
  let notice = document.getElementById('syncRemoteNotice');
  if (!notice) {
    notice = document.createElement('div');
    notice.id = 'syncRemoteNotice';
    notice.className = 'sync-remote-notice';
    document.body.appendChild(notice);
  }
  notice.textContent = '🔄 Dane zaktualizowane z innego urządzenia';
  notice.classList.add('show');
  clearTimeout(notice._timer);
  notice._timer = setTimeout(() => notice.classList.remove('show'), 3500);
}

// Udostępnij diagnostykę Firestore z konsoli przeglądarki
try { window.scanFirestore = scanFirestore; } catch (_) {}
