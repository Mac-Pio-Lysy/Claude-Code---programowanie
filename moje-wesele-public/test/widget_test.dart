// Test ekranu logowania (widget prezentacyjny — bez połączenia z Firebase).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moje_wesele/screens/login_screen.dart';

void main() {
  testWidgets('Ekran logowania pokazuje tytuł, przycisk i informację o prywatności',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(onGoogleSignIn: () {})),
    );

    expect(find.textContaining('Ceremonia'), findsOneWidget);
    expect(find.text('Panel organizacji wesela'), findsOneWidget);
    expect(find.text('Zaloguj się przez Google'), findsOneWidget);
    expect(find.textContaining('Aplikacja prywatna'), findsOneWidget);
  });
}
