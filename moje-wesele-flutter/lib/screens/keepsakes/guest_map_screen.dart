import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../app_colors.dart';
import '../../config/public_urls.dart';
import '../../models/guest_map_entry.dart';
import '../../models/wedding_data.dart';
import '../../services/geocoding_service.dart';
import '../../services/guest_map_service.dart';
import '../../widgets/guest_page_tab.dart';

/// Podzakładka „Mapa gości" (w sekcji „Ślubne pamiątki").
///
/// Wizualna mapa (flutter_map + OpenStreetMap) z pinezkami miejscowości gości,
/// lista, statystyki (liczba miejscowości, najdalszy gość) oraz ręczne
/// dodawanie/edycja z geokodowaniem (Nominatim). Dane w kolekcji `guestMap`.
class GuestMapScreen extends StatefulWidget {
  const GuestMapScreen({super.key, required this.data});

  final WeddingData? data;

  @override
  State<GuestMapScreen> createState() => _GuestMapScreenState();
}

class _GuestMapScreenState extends State<GuestMapScreen> {
  final GuestMapService _service = GuestMapService();
  final GeocodingService _geo = GeocodingService();
  late final Stream<List<GuestMapEntry>> _stream = _service.watchEntries();
  final MapController _mapController = MapController();

  /// Punkt odniesienia = miejsce wesela (z `appConfig`), do liczenia dystansu.
  GeoPoint? _reception;
  String _receptionLabel = '';

  static const _distance = Distance();
  static const _polandCenter = LatLng(52.0, 19.4);

  @override
  void initState() {
    super.initState();
    _resolveReception();
  }

