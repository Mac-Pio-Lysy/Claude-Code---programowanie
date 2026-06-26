import '../../models/song.dart';

/// Wynik parsowania importu: tytuł, wykonawca, status.
class ParsedSong {
  ParsedSong(this.title, this.artist, this.status);
  final String title;
  final String artist;
  final String status;
}

/// Generowanie i parsowanie eksportu/importu listy piosenek.
class MusicExport {
  MusicExport._();

  /// Eksport CSV (separator `;`, jak w wersji web).
  static String toCsv(List<Song> songs) {
    String cell(String v) {
      final needsQuote = v.contains(';') || v.contains('"') || v.contains('\n');
      final escaped = v.replaceAll('"', '""');
      return needsQuote ? '"$escaped"' : escaped;
    }

    final head = ['Tytuł', 'Wykonawca', 'Moment imprezy', 'Status', 'Gatunek', 'Od gościa'];
    final rows = songs.map((s) => [
          s.title,
          s.artist,
          s.moment,
          s.status.label,
          s.genre,
          s.fromGuest ? (s.guestName.isEmpty ? 'tak' : s.guestName) : '',
        ]);
    return [head, ...rows].map((r) => r.map(cell).join(';')).join('\r\n');
  }

  /// Eksport tekstowy pogrupowany po momentach imprezy.
  static String toTxt(List<Song> songs) {
    final byMoment = <String, List<Song>>{};
    for (final s in songs) {
      byMoment.putIfAbsent(s.moment.isEmpty ? 'Inne' : s.moment, () => []).add(s);
    }
    final buf = StringBuffer()
      ..writeln('LISTA PIOSENEK NA WESELE')
      ..writeln('========================')
      ..writeln();
    for (final m in kMusicMoments) {
      final list = byMoment[m];
      if (list == null) continue;
      buf.writeln('### $m');
      for (final s in list) {
        final artist = s.artist.isNotEmpty ? ' — ${s.artist}' : '';
        final genre = s.genre.isNotEmpty ? ' (${s.genre})' : '';
        buf.writeln('- ${s.title}$artist [${s.status.label}]$genre');
      }
      buf.writeln();
    }
    return buf.toString();
  }

  /// Instrukcja formatu importu (pokazywana użytkownikowi).
  static const String importHelp =
      'Wklej listę utworów. Obsługiwane formaty:\n'
      '• CSV: Tytuł;Wykonawca;Status (separator średnik)\n'
      '• Tekst: "- Tytuł — Wykonawca" (po jednym w linii)\n'
      'Status rozpoznawany ze słów: „zatwierdzone", „odrzucone", „dj".';

  /// Parsuje wklejony tekst (CSV lub listę).
  static List<ParsedSong> parse(String text) {
    final result = <ParsedSong>[];
    for (var line in text.split(RegExp(r'\r?\n'))) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#') || line.startsWith('=')) continue;
      if (line.startsWith('- ')) line = line.substring(2).trim();
      // Pomiń wiersz nagłówka CSV.
      if (line.toLowerCase().startsWith('tytuł;')) continue;

      String title, artist = '';
      String status = 'proposal';

      if (line.contains(';')) {
        final cols = line.split(';');
        title = cols.isNotEmpty ? cols[0].trim() : '';
        artist = cols.length > 1 ? cols[1].trim() : '';
        if (cols.length > 3) status = _statusFromText(cols[3]);
      } else {
        // „Tytuł — Wykonawca [Status] (gatunek)"
        status = _statusFromText(line);
        final clean = line.replaceAll(RegExp(r'\[.*?\]|\(.*?\)'), '').trim();
        final parts = clean.split(RegExp(r'\s+[—-]\s+'));
        title = parts.isNotEmpty ? parts[0].trim() : clean;
        artist = parts.length > 1 ? parts[1].trim() : '';
      }

      if (title.isNotEmpty) result.add(ParsedSong(title, artist, status));
    }
    return result;
  }

  static String _statusFromText(String s) {
    final t = s.toLowerCase();
    if (t.contains('zatw')) return 'approved';
    if (t.contains('odrzu')) return 'rejected';
    if (t.contains('dj')) return 'dj';
    return 'proposal';
  }
}
