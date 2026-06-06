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
    console.error('[Auth] Firebase SDK nie załadowany — pomijam autoryzację');
    _showApp(null);
    return;
  }

  // Używa już zainicjalizowanej aplikacji Firebase (z firebase-config.js)
  try {
    if (!firebase.apps.length) firebase.initializeApp(firebaseConfig);
    _auth = firebase.auth();
  } catch (e) {
    console.error('[Auth] Błąd inicjalizacji Auth:', e);
    _showApp(null);
    return;
  }

  _auth.onAuthStateChanged(user => {
    if (!user) {
      _showLoginScreen(null);
      return;
    }

    if (!ALLOWED_EMAILS.includes((user.email || '').toLowerCase())) {
      console.warn('[Auth] Nieautoryzowany email:', user.email);
      _auth.signOut();
      _showLoginScreen('Brak dostępu — ta aplikacja jest prywatna.');
      return;
    }

    _showApp(user);
  });
}

function signInWithGoogle() {
  if (!_auth) return;
  _hideLoginError();
  _setSignInBtnState(true);

  const provider = new firebase.auth.GoogleAuthProvider();
  provider.setCustomParameters({ prompt: 'select_account' });

  _auth.signInWithPopup(provider).catch(err => {
    _setSignInBtnState(false);
    if (err.code === 'auth/popup-closed-by-user') return;
    _showLoginError('Błąd logowania: ' + (err.message || 'Spróbuj ponownie.'));
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
  if (errorMsg) _showLoginError(errorMsg);
  _setSignInBtnState(false);
}

function _showApp(user) {
  const ls = document.getElementById('loginScreen');
  const ac = document.getElementById('appContent');
  if (ls) ls.style.display = 'none';
  if (ac) ac.style.display = '';
  _updateNavUser(user);
}

function _updateNavUser(user) {
  const panel = document.getElementById('navUserPanel');
  const photo = document.getElementById('navUserPhoto');
  const name  = document.getElementById('navUserName');
  if (!panel) return;

  if (!user) {
    panel.style.display = 'none';
    return;
  }

  panel.style.display = 'flex';
  if (photo) {
    if (user.photoURL) {
      photo.src = user.photoURL;
      photo.style.display = '';
    } else {
      photo.style.display = 'none';
    }
  }
  if (name) name.textContent = user.displayName || user.email;
}

function _showLoginError(msg) {
  const el = document.getElementById('loginError');
  if (el) { el.textContent = msg; el.style.display = 'block'; }
}

function _hideLoginError() {
  const el = document.getElementById('loginError');
  if (el) el.style.display = 'none';
}

function _setSignInBtnState(loading) {
  const btn = document.getElementById('googleSignInBtn');
  if (!btn) return;
  btn.disabled = loading;
  if (loading) {
    btn.innerHTML = '<span class="gsi-spinner"></span> Logowanie…';
  } else {
    btn.innerHTML = `<svg class="gsi-logo" viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
      <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
      <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
      <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
      <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.18 1.48-4.97 2.31-8.16 2.31-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
    </svg> Zaloguj się przez Google`;
  }
}
