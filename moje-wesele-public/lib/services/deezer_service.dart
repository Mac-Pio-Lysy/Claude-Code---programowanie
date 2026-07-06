import 'dart:convert';

import 'package:http/http.dart' as http;

/// Wynik wyszukiwania w Deezer.
class DeezerTrack {
  DeezerTrack({
    required this.title,
    required this.artist,
    required this.cover,
    required this.preview,
  });

  final String title;
  final String artist;
  final String cover;
  final String preview;
}

/// Wyszukiwanie utworów przez publiczne API Deezer (api.deezer.com/search).
///
/// UWAGA: na Flutter Web zapytanie może zostać zablokowane przez CORS
/// (Deezer nie wysyła nagłówków CORS). Na Androidzie/iOS działa bez problemu.
/// W razie błędu zwracamy `null`, a UI proponuje dodanie utworu ręcznie.
class DeezerService {
  DeezerService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<DeezerTrack>?> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    final uri = Uri.parse(
        'https://api.deezer.com/search?q=${Uri.encodeComponent(q)}&limit=15');
    try {
      final resp = await _client.get(uri).timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return null;
      final json = jsonDecode(resp.body);
      final data = (json is Map && json['data'] is List)
          ? json['data'] as List
          : const [];
      return data.whereType<Map>().map((t) {
        final artist = t['artist'];
        final album = t['album'];
        return DeezerTrack(
          title: (t['title'] as String?) ?? '',
          artist: (artist is Map ? artist['name'] as String? : null) ?? '',
          cover: (album is Map ? album['cover_medium'] as String? : null) ?? '',
          preview: (t['preview'] as String?) ?? '',
        );
      }).toList();
    } catch (_) {
      return null;
    }
  }
}
