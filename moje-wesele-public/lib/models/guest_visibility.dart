import 'package:flutter/material.dart';

/// Ustawienia widoczności sekcji dla GOŚCI (strony publiczne) w czasie.
///
/// Zapisywane przy weselu w `weddings/{id}` pod kluczem `guestVisibility`.
/// Strony publiczne (wersja web) czytają ten sam schemat i decydują, czy
/// pokazać sekcję, komunikat, czy ją ukryć — wg dat OD/DO i przełączników.
///
/// Schemat w Firestore:
/// ```
/// guestVisibility: {
///   masterEnabled: bool,                 // widoczność CAŁEJ strony dla gości
///   sections: {
///     rsvp: { enabled: bool,
///             from: "YYYY-MM-DD"|null,    // widoczne OD (włącznie)
///             to:   "YYYY-MM-DD"|null,    // widoczne DO (włącznie)
///             outOfRange: "message"|"hide" },
///     gallery: { ... }, ...
///   }
/// }
/// ```

/// Definicja sekcji gościa (klucz w Firestore + etykieta + ikona w panelu).
class GuestSectionDef {
  const GuestSectionDef(this.key, this.label, this.icon);
  final String key;
  final String label;
  final IconData icon;
}

/// Sekcje dostępne dla gości na stronach publicznych. Klucze są STABILNE —
/// wersja web używa ich do odczytu ustawień widoczności.
const List<GuestSectionDef> kGuestSections = [
  GuestSectionDef('rsvp', 'RSVP (Potwierdzenia)', Icons.how_to_reg_outlined),
  GuestSectionDef('gallery', 'Galeria', Icons.photo_library_outlined),
  GuestSectionDef('schedule', 'Harmonogram', Icons.event_outlined),
  GuestSectionDef('music', 'Muzyka', Icons.music_note_outlined),
  GuestSectionDef('guestbook', 'Księga gości', Icons.menu_book_outlined),
  GuestSectionDef('advice', 'Rady', Icons.tips_and_updates_outlined),
  GuestSectionDef('timeCapsule', 'Kapsuła czasu', Icons.mail_outline),
  GuestSectionDef('guestMap', 'Mapa gości', Icons.map_outlined),
  GuestSectionDef('quiz', 'Quiz', Icons.quiz_outlined),
  GuestSectionDef('trueFalse', 'Prawda/Fałsz', Icons.rule),
  GuestSectionDef('photoGuess', 'Zgadnij zdjęcie', Icons.image_search),
  GuestSectionDef('photoChallenge', 'Foto-wyzwania', Icons.photo_camera_outlined),
  GuestSectionDef('bingo', 'Ślubne Bingo', Icons.grid_view_outlined),
];

/// Zachowanie, gdy sekcja jest poza zakresem dat lub wyłączona.
class OutOfRangeMode {
  static const String message = 'message'; // pokaż komunikat „dostępne od…"
  static const String hide = 'hide'; // całkowicie ukryj sekcję
}

/// Wynik oceny widoczności sekcji dla gościa w danym momencie.
enum VisibilityState {
  /// Widoczne — w zakresie i włączone (główny przełącznik też).
  visible,

  /// Główny przełącznik strony wyłączony (cała strona niedostępna).
  masterOff,

  /// Przełącznik tej sekcji wyłączony.
  disabled,

  /// Przed datą OD — jeszcze niedostępne.
  beforeStart,

  /// Po dacie DO — już niedostępne.
  afterEnd,
}

/// Ustawienia widoczności pojedynczej sekcji.
class SectionVisibility {
  const SectionVisibility({
    this.enabled = true,
    this.from,
    this.to,
    this.outOfRange = OutOfRangeMode.message,
  });

  /// Czy sekcja jest w ogóle włączona dla gości.
  final bool enabled;

  /// Data OD ("YYYY-MM-DD") lub null (bez początku).
  final String? from;

  /// Data DO ("YYYY-MM-DD") lub null (bez końca).
  final String? to;

