/// Pojedynczy krok listy „Od czego zacząć?" (sugerowana kolejność organizacji
/// wesela). Odpowiednik pozycji `planningSteps` z zrodlo-web/script.js:
/// `{ id, label, note, done }`. Dane współdzielone z wersją web przez Firestore.
class PlanningStep {
  PlanningStep({
    required this.id,
    required this.label,
    this.note = '',
    this.done = false,
  });

  final int id;
  String label;
  String note;
  bool done;

  factory PlanningStep.fromMap(Map<dynamic, dynamic> m) => PlanningStep(
        id: (m['id'] as num?)?.toInt() ?? 0,
        label: (m['label'] as String?) ?? '',
        note: (m['note'] as String?) ?? '',
        done: m['done'] == true,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'note': note,
        'done': done,
      };

  /// Domyślna lista kroków (identyczna jak DEFAULT_PLANNING_STEPS w web),
  /// rozszerzona o pełen zakres możliwości aplikacji.
  static const List<(String, String)> defaults = [
    ('Wybór i rezerwacja sali weselnej', ''),
    ('Ustalenie daty (zależnie od dostępności sali i kościoła)', ''),
    ('Rezerwacja kościoła / USC', 'Dotyczy ślubu kościelnego lub konkordatowego'),
    ('Dodanie listy gości', ''),
    ('Znalezienie i rezerwacja DJ / zespołu', ''),
    ('Fotograf / kamerzysta', ''),
    ('Florystka / dekoracje', ''),
    ('Garnitur i suknia ślubna', ''),
    ('Obrączki', ''),
    ('Pozostali dostawcy (tort, barman, atrakcje)', ''),
    ('Transport gości i pary młodej', ''),
    ('Noclegi dla gości', ''),
    ('Ustalenie budżetu i pilnowanie wydatków', ''),
    ('Plan stołów i rozsadzenie gości', ''),
    ('Muzyka — playlista i propozycje gości', ''),
    ('Lista prezentów / podziękowania dla gości', ''),
    ('Pozostałe szczegóły i dekoracje', ''),
  ];

  /// Buduje domyślną listę z kolejnymi identyfikatorami.
  static List<PlanningStep> defaultList() => [
        for (var i = 0; i < defaults.length; i++)
          PlanningStep(
              id: i + 1, label: defaults[i].$1, note: defaults[i].$2),
      ];
}
