// ══════════════════════════════════════════════════════
//  Firebase Authentication — dostęp tylko dla wybranych
// ══════════════════════════════════════════════════════

const ALLOWED_EMAILS = [
  'macholak.piotr@gmail.com',
  'ceremonia.panstwa.macholak@gmail.com',
  'patrycja.staniow@gmail.com',
];

let _auth = null;

function initAuth() {
  if (!window.firebase) {
    console.error('[Auth] Firebase SDK nie załadowany');
    _showApp(null);
    return;
  }

  try {
    if (!firebase.apps.length) firebase.initializeApp(firebaseConfig);
    _auth = firebase.auth();
  } catch (e) {
    console.error('[Auth] Błąd inicjalizacji Auth:', e);
    _showApp(null);
    return;
  }

  // Obsługa wyniku logowania przez przekierowanie (fallback dla zablokowanych popupów)
  _auth.getRedirectResult().catch(err => {
    if (err && err.code !== 'auth/no-current-user') {
      _showLoginError(_errMsg(err));
    }
  });

  _auth.onAuthStateChanged(user => {
    _stopBlockWatcher();

    if (!user) {
      _showLoginScreen(null);
      return;
    }

    const email = (user.email || '').toLowerCase();

    if (!ALLOWED_EMAILS.includes(email)) {
      console.warn('[Auth] Nieautoryzowany email:', user.email);
      _auth.signOut();
      _showLoginScreen('Brak dostępu — ta aplikacja jest prywatna.\nSkontaktuj się z organizatorem.');
      return;
    }

    // Sprawdź czy email nie jest na czarnej liście (blokada w Firestore)
    _checkBlocked(email).then(blocked => {
      if (blocked) {
        console.warn('[Auth] Dostęp zablokowany dla:', email);
        _auth.signOut();
        _showLoginScreen('🚫 Twój dostęp został zablokowany.\nSkontaktuj się z organizatorem.');
        return;
      }
      _showApp(user);
      // Nasłuchuj zmian — wyloguj natychmiast, jeśli konto zostanie zablokowane
      _startBlockWatcher(email);
    });
  });
}

// ── Czarna lista (Firestore: accessControl/main → blockedEmails[]) ──
let _blockWatcherUnsub = null;

function _blockedEmailsFrom(data) {
  const list = (data && data.blockedEmails) || [];
  return list.map(e => (e || '').toLowerCase());
}

function _checkBlocked(email) {
  try {
    const db = firebase.firestore();
    return db.collection('accessControl').doc('main').get()
      .then(doc => doc.exists && _blockedEmailsFrom(doc.data()).includes(email))
      .catch(err => { console.error('[Auth] Odczyt czarnej listy:', err); return false; });
  } catch (e) {
    console.error('[Auth] Firestore niedostępny:', e);
    return Promise.resolve(false);
  }
}

function _startBlockWatcher(email) {
  _stopBlockWatcher();
  try {
    const db = firebase.firestore();
    _blockWatcherUnsub = db.collection('accessControl').doc('main')
      .onSnapshot(doc => {
        if (doc.exists && _blockedEmailsFrom(doc.data()).includes(email)) {
          _stopBlockWatcher();
          if (_auth) _auth.signOut();
          _showLoginScreen('🚫 Twój dostęp został zablokowany.\nSkontaktuj się z organizatorem.');
        }
      }, () => {});
  } catch (_) {}
}

function _stopBlockWatcher() {
  if (_blockWatcherUnsub) { try { _blockWatcherUnsub(); } catch (_) {} _blockWatcherUnsub = null; }
}

