import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_colors.dart';
import '../../models/guest.dart';
import '../../models/hotel.dart';
import '../../models/wedding_data.dart';
import '../../services/accommodation_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/format.dart';
import 'hotel_form_sheet.dart';

/// Sekcja „Noclegi" — hotele i przypisania gości potrzebujących noclegu.
class AccommodationScreen extends StatelessWidget {
  AccommodationScreen({
    super.key,
    required this.data,
    required FirestoreService firestore,
  }) : service = AccommodationService(firestore: firestore);

  final WeddingData? data;
  final AccommodationService service;

  List<Guest> get _guests => [
        for (final e in data?.guests ?? const [])
          if (e is Map) Guest(Map<String, dynamic>.from(e)),
      ];

  List<Hotel> get _hotels => [
        for (final e in data?.raw['hotels'] ?? const [])
          if (e is Map) Hotel(Map<String, dynamic>.from(e)),
      ];

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _addHotel(BuildContext context) async {
    final draft = await showModalBottomSheet<HotelDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const HotelFormSheet(),
    );
    if (draft == null) return;
    await service.addHotel(draft);
    if (context.mounted) _toast(context, 'Dodano hotel');
  }

  Future<void> _editHotel(BuildContext context, Hotel hotel) async {
    final draft = await showModalBottomSheet<HotelDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HotelFormSheet(existing: hotel),
    );
    if (draft == null || hotel.id == null) return;
    await service.updateHotel(hotel.id!, draft);
  }

  Future<void> _deleteHotel(BuildContext context, Hotel hotel) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunąć hotel?'),
        content: Text('Czy na pewno usunąć „${hotel.name}"? '
            'Przypisania gości do tego hotelu zostaną wyczyszczone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Anuluj')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC0392B)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (ok != true || hotel.id == null) return;
    await service.deleteHotel(hotel.id!);
    if (context.mounted) _toast(context, 'Usunięto hotel');
  }

  @override
  Widget build(BuildContext context) {
    final guests = _guests;
    final hotels = _hotels;
    final needs = guests.where((g) => g.needsAccommodation).toList();
    final reserved = needs
        .where((g) => g.raw['accommodationStatus'] == 'reserved')
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Noclegi',
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
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            children: [
              _summary(needs.length, reserved),
              const SizedBox(height: 16),
              Text('Goście potrzebujący noclegu',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text)),
              const SizedBox(height: 8),
              if (needs.isEmpty)
                _hint(
                    'Brak gości z zaznaczonym noclegiem.\nZaznacz „Nocleg" przy gościu w sekcji Goście.')
              else
                for (final g in needs) _guestRow(g, hotels),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text('Hotele i miejsca noclegowe',
                        style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (hotels.isEmpty)
                _hint('Brak hoteli. Dodaj pierwszy poniżej.')
              else
                for (final h in hotels)
                  _hotelCard(context, h,
                      guests.where((g) => g.raw['hotelId'] == h.id).length),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _addHotel(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Dodaj hotel'),
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _summary(int needs, int reserved) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EAF7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _stat('$needs', 'Potrzebuje noclegu', AppColors.accent),
          _stat('$reserved', 'Zarezerwowane', const Color(0xFF059669)),
          _stat('${needs - reserved}', 'Do zarezerwowania',
              const Color(0xFFB45309)),
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
                  fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _guestRow(Guest g, List<Hotel> hotels) {
    final hotelId = (g.raw['hotelId'] as num?)?.toInt();
    final status = g.raw['accommodationStatus'] as String?;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.accent,
                child: Text(g.initials.toUpperCase(),
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(g.fullName.isEmpty ? '(bez imienia)' : g.fullName,
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: hotels.any((h) => h.id == hotelId)
                      ? hotelId
                      : null,
                  isExpanded: true,
                  decoration: _miniDec(),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Brak hotelu')),
                    for (final h in hotels.where((h) => h.name.isNotEmpty))
                      DropdownMenuItem(value: h.id, child: Text(h.name)),
                  ],
                  onChanged: (v) => service.updateGuestAccommodation(g.id ?? 0,
                      hotelId: v, clearHotel: v == null),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: AccommodationStatus.all
                          .any((s) => s.value == status)
                      ? status
                      : '',
                  isExpanded: true,
                  decoration: _miniDec(),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Status…')),
                    for (final s in AccommodationStatus.all)
                      DropdownMenuItem(value: s.value, child: Text(s.label)),
                  ],
                  onChanged: (v) => service.updateGuestAccommodation(g.id ?? 0,
                      status: v ?? ''),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hotelCard(BuildContext context, Hotel h, int guestCount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF7)),
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
              Expanded(
                child: Text('🏨 ${h.name.isEmpty ? 'Hotel' : h.name}',
                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
              ),
              if (h.inComplex)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('🏰 W kompleksie',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7C3AED))),
                ),
              IconButton(
                onPressed: () => _editHotel(context, h),
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: AppColors.accent,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: () => _deleteHotel(context, h),
                icon: const Icon(Icons.delete_outline, size: 18),
                color: const Color(0xFFC0392B),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (h.address.isNotEmpty)
            Text('📍 ${h.address}',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textLight)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (h.phone.isNotEmpty)
                _chip('📞 ${h.phone}'),
              _chip('${formatPlnZl(h.pricePerNight)}/os.'),
              _chip('👥 ${h.personsPerRoom} os./pokój'),
              _chip('💰 koszt: ${formatPlnZl(h.cost)}'),
              _chip('🛏 gości: $guestCount'),
            ],
          ),
          if (h.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(h.notes,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.text)),
            ),
          if (h.bookingLink.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton.icon(
                onPressed: () => _openLink(h.bookingLink),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Rezerwacja'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openLink(String link) async {
    var url = link.trim();
    if (!url.startsWith('http')) url = 'https://$url';
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _chip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text,
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.text)),
      );

  Widget _hint(String text) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2EAF7)),
        ),
        child: Text(text,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight)),
      );

  InputDecoration _miniDec() => InputDecoration(
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF8FAFF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDCE4F2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDCE4F2)),
        ),
      );
}
