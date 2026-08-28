import 'package:budget_app/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpAtSize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const BudgetApp());
  await tester.pumpAndSettle();

  await tester.tap(find.text('Kontynuuj jako gość (Demo / Tryb testowy)'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Budżet Domowy 2026'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows bottom NavigationBar and no sidebar under 900px',
      (tester) async {
    await _pumpAtSize(tester, const Size(500, 900));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(VerticalDivider), findsNothing);
  });

  testWidgets('shows the master-detail columns and no bottom bar at 900px+',
      (tester) async {
    await _pumpAtSize(tester, const Size(1200, 900));

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(VerticalDivider), findsWidgets);
  });

  testWidgets(
      'desktop rail lists every top-level destination, and each one switches the view',
      (tester) async {
    await _pumpAtSize(tester, const Size(1200, 900));

    final rail = find.byType(NavigationRail);
    expect(rail, findsOneWidget);
    for (final label in ['Dashboard', 'Arkusz', 'Oszczędności', 'Skaner OCR', 'Ustawienia']) {
      expect(find.descendant(of: rail, matching: find.text(label)), findsOneWidget);
    }

    // Dashboard/Arkusz share the same master-detail content on desktop, so
    // switching between them just updates the active index — it must not
    // navigate away from the budget workspace.
    await tester.tap(find.descendant(of: rail, matching: find.text('Arkusz')));
    await tester.pumpAndSettle();
    expect(find.text('Bilans netto'), findsOneWidget);

    await tester.tap(find.descendant(of: rail, matching: find.text('Oszczędności')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Oszczędności'), findsOneWidget);
  });

  testWidgets('category pill selection filters the mobile list', (tester) async {
    await _pumpAtSize(tester, const Size(500, 900));

    expect(find.text('Czynsz'), findsOneWidget);
    expect(find.text('Netflix'), findsOneWidget);

    await tester.tap(find.text('Mieszkanie').first);
    await tester.pumpAndSettle();

    // "Czynsz" is subCategory Mieszkanie and stays; "Netflix" is Multimedia
    // and is filtered out. The installment liability is never filtered.
    expect(find.text('Czynsz'), findsOneWidget);
    expect(find.text('Netflix'), findsNothing);
    expect(find.text('Rata za laptopa'), findsOneWidget);
  });
}
