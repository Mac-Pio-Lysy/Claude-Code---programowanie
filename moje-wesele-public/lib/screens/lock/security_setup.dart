import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../services/app_lock_service.dart';
import 'pattern_lock.dart';
import 'pin_pad.dart';

/// Ekran konfiguracji zabezpieczenia zapasowego (PIN lub wzór) wymaganego
/// przy włączaniu blokady aplikacji. Może też od razu włączyć biometrię.
///
/// Użyj [SecuritySetup.start] — pełny przepływ (potwierdzenie biometrii →
/// ustawienie PIN/wzoru). Zwraca `true`, gdy zabezpieczenia zostały zapisane.
class SecuritySetupScreen extends StatefulWidget {
  const SecuritySetupScreen({
    super.key,
    required this.enableBiometric,
    this.changeOnly = false,
  });

  /// Czy po zapisaniu PIN/wzoru włączyć też szybkie odblokowanie biometrią.
  final bool enableBiometric;

  /// Tryb samej zmiany PIN/wzoru (blokada już aktywna) — inny tytuł.
  final bool changeOnly;

  /// Uruchamia pełny przepływ włączania zabezpieczeń.
  static Future<bool> start(
    BuildContext context, {
    required bool withBiometric,
    bool changeOnly = false,
  }) async {
    final lock = AppLockService();
    var bio = withBiometric;

    if (bio && !changeOnly) {
      final ok = await lock.authenticateBiometric(
        reason: 'Potwierdź odcisk palca, aby włączyć logowanie biometryczne',
      );
      if (!ok) {
        if (!context.mounted) return false;
        final onlyPin = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Biometria niepotwierdzona'),
            content: const Text(
                'Nie udało się potwierdzić odcisku palca. Czy ustawić samo '
                'zabezpieczenie zapasowe (PIN lub wzór)?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Anuluj'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                child: const Text('Ustaw PIN/wzór'),
              ),
            ],
          ),
        );
        if (onlyPin != true) return false;
        bio = false;
      }
    }

    if (!context.mounted) return false;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SecuritySetupScreen(
          enableBiometric: bio,
          changeOnly: changeOnly,
        ),
      ),
    );
    return result == true;
  }

  @override
  State<SecuritySetupScreen> createState() => _SecuritySetupScreenState();
}

enum _Step { choose, enter, confirm }

class _SecuritySetupScreenState extends State<SecuritySetupScreen> {
  final _lock = AppLockService();

  _Step _step = _Step.choose;
  BackupType? _type;
  String _first = '';
  String _pin = '';
  bool _error = false;
  bool _saving = false;

  String get _title => switch (_step) {
        _Step.choose => 'Wybierz zabezpieczenie zapasowe',
        _Step.enter => _type == BackupType.pin
            ? 'Ustaw kod PIN (4 cyfry)'
            : 'Narysuj wzór odblokowania',
        _Step.confirm => _type == BackupType.pin
            ? 'Powtórz kod PIN'
            : 'Powtórz wzór, aby potwierdzić',
      };

  void _pick(BackupType t) =>
      setState(() {
        _type = t;
        _step = _Step.enter;
        _pin = '';
        _first = '';
        _error = false;
      });

  void _onFirst(String secret) {
    if (secret.isEmpty) {
      setState(() => _error = true);
      return;
    }
    setState(() {
      _first = secret;
      _pin = '';
      _error = false;
      _step = _Step.confirm;
    });
  }

  Future<void> _onConfirm(String secret) async {
    if (secret != _first) {
      setState(() {
        _error = true;
        _pin = '';
        // Wracamy do ponownego wpisania od początku.
        _step = _Step.enter;
        _first = '';
      });
      _toast(_type == BackupType.pin
          ? 'Kody PIN się różnią — spróbuj ponownie'
          : 'Wzory się różnią — spróbuj ponownie');
      return;
    }
    setState(() => _saving = true);
    await _lock.setBackupSecret(_type!, secret);
    await _lock.setBiometricEnabled(widget.enableBiometric);
    await _lock.markPromptDone();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
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
          child: Column(
            children: [
              _topBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      const Text('🔐', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 12),
                      Text(
                        _title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.enableBiometric
                            ? 'PIN/wzór posłuży, gdy odcisk palca nie zadziała '
                                '(np. mokry palec).'
                            : 'To zabezpieczenie odblokuje aplikację przy '
                                'kolejnych otwarciach.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textLight),
                      ),
                      const SizedBox(height: 28),
                      if (_saving)
                        const Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation(AppColors.accent),
                          ),
                        )
                      else
                        _body(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (_step == _Step.choose) {
                Navigator.of(context).pop(false);
              } else {
                setState(() {
                  _step = _step == _Step.confirm ? _Step.enter : _Step.choose;
                  _pin = '';
                  _first = '';
                  _error = false;
                });
              }
            },
            icon: const Icon(Icons.arrow_back, color: AppColors.text),
          ),
          Expanded(
            child: Text(
              widget.changeOnly ? 'Zmiana zabezpieczenia' : 'Konfiguracja blokady',
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    switch (_step) {
      case _Step.choose:
        return Column(
          children: [
            _methodCard(
              icon: Icons.pin_outlined,
              title: 'Kod PIN',
              subtitle: '4 cyfry',
              onTap: () => _pick(BackupType.pin),
            ),
            const SizedBox(height: 12),
            _methodCard(
              icon: Icons.pattern_outlined,
              title: 'Wzór graficzny',
              subtitle: 'Połącz co najmniej 4 punkty',
              onTap: () => _pick(BackupType.pattern),
            ),
          ],
        );
      case _Step.enter:
      case _Step.confirm:
        final onDone = _step == _Step.enter ? _onFirst : _onConfirm;
        if (_type == BackupType.pin) {
          return PinPad(
            value: _pin,
            error: _error,
            onChanged: (v) => setState(() {
              _pin = v;
              _error = false;
            }),
            onCompleted: onDone,
          );
        }
        return PatternLock(
          error: _error,
          onCompleted: (nodes) {
            if (nodes.isEmpty) {
              setState(() => _error = true);
              _toast('Wzór jest za krótki — połącz min. 4 punkty');
              return;
            }
            onDone(PatternLock.serialize(nodes));
          },
        );
    }
  }

  Widget _methodCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2EAF7)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF3FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text)),
                    Text(subtitle,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textLight)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textLight),
            ],
          ),
        ),
      ),
    );
  }
}
