import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'firebase_options.dart';
import 'screens/guest_web/guest_web_app.dart';
import 'widgets/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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

    return MaterialApp(
      title: 'Moje Wesele - Wedding Planner',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: GoogleFonts.interTextTheme(base.textTheme),
      ),
      home: const AuthGate(),
    );
  }
}
