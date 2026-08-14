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
import 'widgets/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Dane nazw miesięcy i separatorów dla `intl`. Bez tego DateFormat z
  // językiem innym niż systemowy rzuca wyjątkiem przy pierwszym użyciu.
  await initializeDateFormatting();

  // TRYB GOŚCIA WEB: gdy w adresie jest token (?t=...), pokazujemy stronę gości
  // BEZ logowania (dla danego wesela). W pozostałych przypadkach — normalna
  // aplikacja organizatora (logowanie → panel).
  final guestToken = _detectGuestToken();
  if (guestToken != null) {
    runApp(GuestWebApp(token: guestToken));
    return;
  }
  runApp(const MojeWeseleApp());
}

/// Wykrywa token gościa z URL (tylko web). Obsługuje `?t=TOKEN`.
String? _detectGuestToken() {
  if (!kIsWeb) return null;
  final t = Uri.base.queryParameters['t']?.trim();
  return (t != null && t.isNotEmpty) ? t : null;
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
