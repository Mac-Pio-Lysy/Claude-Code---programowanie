import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app_colors.dart';
import '../../models/wedding_data.dart';
import '../../services/backup_service.dart';
import '../../services/config_service.dart';
import '../../services/firestore_service.dart';
import '../../services/wedding_service.dart';
import '../../utils/format.dart';
import 'guest_visibility_screen.dart';
import 'security_settings_screen.dart';

/// Sekcja „Ustawienia" — konfiguracja, dostęp, narzędzia programistyczne,
/// status synchronizacji i wylogowanie.
class SettingsScreen extends StatefulWidget {
  SettingsScreen({
    super.key,
    required this.data,
    required this.firestore,
    required this.onSignOut,
    required this.onStartTour,
    required this.onOpenPlanning,
  }) : config = ConfigService(firestore: firestore);

  final WeddingData? data;
  final FirestoreService firestore;
  final VoidCallback onSignOut;

  /// Uruchamia przewodnik (z ekranem wyboru tempa).
  final VoidCallback onStartTour;

  /// Otwiera listę „Od czego zacząć?".
  final VoidCallback onOpenPlanning;
  final ConfigService config;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _backups = BackupService();

  late final TextEditingController _eventName;
  late final TextEditingController _displayNames;
  late final TextEditingController _ceremony;
  late final TextEditingController _reception;
  late final TextEditingController _person1;
  late final TextEditingController _person2;
  late final TextEditingController _menu;
  late final TextEditingController _expenseCats;
  late final TextEditingController _witnessCount;
  late final TextEditingController _plannedBudget;
  late final TextEditingController _reserve;
  String _weddingDate = '';
  String _weddingTime = '16:00';

  /// Kod dołączenia dla gości (z `weddings/{id}.joinCode`). Null = jeszcze
  /// wczytywany/generowany.
  String? _joinCode;

  @override
  void initState() {
    super.initState();
    final raw = widget.data?.raw ?? const {};
    final cfg = (raw['appConfig'] is Map)
        ? raw['appConfig'] as Map
        : const {};
    final bd = (raw['budgetData'] is Map) ? raw['budgetData'] as Map : const {};
    final couple = (bd['coupleNames'] is List) ? bd['coupleNames'] as List : const [];

    _eventName = TextEditingController(text: (cfg['eventName'] as String?) ?? '');
    _displayNames =
        TextEditingController(text: (cfg['displayNames'] as String?) ?? '');
    _ceremony =
        TextEditingController(text: (cfg['ceremonyPlace'] as String?) ?? '');
    _reception =
        TextEditingController(text: (cfg['receptionPlace'] as String?) ?? '');
    _person1 = TextEditingController(
        text: couple.isNotEmpty ? couple[0]?.toString() ?? '' : '');
    _person2 = TextEditingController(
        text: couple.length > 1 ? couple[1]?.toString() ?? '' : '');
    _menu = TextEditingController(
        text: (cfg['menuOptions'] is List)
            ? (cfg['menuOptions'] as List).join('\n')
            : '');
    _expenseCats = TextEditingController(
        text: (cfg['expenseCategories'] is List)
            ? (cfg['expenseCategories'] as List).join('\n')
            : '');
    final wc = (cfg['witnessCount'] is num)
        ? (cfg['witnessCount'] as num).toInt()
        : 2;
    _witnessCount = TextEditingController(text: '${wc < 1 ? 2 : wc}');
    final totalNum = (bd['total'] is num) ? (bd['total'] as num).toDouble() : 0.0;
    final reserveNum =
        (bd['reserve'] is num) ? (bd['reserve'] as num).toDouble() : 0.0;
    _plannedBudget =
        TextEditingController(text: totalNum == 0 ? '' : formatPln(totalNum));
    _reserve =
        TextEditingController(text: reserveNum == 0 ? '' : formatPln(reserveNum));
    _weddingDate = (raw['weddingDate'] as String?) ?? '';
    _weddingTime = (raw['weddingTime'] as String?) ?? '16:00';
    _loadJoinCode(raw);
  }

