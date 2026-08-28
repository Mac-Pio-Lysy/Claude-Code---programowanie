import 'package:budget_app/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// End-to-end UI smoke tests: the mobile FAB add-flow and the long-press
/// delete-flow both go through the real `BudgetSheetBloc`, so a passing
/// assertion here proves the wiring — not just the reducer logic already
/// covered by budget_sheet_bloc_test.dart.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpMobileApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BudgetApp());
    await tester.pumpAndSettle();
  }

  testWidgets('adding an income entry via the FAB updates the tile list and the balance',
      (tester) async {
    await pumpMobileApp(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Wpływ'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Nazwa'), 'Premia');
    await tester.enterText(find.widgetWithText(TextFormField, 'Kwota brutto'), '1000');
    await tester.enterText(find.widgetWithText(TextFormField, 'Kwota netto'), '800');

    await tester.tap(find.widgetWithText(FilledButton, 'Zapisz'));
    await tester.pumpAndSettle();

    expect(find.text('Premia'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Text && (widget.data ?? '').startsWith('+800,00'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('deleting a tile via long-press removes it', (tester) async {
    await pumpMobileApp(tester);

    expect(find.text('Netflix'), findsOneWidget);
    await tester.ensureVisible(find.text('Netflix'));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Netflix'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Usuń'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Usuń'));
    await tester.pumpAndSettle();

    expect(find.text('Netflix'), findsNothing);
  });
}
