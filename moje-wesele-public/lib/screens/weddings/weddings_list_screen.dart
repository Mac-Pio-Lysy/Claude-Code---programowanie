import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/wedding_summary.dart';
import '../../services/user_service.dart';
import '../../services/wedding_service.dart';
import 'create_wedding_sheet.dart';

/// Ekran „Twoje wesela" — pokazywany po wejściu do aplikacji, przed panelem.
///
/// Lista wesel, do których użytkownik ma dostęp (z jego członkostw) oraz
/// przycisk „+ Nowe wesele". Wybór wesela ustawia aktywne `weddingId`
/// (przez [onOpen]) i wczytuje jego dane w panelu głównym.
class WeddingsListScreen extends StatefulWidget {
  const WeddingsListScreen({
    super.key,
    required this.userId,
    required this.onOpen,
    this.displayName,
    this.email,
    this.onSignOut,
  });

  /// Identyfikator użytkownika (uid lub testowy w trybie bypassLogin).
  final String userId;

  /// Wywoływane po wyborze wesela — przekazuje wybrane `weddingId`.
  final ValueChanged<String> onOpen;

  final String? displayName;
  final String? email;

  /// Opcjonalne wylogowanie (pokazuje przycisk w nagłówku, gdy podane).
  final VoidCallback? onSignOut;

  @override
  State<WeddingsListScreen> createState() => _WeddingsListScreenState();
}

class _WeddingsListScreenState extends State<WeddingsListScreen> {
  final WeddingService _weddings = WeddingService();
  final UserService _users = UserService();

  late Future<List<WeddingSummary>> _future;

  @override
  void initState() {
    super.initState();
    // Upewnij się, że profil użytkownika istnieje (users/{uid}).
    _users.ensureUser(
      uid: widget.userId,
      displayName: widget.displayName,
      email: widget.email,
    );
    _future = _load();
  }

  Future<List<WeddingSummary>> _load() =>
      _weddings.listForUser(widget.userId);

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _createWedding() async {
    final draft = await showCreateWeddingSheet(context);
    if (draft == null || !mounted) return;

    String weddingId;
    try {
      weddingId = await _weddings.createWedding(
        userId: widget.userId,
        name: draft.name,
        persons: draft.persons,
        date: draft.date,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Nie udało się utworzyć wesela: $e')));
      return;
    }
    if (!mounted) return;
    // Od razu otwieramy nowo utworzone wesele.
    widget.onOpen(weddingId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGradient.last,
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
              _header(),
              Expanded(
                child: FutureBuilder<List<WeddingSummary>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation(AppColors.accent),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return _errorState(snapshot.error);
                    }
                    final weddings = snapshot.data ?? const [];
                    if (weddings.isEmpty) return _emptyState();
                    return _list(weddings);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createWedding,
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          'Nowe wesele',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Twoje wesela',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Wybierz wesele lub utwórz nowe',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          if (widget.onSignOut != null)
            IconButton(
              tooltip: 'Wyloguj',
              onPressed: widget.onSignOut,
              icon: const Icon(Icons.logout, color: Color(0xFFC0392B)),
            ),
        ],
      ),
    );
  }

  Widget _list(List<WeddingSummary> weddings) {
    return RefreshIndicator(
      onRefresh: () async => _reload(),
      color: AppColors.accent,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
        itemCount: weddings.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _WeddingCard(
          wedding: weddings[i],
          onTap: () => widget.onOpen(weddings[i].id),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(alpha: 0.08),
                  ),
                  child: const Icon(Icons.favorite_border,
                      size: 44, color: AppColors.accent),
                ),
                const SizedBox(height: 24),
                Text(
                  'Nie masz jeszcze żadnego wesela',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Utwórz pierwsze wesele, aby rozpocząć organizację.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: _createWedding,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                  ),
                  icon: const Icon(Icons.add),
                  label: Text(
                    'Utwórz pierwsze wesele',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 44, color: Color(0xFFC0392B)),
            const SizedBox(height: 16),
            Text(
              'Nie udało się wczytać wesel',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              label: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Karta pojedynczego wesela na liście.
class _WeddingCard extends StatelessWidget {
  const _WeddingCard({required this.wedding, required this.onTap});

  final WeddingSummary wedding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0.5,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE3EAF6)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.accent.withValues(alpha: 0.14),
                      AppColors.accent2.withValues(alpha: 0.10),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: const Text('💍', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wedding.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    if (wedding.persons.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        wedding.persons,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.event,
                            size: 14, color: AppColors.textLight),
                        const SizedBox(width: 4),
                        Text(
                          _dateLabel(wedding.date),
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.textLight),
                        ),
                        const SizedBox(width: 12),
                        _roleChip(wedding.roleLabel),
                      ],
                    ),
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

  Widget _roleChip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8A6D26),
          ),
        ),
      );

  static String _dateLabel(DateTime? date) {
    if (date == null) return 'Data do ustalenia';
    const months = [
      'stycznia', 'lutego', 'marca', 'kwietnia', 'maja', 'czerwca',
      'lipca', 'sierpnia', 'września', 'października', 'listopada', 'grudnia'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
