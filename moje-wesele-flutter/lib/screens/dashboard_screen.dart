import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';
import '../models/dash_widget.dart';
import '../models/gallery_item.dart';
import '../models/wedding_data.dart';
import '../navigation/app_sections.dart';
import '../services/dash_layout_service.dart';
import '../services/gallery_service.dart';

/// Dashboard z konfigurowalnym systemem kafelków (jak w wersji web).
class DashboardScreen extends StatefulWidget {
  DashboardScreen({
    super.key,
    required this.data,
    required this.isLoading,
    required this.uid,
    required this.onOpenSection,
  }) : layoutService = DashLayoutService(uid: uid);

  final WeddingData? data;
  final bool isLoading;
  final String uid;
  final void Function(AppSection) onOpenSection;
  final DashLayoutService layoutService;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _gallery = GalleryService();
  List<String> _layout = List.of(DashWidgets.defaultLayout);
  bool _editMode = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    widget.layoutService.load().then((l) {
      if (!mounted) return;
      setState(() {
        _layout = l;
        _loaded = true;
      });
    });
  }

  void _save() => widget.layoutService.save(_layout);

  void _addWidget(String id) {
    setState(() {
      if (!_layout.contains(id)) _layout.add(id);
    });
    _save();
  }

  void _removeWidget(String id) {
    setState(() => _layout.remove(id));
    _save();
  }

  Future<void> _reset() async {
    await widget.layoutService.reset();
    setState(() => _layout = List.of(DashWidgets.defaultLayout));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.data == null && !_loaded) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppColors.accent),
        ),
      );
    }

    final hidden = DashWidgets.all
        .where((w) => !_layout.contains(w.id))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        _header(),
        const SizedBox(height: 16),
        if (_editMode)
          _editList()
        else
          _grid(),
        if (_editMode && hidden.isNotEmpty) ...[
          const SizedBox(height: 16),
          _availableSection(hidden),
        ],
      ],
    );
  }

  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dashboard',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text)),
              const SizedBox(height: 4),
              Container(
                width: 44,
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient:
                      const LinearGradient(colors: AppColors.dividerGradient),
                ),
              ),
            ],
          ),
        ),
        if (_editMode) ...[
          TextButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Resetuj'),
            style: TextButton.styleFrom(foregroundColor: AppColors.textLight),
          ),
          const SizedBox(width: 4),
          ElevatedButton(
            onPressed: () => setState(() => _editMode = false),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Gotowe'),
          ),
        ] else
          OutlinedButton.icon(
            onPressed: () => setState(() => _editMode = true),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edytuj'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
            ),
          ),
      ],
    );
  }

  Widget _grid() {
    if (_layout.isEmpty) {
      return _emptyHint('Brak kafelków. Kliknij „Edytuj", aby dodać.');
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cols = w >= 900 ? 4 : (w >= 600 ? 3 : 2);
        const gap = 14.0;
        final tileWidth = (w - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final id in _layout)
              SizedBox(width: tileWidth, child: _tileFor(id)),
          ],
        );
      },
    );
  }

  Widget _tileFor(String id) {
    final def = DashWidgets.byId(id);
    if (def == null) return const SizedBox.shrink();
    if (id == 'countdown') {
      return _CountdownTile(
          data: widget.data,
          onTap: () => widget.onOpenSection(def.target));
    }
    if (id == 'gallery') {
      return StreamBuilder<List<GalleryItem>>(
        stream: _gallery.watch(),
        builder: (context, snap) {
          final count = snap.data?.length;
          return _DashTile(
            def: def,
            stat: DashStat(
                count == null ? '…' : '$count', 'zdjęć i filmów'),
            onTap: () => widget.onOpenSection(def.target),
          );
        },
      );
    }
    return _DashTile(
      def: def,
      stat: def.compute(widget.data),
      onTap: () => widget.onOpenSection(def.target),
    );
  }

  Widget _editList() {
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      onReorderItem: (oldIndex, newIndex) {
        setState(() {
          final item = _layout.removeAt(oldIndex);
          _layout.insert(newIndex, item);
        });
        _save();
      },
      children: [
        for (var i = 0; i < _layout.length; i++)
          _editRow(i, DashWidgets.byId(_layout[i])),
      ],
    );
  }

  Widget _editRow(int index, DashWidgetDef? def) {
    final id = _layout[index];
    return Container(
      key: ValueKey(id),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE4F2)),
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.drag_handle, color: AppColors.textLight),
            ),
          ),
          Text(def?.icon ?? '•', style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(def?.title ?? id,
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          IconButton(
            tooltip: 'Ukryj',
            onPressed: () => _removeWidget(id),
            icon: const Icon(Icons.close, size: 18),
            color: const Color(0xFFC0392B),
          ),
        ],
      ),
    );
  }

  Widget _availableSection(List<DashWidgetDef> hidden) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dostępne kafelki',
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final w in hidden)
                ActionChip(
                  avatar: Text(w.icon, style: const TextStyle(fontSize: 14)),
                  label: Text(w.title),
                  onPressed: () => _addWidget(w.id),
                  backgroundColor: const Color(0xFFF1F5F9),
                  side: BorderSide.none,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyHint(String text) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2EAF7)),
        ),
        child: Text(text,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textLight)),
      );
}

/// Kafelek statystyczny (klikalny skrót do sekcji).
class _DashTile extends StatelessWidget {
  const _DashTile({required this.def, required this.stat, required this.onTap});

  final DashWidgetDef def;
  final DashStat stat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: stat.alert
                    ? const Color(0xFFE9A8A8)
                    : const Color(0xFFE2EAF7)),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(def.icon, style: const TextStyle(fontSize: 22)),
                  const Spacer(),
                  if (stat.alert)
                    const Icon(Icons.warning_amber_rounded,
                        size: 16, color: Color(0xFFC0392B)),
                ],
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  stat.value,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(def.title,
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
              const SizedBox(height: 2),
              Text(
                stat.sub,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kafelek „Licznik do ślubu" z tykającym czasem (HH:MM:SS).
class _CountdownTile extends StatefulWidget {
  const _CountdownTile({required this.data, required this.onTap});

  final WeddingData? data;
  final VoidCallback onTap;

  @override
  State<_CountdownTile> createState() => _CountdownTileState();
}

class _CountdownTileState extends State<_CountdownTile> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  DateTime? get _target {
    final date = widget.data?.weddingDate;
    if (date == null) return null;
    final t = (widget.data?.raw['weddingTime'] as String?) ?? '16:00';
    final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(t);
    final hh = m != null ? int.parse(m.group(1)!) : 16;
    final mm = m != null ? int.parse(m.group(2)!) : 0;
    return DateTime(date.year, date.month, date.day, hh, mm);
  }

  @override
  Widget build(BuildContext context) {
    final target = _target;
    final def = DashWidgets.byId('countdown')!;
    DashStat stat;
    if (target == null) {
      stat = const DashStat('—', 'Ustaw datę w Ustawieniach');
    } else {
      final diff = target.difference(DateTime.now());
      if (diff.isNegative) {
        stat = const DashStat('🎉', 'Już po ślubie!');
      } else {
        String p(int n) => n.toString().padLeft(2, '0');
        final days = diff.inDays;
        final h = diff.inHours % 24;
        final m = diff.inMinutes % 60;
        final s = diff.inSeconds % 60;
        stat = DashStat('$days', 'dni · ${p(h)}:${p(m)}:${p(s)}');
      }
    }
    return _DashTile(def: def, stat: stat, onTap: widget.onTap);
  }
}