function signInWithGoogle() {
  if (!_auth) {
    _showLoginError('Usługa logowania nie jest gotowa. Odśwież stronę i spróbuj ponownie.');
    return;
  }

  _hideLoginError();
  _setBtnLoading(true);

  const provider = new firebase.auth.GoogleAuthProvider();
  provider.setCustomParameters({ prompt: 'select_account' });

  _auth.signInWithPopup(provider).catch(err => {
    // Użytkownik sam zamknął popup — bez komunikatu błędu
    if (err.code === 'auth/popup-closed-by-user' ||
        err.code === 'auth/cancelled-popup-request') {
      _setBtnLoading(false);
      return;
    }

    // Popup zablokowany przez przeglądarkę — przełącz na przekierowanie
    if (err.code === 'auth/popup-blocked') {
      _showLoginError('Popup zablokowany przez przeglądarkę — przekierowuję…');
      _auth.signInWithRedirect(provider).catch(e2 => {
        _setBtnLoading(false);
        _showLoginError(_errMsg(e2));
      });
      return;
    }

    _setBtnLoading(false);
    _showLoginError(_errMsg(err));
  });
}

function authSignOut() {
  if (_auth) _auth.signOut();
}

// ── prywatne helpers ──────────────────────────────────

function _showLoginScreen(errorMsg) {
  const ls = document.getElementById('loginScreen');
  const ac = document.getElementById('appContent');
  if (ls) ls.style.display = 'flex';
  if (ac) ac.style.display = 'none';
  _updateNavUser(null);
  _setBtnLoading(false);
  if (errorMsg) _showLoginError(errorMsg);
}

function _showApp(user) {
  const ls = document.getElementById('loginScreen');
  const ac = document.getElementById('appContent');
  if (ls) ls.style.display = 'none';
  if (ac) ac.style.display = '';
  _updateNavUser(user);
  // Przeładuj spersonalizowany układ dashboardu dla zalogowanego użytkownika
  if (typeof onDashboardUserChange === 'function') onDashboardUserChange();
  // Przewodnik po pierwszym zalogowaniu (per użytkownik)
  if (typeof maybeStartOnboarding === 'function') setTimeout(maybeStartOnboarding, 700);
}

function _updateNavUser(user) {
  const panel = document.getElementById('navUserPanel');
  const photo = document.getElementById('navUserPhoto');
  const name  = document.getElementById('navUserName');
  if (panel) {
    if (!user) {
      panel.style.display = 'none';
    } else {
      panel.style.display = 'flex';
      if (photo) { photo.src = user.photoURL || ''; photo.style.display = user.photoURL ? '' : 'none'; }
      if (name)  name.textContent = user.displayName || user.email;
    }
  }
  // Mobile drawer user panel
  const mobPanel = document.getElementById('mobNavUserPanel');
  const mobName  = document.getElementById('mobNavUserName');
  if (mobPanel) mobPanel.style.display = user ? 'flex' : 'none';
  if (mobName && user) mobName.textContent = user.displayName || user.email;
}

function _setBtnLoading(loading) {
  const btn  = document.getElementById('googleSignInBtn');
  const text = document.getElementById('googleSignInText');
  const spin = document.getElementById('googleSignInSpinner');
  if (!btn) return;
  btn.disabled = loading;
  if (text) text.textContent = loading ? 'Logowanie…' : 'Zaloguj się przez Google';
  if (spin) spin.style.display = loading ? 'inline-block' : 'none';
}

function _showLoginError(msg) {
  const el = document.getElementById('loginError');
  if (el) { el.textContent = msg; el.style.display = 'block'; }
}

function _hideLoginError() {
  const el = document.getElementById('loginError');
  if (el) el.style.display = 'none';
}

function _errMsg(err) {
  const map = {
    'auth/network-request-failed': 'Błąd sieci — sprawdź połączenie z internetem.',
    'auth/too-many-requests':      'Zbyt wiele prób logowania. Poczekaj chwilę i spróbuj ponownie.',
    'auth/user-disabled':          'To konto Google zostało wyłączone.',
    'auth/operation-not-allowed':  'Logowanie przez Google nie jest włączone. Skontaktuj się z administratorem.',
    'auth/invalid-api-key':        'Błąd konfiguracji aplikacji (nieprawidłowy klucz API).',
    'auth/app-not-authorized':     'Ta domena nie jest autoryzowana. Sprawdź ustawienia Firebase Console.',
    'auth/internal-error':         'Wewnętrzny błąd Firebase. Spróbuj ponownie.',
  };
  return map[err.code] || ('Błąd logowania (' + (err.code || '?') + '): ' + (err.message || 'Spróbuj ponownie.'));
}
