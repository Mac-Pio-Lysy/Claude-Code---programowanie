import '../../models/song.dart';
import '../../l10n/app_text.dart';

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

    final head = [
      AppText.t.music_exportTitle,
      'Wykonawca',
      AppText.t.music_partyMoment,
      AppText.t.music_exportSpecial,
      'Status',
      'Gatunek',
      AppText.t.music_exportFromGuest
    ];
    final rows = songs.map((s) => [
          s.title,
          s.artist,
          s.moment,
          s.specialMoment,
          s.status.label,
          s.genre,
          s.fromGuest ? (s.guestName.isEmpty ? 'tak' : s.guestName) : '',
        ]);
    return [head, ...rows].map((r) => r.map(cell).join(';')).join('\r\n');
  }

  /// Eksport tekstowy: najpierw kluczowe momenty (utwory specjalne) w kolejności
  /// [specialMoments], potem reszta pogrupowana po momentach imprezy.
  static String toTxt(List<Song> songs, {List<String> specialMoments = const []}) {
    final buf = StringBuffer()
      ..writeln(AppText.t.music_exportHeader)
      ..writeln('========================')
      ..writeln();

    // ── Utwory specjalne (kluczowe momenty) ──
    final special = <String, List<Song>>{};
    for (final s in songs) {
      if (s.isSpecial) special.putIfAbsent(s.specialMoment, () => []).add(s);
    }
    if (special.isNotEmpty) {
      buf
        ..writeln(AppText.t.music_exportSpecialHeader)
        ..writeln();
      final ordered = <String>[
        ...specialMoments.where(special.containsKey),
        ...special.keys.where((k) => !specialMoments.contains(k)),
      ];
      for (final m in ordered) {
        for (final s in special[m]!) {
          final artist = s.artist.isNotEmpty ? ' — ${s.artist}' : '';
          buf.writeln(
              '${specialMomentIcon(m)} $m: ${s.title}$artist [${s.status.label}]');
        }
      }
      buf.writeln();
    }

    final byMoment = <String, List<Song>>{};
    for (final s in songs) {
      byMoment.putIfAbsent(s.moment.isEmpty ? 'Inne' : s.moment, () => []).add(s);
    }
    buf
      ..writeln(AppText.t.music_exportAllHeader)
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
  ///
  /// Getter, nie stała: treść jest tłumaczona.
  static String get importHelp => AppText.t.music_importHelp;

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
