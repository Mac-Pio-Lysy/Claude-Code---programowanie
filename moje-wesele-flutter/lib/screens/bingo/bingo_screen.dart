import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/bingo.dart';
import '../../models/schedule_event.dart';
import '../../models/wedding_data.dart';
import '../../services/bingo_service.dart';
import '../../services/firestore_service.dart';
import '../../services/pdf_service.dart';
import '../budget/budget_fields.dart';

/// Sekcja „Ślubne Bingo" — baza pól, generator i wydruki PDF.
class BingoScreen extends StatefulWidget {
  BingoScreen({
    super.key,
    required this.data,
    required FirestoreService firestore,
  }) : service = BingoService(firestore: firestore);

  final WeddingData? data;
  final BingoService service;

  @override
  State<BingoScreen> createState() => _BingoScreenState();
}

class _BingoScreenState extends State<BingoScreen> {
  final _newField = TextEditingController();
  List<String>? _previewBoard;
  int _boardCount = 1;
  String _format = 'A4';
  bool _generating = false;

  @override
  void dispose() {
    _newField.dispose();
    super.dispose();
  }

  List<BingoField> get _fields => [
        for (final e in widget.data?.raw['bingoFields'] ?? const [])
          if (e is Map) BingoField(Map<String, dynamic>.from(e)),
      ];

  List<ScheduleEvent> get _events => [
        for (final e in widget.data?.raw['scheduleEvents'] ?? const [])
          if (e is Map) ScheduleEvent(Map<String, dynamic>.from(e)),
      ];

