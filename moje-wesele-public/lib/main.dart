import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app_colors.dart';
import 'l10n/app_localizations.dart';
import 'l10n/app_text.dart';
import 'l10n/locale_controller.dart';
import 'firebase_options.dart';
import 'layout/responsive.dart';
import 'utils/app_format.dart';
import 'screens/guest_web/guest_web_app.dart';
import 'screens/guest_web/invite_entry_app.dart';
import 'widgets/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Dane nazw miesięcy i separatorów dla `intl`. Bez tego DateFormat z
  // językiem innym niż systemowy rzuca wyjątkiem przy pierwszym użyciu.
  await initializeDateFormatting();

  // TRYB GOŚCIA WEB — dwa wejścia do TEJ SAMEJ strefy:
  //   ?i=KOD    kod paczki: najpierw wybór tożsamości, potem strefa,
  //   ?t=TOKEN  wspólny link: prosto do strefy, jak dotąd.
  //
  // Kolejność ma znaczenie: kod paczki sprawdzamy PIERWSZY, bo niesie więcej
  // (rozpoznaje gościa), a token i tak wyciągniemy z jego dokumentu. Wspólny
  // link działa RÓWNOLEGLE i bez żadnych zmian — także w trybie
  // indywidualnym, dla gości bez zaproszenia z kodem.
  final inviteCode = _detectParam('i');
  final guestToken = _detectParam('t');
  if (inviteCode != null || guestToken != null) {
    // Gość nie ma konta, więc jego wybór języka wisi pod wspólnym kluczem
    // `locale_guest`. Wczytujemy PRZED `runApp`, żeby strona nie mrugnęła
    // najpierw domyślnym językiem.
    await LocaleController.loadGuest();
    runApp(inviteCode != null
        ? InviteEntryApp(code: inviteCode)
        : GuestWebApp(token: guestToken!));
    return;
  }
  runApp(const MojeWeseleApp());
}

/// Odczytuje parametr z adresu (tylko web). Pusty → `null`.
String? _detectParam(String name) {
  if (!kIsWeb) return null;
  final v = Uri.base.queryParameters[name]?.trim();
  return (v != null && v.isNotEmpty) ? v : null;
}

class MojeWeseleApp extends StatelessWidget {
  const MojeWeseleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        primary: AppColors.accent,
      ),
      useMaterial3: true,
    );

    // Nasłuch w KORZENIU drzewa: tryb wyświetlania i język przebudowują CAŁĄ
    // aplikację od razu, bez wychodzenia z ekranu. Język musi być tutaj, a nie
    // przy `home`, bo `locale` jest parametrem samego MaterialApp.
    //
    // ⚠️ NIE dodawać `const` przed AuthGate ani przed MaterialApp. Stała jest
    // kanonizowana, więc builder zwracałby przy każdej zmianie DOKŁADNIE ten
    // sam obiekt widgetu; Flutter porównuje go z poprzednim
    // (`child.widget == newWidget`) i pomija przebudowę poddrzewa. Efekt:
    // wybór zapisuje się, ale interfejs zostaje stary — dokładnie ten błąd
    // zgłoszony jako #20.
    return ListenableBuilder(
      listenable: Listenable.merge([
        DisplayModeController.mode,
        LocaleController.locale,
      ]),
      builder: (context, _) {
        // Formatowanie kwot i dat podąża za wybranym językiem.
        AppFormat.configure(
            locale: LocaleController.locale.value?.languageCode ??
                LocaleController.fallback.languageCode);
        return MaterialApp(
          title: 'Moje Wesele - Wedding Planner',
          debugShowCheckedModeBanner: false,
          theme: base.copyWith(
            textTheme: GoogleFonts.interTextTheme(base.textTheme),
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: LocaleController.locale.value,
          // Urządzenie w języku, którego nie mamy (np. niemieckim) dostaje
          // polski, a nie angielski — patrz `LocaleController.fallback`.
          localeResolutionCallback: LocaleController.resolve,
          // Udostępnienie tłumaczeń poza drzewem widgetów (modele, agregaty).
          // Robimy to pod MaterialApp, bo dopiero tam znany jest wynik
          // `localeResolutionCallback`.
          home: Builder(builder: (context) {
            AppText.apply(AppLocalizations.of(context));
            return AuthGate();
          }),
        );
      },
    );
  }
}
