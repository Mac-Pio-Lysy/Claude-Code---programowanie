import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/photo_contest.dart';
import '../../services/guest_space_service.dart';
import '../../services/photo_contest_service.dart';
import '../../services/wedding_service.dart';
import '../../l10n/app_text.dart';

/// Etapy 4/5 „Konkursów fotograficznych": wyniki dla organizatora.
///
/// Organizator widzi punkty ZAWSZE (jego widok czyta `contestVotes`
/// bezpośrednio, `list: orgOf` — reguła etapu 3), niezależnie od tego, czy
/// wyniki zostały już „ujawnione" gościom. „Ujawnij teraz" to jedna akcja,
/// która liczy ranking (etap 4) i zapisuje razem z bieżąco ułożonym
/// werdyktem Pary Młodej (etap 5) — zgodnie z ustaleniem „razem, jedną
/// akcją". Zero zmian w regułach: to zwykły odczyt `list`/zapis
/// `weddings/{id}` (`fullAccess`), oba już istniejące.
class ContestResultsScreen extends StatefulWidget {
  const ContestResultsScreen({
    super.key,
    required this.contest,
    required this.service,
    required this.guestToken,
    required this.weddingId,
  });

  final PhotoContest contest;
  final PhotoContestService service;
  final String guestToken;
  final String weddingId;

  @override
  State<ContestResultsScreen> createState() => _ContestResultsScreenState();
}

class _ContestResultsScreenState extends State<ContestResultsScreen> {
  late final GuestSpaceService _guestSpace = GuestSpaceService(token: widget.guestToken);
  late int? _subcategoryId =
      widget.contest.subcategories.isEmpty ? null : widget.contest.subcategories.first.id;

  List<Map<String, dynamic>> _submissions = const [];
  List<Map<String, dynamic>> _votes = const [];
  StreamSubscription<List<Map<String, dynamic>>>? _subSub;
  StreamSubscription<List<Map<String, dynamic>>>? _voteSub;