  Future<void> _resolveReception() async {
    final cfg = widget.data?.raw['appConfig'];
    final place = (cfg is Map)
        ? ((cfg['receptionPlace'] as String?)?.trim().isNotEmpty ?? false
            ? (cfg['receptionPlace'] as String).trim()
            : (cfg['ceremonyPlace'] as String?)?.trim() ?? '')
        : '';
    if (place.isEmpty) return;
    try {
      final p = await _geo.geocode(place);
      if (!mounted || p == null) return;
      setState(() {
        _reception = p;
        _receptionLabel = place;
      });
    } catch (_) {
      // Brak punktu odniesienia — dystans po prostu się nie pokaże.
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  double? _distanceKm(GuestMapEntry e) {
    if (_reception == null || !e.hasCoords) return null;
    return _distance.as(LengthUnit.Kilometer,
        LatLng(_reception!.lat, _reception!.lng), LatLng(e.lat!, e.lng!));
  }

  @override
  Widget build(BuildContext context) {
    final base = PublicPages.baseUrl(widget.data?.raw);
    return DefaultTabController(
      length: 2,
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
            tabs: const [
              Tab(text: 'Mapa'),
              Tab(text: 'Strona dla gości'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _mapTab(),
                GuestPageTab(
                  links: [('🗺️ Mapa gości', PublicPages.mapa(base))],
                  intro:
                      'Strona, na której goście zaznaczają, skąd przyjeżdżają. '
                      'Pokaż im kod QR lub wyślij link.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapTab() {
    return StreamBuilder<List<GuestMapEntry>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _info('Nie udało się wczytać mapy. Sprawdź połączenie.');
        }
        final entries = snapshot.data ?? const <GuestMapEntry>[];
        final located = entries.where((e) => e.hasCoords).toList();

        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  _mapCard(located),
                  const SizedBox(height: 14),
                  _statsCard(entries, located),
                  const SizedBox(height: 14),
                  if (entries.isEmpty)
                    _info('Brak wpisów. Udostępnij gościom kod QR z zakładki '
                        '„Strona dla gości".')
                  else
                    for (final e in entries) _entryCard(e),
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
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: const Text('Dodaj gościa ręcznie'),
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
      },
    );
  }

  Widget _mapCard(List<GuestMapEntry> located) {
    final center = _reception != null
        ? LatLng(_reception!.lat, _reception!.lng)
        : (located.isNotEmpty
            ? LatLng(located.first.lat!, located.first.lng!)
            : _polandCenter);
    final zoom = _reception != null || located.isNotEmpty ? 6.0 : 5.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 300,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: zoom,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.moje_wesele',
                ),
                MarkerLayer(
                  markers: [
                    if (_reception != null)
                      Marker(
                        point: LatLng(_reception!.lat, _reception!.lng),
                        width: 44,
                        height: 44,
                        child: const Icon(Icons.favorite,
                            color: Color(0xFFC0392B), size: 34),
                      ),
                    for (final e in located)
                      Marker(
                        point: LatLng(e.lat!, e.lng!),
                        width: 40,
                        height: 40,
                        child: Tooltip(
                          message:
                              '${e.name.isEmpty ? 'Gość' : e.name} · ${e.city}',
                          child: const Icon(Icons.location_on,
                              color: AppColors.accent, size: 32),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (located.isEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.white.withValues(alpha: 0.85),
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'Brak zlokalizowanych gości. Pinezki pojawią się po '
                    'wpisach gości lub ręcznym dodaniu z miejscowością.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textLight),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statsCard(List<GuestMapEntry> entries, List<GuestMapEntry> located) {
    final cities = entries
        .map((e) => e.city.trim().toLowerCase())
        .where((c) => c.isNotEmpty)
        .toSet()
        .length;

    GuestMapEntry? farthest;
    double farthestKm = -1;
    for (final e in located) {
      final d = _distanceKm(e);
      if (d != null && d > farthestKm) {
        farthestKm = d;
        farthest = e;
      }
    }

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _stat('${entries.length}', 'Gości', AppColors.accent),
              _stat('$cities', 'Miejscowości', const Color(0xFF7C3AED)),
              _stat('${located.length}', 'Na mapie', const Color(0xFF059669)),
            ],
          ),
          if (farthest != null) ...[
            const Divider(height: 20),
            Row(
              children: [
                const Text('🏅', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Najdalszy gość: ${farthest.name.isEmpty ? 'Gość' : farthest.name} '
                    '(${farthest.city}) — ${farthestKm.round()} km'
                    '${_receptionLabel.isNotEmpty ? ' od: $_receptionLabel' : ''}',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text),
                  ),
                ),
              ],
            ),
          ] else if (_reception == null) ...[
            const Divider(height: 20),
            Text(
              'Aby policzyć dystans najdalszego gościa, ustaw „Miejsce wesela" '
              'w Konfiguracji (sekcja Ustawienia).',
              style:
                  GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
            ),
          ],
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

  Widget _entryCard(GuestMapEntry e) {
    final km = _distanceKm(e);
    return Container(
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
          Icon(e.hasCoords ? Icons.location_on : Icons.location_off_outlined,
              color: e.hasCoords ? AppColors.accent : const Color(0xFFB45309),
              size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.name.isEmpty ? 'Gość' : e.name,
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
                Text(
                  e.city.isEmpty ? 'Brak miejscowości' : e.city,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textLight),
                ),
                if (km != null)
                  Text('${km.round()} km od miejsca wesela',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: const Color(0xFF059669))),
                if (!e.hasCoords)
                  Text('⚠ Niezlokalizowany — uzupełnij miejscowość',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: const Color(0xFFB45309))),
                if (e.greeting.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('„${e.greeting}"',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppColors.text)),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => _openForm(existing: e),
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: AppColors.accent,
            visualDensity: VisualDensity.compact,
            tooltip: 'Edytuj',
          ),
          IconButton(
            onPressed: () => _confirmDelete(e),
            icon: const Icon(Icons.delete_outline, size: 18),
            color: const Color(0xFFC0392B),
            visualDensity: VisualDensity.compact,
            tooltip: 'Usuń',
          ),
        ],
      ),
    );
  }

  Future<void> _openForm({GuestMapEntry? existing}) async {
    final draft = await showDialog<_MapDraft>(
      context: context,
      builder: (_) => _EntryFormDialog(existing: existing),
    );
    if (draft == null) return;
    try {
      // Geokodowanie miejscowości (jeśli podano).
      double? lat, lng;
      if (draft.city.isNotEmpty) {
        final p = await _geo.geocode('${draft.city}, Polska');
        final pp = p ?? await _geo.geocode(draft.city);
        if (pp != null) {
          lat = pp.lat;
          lng = pp.lng;
        }
      }
      if (existing != null) {
        await _service.updateEntry(existing.id,
            name: draft.name,
            city: draft.city,
            greeting: draft.greeting,
            lat: lat,
            lng: lng);
        _toast(lat == null
            ? 'Zapisano (nie udało się zlokalizować miejscowości)'
            : 'Zapisano wpis');
      } else {
        await _service.addEntry(
            name: draft.name,
            city: draft.city,
            greeting: draft.greeting,
            lat: lat,
            lng: lng);
        _toast(lat == null
            ? 'Dodano (nie udało się zlokalizować miejscowości)'
            : 'Dodano wpis');
      }
    } catch (e) {
      _toast('Błąd zapisu: $e');
    }
  }

  Future<void> _confirmDelete(GuestMapEntry e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunąć wpis?'),
        content: Text(
            'Czy na pewno usunąć „${e.name.isEmpty ? 'Gość' : e.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: const Color(0xFFC0392B)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.deleteEntry(e.id);
      _toast('Usunięto wpis');
    } catch (e) {
      _toast('Błąd usuwania: $e');
    }
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

/// Dane wpisu z formularza ręcznego dodania/edycji.
class _MapDraft {
  _MapDraft(this.name, this.city, this.greeting);
  final String name;
  final String city;
  final String greeting;
}

class _EntryFormDialog extends StatefulWidget {
  const _EntryFormDialog({this.existing});
  final GuestMapEntry? existing;

  @override
  State<_EntryFormDialog> createState() => _EntryFormDialogState();
}

class _EntryFormDialogState extends State<_EntryFormDialog> {
  late final TextEditingController _name;
  late final TextEditingController _city;
  late final TextEditingController _greeting;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _city = TextEditingController(text: widget.existing?.city ?? '');
    _greeting = TextEditingController(text: widget.existing?.greeting ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _greeting.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing != null ? 'Edytuj wpis' : 'Dodaj gościa'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                  labelText: 'Imię', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _city,
              decoration: const InputDecoration(
                  labelText: 'Miejscowość',
                  hintText: 'np. Kraków',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _greeting,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Pozdrowienie (opcjonalnie)',
                  border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
          onPressed: () {
            final name = _name.text.trim();
            final city = _city.text.trim();
            if (name.isEmpty && city.isEmpty) {
              Navigator.of(context).pop();
              return;
            }
            Navigator.of(context)
                .pop(_MapDraft(name, city, _greeting.text.trim()));
          },
          child: Text(widget.existing != null ? 'Zapisz' : 'Dodaj'),
        ),
      ],
    );
  }
}
