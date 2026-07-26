// Test ekranu logowania (widget prezentacyjny — bez połączenia z Firebase).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moje_wesele/screens/login_screen.dart';

void main() {
  testWidgets('Ekran logowania pokazuje nazwę, przycisk Google i zachętę do rejestracji',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(onGoogleSignIn: () {})),
    );

    expect(find.text('Moje Wesele'), findsOneWidget);
    expect(find.text('WEDDING PLANNER'), findsOneWidget);
    expect(find.text('Zaloguj się przez Google'), findsOneWidget);
    // Rejestracja otwarta — zachęta do logowania/założenia konta.
    expect(find.textContaining('załóż konto'), findsOneWidget);
  });
}