  /// 'message' | 'hide' — co widzi gość, gdy poza zakresem/wyłączone.
  final String outOfRange;

  SectionVisibility copyWith({
    bool? enabled,
    String? from,
    String? to,
    bool clearFrom = false,
    bool clearTo = false,
    String? outOfRange,
  }) =>
      SectionVisibility(
        enabled: enabled ?? this.enabled,
        from: clearFrom ? null : (from ?? this.from),
        to: clearTo ? null : (to ?? this.to),
        outOfRange: outOfRange ?? this.outOfRange,
      );

  factory SectionVisibility.fromMap(Map<String, dynamic> m) => SectionVisibility(
        enabled: m['enabled'] is bool ? m['enabled'] as bool : true,
        from: _cleanDate(m['from']),
        to: _cleanDate(m['to']),
        outOfRange: m['outOfRange'] == OutOfRangeMode.hide
            ? OutOfRangeMode.hide
            : OutOfRangeMode.message,
      );

  Map<String, dynamic> toMap() => {
        'enabled': enabled,
        'from': from,
        'to': to,
        'outOfRange': outOfRange,
      };

  static String? _cleanDate(dynamic v) =>
      (v is String && v.trim().isNotEmpty) ? v.trim() : null;
}

/// Komplet ustawień widoczności dla gości (główny przełącznik + sekcje).
class GuestVisibility {
  const GuestVisibility({
    this.masterEnabled = true,
    this.sections = const {},
  });

  /// Widoczność CAŁEJ strony dla gości (wyłącza wszystko naraz).
  final bool masterEnabled;

  /// Ustawienia per sekcja (klucz = [GuestSectionDef.key]).
  final Map<String, SectionVisibility> sections;

  /// Ustawienia sekcji (domyślne, gdy jeszcze nie zapisano).
  SectionVisibility sectionFor(String key) =>
      sections[key] ?? const SectionVisibility();

  GuestVisibility copyWith({
    bool? masterEnabled,
    Map<String, SectionVisibility>? sections,
  }) =>
      GuestVisibility(
        masterEnabled: masterEnabled ?? this.masterEnabled,
        sections: sections ?? this.sections,
      );

  /// Buduje ustawienia z surowego dokumentu wesela (`data.raw`).
  factory GuestVisibility.fromRaw(Map<String, dynamic> raw) {
    final gv = raw['guestVisibility'];
    if (gv is! Map) return const GuestVisibility();
    final master = gv['masterEnabled'];
    final secRaw = gv['sections'];
    final sections = <String, SectionVisibility>{};
    if (secRaw is Map) {
      for (final entry in secRaw.entries) {
        if (entry.value is Map) {
          sections[entry.key.toString()] = SectionVisibility.fromMap(
              Map<String, dynamic>.from(entry.value as Map));
        }
      }
    }
    return GuestVisibility(
      masterEnabled: master is bool ? master : true,
      sections: sections,
    );
  }

  Map<String, dynamic> toMap() => {
        'masterEnabled': masterEnabled,
        'sections': {
          for (final e in sections.entries) e.key: e.value.toMap(),
        },
      };

  /// Ocena widoczności sekcji dla gościa względem [today] (data w Warszawie).
  VisibilityState stateOf(String key, DateTime today) {
    if (!masterEnabled) return VisibilityState.masterOff;
    final sec = sectionFor(key);
    if (!sec.enabled) return VisibilityState.disabled;
    final from = _parse(sec.from);
    final to = _parse(sec.to);
    final d = DateTime(today.year, today.month, today.day);
    if (from != null && d.isBefore(from)) return VisibilityState.beforeStart;
    if (to != null && d.isAfter(to)) return VisibilityState.afterEnd;
    return VisibilityState.visible;
  }

  static DateTime? _parse(String? s) {
    if (s == null) return null;
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(s);
    if (m == null) return null;
    return DateTime(
        int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!));
  }
}