  /// Wczytuje kod dołączenia; gdy brak (starsze wesele) — generuje i zapisuje.
  Future<void> _loadJoinCode(Map raw) async {
    final existing = (raw['joinCode'] as String?)?.trim();
    if (existing != null && existing.isNotEmpty) {
      setState(() => _joinCode = existing);
      return;
    }
    try {
      final code =
          await WeddingService().ensureJoinCode(widget.firestore.weddingId);
      if (mounted) setState(() => _joinCode = code);
    } catch (_) {
      // Ciche niepowodzenie — karta pokaże stan „—".
    }
  }

  @override
  void dispose() {
    for (final c in [
      _eventName, _displayNames, _ceremony, _reception,
      _person1, _person2, _menu, _expenseCats, _witnessCount,
      _plannedBudget, _reserve,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  List<String> _lines(TextEditingController c) =>
      c.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  Future<void> _saveConfig() async {
    await widget.config.saveConfig(AppConfigDraft(
      eventName: _eventName.text.trim(),
      displayNames: _displayNames.text.trim(),
      ceremonyPlace: _ceremony.text.trim(),
      receptionPlace: _reception.text.trim(),
      weddingDate: _weddingDate,
      weddingTime: _weddingTime,
      person1: _person1.text.trim(),
      person2: _person2.text.trim(),
      menuOptions: _lines(_menu),
      expenseCategories: _lines(_expenseCats),
      witnessCount: int.tryParse(_witnessCount.text.trim()) ?? 2,
    ));
    _toast('Konfiguracja zapisana ✓');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Text('Ustawienia',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text)),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            children: [
              _syncCard(),
              const SizedBox(height: 12),
              _helpCard(),
              const SizedBox(height: 12),
              _guestVisibilityCard(),
              const SizedBox(height: 12),
              _joinCodeCard(),
              const SizedBox(height: 12),
              _loginCard(),
              const SizedBox(height: 12),
              _configCard(),
              const SizedBox(height: 12),
              _budgetSettingsCard(),
              const SizedBox(height: 12),
              _accessCard(),
              const SizedBox(height: 12),
              _devCard(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: widget.onSignOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Wyloguj'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC0392B),
                    side: const BorderSide(color: Color(0xFFE9A8A8)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _syncCard() {
    final ok = widget.data != null;
    return _card(
      'Status synchronizacji',
      Row(
        children: [
          Icon(ok ? Icons.cloud_done_outlined : Icons.cloud_sync_outlined,
              color: ok ? const Color(0xFF059669) : AppColors.textLight),
          const SizedBox(width: 8),
          Text(ok ? 'Zsynchronizowano z Firestore' : 'Łączenie…',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _helpCard() {
    return _card(
      'Przewodnik i pomoc',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wróć do interaktywnego przewodnika po aplikacji lub do listy '
            'kroków organizacji wesela.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onStartTour,
              icon: const Text('🧭', style: TextStyle(fontSize: 16)),
              label: const Text('Uruchom przewodnik'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onOpenPlanning,
              icon: const Text('📋', style: TextStyle(fontSize: 16)),
              label: const Text('Od czego zacząć?'),
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

  Widget _joinCodeCard() {
    final code = _joinCode;
    return _card(
      'Kod dołączenia dla gości',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Podaj ten kod gościom (np. na zaproszeniu). Aby dołączyć, gość '
            'wpisuje kod, datę ślubu i nazwisko Państwa Młodych.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
          ),
          const SizedBox(height: 14),
          if (code == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.accent),
                ),
              ),
            )
          else
            Row(
              children: [
                // Kod + przycisk kopiowania
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.accent, width: 1.4),
                        ),
                        child: Text(
                          code,
                          style: GoogleFonts.robotoMono(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 4,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: code));
                          _toast('Skopiowano kod: $code');
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Kopiuj kod'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accent,
                          side: const BorderSide(color: AppColors.accent),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // QR z kodem
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2EAF7)),
                      ),
                      child: QrImageView(
                        data: code,
                        size: 96,
                        eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF1040B0)),
                        dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF1040B0)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Kod QR',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.textLight)),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _guestVisibilityCard() {
    return _card(
      'Widoczność dla gości',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ustal, które sekcje i w jakim czasie widzą goście na stronach '
            'publicznych (np. RSVP do tygodnia przed, galeria od dnia wesela).',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GuestVisibilityScreen(
                    firestore: widget.firestore,
                    raw: widget.data?.raw ?? const {},
                  ),
                ),
              ),
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('Ustaw widoczność sekcji'),
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

  Widget _loginCard() {
    return _card(
      'Logowanie',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Biometria (odcisk palca), PIN lub wzór do odblokowywania '
            'aplikacji przy kolejnych otwarciach.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const SecuritySettingsScreen()),
              ),
              icon: const Icon(Icons.fingerprint, size: 18),
              label: const Text('Logowanie i zabezpieczenia'),
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

  Widget _configCard() {
    return _card(
      'Konfiguracja',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _field('Nazwa wydarzenia', _eventName),
          _field('Osoby', _displayNames),
          Row(
            children: [
              Expanded(
                child: _pickerField('Data ślubu',
                    _weddingDate.isEmpty ? 'Wybierz' : _weddingDate, _pickDate),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _pickerField('Godzina', _weddingTime, _pickTime),
              ),
            ],
          ),
          _field('Miejsce ceremonii', _ceremony),
          _field('Miejsce wesela', _reception),
          Row(
            children: [
              Expanded(child: _field('Osoba 1 (podział kosztów)', _person1)),
              const SizedBox(width: 12),
              Expanded(child: _field('Osoba 2', _person2)),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _field('Liczba świadków', _witnessCount,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Domyślnie 2. Dla nietradycyjnych ślubów możesz ustawić więcej.',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textLight),
                  ),
                ),
              ),
            ],
          ),
          _field('Słownik menu (po jednym w linii)', _menu, maxLines: 4),
          _field('Kategorie wydatków (po jednym w linii)', _expenseCats,
              maxLines: 4),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveConfig,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Zapisz konfigurację'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _budgetSettingsCard() {
    return _card(
      'Ustawienia budżetu',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budżet planowany to kwota założona na start. Rezerwa to opcjonalny '
            'bufor na nieprzewidziane wydatki — doliczany do planowanego jako '
            'bezpiecznik.',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _field('Budżet planowany (zł)', _plannedBudget,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field('Rezerwa (zł)', _reserve,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveBudgetSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Zapisz ustawienia budżetu'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBudgetSettings() async {
    final planned = parsePln(_plannedBudget.text) ?? 0;
    final reserve = parsePln(_reserve.text) ?? 0;
    try {
      await widget.config
          .saveBudgetSettings(plannedBudget: planned, reserve: reserve);
      _toast('Zapisano ustawienia budżetu ✓');
    } catch (e) {
      _toast('Błąd zapisu: $e');
    }
  }

  Widget _accessCard() {
    return _card(
      'Dostęp',
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.group_add_outlined,
              size: 18, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Rejestracja otwarta — każde konto Google może się zalogować '
              'i założyć własne wesele. Dostęp do tego wesela mają osoby z nim '
              'powiązane (właściciel i zaproszeni).',
              style: GoogleFonts.inter(
                  fontSize: 13, height: 1.45, color: AppColors.textLight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _devCard() {
    return _card(
      'Ustawienia programistyczne',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _exportData,
                icon: const Icon(Icons.ios_share, size: 18),
                label: const Text('Eksport danych'),
                style: _devBtnStyle(),
              ),
              OutlinedButton.icon(
                onPressed: _importData,
                icon: const Icon(Icons.file_download_outlined, size: 18),
                label: const Text('Import danych'),
                style: _devBtnStyle(),
              ),
              OutlinedButton.icon(
                onPressed: _createBackup,
                icon: const Icon(Icons.backup_outlined, size: 18),
                label: const Text('Utwórz kopię'),
                style: _devBtnStyle(),
              ),
              OutlinedButton.icon(
                onPressed: _showBackups,
                icon: const Icon(Icons.history, size: 18),
                label: const Text('Kopie zapasowe'),
                style: _devBtnStyle(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Kopie zapasowe (3 ostatnie) przechowywane lokalnie na urządzeniu.',
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.textLight)),
        ],
      ),
    );
  }

  ButtonStyle _devBtnStyle() => OutlinedButton.styleFrom(
        foregroundColor: AppColors.accent,
        side: const BorderSide(color: AppColors.accent),
      );

  Future<void> _exportData() async {
    final data = await widget.config.exportData();
    final json = const JsonEncoder.withIndent('  ')
        .convert(_jsonSafe(data));
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eksport danych (JSON)'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(json,
                style: GoogleFonts.robotoMono(fontSize: 11)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: json));
              _toast('Skopiowano do schowka');
            },
            child: const Text('Kopiuj'),
          ),
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Zamknij')),
        ],
      ),
    );
  }

  Future<void> _importData() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import danych'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⚠ Import ZASTĄPI wszystkie obecne dane. Wklej poprawny JSON.',
                style: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFFC0392B)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                maxLines: 8,
                decoration: const InputDecoration(
                    hintText: 'Wklej JSON…', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Anuluj')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC0392B)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Importuj (zastąp)'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final decoded = jsonDecode(controller.text);
      if (decoded is! Map) {
        _toast('Nieprawidłowy format JSON');
        return;
      }
      await widget.config.importData(Map<String, dynamic>.from(decoded));
      _toast('Zaimportowano dane');
    } catch (e) {
      _toast('Błąd importu: $e');
    }
  }

