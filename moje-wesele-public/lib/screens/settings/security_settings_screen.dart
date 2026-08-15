import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../services/app_lock_service.dart';
import '../lock/security_setup.dart';
import '../../l10n/app_text.dart';

/// Zakładka „Logowanie" (sekcja Ustawienia): biometria, zapasowy PIN/wzór
/// i status zabezpieczeń. Dane trzymane lokalnie na urządzeniu
/// (flutter_secure_storage), nigdy w Firestore.
class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final _lock = AppLockService();

  bool _loading = true;
  bool _lockEnabled = false;
  bool _bioEnabled = false;
  bool _bioCapable = false;
  BackupType? _backupType;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _lock.isLockEnabled(),
      _lock.isBiometricEnabled(),
      _lock.canUseBiometrics(),
      _lock.backupType(),
    ]);
    if (!mounted) return;
    setState(() {
      _lockEnabled = results[0] as bool;
      _bioEnabled = results[1] as bool;
      _bioCapable = results[2] as bool;
      _backupType = results[3] as BackupType?;
      _loading = false;
    });
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Akcje ──────────────────────────────────────────────────────────

  Future<void> _enableLock() async {
    final ok =
        await SecuritySetupScreen.start(context, withBiometric: _bioCapable);
    if (ok) _toast(AppText.t.sec_enabled);
    await _load();
  }

  Future<void> _disableLock() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppText.t.sec_disableTitle),
        content: Text(
            AppText.t.sec_disableBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppText.t.common_cancel)),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC0392B)),
            child: Text(AppText.t.sec_disable),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _lock.clearAll();
    _toast(AppText.t.sec_disabled);
    await _load();
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final ok = await _lock.authenticateBiometric(
        reason: AppText.t.sec_confirmBiometric,
      );
      if (!ok) {
        _toast(AppText.t.sec_biometricFailed);
        return;
      }
      await _lock.setBiometricEnabled(true);
      _toast(AppText.t.sec_biometricOn);
    } else {
      await _lock.setBiometricEnabled(false);
      _toast(AppText.t.sec_biometricOff);
    }
    await _load();
  }

  Future<void> _changeBackup() async {
    final ok = await SecuritySetupScreen.start(
      context,
      withBiometric: _bioEnabled,
      changeOnly: true,
    );
    if (ok) _toast(AppText.t.sec_backupChanged);
    await _load();
  }

  // ── UI ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGradient.last,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        title: Text(AppText.t.sec_title,
            style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.text)),
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.45, 1.0],
            colors: AppColors.bgGradient,
          ),
        ),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppColors.accent),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  _statusCard(),
                  const SizedBox(height: 12),
                  _masterCard(),
                  if (_lockEnabled) ...[
                    const SizedBox(height: 12),
                    _biometricCard(),
                    const SizedBox(height: 12),
                    _changeCard(),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _statusCard() {
    final active = _lockEnabled;
    return _card(
      AppText.t.sec_statusCard,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statusRow(
            icon: active ? Icons.lock_outline : Icons.lock_open_outlined,
            color: active ? const Color(0xFF059669) : AppColors.textLight,
            text: active
                ? AppText.t.sec_lockOn
                : AppText.t.sec_lockOff,
          ),
          if (active) ...[
            const SizedBox(height: 8),
            _statusRow(
              icon: Icons.fingerprint,
              color: _bioEnabled ? AppColors.accent : AppColors.textLight,
              text: _bioEnabled
                  ? AppText.t.sec_biometricStatusOn
                  : AppText.t.sec_biometricStatusOff,
            ),
            const SizedBox(height: 8),
            _statusRow(
              icon: _backupType == BackupType.pattern
                  ? Icons.pattern_outlined
                  : Icons.pin_outlined,
              color: AppColors.accent,
              text:
                  AppText.t.sec_backupStatus(
                      _backupType?.label ?? AppText.t.sec_backupPin),
            ),
          ],
          if (!_bioCapable) ...[
            const SizedBox(height: 8),
            _statusRow(
              icon: Icons.info_outline,
              color: AppColors.textLight,
              text: AppText.t.sec_noReader,
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusRow(
      {required IconData icon, required Color color, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text)),
        ),
      ],
    );
  }

  Widget _masterCard() {
    return _card(
      AppText.t.sec_lockCard,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.accent,
            value: _lockEnabled,
            onChanged: (v) => v ? _enableLock() : _disableLock(),
            title: Text(
              _bioCapable
                  ? AppText.t.sec_requireBiometric
                  : AppText.t.sec_requirePin,
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              AppText.t.sec_onNextOpen,
              style:
                  GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _biometricCard() {
    return _card(
      AppText.t.sec_fingerprint,
      _bioCapable
          ? SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.accent,
              value: _bioEnabled,
              onChanged: _toggleBiometric,
              title: Text(AppText.t.sec_fastLogin,
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text(
                AppText.t.sec_pinStaysBackup,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textLight),
              ),
            )
          : Text(
              AppText.t.sec_noReaderLong,
              style:
                  GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
            ),
    );
  }

  Widget _changeCard() {
    return _card(
      AppText.t.sec_backupCard,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppText.t.sec_backupCurrent(
                _backupType?.label ?? AppText.t.sec_backupPin),
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _changeBackup,
              icon: const Icon(Icons.password_outlined, size: 18),
              label: Text(AppText.t.sec_changePin),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
