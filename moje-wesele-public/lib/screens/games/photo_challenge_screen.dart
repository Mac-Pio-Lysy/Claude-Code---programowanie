import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../config/public_urls.dart';
import '../../models/photo_challenge.dart';
import '../../models/wedding_data.dart';
import '../../services/firestore_service.dart';
import '../../services/photo_challenge_service.dart';
import '../../widgets/guest_page_tab.dart';
import '../../l10n/app_text.dart';

/// Podzakładka „Foto-wyzwania" (w sekcji „Ślubne gry").
///
/// Cztery wewnętrzne zakładki: „Wyzwania" (panel organizatora), „Galeria"
/// (zdjęcia gości pogrupowane po wyzwaniach), „Ranking" (goście wg liczby
/// wykonanych wyzwań) oraz „Strona dla gości" (kod QR/link).
class PhotoChallengeScreen extends StatefulWidget {
  PhotoChallengeScreen(
      {super.key, required this.data, required FirestoreService firestore})
      : service = PhotoChallengeService(firestore: firestore);

  final WeddingData? data;
  final PhotoChallengeService service;

  @override
  State<PhotoChallengeScreen> createState() => _PhotoChallengeScreenState();
}

class _PhotoChallengeScreenState extends State<PhotoChallengeScreen> {
  late final Stream<List<PhotoChallengeSubmission>> _submissionsStream =
      widget.service.watchSubmissions();

  List<PhotoChallengeTask> get _tasks => [
        for (final e in widget.data?.raw['photoChallengeTasks'] ?? const [])
          if (e is Map) PhotoChallengeTask(Map<String, dynamic>.from(e)),
      ];

