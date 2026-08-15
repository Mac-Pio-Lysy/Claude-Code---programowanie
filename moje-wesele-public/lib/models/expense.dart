import '../l10n/app_text.dart';

/// Status wydatku wyliczony z opłaconej kwoty.
enum ExpenseStatus { paid, partial, unpaid }

/// Model wydatku — nakładka na surową mapę z `budgetData.expenses`.
/// Zachowuje pełną mapę [raw], więc edycja nie gubi nieznanych pól.
class Expense {
  Expense(this.raw);

  final Map<String, dynamic> raw;

  int? get id => (raw['id'] as num?)?.toInt();
  String get category => (raw['category'] as String?) ?? 'Inne';
  String get customName => (raw['customName'] as String?) ?? '';

  /// Identyfikator powiązanego dostawcy (jeśli wydatek pokazuje się też
  /// w sekcji Dostawcy jako TEN SAM rekord).
  int? get vendorId => (raw['vendorId'] as num?)?.toInt();
  bool get hasVendor => vendorId != null;

  /// Sekcja, w której rekord został utworzony (źródło dla etykiety
  /// „Dodano w:"). 'expenses' | 'vendors' | 'tasks' | 'honeymoon'. Dla
  /// starszych wpisów bez pola: obecność `vendorId` oznacza pochodzenie
  /// z sekcji Dostawcy.
  String get origin {
    final o = (raw['origin'] as String?)?.trim();
    if (o != null && o.isNotEmpty) return o;
    return vendorId != null ? 'vendors' : 'expenses';
  }

  /// Czy rekord „mieszka" w Wydatkach (źródłem jest ta sekcja).
  bool get fromExpenses => origin == 'expenses';

  /// Czy rekord został dodany w Dostawcach i tu tylko się pokazuje.
  bool get fromVendors => origin == 'vendors';

  /// Czy rekord został utworzony z Zadania (osiągnięty cel) i tu tylko się pokazuje.
  bool get fromTasks => origin == 'tasks';
  double get planned => _d(raw['planned']);
  double get estimatedAmount => _d(raw['estimatedAmount']);
  double get paid => _d(raw['paid']);
  double get splitP1 => _d(raw['splitP1']);
  double get splitP2 => _d(raw['splitP2']);
  String get paymentDate => (raw['paymentDate'] as String?) ?? '';
  String get note => (raw['note'] as String?) ?? '';
  bool get sidePanel => raw['sidePanel'] == true;

  /// Kwota efektywna: potwierdzona, a jeśli brak — przewidywana
  /// (`_payEffective` w wersji web).
  double get effective => planned > 0 ? planned : estimatedAmount;

  /// Czy wpis jest tylko przewidywany (brak potwierdzonej kwoty).
  bool get isPredicted => planned == 0 && estimatedAmount > 0;

  /// Pozostało do zapłaty (na podstawie kwoty potwierdzonej).
  double get remaining {
    final r = planned - paid;
    return r < 0 ? 0 : r;
  }

  /// Procent opłacenia (względem kwoty efektywnej).
  double get progressPercent =>
      effective > 0 ? (paid / effective * 100).clamp(0, 100) : 0;

  /// Status na potrzeby plakietki (jak `renderExpenseTile` — względem efektywnej).
  ExpenseStatus get status {
    if (paid >= effective && effective > 0) return ExpenseStatus.paid;
    if (paid > 0) return ExpenseStatus.partial;
    return ExpenseStatus.unpaid;
  }

  // Status na potrzeby filtrów (jak `getExpensesToShow` — względem planowanej).
  bool get filterPaid => paid >= planned && planned > 0;
  bool get filterPartial => paid > 0 && !filterPaid;

  /// Nazwa wyświetlana: dla „Inne" pokazuje własną nazwę.
  ///
  /// Porównanie z `'Inne'` zostaje po polsku — to WARTOŚĆ w bazie. Tłumaczy się
  /// tylko etykieta zwracanej kategorii i nazwa zastępcza.
  String get displayName => category == 'Inne'
      ? (customName.isNotEmpty ? customName : AppText.t.budget_expenseFallbackName)
      : ExpenseCategories.labelFor(category);

