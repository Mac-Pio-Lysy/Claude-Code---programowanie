import 'app_localizations.dart';
import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';

/// Dostęp do tłumaczeń POZA drzewem widgetów.
///
/// Reguła: mając `BuildContext`, używaj `AppLocalizations.of(context)` — to
/// właściwa droga i sama pilnuje przebudowy. [AppText.t] jest wyjściem
/// awaryjnym dla miejsc, gdzie kontekstu nie ma i nie da się go sensownie
/// dostarczyć: statycznych funkcji w modelach (`GuestOptions.dietLabel`),
/// agregatów i generatora PDF.
///
/// Instancję ustawia korzeń aplikacji przy każdej przebudowie, więc po zmianie
/// języka holder od razu wskazuje nowe tłumaczenia. Wzorzec ten sam co
/// `AppFormat` i `CoupleLabels.current`.
class AppText {
  AppText._();

  /// Awaryjny zestaw polski — używany, zanim korzeń zdąży ustawić właściwy
  /// (np. w testach jednostkowych modeli).
  static AppLocalizations _current = AppLocalizationsPl();

  /// Bieżące tłumaczenia.
  static AppLocalizations get t => _current;

  /// Ustawiane przez korzeń aplikacji po zbudowaniu `MaterialApp`.
  static void apply(AppLocalizations value) => _current = value;

  /// Tłumaczenia we WSZYSTKICH obsługiwanych językach naraz.
  ///
  /// Potrzebne tam, gdzie porównujemy tekst ZAPISANY W BAZIE z etykietą:
  /// zapis powstał w języku, w którym zakładano wesele, więc dopasowanie tylko
  /// do języka bieżącego by go przegapiło (patrz `specialMomentIcon`).
  /// Dodanie kolejnego języka = jedna pozycja tutaj.
  static final List<AppLocalizations> allLocales = [
    AppLocalizationsPl(),
    AppLocalizationsEn(),
  ];
}
