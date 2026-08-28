import 'package:budget_app/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _signInAsGuest(WidgetTester tester) async {
  await tester.pumpWidget(const BudgetApp());
  await tester.pumpAndSettle();

  final guestButton = find.text('Kontynuuj jako gość (Demo / Tryb testowy)');
  await tester.ensureVisible(guestButton);
  await tester.pumpAndSettle();
  await tester.tap(guestButton);
  await tester.pumpAndSettle();
}

Future<void> _enterFirstBudget(WidgetTester tester) async {
  await _signInAsGuest(tester);
  await tester.tap(find.text('Budżet Domowy 2026'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('App boots into the Splash screen, then Login when signed out',
      (tester) async {
    await tester.pumpWidget(const BudgetApp());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsWidgets);

    await tester.pumpAndSettle();

    expect(find.text('Zaloguj się'), findsWidgets);
    expect(find.text('Kontynuuj jako gość (Demo / Tryb testowy)'), findsOneWidget);
  });

  testWidgets('Signing in as guest reaches WorkspaceSelectionPage with the seeded budget',
      (tester) async {
    await _signInAsGuest(tester);

    expect(find.text('Twoje budżety'), findsOneWidget);
    expect(find.text('Budżet Domowy 2026'), findsOneWidget);
  });

  testWidgets('Tapping a budget card opens its dashboard', (tester) async {
    await _enterFirstBudget(tester);

    expect(find.text('Bilans netto'), findsOneWidget);
    expect(find.text('Wpływy'), findsOneWidget);
  });

  testWidgets('Bottom nav switches to Ustawienia', (tester) async {
    await _enterFirstBudget(tester);

    await tester.tap(find.text('Ustawienia').last);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Ustawienia'), findsOneWidget);
  });

  testWidgets('The workspace-switch icon returns to WorkspaceSelectionPage',
      (tester) async {
    await _enterFirstBudget(tester);

    await tester.tap(find.byTooltip('Przełącz budżet'));
    await tester.pumpAndSettle();

    expect(find.text('Twoje budżety'), findsOneWidget);
  });

  testWidgets('Signing out from the profile menu returns to Login', (tester) async {
    await _enterFirstBudget(tester);

    await tester.tap(find.byTooltip('Profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wyloguj'));
    await tester.pumpAndSettle();

    expect(find.text('Zaloguj się'), findsWidgets);
  });
}