  Future<void> _createBackup() async {
    final data = await widget.config.exportData();
    await _backups.create(_jsonSafe(data));
    _toast('Utworzono kopię zapasową');
  }

  Future<void> _showBackups() async {
    final list = await _backups.list();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Kopie zapasowe',
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Brak kopii zapasowych.'),
              )
            else
              for (final b in list)
                ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(_fmtDate(b.timestamp)),
                  trailing: TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _restoreBackup(b);
                    },
                    child: const Text('Przywróć'),
                  ),
                ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _restoreBackup(Backup b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Przywrócić kopię?'),
        content: Text(
            'Dane z ${_fmtDate(b.timestamp)} zastąpią obecne dane.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Anuluj')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Przywróć')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final data = await _backups.decode(b);
      await widget.config.importData(data);
      _toast('Przywrócono kopię');
    } catch (e) {
      _toast('Błąd przywracania: $e');
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_weddingDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _weddingDate =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _pickTime() async {
    final parts = _weddingTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.isNotEmpty ? parts[0] : '16') ?? 16,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() => _weddingTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
    }
  }

  Widget _field(String label, TextEditingController c,
      {int maxLines = 1,
      TextInputType? keyboardType,
      List<TextInputFormatter>? inputFormatters}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 2),
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text)),
          ),
          TextField(
            controller: c,
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            decoration: _dec(),
          ),
        ],
      ),
    );
  }

  Widget _pickerField(String label, String value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 2),
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text)),
          ),
          InkWell(
            onTap: onTap,
            child: InputDecorator(
              decoration: _dec(),
              child: Text(value,
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.text)),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec() => InputDecoration(
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF8FAFF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDCE4F2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDCE4F2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
      );

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

  /// Zamienia wartości nieserializowalne do JSON (np. Timestamp) na stringi.
  Map<String, dynamic> _jsonSafe(Map<String, dynamic> data) {
    final encoded = jsonEncode(data, toEncodable: (o) => o.toString());
    return jsonDecode(encoded) as Map<String, dynamic>;
  }
}
