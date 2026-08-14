import '../l10n/app_text.dart';
import 'couple.dart';

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

  /// „+1" BEZ własnego rekordu gościa.
  ///
  /// Pole zgodności ze starymi danymi. W nowym modelu osoba towarzysząca ma
  /// zawsze własny rekord, więc u zapraszającego ta flaga jest `false`.
  /// Reguła „rekord istnieje ⇒ hasCompanion == false" chroni przed policzeniem
  /// tej samej osoby dwa razy w cateringu.
  bool get hasCompanion => raw['hasCompanion'] == true;

  /// Imię towarzyszącej wpisane tekstem (stary model, bez powiązania).
  String get companionName => (raw['companionName'] as String?)?.trim() ?? '';

  // ── Powiązanie osoby towarzyszącej (nowy model) ───────────────────────────

  /// ID gościa, który zaprosił tę osobę. `null` = gość samodzielny.
  ///
  /// Relacja jest JEDNOKIERUNKOWA (towarzysząca → zapraszający). U zapraszającego
  /// nie dublujemy jej, żeby nie mieć dwóch źródeł prawdy do rozjechania.
  int? get companionOfId => (raw['companionOfId'] as num?)?.toInt();

  /// Czy ten gość jest czyjąś osobą towarzyszącą.
  bool get isCompanion => companionOfId != null;

  /// Typ relacji z zapraszającym — patrz [CompanionRelation].
  String? get relationType {
    final v = (raw['relationType'] as String?)?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  /// Imię jeszcze nieznane — rekord istnieje (liczy się do cateringu i ma
  /// miejsce przy stole), ale dane osobowe czekają na uzupełnienie.
  bool get namePending => raw['namePending'] == true;

  /// Czy ten gość jest dzieckiem (zgłoszenie #6).
  ///
  /// Flaga, a NIE kategoria: dziecko kuzynki jest jednocześnie „Rodziną"
  /// i dzieckiem. Kategoria zmusiłaby do wyboru jednego i wywróciła filtry.
  /// Ortogonalna do `category`, `invitedBy` i powiązania towarzyszącego —
  /// tak samo jak [namePending] czy [companionOfId].
  ///
  /// Brak pola = dorosły, czyli zachowanie sprzed wprowadzenia flagi.
  bool get isChild => raw['isChild'] == true;
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

/// Typ relacji osoby towarzyszącej z gościem, który ją zaprosił.
class CompanionRelation {
  CompanionRelation._();

  /// Partner / partnerka, mąż / żona.
  static const String partner = 'partner';

  /// Ktoś z rodziny zapraszającego.
  static const String family = 'family';

  /// Osoba jeszcze nieznana — gość wie, że przyjdzie z kimś, ale nie z kim.
  static const String unknown = 'unknown';

  static const List<String> all = [partner, family, unknown];

  /// Etykieta typu relacji. Wartości (`'partner'`…) zostają w bazie.
  static String label(String? value) => switch (value) {
        partner => AppText.t.guests_relationPartner,
        family => AppText.t.guests_relationFamily,
        unknown => AppText.t.guests_relationUnknown,
        _ => AppText.t.common_none,
      };

  /// Kategoria podpowiadana dla danego typu relacji (`null` = dziedzicz po
  /// zapraszającym). Dla rodziny sensowniejsza jest „Rodzina" niż kategoria
  /// zapraszającego.
  static String? suggestedCategory(String? value) =>
      value == family ? 'Rodzina' : null;

  /// Nazwa zastępcza osoby bez podanego imienia. Nazwisko zapraszającego
  /// dokładamy dla czytelności listy i planu sali („Osoba towarzysząca
  /// Kowalski"), żeby dało się ją odróżnić od innych takich wpisów.
  static const String placeholderFirstName = 'Osoba towarzysząca';
}

/// Stałe i etykiety pól gościa — zgodne z formularzem w zrodlo-web/index.html.
class GuestOptions {
  GuestOptions._();

  /// Kategorie gościa (w kolejności z `<select id="guestCategory">`).
  static const List<String> categories = [
    // Wartość zapisywana w bazie; etykietę do wyświetlenia daje
    // `CoupleLabels.current.coupleCategoryLabel`.
    CoupleLabels.coupleCategoryValue,
    'Świadkowie',
    'Rodzice',
    'Rodzina',
    'Znajomi',
    'Praca',
    'Inne',
  ];

  /// Domyślna opcja menu dla dzieci — podpowiadana po oznaczeniu gościa jako
  /// dziecko. Para może ją usunąć z konfiguracji, dlatego podpowiedź działa
  /// tylko wtedy, gdy ta pozycja jest na aktualnej liście menu.
  static const String childMenuOption = 'Dla dziecka';

  /// Domyślne opcje menu/diety (DEFAULT_APP_CONFIG.menuOptions w script.js).
  static const List<String> defaultMenuOptions = [
    'Danie mięsne',
    'Danie rybne',
    'Wegetariańskie',
    'Wegańskie',
    childMenuOption,
  ];

  /// Etykieta kategorii do WYŚWIETLENIA.
  ///
  /// ⚠️ [categories] to wartości ZAPISYWANE w bazie i zostają polskie —
  /// przetłumaczenie ich zerwałoby dane istniejących wesel i rozjechało je
  /// z wersją web, która czyta ten sam dokument. Tłumaczy się wyłącznie to,
  /// co widzi użytkownik. Ten sam wzorzec co `CoupleLabels.coupleCategoryValue`
  /// kontra `coupleCategoryLabel`.
  ///
  /// Nieznana wartość (np. kategoria wpisana w wersji web) wraca bez zmian —
  /// lepiej pokazać oryginał niż pustkę.
  static String categoryLabel(String value) {
    final t = AppText.t;
    return switch (value) {
      CoupleLabels.coupleCategoryValue =>
        CoupleLabels.current.coupleCategoryLabel,
      'Świadkowie' => t.guests_categoryWitnesses,
      'Rodzice' => t.guests_categoryParents,
      'Rodzina' => t.guests_categoryFamily,
      'Znajomi' => t.guests_categoryFriends,
      'Praca' => t.guests_categoryWork,
      'Inne' => t.guests_categoryOther,
      _ => value,
    };
  }

  /// Etykieta opcji menu do WYŚWIETLENIA. Wartości są konfigurowalne przez
  /// parę, więc tłumaczymy tylko te domyślne — własne wracają bez zmian.
  static String menuLabel(String value) {
    final t = AppText.t;
    return switch (value) {
      'Danie mięsne' => t.guests_menuMeat,
      'Danie rybne' => t.guests_menuFish,
      'Wegetariańskie' => t.guests_menuVegetarian,
      'Wegańskie' => t.guests_menuVegan,
      childMenuOption => t.guests_menuChild,
      _ => value,
    };
  }

  /// Etykieta „kto zaprosił" — wyliczana z typu uroczystości.
  ///
  /// Wartości `'groom'` / `'bride'` w bazie zostają bez zmian; zmienia się
  /// wyłącznie tekst pokazywany użytkownikowi (patrz [CoupleLabels]).
  static String invitedByLabel(String? value) =>
      CoupleLabels.current.invitedBy(value);

  static String genderLabel(String? value) => switch (value) {
        'K' => AppText.t.guests_genderFemale,
        'M' => AppText.t.guests_genderMale,
        'N' => AppText.t.guests_genderNonbinary,
        _ => AppText.t.common_none,
      };

  static String witnessLabel(String? value) =>
      CoupleLabels.current.witness(value);

  /// Etykieta diety (zgodna z `dietLabel` w zrodlo-web/script.js).
  ///
  /// Wartości `'standard'`, `'vegan'`… zostają w bazie; tłumaczy się etykieta.
  /// `dietOther` to tekst wpisany przez parę — nie tłumaczymy go.
  static String dietLabel(String diet, String dietOther) {
    final t = AppText.t;
    return switch (diet) {
      'standard' => t.guests_dietStandard,
      'vegetarian' => t.guests_dietVegetarian,
      'vegan' => t.guests_dietVegan,
      'glutenfree' => t.guests_dietGlutenFree,
      'other' => dietOther.isNotEmpty ? dietOther : t.guests_dietOther,
      _ => diet,
    };
  }
}