  bool get _active => widget.data?.raw['photoChallengesActive'] == true;

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final base = PublicPages.baseUrl(widget.data?.raw);
    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textLight,
            indicatorColor: AppColors.accent,
            dividerColor: const Color(0xFFE2EAF7),
            labelStyle:
                GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
            tabs: [
              Tab(text: 'Wyzwania'),
              Tab(text: 'Galeria'),
              Tab(text: 'Ranking'),
              Tab(text: AppText.t.gp_guestPage),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _tasksTab(),
                _galleryTab(),
                _rankingTab(),
                GuestPageTab(
                  links: [
                    (AppText.t.pc_headerTitle, PublicPages.fotoWyzwania(base))
                  ],
                  intro:
                      AppText.t.photoChallenge_txt1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── WYZWANIA ─────────────────────────────────────────────────────────
  Widget _tasksTab() {
    final tasks = _tasks;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            children: [
              _activeCard(tasks.isNotEmpty),
              const SizedBox(height: 14),
              if (tasks.isEmpty)
                _emptyTasks()
              else
                _reorderable(tasks),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add),
                label: Text(AppText.t.photoChallenge_add),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _activeCard(bool hasTasks) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        activeThumbColor: AppColors.accent,
        value: _active,
        onChanged: hasTasks ? (v) => widget.service.setActive(v) : null,
        title: Text(AppText.t.games_activeForGuests,
            style:
                GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
        subtitle: Text(
          hasTasks
              ? (_active
                  ? AppText.t.pc_activeHint
                  : AppText.t.pc_enableHint)
              : AppText.t.pc_needChallenge,
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
        ),
      ),
    );
  }

  Widget _emptyTasks() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Column(
        children: [
          const Text('📷', style: TextStyle(fontSize: 34)),
          const SizedBox(height: 10),
          Text(AppText.t.photoChallenge_empty,
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text)),
          const SizedBox(height: 6),
          Text(
            AppText.t.photoChallenge_emptyHint,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () async {
              await widget.service.seedExamples();
              _toast(AppText.t.photoChallenge_examplesAdded);
            },
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: Text(AppText.t.photoChallenge_addExamples),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reorderable(List<PhotoChallengeTask> tasks) {
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      onReorderItem: (oldIndex, newIndex) {
        final ids = tasks.map((t) => t.id ?? 0).toList();
        final id = ids.removeAt(oldIndex);
        ids.insert(newIndex, id);
        widget.service.reorderTasks(ids);
      },
      children: [
        for (var i = 0; i < tasks.length; i++)
          _taskCard(tasks[i], i, key: ValueKey(tasks[i].id)),
      ],
    );
  }

  Widget _taskCard(PhotoChallengeTask t, int index, {required Key key}) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.only(top: 2, right: 8),
              child:
                  Icon(Icons.drag_handle, color: AppColors.textLight, size: 20),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppText.t.quiz_numbered(index + 1, t.text),
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(AppText.t.photoChallenge_points(t.points),
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _openForm(existing: t),
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: AppColors.accent,
            visualDensity: VisualDensity.compact,
            tooltip: 'Edytuj',
          ),
          IconButton(
            onPressed: () => _confirmDeleteTask(t),
            icon: const Icon(Icons.delete_outline, size: 18),
            color: const Color(0xFFC0392B),
            visualDensity: VisualDensity.compact,
            tooltip: AppText.t.common_delete,
          ),
        ],
      ),
    );
  }

  Future<void> _openForm({PhotoChallengeTask? existing}) async {
    final draft = await showDialog<({String text, int points})>(
      context: context,
      builder: (_) => _TaskFormDialog(existing: existing),
    );
    if (draft == null) return;
    try {
      if (existing?.id != null) {
        await widget.service
            .updateTask(existing!.id!, text: draft.text, points: draft.points);
        _toast(AppText.t.photoChallenge_saved);
      } else {
        await widget.service.addTask(draft.text, draft.points);
        _toast(AppText.t.photoChallenge_added);
      }
    } catch (e) {
      _toast(AppText.t.common_saveErrorToast('$e'));
    }
  }

  Future<void> _confirmDeleteTask(PhotoChallengeTask t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppText.t.photoChallenge_deleteTitle),
        content: Text(AppText.t.pc_deleteConfirm(t.text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppText.t.common_cancel),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: const Color(0xFFC0392B)),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppText.t.common_delete),
          ),
        ],
      ),
    );
    if (ok != true || t.id == null) return;
    try {
      await widget.service.deleteTask(t.id!);
      _toast(AppText.t.photoChallenge_deleted);
    } catch (e) {
      _toast(AppText.t.common_deleteErrorToast('$e'));
    }
  }

  // ── GALERIA ──────────────────────────────────────────────────────────
  Widget _galleryTab() {
    return StreamBuilder<List<PhotoChallengeSubmission>>(
      stream: _submissionsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _info(AppText.t.pc_loadPhotosError);
        }
        final subs = snapshot.data ?? const <PhotoChallengeSubmission>[];
        if (subs.isEmpty) {
          return _info(AppText.t.photoChallenge_txt2);
        }
        final tasks = _tasks;
        final byChallenge = <int, List<PhotoChallengeSubmission>>{};
        for (final s in subs) {
          byChallenge.putIfAbsent(s.challengeId, () => []).add(s);
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            for (final t in tasks)
              if ((byChallenge[t.id] ?? const []).isNotEmpty)
                _challengeGallery(t.text, byChallenge[t.id]!),
            // Zdjęcia do usuniętych wyzwań:
            for (final entry in byChallenge.entries)
              if (!tasks.any((t) => t.id == entry.key))
                _challengeGallery(AppText.t.pc_deleted, entry.value),
          ],
        );
      },
    );
  }

  Widget _challengeGallery(
      String title, List<PhotoChallengeSubmission> subs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${subs.length}',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: subs.length,
            itemBuilder: (_, i) => _thumb(subs[i]),
          ),
        ],
      ),
    );
  }

  Widget _thumb(PhotoChallengeSubmission s) {
    return GestureDetector(
      onTap: () => _viewSubmission(s),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              s.photoUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : Container(
                      color: const Color(0xFFEEF3FF),
                      alignment: Alignment.center,
                      child: const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))),
              errorBuilder: (_, _, _) => Container(
                color: const Color(0xFFEEF3FF),
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined,
                    color: AppColors.textLight),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black.withValues(alpha: 0.45),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(s.name.isEmpty ? AppText.t.role_guest : s.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _viewSubmission(PhotoChallengeSubmission s) async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: InteractiveViewer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(s.photoUrl, fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s.name.isEmpty ? AppText.t.role_guest : s.name,
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _confirmDeleteSubmission(s);
                    },
                    icon: const Icon(Icons.delete_outline,
                        size: 16, color: Color(0xFFC0392B)),
                    label: Text(AppText.t.common_delete,
                        style: TextStyle(color: Color(0xFFC0392B))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteSubmission(PhotoChallengeSubmission s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppText.t.pc_deletePhotoTitle),
        content: Text(
            'Czy na pewno usunąć zdjęcie od „${s.name.isEmpty ? AppText.t.role_guest : s.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppText.t.common_cancel),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: const Color(0xFFC0392B)),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppText.t.common_delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.service.deleteSubmission(s.id);
      _toast(AppText.t.photoChallenge_photoDeleted);
    } catch (e) {
      _toast(AppText.t.common_deleteErrorToast('$e'));
    }
  }

  // ── RANKING ──────────────────────────────────────────────────────────
  Widget _rankingTab() {
    return StreamBuilder<List<PhotoChallengeSubmission>>(
      stream: _submissionsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final subs = snapshot.data ?? const <PhotoChallengeSubmission>[];
        final taskCount = _tasks.length;

        // Per gość: zbiór wykonanych wyzwań (distinct challengeId).
        final done = <String, Set<int>>{};
        for (final s in subs) {
          final name = s.name.isEmpty ? AppText.t.role_guest : s.name;
          done.putIfAbsent(name, () => <int>{}).add(s.challengeId);
        }
        final ranking = done.entries
            .map((e) => (name: e.key, count: e.value.length))
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _rankSummary(ranking.length, subs.length, taskCount),
            const SizedBox(height: 16),
            Text(AppText.t.games_ranking,
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text)),
            const SizedBox(height: 8),
            if (ranking.isEmpty)
              _info(AppText.t.pc_empty)
            else
              ..._ranking(ranking, taskCount),
          ],
        );
      },
    );
  }

  Widget _rankSummary(int players, int photos, int taskCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EAF7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _stat('$players', AppText.t.gp_participants, AppColors.accent),
          _stat('$photos', AppText.t.pc_photos, const Color(0xFF7C3AED)),
          _stat('$taskCount', AppText.t.pc_challenges, const Color(0xFF059669)),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.inter(fontSize: 11, color: AppColors.textLight)),
        ],
      ),
    );
  }

  List<Widget> _ranking(
      List<({String name, int count})> ranking, int taskCount) {
    const medals = ['🥇', '🥈', '🥉'];
    return [
      for (var i = 0; i < ranking.length; i++)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: i < 3 ? AppColors.accent : const Color(0xFFE2EAF7)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 34,
                child: Text(i < 3 ? medals[i] : '${i + 1}.',
                    style: GoogleFonts.inter(
                        fontSize: i < 3 ? 20 : 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textLight)),
              ),
              Expanded(
                child: Text(ranking[i].name,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                    taskCount > 0
                        ? '${ranking[i].count}/$taskCount'
                        : '${ranking[i].count}',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent)),
              ),
            ],
          ),
        ),
    ];
  }

  Widget _info(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Text(text,
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.inter(fontSize: 14, color: AppColors.textLight)),
        ),
      );
}

