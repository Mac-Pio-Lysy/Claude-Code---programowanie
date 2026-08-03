import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../services/guest_space_service.dart';

/// Moderacja interakcji gości (z trybu web gościa) — dla organizatora.
///
/// Czyta podkolekcje `guestSpaces/{guestToken}/…` (RSVP, rady, mapa, kapsuła,
/// księga) i pozwala usuwać nieodpowiednie wpisy. RSVP i kapsuła czasu są
/// czytelne WYŁĄCZNIE dla organizatora (reguły), pozostałe są też publiczne.
class GuestInteractionsScreen extends StatelessWidget {
  const GuestInteractionsScreen({super.key, required this.guestToken});

  final String guestToken;

  static const _tabs = <({String coll, String label})>[
    (coll: 'rsvp', label: 'RSVP'),
    (coll: 'guestbook', label: 'Księga'),
    (coll: 'advice', label: 'Rady'),
    (coll: 'guestMap', label: 'Mapa'),
    (coll: 'timeCapsule', label: 'Kapsuła'),
  ];

  @override
  Widget build(BuildContext context) {
    final service = GuestSpaceService(token: guestToken);
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        backgroundColor: AppColors.bgGradient.last,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0.5,
          title: Text('Interakcje gości',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text)),
          bottom: TabBar(
            isScrollable: true,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textLight,
            indicatorColor: AppColors.accent,
            tabs: [for (final t in _tabs) Tab(text: t.label)],
          ),
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
          child: SafeArea(
            top: false,
            child: TabBarView(
              children: [
                for (final t in _tabs)
                  _InteractionList(service: service, coll: t.coll),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractionList extends StatelessWidget {
  const _InteractionList({required this.service, required this.coll});

  final GuestSpaceService service;
  final String coll;

  Future<void> _delete(BuildContext context, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Usunąć wpis?'),
        content: const Text('Wpis gościa zostanie trwale usunięty.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Anuluj')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC0392B)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (ok == true) await service.deleteEntry(coll, id);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: service.watchCollection(coll),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.accent));
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Nie udało się wczytać: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: AppColors.textLight)),
            ),
          );
        }
        final entries = snapshot.data ?? const [];
        if (entries.isEmpty) {
          return Center(
            child: Text('Brak wpisów.',
                style: GoogleFonts.inter(color: AppColors.textLight)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final e = entries[i];
            return Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2EAF7)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_title(e),
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent)),
                        const SizedBox(height: 2),
                        Text(_body(e),
                            style: GoogleFonts.inter(
                                fontSize: 13, color: AppColors.text)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _delete(context, e['id'] as String),
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: const Color(0xFFC0392B),
                    tooltip: 'Usuń',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _title(Map<String, dynamic> e) {
    final name = (e['name'] as String?) ?? 'Gość';
    if (coll == 'rsvp') {
      final attending = e['attending'] == true;
      final comp = (e['companions'] as num?)?.toInt() ?? 0;
      return '$name — ${attending ? 'Będzie' : 'Nie będzie'}'
          '${attending && comp > 0 ? ' (+$comp)' : ''}';
    }
    if (coll == 'guestMap') {
      final city = (e['city'] as String?) ?? '';
      return city.isNotEmpty ? '$name • $city' : name;
    }
    return name;
  }

  String _body(Map<String, dynamic> e) {
    if (coll == 'rsvp') {
      final diet = (e['diet'] as String?) ?? '';
      final note = (e['note'] as String?) ?? '';
      return [
        if (diet.isNotEmpty) 'Dieta: $diet',
        if (note.isNotEmpty) note,
      ].join('\n');
    }
    return (e['message'] as String?) ?? (e['greeting'] as String?) ?? '';
  }
}