  String get icon => ExpenseCategories.iconFor(category);

  static double _d(dynamic v) => v is num ? v.toDouble() : 0.0;
}

/// Kategorie wydatków z ikonami (EXPENSE_CATEGORIES w zrodlo-web/script.js).
class ExpenseCategories {
  ExpenseCategories._();

  static const Map<String, String> icons = {
    'Sala i catering': '🍽',
    'Suknia ślubna': '👗',
    'Garnitur/strój': '👔',
    'Obrączki': '💍',
    'Fotograf': '📷',
    'Kamerzysta/wideo': '🎥',
    'Kwiaty/dekoracje': '💐',
    'Bukiet ślubny': '🌹',
    'Kwiaty dla PM': '🌸',
    'Przystrojenie kościoła': '⛪',
    'Tort weselny': '🎂',
    'Muzyka/DJ/zespół': '🎵',
    'Zaproszenia': '✉️',
    'Uroda': '💄',
    'Makijaż i fryzura': '💇',
    'Transport': '🚗',
    'Dojazd do wesela': '🚌',
    'Dojazd do kościoła': '🚗',
    'Upominki dla gości': '🎁',
    'Upominki dla rodziców': '🎀',
    'Upominki dla świadków': '🥂',
    'Podróż poślubna': '✈️',
    'Alkohol': '🍾',
    'Inne': '📦',
  };

  static List<String> get names => icons.keys.toList();

  static String iconFor(String name) => icons[name] ?? '📦';

  /// Etykieta kategorii do WYŚWIETLENIA.
  ///
  /// ⚠️ Klucze [icons] to WARTOŚCI zapisywane w bazie: w `appConfig
  /// .expenseCategories` oraz w polu `category` każdego wydatku. Muszą zostać
  /// polskie — przetłumaczenie zerwałoby dane istniejących wesel i rozjechało
  /// je z wersją web. Tłumaczy się wyłącznie to, co widzi użytkownik.
  ///
  /// Nieznana wartość wraca bez zmian — para może dopisać własną kategorię
  /// w Ustawieniach i taka nazwa nie ma tłumaczenia.
  static String labelFor(String name) {
    final t = AppText.t;
    return switch (name) {
      'Sala i catering' => t.budget_catVenueCatering,
      'Suknia ślubna' => t.budget_catDress,
      'Garnitur/strój' => t.budget_catSuit,
      'Obrączki' => t.budget_catRings,
      'Fotograf' => t.budget_catPhoto,
      'Kamerzysta/wideo' => t.budget_catVideo,
      'Kwiaty/dekoracje' => t.budget_catFlowersDecor,
      'Bukiet ślubny' => t.budget_catBouquet,
      'Kwiaty dla PM' => t.budget_catFlowersCouple,
      'Przystrojenie kościoła' => t.budget_catChurchDecor,
      'Tort weselny' => t.budget_catCake,
      'Muzyka/DJ/zespół' => t.budget_catMusic,
      'Zaproszenia' => t.budget_catInvitations,
      'Uroda' => t.budget_catBeauty,
      'Makijaż i fryzura' => t.budget_catHairMakeup,
      'Transport' => t.budget_catTransport,
      'Dojazd do wesela' => t.budget_catRideReception,
      'Dojazd do kościoła' => t.budget_catRideChurch,
      'Upominki dla gości' => t.budget_catGiftsGuests,
      'Upominki dla rodziców' => t.budget_catGiftsParents,
      'Upominki dla świadków' => t.budget_catGiftsWitnesses,
      'Podróż poślubna' => t.budget_catHoneymoon,
      'Alkohol' => t.budget_catAlcohol,
      'Inne' => t.budget_catOther,
      _ => name,
    };
  }

  /// Lista kategorii z konfiguracji (`appConfig.expenseCategories`) lub domyślna.
  static List<String> resolve(Map<String, dynamic> raw) {
    final cfg = raw['appConfig'];
    if (cfg is Map && cfg['expenseCategories'] is List) {
      final list = (cfg['expenseCategories'] as List)
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .toList();
      if (list.isNotEmpty) return list;
    }
    return names;
  }
}