/// Formularz dodawania / edycji wyzwania (treść + punkty).
class _TaskFormDialog extends StatefulWidget {
  const _TaskFormDialog({this.existing});
  final PhotoChallengeTask? existing;

  @override
  State<_TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<_TaskFormDialog> {
  late final TextEditingController _text;
  late final TextEditingController _points;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.existing?.text ?? '');
    _points =
        TextEditingController(text: '${widget.existing?.points ?? 1}');
  }

  @override
  void dispose() {
    _text.dispose();
    _points.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing != null ? AppText.t.pc_editChallenge : AppText.t.photoChallenge_add),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _text,
              maxLines: 2,
              decoration: InputDecoration(
                  labelText: AppText.t.photoChallenge_text,
                  hintText: AppText.t.photoChallenge_textHint,
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _points,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Punkty', border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppText.t.common_cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
          onPressed: () {
            final text = _text.text.trim();
            if (text.isEmpty) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                    SnackBar(content: Text(AppText.t.photoChallenge_textRequired)));
              return;
            }
            final points = int.tryParse(_points.text.trim()) ?? 1;
            Navigator.of(context).pop((text: text, points: points));
          },
          child: Text(widget.existing != null ? AppText.t.common_save : 'Dodaj'),
        ),
      ],
    );
  }
}