  /// Werdykt Pary Młodej w BUDOWIE — zainicjowany z zapisanego stanu (jeśli
  /// już ujawniony), edytowalny lokalnie, wysyłany dopiero razem z
  /// „Ujawnij teraz"/„Zaktualizuj wyniki".
  String? _coupleFirst;
  String? _coupleSecond;
  String? _coupleThird;
  List<String> _honorable = [];

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadSubcategory();
  }

  @override
  void dispose() {
    _subSub?.cancel();
    _voteSub?.cancel();
    super.dispose();
  }

  void _loadSubcategory() {
    _subSub?.cancel();
    _voteSub?.cancel();
    setState(() {
      _submissions = const [];
      _votes = const [];
    });
    final subId = _subcategoryId;
    final saved = subId == null ? null : widget.contest.subcategoryCoupleChoice(subId);
    setState(() {
      _coupleFirst = saved?['first'] as String?;
      _coupleSecond = saved?['second'] as String?;
      _coupleThird = saved?['third'] as String?;
      _honorable = [
        for (final h in (saved?['honorable'] as List?) ?? const []) if (h is String) h,
      ];
    });
    if (subId == null) return;
    _subSub = _guestSpace
        .watchContestSubmissions(widget.contest.id, subId)
        .listen((v) => mounted ? setState(() => _submissions = v) : null);
    _voteSub = _guestSpace
        .watchContestVotes(widget.contest.id, subId)
        .listen((v) => mounted ? setState(() => _votes = v) : null);
  }

  void _selectSubcategory(int id) {
    setState(() => _subcategoryId = id);
    _loadSubcategory();
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  Future<void> _resync() async {
    try {
      await WeddingService().ensureGuestToken(widget.weddingId);
    } catch (_) {}
  }

  Future<void> _reveal() async {
    final subId = _subcategoryId;
    if (subId == null) return;
    setState(() => _busy = true);
    try {
      await widget.service.revealSubcategory(
        guestSpace: _guestSpace,
        contestId: widget.contest.id,
        subcategoryId: subId,
        rankingSize: widget.contest.rankingSize,
        coupleChoice: (_coupleFirst == null &&
                _coupleSecond == null &&
                _coupleThird == null &&
                _honorable.isEmpty)
            ? null
            : {
                'first': _coupleFirst,
                'second': _coupleSecond,
                'third': _coupleThird,
                'honorable': _honorable,
              },
      );
      await _resync();
      if (mounted) _snack(AppText.t.contest_revealed);
    } catch (e) {
      if (mounted) _snack(AppText.t.common_saveErrorToast('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<Map<String, dynamic>> get _ranking => computeContestRanking(
        submissions: _submissions,
        votes: _votes,
        rankingSize: widget.contest.rankingSize,
      );

  int? _coupleRoleOf(String id) {
    if (_coupleFirst == id) return 1;
    if (_coupleSecond == id) return 2;
    if (_coupleThird == id) return 3;
    if (_honorable.contains(id)) return 0; // 0 = wyróżnienie
    return null;
  }

  Future<void> _openCouplePicker(Map<String, dynamic> submission) async {
    final id = submission['id'] as String;
    final current = _coupleRoleOf(id);
    final choice = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(AppText.t.contest_couplePickTitle),
        children: [
          for (final p in [1, 2, 3])
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(p),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Expanded(child: Text(AppText.t.gw_contestPlaceN(p))),
                  if (current == p) const Icon(Icons.check, size: 18, color: AppColors.accent),
                ],
              ),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop(4),
            child: Row(
              children: [
                const Icon(Icons.star_outline, color: AppColors.accent),
                const SizedBox(width: 10),
                Expanded(child: Text(AppText.t.contest_honorableMention)),
                if (current == 0) const Icon(Icons.check, size: 18, color: AppColors.accent),
              ],
            ),
          ),
          if (current != null)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(0),
              child: Row(
                children: [
                  const Icon(Icons.close, color: AppColors.textLight),
                  const SizedBox(width: 10),
                  Text(AppText.t.gw_contestUndo),
                ],
              ),
            ),
        ],
      ),
    );
    if (choice == null) return;
    setState(() {
      // Zawsze najpierw usuń zdjęcie z JAKIEGOKOLWIEK dotychczasowego slotu
      // (miejsce ALBO wyróżnienie) — jak przy głosowaniu gości, jedno
      // zdjęcie = jedna rola naraz.
      if (_coupleFirst == id) _coupleFirst = null;
      if (_coupleSecond == id) _coupleSecond = null;
      if (_coupleThird == id) _coupleThird = null;
      _honorable = [..._honorable]..remove(id);
      switch (choice) {
        case 1:
          _coupleFirst = id;
        case 2:
          _coupleSecond = id;
        case 3:
          _coupleThird = id;
        case 4:
          if (_honorable.length >= 2) {
            _snack(AppText.t.contest_honorableFull);
          } else {
            _honorable = [..._honorable, id];
          }
        case 0:
          break; // cofnij — już usunięte wyżej
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final subs = widget.contest.subcategories;
    return Scaffold(
      backgroundColor: AppColors.bgGradient.last,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        title: Text(widget.contest.name,
            style: GoogleFonts.playfairDisplay(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
      ),
      body: subs.isEmpty
          ? Center(
              child: Text(AppText.t.contest_subcategoriesEmpty,
                  style: GoogleFonts.inter(color: AppColors.textLight)))
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.45, 1.0],
                  colors: AppColors.bgGradient,
                ),
              ),
              child: SafeArea(
                top: false,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (subs.length > 1) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in subs)
                            ChoiceChip(
                              label: Text(s.label),
                              selected: _subcategoryId == s.id,
                              onSelected: (_) => _selectSubcategory(s.id),
                              selectedColor: AppColors.accent.withValues(alpha: 0.15),
                              labelStyle: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: _subcategoryId == s.id
                                      ? AppColors.accent
                                      : AppColors.text),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_subcategoryId != null) ..._subcategoryBody(_subcategoryId!),
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _subcategoryBody(int subId) {
    final revealed = widget.contest.isSubcategoryRevealed(subId);
    final ranking = _ranking;
    return [
      Row(
        children: [
          Expanded(
            child: Text(AppText.t.contest_ranking,
                style: GoogleFonts.playfairDisplay(
                    fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
          ),
          if (revealed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(AppText.t.contest_revealedBadge,
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2E7D32))),
            ),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        AppText.t.contest_rankingHint(_votes.length),
        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
      ),
      const SizedBox(height: 10),
      if (ranking.isEmpty)
        Text(AppText.t.contest_noVotesYet,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight))
      else
        for (var i = 0; i < ranking.length; i++) _rankRow(i + 1, ranking[i]),
      const SizedBox(height: 22),
      Text(AppText.t.contest_coupleChoice,
          style: GoogleFonts.playfairDisplay(
              fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
      const SizedBox(height: 4),
      Text(AppText.t.contest_coupleChoiceHint,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight)),
      const SizedBox(height: 10),
      if (_submissions.isEmpty)
        Text(AppText.t.gw_photosEmpty,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight))
      else
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: _submissions.length,
          itemBuilder: (context, i) => _coupleTile(_submissions[i]),
        ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _busy ? null : _reveal,
          icon: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.campaign_outlined),
          label: Text(revealed ? AppText.t.contest_updateResults : AppText.t.contest_revealNow),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    ];
  }

  Widget _rankRow(int rank, Map<String, dynamic> entry) {
    final url = (entry['photoUrl'] as String?) ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text('$rank',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 40,
              height: 40,
              child: url.isEmpty
                  ? const ColoredBox(color: Color(0xFFF1F5FC))
                  : Image.network(url, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text((entry['name'] as String?) ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Text(AppText.t.contest_points((entry['points'] as num?)?.toInt() ?? 0),
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.accent)),
        ],
      ),
    );
  }

  Widget _coupleTile(Map<String, dynamic> item) {
    final url = (item['photoUrl'] as String?) ?? '';
    final role = _coupleRoleOf(item['id'] as String);
    final label = switch (role) {
      1 => '1',
      2 => '2',
      3 => '3',
      0 => '★',
      _ => null,
    };
    return GestureDetector(
      onTap: () => _openCouplePicker(item),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: role != null ? Border.all(color: AppColors.accent, width: 3) : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              url.isEmpty
                  ? const ColoredBox(color: Color(0xFFF1F5FC))
                  : Image.network(url, fit: BoxFit.cover),
              if (label != null)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent,
                    ),
                    child: Text(label,
                        style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