  bool get _useSchedule => widget.data?.raw['bingoUseSchedule'] != false;
  String get _centerMode =>
      (widget.data?.raw['bingoCenterMode'] as String?) ?? 'gratis';
  Set<int> get _excluded {
    final v = widget.data?.raw['bingoScheduleExclude'];
    return v is List
        ? v.map((e) => (e as num?)?.toInt()).whereType<int>().toSet()
        : <int>{};
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  void _generatePreview() {
    final pool = BingoEngine.pool(widget.data);
    if (pool.length < 24) {
      _toast('Potrzeba min. 24 pól w puli (jest ${pool.length}).');
      return;
    }
    setState(() => _previewBoard = BingoEngine.generateBoard(pool, Random()));
  }

  Future<void> _generatePdf() async {
    final pool = BingoEngine.pool(widget.data);
    if (pool.length < 24) {
      _toast('Potrzeba min. 24 pól w puli (jest ${pool.length}).');
      return;
    }
    setState(() => _generating = true);
    try {
      final rng = Random();
      final boards = [
        for (var i = 0; i < _boardCount; i++)
          BingoEngine.generateBoard(pool, rng),
      ];
      final bytes = await PdfService.bingo(
        boards: boards,
        centerLabel: BingoEngine.centerLabel(widget.data),
        format: pdfFormatFromLabel(_format),
      );
      await PdfService.preview(bytes, 'bingo.pdf');
    } catch (e) {
      _toast('Błąd generowania PDF: $e');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fields = _fields;
    final activeCount = fields.where((f) => f.enabled).length;
    final pool = BingoEngine.pool(widget.data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Text('Ślubne Bingo',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text)),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            children: [
              _generatorCard(pool.length),
              const SizedBox(height: 12),
              if (_previewBoard != null) _previewCard(),
              if (_previewBoard != null) const SizedBox(height: 12),
              _settingsCard(),
              const SizedBox(height: 12),
              _fieldsCard(fields, activeCount),
            ],
          ),
        ),
      ],
    );
  }

  Widget _generatorCard(int poolSize) {
    return _card(
      title: 'Generator plansz',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pula losowania: $poolSize pól',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textLight)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _generatePreview,
                  icon: const Icon(Icons.casino_outlined, size: 18),
                  label: const Text('Losuj podgląd'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('Liczba plansz:',
                  style: GoogleFonts.inter(fontSize: 13)),
              const SizedBox(width: 8),
              _stepper(Icons.remove, () {
                if (_boardCount > 1) setState(() => _boardCount--);
              }),
              SizedBox(
                width: 36,
                child: Text('$_boardCount',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              _stepper(Icons.add, () {
                if (_boardCount < 50) setState(() => _boardCount++);
              }),
              const Spacer(),
              DropdownButton<String>(
                value: _format,
                items: const [
                  DropdownMenuItem(value: 'A4', child: Text('A4')),
                  DropdownMenuItem(value: 'A5', child: Text('A5')),
                  DropdownMenuItem(value: 'A6', child: Text('A6')),
                ],
                onChanged: (v) => setState(() => _format = v ?? 'A4'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _generating ? null : _generatePdf,
              icon: _generating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.picture_as_pdf_outlined),
              label: Text('Generuj PDF ($_boardCount plansz, $_format)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewCard() {
    final board = _previewBoard!;
    final center = BingoEngine.centerLabel(widget.data);
    final cells = <String>[];
    var k = 0;
    for (var i = 0; i < 25; i++) {
      if (i == 12) {
        cells.add(center);
      } else {
        cells.add(k < board.length ? board[k] : '');
        k++;
      }
    }
    return _card(
      title: 'Podgląd planszy',
      child: GridView.count(
        crossAxisCount: 5,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (var i = 0; i < 25; i++)
            Container(
              margin: const EdgeInsets.all(2),
              padding: const EdgeInsets.all(2),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.accent),
                color: i == 12 ? const Color(0xFFE8F1FC) : Colors.white,
              ),
              child: Text(cells[i],
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                      fontSize: 7,
                      fontWeight:
                          i == 12 ? FontWeight.w800 : FontWeight.w400)),
            ),
        ],
      ),
    );
  }

  Widget _settingsCard() {
    return _card(
      title: 'Ustawienia',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.accent,
            title: Text('Dołącz pola z harmonogramu',
                style: GoogleFonts.inter(fontSize: 13)),
            value: _useSchedule,
            onChanged: (v) => widget.service.setUseSchedule(v),
          ),
          if (_useSchedule)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final ev in _events.where((e) => !e.private && e.name.isNotEmpty))
                    Row(
                      children: [
                        Checkbox(
                          value: !_excluded.contains(ev.id),
                          activeColor: AppColors.accent,
                          onChanged: (v) => widget.service
                              .setScheduleEventExcluded(ev.id ?? 0, v != true),
                        ),
                        Expanded(
                          child: Text(ev.name,
                              style: GoogleFonts.inter(fontSize: 12)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          const Divider(),
          Text('Środkowe pole planszy',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            children: [
              _modeChip('GRATIS', 'gratis'),
              const SizedBox(width: 8),
              _modeChip('Imiona Pary Młodej', 'names'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeChip(String label, String value) {
    final selected = _centerMode == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => widget.service.setCenterMode(value),
      showCheckmark: false,
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: selected ? Colors.white : AppColors.textLight,
      ),
      selectedColor: AppColors.accent,
      backgroundColor: Colors.white,
      side: BorderSide(
          color: selected ? AppColors.accent : const Color(0xFFDCE4F2)),
    );
  }

  Widget _fieldsCard(List<BingoField> fields, int activeCount) {
    return _card(
      title: 'Baza pól ($activeCount / ${fields.length} aktywnych)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newField,
                  decoration: InputDecoration(
                    hintText: 'Nowe pole bingo…',
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFF),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFDCE4F2)),
                    ),
                  ),
                  onSubmitted: (_) => _addField(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addField,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                child: const Text('Dodaj'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (fields.isEmpty)
            Text('Brak pól. Dodaj pierwsze powyżej.',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textLight))
          else
            for (final f in fields)
              Row(
                children: [
                  Checkbox(
                    value: f.enabled,
                    activeColor: AppColors.accent,
                    onChanged: (v) => widget.service
                        .updateField(f.id ?? 0, enabled: v ?? false),
                  ),
                  Expanded(
                    child: BudgetTextField(
                      key: ValueKey('bingo-${f.id}'),
                      initial: f.text,
                      hint: 'Treść pola…',
                      onSaved: (v) =>
                          widget.service.updateField(f.id ?? 0, text: v),
                    ),
                  ),
                  IconButton(
                    onPressed: () => widget.service.deleteField(f.id ?? 0),
                    icon: const Icon(Icons.close, size: 18),
                    color: const Color(0xFFC0392B),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
        ],
      ),
    );
  }

  void _addField() {
    final t = _newField.text.trim();
    if (t.isEmpty) return;
    widget.service.addField(t);
    _newField.clear();
  }

  Widget _stepper(IconData icon, VoidCallback onTap) => Material(
        color: const Color(0xFFEEF3FF),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, color: AppColors.accent, size: 18),
          ),
        ),
      );

  Widget _card({required String title, required Widget child}) {
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
