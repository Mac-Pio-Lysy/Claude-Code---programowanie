import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

/// Rodzaj zabezpieczenia zapasowego (gdy biometria nie zadziała).
enum BackupType { pin, pattern }

extension BackupTypeMeta on BackupType {
  String get storageValue => this == BackupType.pin ? 'pin' : 'pattern';
  String get label => this == BackupType.pin ? 'PIN' : 'wzór';
}

/// Lokalna (per urządzenie) obsługa blokady aplikacji: biometria + zapasowy
/// PIN/wzór. Wszystko trzymane w `flutter_secure_storage` — NIGDY w Firestore.
///
/// PIN/wzór nie jest zapisywany jawnie — przechowujemy tylko skrót SHA-256
/// z losową solą. Konto Google pozostaje zalogowane w tle (Firebase), a ten
/// mechanizm jedynie odblokowuje dostęp do aplikacji przy kolejnych otwarciach.
class AppLockService {
  AppLockService({FlutterSecureStorage? storage, LocalAuthentication? auth})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            ),
        _auth = auth ?? LocalAuthentication();

  final FlutterSecureStorage _storage;
  final LocalAuthentication _auth;

  // ── Klucze ───────────────────────────────────────────────────────────
  static const _kLockEnabled = 'lock_enabled';
  static const _kBioEnabled = 'biometric_enabled';
  static const _kSecretHash = 'backup_secret_hash';
  static const _kSecretSalt = 'backup_secret_salt';
  static const _kBackupType = 'backup_type';
  static const _kFails = 'pin_fail_count';
  static const _kPromptDone = 'security_prompt_done';

  /// Po tylu błędnych próbach PIN/wzoru wymagamy ponownego logowania Google.
  static const int maxAttempts = 5;

  // ── Stan blokady ─────────────────────────────────────────────────────

  /// Czy blokada aplikacji jest aktywna (ustawiono zabezpieczenie zapasowe).
  Future<bool> isLockEnabled() async =>
      (await _storage.read(key: _kLockEnabled)) == '1';

  Future<bool> isBiometricEnabled() async =>
      (await _storage.read(key: _kBioEnabled)) == '1';

  Future<BackupType?> backupType() async {
    final v = await _storage.read(key: _kBackupType);
    if (v == 'pin') return BackupType.pin;
    if (v == 'pattern') return BackupType.pattern;
    return null;
  }

  /// Czy pokazano już jednorazową propozycję włączenia biometrii.
  Future<bool> isPromptDone() async =>
      (await _storage.read(key: _kPromptDone)) == '1';

  Future<void> markPromptDone() =>
      _storage.write(key: _kPromptDone, value: '1');

  /// Czy zaproponować konfigurację zabezpieczeń (po pierwszym logowaniu).
  Future<bool> shouldOfferSetup() async =>
      !(await isLockEnabled()) && !(await isPromptDone());

  // ── Biometria (local_auth) ───────────────────────────────────────────

  /// Czy urządzenie ma sprawny i skonfigurowany czytnik biometryczny.
  /// Gdy false — proponujemy wyłącznie PIN/wzór.
  Future<bool> canUseBiometrics() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      final available = await _auth.getAvailableBiometrics();
      return supported && canCheck && available.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  /// Prośba o weryfikację biometryczną. Zwraca true przy sukcesie.
  Future<bool> authenticateBiometric({
    String reason = 'Potwierdź tożsamość, aby odblokować aplikację',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Logowanie biometryczne',
            biometricHint: 'Zweryfikuj tożsamość',
            cancelButton: 'Anuluj',
            biometricNotRecognized: 'Nie rozpoznano — spróbuj ponownie',
            biometricSuccess: 'Rozpoznano',
            goToSettingsButton: 'Ustawienia',
            goToSettingsDescription:
                'Skonfiguruj biometrię w ustawieniach urządzenia.',
          ),
        ],
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  // ── Konfiguracja zabezpieczeń ────────────────────────────────────────

  /// Zapisuje zapasowy sekret (PIN lub serializowany wzór), włącza blokadę
  /// i zeruje licznik błędnych prób. Sekret hashowany SHA-256 + losowa sól.
  Future<void> setBackupSecret(BackupType type, String secret) async {
    final salt = _newSalt();
    await _storage.write(key: _kSecretSalt, value: salt);
    await _storage.write(key: _kSecretHash, value: _hash(secret, salt));
    await _storage.write(key: _kBackupType, value: type.storageValue);
    await _storage.write(key: _kLockEnabled, value: '1');
    await _storage.write(key: _kFails, value: '0');
  }

  /// Włącza/wyłącza szybkie odblokowanie biometrią (blokada pozostaje).
  Future<void> setBiometricEnabled(bool enabled) =>
      _storage.write(key: _kBioEnabled, value: enabled ? '1' : '0');

  /// Weryfikuje wprowadzony PIN/wzór z zapisanym skrótem.
  Future<bool> verifyBackupSecret(String secret) async {
    final salt = await _storage.read(key: _kSecretSalt);
    final hash = await _storage.read(key: _kSecretHash);
    if (salt == null || hash == null) return false;
    return _hash(secret, salt) == hash;
  }

  // ── Licznik błędnych prób ────────────────────────────────────────────

  Future<int> failCount() async =>
      int.tryParse(await _storage.read(key: _kFails) ?? '0') ?? 0;

  /// Zwiększa licznik błędnych prób i zwraca nową wartość.
  Future<int> registerFail() async {
    final next = (await failCount()) + 1;
    await _storage.write(key: _kFails, value: '$next');
    return next;
  }

  Future<void> resetFails() => _storage.write(key: _kFails, value: '0');

  // ── Czyszczenie ──────────────────────────────────────────────────────

  /// Usuwa wszystkie zabezpieczenia (przy wylogowaniu, gdy użytkownik
  /// potwierdzi, lub po przekroczeniu limitu prób).
  Future<void> clearAll() async {
    for (final k in [
      _kLockEnabled,
      _kBioEnabled,
      _kSecretHash,
      _kSecretSalt,
      _kBackupType,
      _kFails,
      _kPromptDone,
    ]) {
      await _storage.delete(key: k);
    }
  }

  // ── Pomocnicze ───────────────────────────────────────────────────────

  String _hash(String secret, String salt) =>
      sha256.convert(utf8.encode('$salt:$secret')).toString();

  String _newSalt() {
    final r = Random.secure();
    return base64Url.encode(List<int>.generate(16, (_) => r.nextInt(256)));
  }
}
