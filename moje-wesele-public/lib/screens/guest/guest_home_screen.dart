import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../services/wedding_service.dart';
import '../guest_web/guest_web_app.dart';

/// Panel GOŚCIA (rola „guest") dla ZALOGOWANEGO użytkownika.
///
/// D1: ten ekran NIE czyta już dokumentu `weddings/{id}`. Czyta wyłącznie
/// `weddings/{id}/guestView/main`, wyciąga z niego `guestToken` i renderuje
/// dokładnie ten sam interfejs, co gość wchodzący przez QR ([GuestWebHome]) —
/// czyli treść z publicznego mirrora `guestSpaces/{token}`, a interakcje do
/// podkolekcji pod tym tokenem.
///
/// Dzięki temu:
///   • gość nie ma technicznego dostępu do budżetu, listy gości ani dostawców
///     (dokument wesela przestaje być mu potrzebny — etap 5 zamknie go regułą),
///   • znika dublowanie interfejsów: jedna wersja sekcji gościa zamiast dwóch,
///   • gość nie trafia już do EDYTORÓW organizatora. Wcześniej dostawał
///     `RsvpScreen`, `GalleryScreen` itd., które zapisują do dokumentu wesela —
///     a to i tak było mu zabronione regułą `update`, więc kończyło się cichym
///     błędem. Teraz wszystko idzie przez `guestSpaces/{token}`, jak u gościa
///     z QR.
class GuestHomeScreen extends StatefulWidget {
  const GuestHomeScreen({
    super.key,
    required this.user,
    required this.weddingId,
    required this.onSwitchWedding,
    required this.onSignOut,
    this.weddingService,
  });

  final User? user;
  final String weddingId;
  final VoidCallback onSwitchWedding;
  final VoidCallback onSignOut;

  /// Wstrzykiwalny serwis (testy). Domyślnie tworzony wewnętrznie.
  final WeddingService? weddingService;

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen> {
  late final WeddingService _weddings = widget.weddingService ?? WeddingService();
  late final Stream<Map<String, dynamic>?> _guestView =
      _weddings.watchGuestView(widget.weddingId);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _guestView,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final eventName = (data?['eventName'] as String?)?.trim();
        final persons = (data?['displayNames'] as String?)?.trim();
        final token = (data?['guestToken'] as String?)?.trim();

        return Scaffold(
          backgroundColor: AppColors.bgGradient.last,
          appBar: _appBar(
            eventName?.isNotEmpty == true ? eventName! : 'Wesele',
            persons,
          ),
          body: switch (snapshot.connectionState) {
            ConnectionState.waiting => const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            _ when snapshot.hasError => _notReady(
                'Nie udało się wczytać strefy gości.',
                'Sprawdź połączenie z internetem i spróbuj ponownie.',
              ),
            _ when token == null || token.isEmpty => _notReady(
                'Strefa gości nie jest jeszcze gotowa',
                'Para Młoda jeszcze jej nie przygotowała. Zajrzyj później '
                    'albo poproś ją o udostępnienie sekcji dla gości.',
              ),
            _ => GuestWebHome(token: token),
          },
        );
      },
    );
  }

  Widget _notReady(String title, String body) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.45, 1.0],
            colors: AppColors.bgGradient,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💍', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 14, height: 1.45, color: AppColors.textLight),
                ),
              ],
            ),
          ),
        ),
      );

  PreferredSizeWidget _appBar(String eventName, String? persons) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0.5,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eventName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          if (persons != null && persons.isNotEmpty)
            Text(
              persons,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.accent),
            ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Center(child: _guestChip()),
        ),
        PopupMenuButton<String>(
          tooltip: 'Konto',
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (v) {
            if (v == 'switch') widget.onSwitchWedding();
            if (v == 'logout') widget.onSignOut();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              enabled: false,
              child: Text(
                widget.user?.email ?? widget.user?.displayName ?? 'Gość',
                style:
                    GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'switch',
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz, size: 20),
                  const SizedBox(width: 10),
                  Text('Zmień wesele', style: GoogleFonts.inter(fontSize: 14)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  const Icon(Icons.logout, size: 20, color: Color(0xFFC0392B)),
                  const SizedBox(width: 10),
                  Text('Wyloguj',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: const Color(0xFFC0392B))),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _guestChip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline,
                size: 14, color: Color(0xFF8A6D26)),
            const SizedBox(width: 4),
            Text(
              'Gość',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF8A6D26),
              ),
            ),
          ],
        ),
      );
}
