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
const FS_DEBOUNCE_MS = 2000;
const LS_KEY         = 'wedding-planner-v2';

// Unikalny identyfikator urządzenia — pomija własne zapisy w słuchaczu
const _ownDevice = 'd' + Math.random().toString(36).slice(2) + Date.now();

let _db        = null;
let _saveTimer = null;

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
              localStorage.setItem(LS_KEY, JSON.stringify(clean));
              if (typeof loadState === 'function') try { loadState(); } catch (_) {}
              if (typeof renderAll === 'function') try { renderAll(); } catch (_) {}
            } else if (typeof saveState === 'function') {
              // Chmura jest pusta, a mamy lokalne dane — odeślij je z powrotem (uzdrów chmurę).
              try { saveState(); } catch (_) {}
            }
          }
        }
        _badge('synced');
        _startListener();
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

      // Pomiń własne zapisy
      if (data._syncMeta && data._syncMeta.device === _ownDevice) return;

      // Zastosuj zmiany z innego urządzenia
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
        localStorage.setItem(LS_KEY, JSON.stringify(clean));
        if (typeof loadState === 'function') loadState();
        if (typeof renderAll === 'function') renderAll();
        _badge('synced');
        _showRemoteNotice();
      } catch (e) {
        console.error('Błąd zastosowania zmian zdalnych:', e);
      }
    }, () => _badge('error'));
}

// ── Zapis do Firestore (z debounce) ──────────────────────────────────────
function firestoreSave(data) {
  if (!_db) return;
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
