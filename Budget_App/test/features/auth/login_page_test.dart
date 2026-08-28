import 'package:budget_app/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:budget_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:budget_app/features/auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpLoginPage(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider(
        create: (_) => AuthBloc(MockAuthRepository()),
        child: const LoginPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows validation errors for empty fields', (tester) async {
    await _pumpLoginPage(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Zaloguj się'));
    await tester.pumpAndSettle();

    expect(find.text('Podaj e-mail'), findsOneWidget);
    expect(find.text('Podaj hasło'), findsOneWidget);
  });

  testWidgets('shows an error snackbar for the wrong password', (tester) async {
    await _pumpLoginPage(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'E-mail'), 'demo@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Hasło'), 'wrong-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Zaloguj się'));
    await tester.pumpAndSettle();

    expect(find.text('Nieprawidłowe hasło.'), findsOneWidget);
  });

  testWidgets('toggling to sign-up mode changes the form labels', (tester) async {
    await _pumpLoginPage(tester);

    expect(find.text('Zaloguj się'), findsWidgets);
    expect(find.text('Nie masz konta? Zarejestruj się'), findsOneWidget);

    await tester.tap(find.text('Nie masz konta? Zarejestruj się'));
    await tester.pumpAndSettle();

    expect(find.text('Zarejestruj się'), findsWidgets);
    expect(find.text('Masz już konto? Zaloguj się'), findsOneWidget);
  });

  testWidgets('the app logo appears below the login card, not above it', (tester) async {
    await _pumpLoginPage(tester);

    final cardBottom = tester.getBottomLeft(find.byType(Form)).dy;
    final logoTop = tester.getTopLeft(find.text('Budget App')).dy;

    expect(logoTop, greaterThan(cardBottom));
  });

  testWidgets('shows a guest sign-in entry point', (tester) async {
    await _pumpLoginPage(tester);

    expect(find.text('Kontynuuj jako gość (Demo / Tryb testowy)'), findsOneWidget);
  });
}
