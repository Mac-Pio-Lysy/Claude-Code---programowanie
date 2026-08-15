import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_localizations.dart';

/// Wybór języka aplikacji — per użytkownik, zapisywany lokalnie.
///
/// Wzorowane na `DisplayModeController`: globalny [ValueNotifier], który
/// nasłuchuje korzeń drzewa widgetów, więc zmiana przebudowuje CAŁĄ aplikację
/// bez wychodzenia z ekranu.
///
/// ⚠️ PUŁAPKA ZE ZGŁOSZENIA #20: nasłuch w `main.dart` NIE MOŻE budować
/// `const` dziecka. Stała jest kanonizowana, więc builder zwracałby przy każdej
/// zmianie ten sam obiekt widgetu, Flutter porównałby go z poprzednim
/// i pominął przebudowę — język zapisywałby się, ale interfejs zostawałby
/// stary. Dokładnie ten błąd zgłoszono przy trybie wyświetlania.
class LocaleController {
  LocaleController._();

  /// `null` = „jak w systemie" (Flutter sam dobierze z [supportedLocales]).
  static final ValueNotifier<Locale?> locale = ValueNotifier<Locale?>(null);

  /// Języki, które aplikacja rozumie. Dodanie kolejnego = nowy plik
  /// `lib/l10n/app_<kod>.arb` i jedna pozycja tutaj.
  static List<Locale> get supported => AppLocalizations.supportedLocales;

  /// Język używany, gdy urządzenie prosi o coś, czego nie mamy.
  ///
  /// POLSKI, nie angielski — produkt jest polski, więc przy nieznanym języku
  /// systemu bezpieczniej pokazać polski niż tłumaczenie.
  static const Locale fallback = Locale('pl');

  static String _keyFor(String uid) => 'locale_$uid';

  /// Klucz wyboru języka dla NIEZALOGOWANEGO gościa (wejście z linku/QR).
  ///
  /// Gość nie ma konta ani ekranu Ustawień, więc wybór nie może wisieć pod
  /// `uid`. Jedno wspólne miejsce na urządzenie (`locale_guest`) w tym samym
  /// magazynie co reszta: `SharedPreferences`, czyli `localStorage` na webie.
  static const String guestUid = 'guest';

  /// Wczytuje zapisany wybór (po zalogowaniu / wejściu w wesele).
  static Future<void> load(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    locale.value = _parse(prefs.getString(_keyFor(uid)));
  }

  /// Wczytuje wybór gościa. Brak zapisu → `null`, czyli język przeglądarki,
  /// a przy nieobsługiwanym języku [fallback] (polski) — patrz [resolve].
  static Future<void> loadGuest() => load(guestUid);

  /// Zapisuje wybór gościa (bez `uid`, bo gość nie jest zalogowany).
  static Future<void> setGuest(Locale? value) => set(guestUid, value);

  /// Zapisuje wybór i stosuje go natychmiast.
  ///
  /// [value] `null` oznacza powrót do ustawień urządzenia.
  static Future<void> set(String uid, Locale? value) async {
    locale.value = value;
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_keyFor(uid));
    } else {
      await prefs.setString(_keyFor(uid), value.languageCode);
    }
  }

  /// Zamienia zapisany kod na [Locale]; nieznany kod → `null` (system).
  static Locale? _parse(String? code) {
    if (code == null || code.isEmpty) return null;
    for (final l in supported) {
      if (l.languageCode == code) return l;
    }
    return null;
  }

  /// Dobiera język do pokazania: wybór użytkownika → język urządzenia →
  /// [fallback].
  ///
  /// Używane przez `MaterialApp.localeResolutionCallback`, żeby urządzenie
  /// ustawione np. na niemiecki dostało polski, a nie angielski.
  static Locale resolve(Locale? device, Iterable<Locale> supportedLocales) {
    final chosen = locale.value;
    if (chosen != null) return chosen;
    if (device != null) {
      for (final l in supportedLocales) {
        if (l.languageCode == device.languageCode) return l;
      }
    }
    return fallback;
  }
}
