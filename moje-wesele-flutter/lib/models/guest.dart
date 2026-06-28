/// Model gościa — cienka nakładka na surową mapę z Firestore.
///
/// Przechowuje pełną mapę [raw], dzięki czemu edycja zachowuje WSZYSTKIE pola
/// zapisane przez aplikację webową (struktura z `_serializeState()` /
/// `addGuest()` w zrodlo-web/script.js), a nie tylko te pokazywane w UI.
class Guest {
  Guest(this.raw);

  final Map<String, dynamic> raw;

  int? get id => (raw['id'] as num?)?.toInt();
  String get firstName => (raw['firstName'] as String?)?.trim() ?? '';
  String get lastName => (raw['lastName'] as String?)?.trim() ?? '';
  String get category => (raw['category'] as String?) ?? '';

  /// 'K' | 'M' | 'N'
  String? get gender => raw['gender'] as String?;

  /// null | 'groom' (Pan Młody) | 'bride' (Panna Młoda)
  String? get invitedBy {
    final v = raw['invitedBy'] as String?;
    return (v == null || v.isEmpty) ? null : v;
  }

  /// null | 'witness_groom' (Świadek) | 'witness_bride' (Świadkowa)
  String? get witness {
    final v = raw['witness'] as String?;
    return (v == null || v.isEmpty) ? null : v;
  }

  bool get hasCompanion => raw['hasCompanion'] == true;
  String get companionName => (raw['companionName'] as String?)?.trim() ?? '';
  bool get needsAccommodation => raw['needsAccommodation'] == true;
  String get menuChoice => (raw['menuChoice'] as String?)?.trim() ?? '';

  /// Dieta: 'standard' | 'vegetarian' | 'vegan' | 'glutenfree' | 'other'.
  String get diet {
    final v = (raw['diet'] as String?)?.trim();
    return (v == null || v.isEmpty) ? 'standard' : v;
  }

  /// Własny opis diety, gdy `diet == 'other'`.
  String get dietOther => (raw['dietOther'] as String?)?.trim() ?? '';

  /// Alergie / nietolerancje (pole tekstowe).
  String get allergies => (raw['allergies'] as String?)?.trim() ?? '';

  /// Identyfikator przypisanego stołu (null = nieprzypisany).
  int? get tableId => (raw['tableId'] as num?)?.toInt();
  bool get isAssigned => raw['tableId'] != null;

  String get fullName => '$firstName $lastName'.trim();

  /// Inicjały do awatara (jak `initials()` w wersji web).
  String get initials {
    final f = firstName;
    final l = lastName;
    if (f.isEmpty && l.isEmpty) return '?';
    if (l.isNotEmpty) return (f.isNotEmpty ? f[0] : '') + l[0];
    return f.length >= 2 ? f.substring(0, 2) : f;
  }
}

/// Stałe i etykiety pól gościa — zgodne z formularzem w zrodlo-web/index.html.
class GuestOptions {
  GuestOptions._();

  /// Kategorie gościa (w kolejności z `<select id="guestCategory">`).
  static const List<String> categories = [
    'Państwo Młodzi',
    'Świadkowie',
    'Rodzice',
    'Rodzina',
    'Znajomi',
    'Praca',
    'Inne',
  ];

  /// Domyślne opcje menu/diety (DEFAULT_APP_CONFIG.menuOptions w script.js).
  static const List<String> defaultMenuOptions = [
    'Danie mięsne',
    'Danie rybne',
    'Wegetariańskie',
    'Wegańskie',
    'Dla dziecka',
  ];

  static String invitedByLabel(String? value) => switch (value) {
        'groom' => '🤵 Pan Młody',
        'bride' => '👰 Panna Młoda',
        _ => '—',
      };

  static String genderLabel(String? value) => switch (value) {
        'K' => '♀ Kobieta',
        'M' => '♂ Mężczyzna',
        'N' => '⚧ Niebinarna',
        _ => '—',
      };

  static String witnessLabel(String? value) => switch (value) {
        'witness_groom' => 'Świadek',
        'witness_bride' => 'Świadkowa',
        _ => 'Brak roli',
      };

  /// Etykieta diety (zgodna z `dietLabel` w zrodlo-web/script.js).
  static String dietLabel(String diet, String dietOther) => switch (diet) {
        'standard' => 'Standardowa',
        'vegetarian' => 'Wegetariańska',
        'vegan' => 'Wegańska',
        'glutenfree' => 'Bezglutenowa',
        'other' => dietOther.isNotEmpty ? dietOther : 'Inne',
        _ => diet,
      };
}
