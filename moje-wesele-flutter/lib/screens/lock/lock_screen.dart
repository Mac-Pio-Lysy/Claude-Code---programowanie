import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../services/app_lock_service.dart';
import 'pattern_lock.dart';
import 'pin_pad.dart';

/// Ekran blokady pokazywany przy kolejnych otwarciach aplikacji, gdy włączona
/// jest biometria/PIN. Konto pozostaje zalogowane przez Google w tle — tu
/// jedynie odblokowujemy dostęp.
///
/// • Biometria jako główna metoda (autostart + przycisk).
/// • „Użyj PIN/wzór" jako alternatywa.
/// • Po [AppLockService.maxAttempts] błędnych próbach → [onForceReauth]
///   (wymuszenie ponownego logowania Google).
class LockScreen extends StatefulWidget {
  const LockScreen({
    super.key,
    required this.onUnlocked,
    required this.onForceReauth,
    this.displayName,
  });

  final VoidCallback onUnlocked;
  final VoidCallback onForceReauth;
  final String? displayName;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _lock = AppLockService();

  bool _loading = true;
  bool _bioEnabled = false;
  bool _bioCapable = false;
  BackupType? _backupType;

  bool _showBackup = false;
  String _pin = '';
  bool _error = false;
  int _attemptsLeft = AppLockService.maxAttempts;
  bool _authingBio = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final bioEnabled = await _lock.isBiometricEnabled();
    final capable = bioEnabled ? await _lock.canUseBiometrics() : false;
    final type = await _lock.backupType();
    final fails = await _lock.failCount();
    if (!mounted) return;
    setState(() {
      _bioEnabled = bioEnabled;
      _bioCapable = capable;
      _backupType = type;
      _attemptsLeft = (AppLockService.maxAttempts - fails).clamp(0, 99);
      _showBackup = !(bioEnabled && capable);
      _loading = false;
    });
    if (bioEnabled && capable) _tryBiometric();
  }

  Future<void> _tryBiometric() async {
    if (_authingBio) return;
    setState(() => _authingBio = true);
    final ok = await _lock.authenticateBiometric();
    if (!mounted) return;
    setState(() => _authingBio = false);
    if (ok) {
      await _lock.resetFails();
      widget.onUnlocked();
    }
  }

  Future<void> _verify(String secret) async {
    final ok = await _lock.verifyBackupSecret(secret);
    if (!mounted) return;
    if (ok) {
      await _lock.resetFails();
      widget.onUnlocked();
      return;
    }
    final fails = await _lock.registerFail();
    final left = (AppLockService.maxAttempts - fails).clamp(0, 99);
    if (!mounted) return;
    if (fails >= AppLockService.maxAttempts) {
      await _lock.resetFails();
      widget.onForceReauth();
      return;
    }
    setState(() {
      _error = true;
      _pin = '';
      _attemptsLeft = left;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGradient.last,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.45, 1.0],
            colors: AppColors.bgGradient,
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(AppColors.accent),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Image.asset('assets/ikona_apki.png', width: 64, height: 64),
                      const SizedBox(height: 16),
                      Text(
                        'Aplikacja zablokowana',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.displayName?.isNotEmpty == true
                            ? 'Witaj ponownie, ${widget.displayName}'
                            : 'Odblokuj, aby kontynuować',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textLight),
                      ),
                      const SizedBox(height: 28),
                      if (_showBackup) _backupEntry() else _biometricEntry(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _biometricEntry() {
    return Column(
      children: [
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _authingBio ? null : _tryBiometric,
            child: Container(
              width: 110,
              height: 110,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent, width: 2),
              ),
              child: _authingBio
                  ? const SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(AppColors.accent),
                      ),
                    )
                  : const Icon(Icons.fingerprint,
                      size: 56, color: AppColors.accent),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Dotknij, aby zeskanować odcisk palca',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
        ),
        const SizedBox(height: 24),
        if (_backupType != null)
          TextButton.icon(
            onPressed: () => setState(() {
              _showBackup = true;
              _error = false;
              _pin = '';
            }),
            icon: const Icon(Icons.dialpad, size: 18),
            label: Text('Użyj ${_backupType!.label}'),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
          ),
      ],
    );
  }

  Widget _backupEntry() {
    return Column(
      children: [
        Text(
          _backupType == BackupType.pin
              ? 'Wpisz kod PIN'
              : 'Narysuj wzór odblokowania',
          style: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text),
        ),
        if (_error) ...[
          const SizedBox(height: 6),
          Text(
            'Błędny ${_backupType?.label ?? 'kod'} — pozostało prób: $_attemptsLeft',
            style: GoogleFonts.inter(
                fontSize: 12, color: const Color(0xFFC0392B)),
          ),
        ],
        const SizedBox(height: 24),
        if (_backupType == BackupType.pin)
          PinPad(
            value: _pin,
            error: _error,
            onChanged: (v) => setState(() {
              _pin = v;
              _error = false;
            }),
            onCompleted: _verify,
          )
        else
          PatternLock(
            error: _error,
            onCompleted: (nodes) {
              if (nodes.isEmpty) {
                setState(() => _error = true);
                return;
              }
              _verify(PatternLock.serialize(nodes));
            },
          ),
        const SizedBox(height: 20),
        if (_bioEnabled && _bioCapable)
          TextButton.icon(
            onPressed: () => setState(() {
              _showBackup = false;
              _error = false;
            }),
            icon: const Icon(Icons.fingerprint, size: 18),
            label: const Text('Użyj odcisku palca'),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
          ),
        TextButton(
          onPressed: widget.onForceReauth,
          child: Text(
            'Nie pamiętasz? Zaloguj przez Google',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
          ),
        ),
      ],
    );
  }
}
