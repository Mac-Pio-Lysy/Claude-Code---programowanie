import 'dart:convert';

import 'package:http/http.dart' as http;

/// Wynik geokodowania (współrzędne miejscowości).
class GeoPoint {
  GeoPoint(this.lat, this.lng);
  final double lat;
  final double lng;
}

/// Geokodowanie miejscowości na współrzędne przez darmowe Nominatim
/// (OpenStreetMap, bez klucza API). Zgodnie z zasadami Nominatim wysyłamy
/// nagłówek User-Agent i pobieramy tylko 1 wynik.
class GeocodingService {
  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _userAgent = 'MojeWeseleApp/1.0 (mapa gosci wesela)';

  /// Zwraca współrzędne dla zapytania (np. „Kraków, Polska") lub null.
  Future<GeoPoint?> geocode(String query) async {
    final q = query.trim();
    if (q.isEmpty) return null;
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': q,
      'format': 'json',
      'limit': '1',
      'accept-language': 'pl',
    });
    final res = await _client.get(uri, headers: {'User-Agent': _userAgent});
    if (res.statusCode != 200) {
      throw Exception('Nominatim ${res.statusCode}');
    }
    final data = jsonDecode(res.body);
    if (data is! List || data.isEmpty) return null;
    final first = data.first;
    if (first is! Map) return null;
    final lat = double.tryParse('${first['lat']}');
    final lon = double.tryParse('${first['lon']}');
    if (lat == null || lon == null) return null;
    return GeoPoint(lat, lon);
  }
}
