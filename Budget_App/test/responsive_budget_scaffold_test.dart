import 'package:budget_app/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> _pumpAtSize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const BudgetApp());
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

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

  testWidgets('category pill/rail selection filters the sheet', (tester) async {
    await _pumpAtSize(tester, const Size(500, 900));

    expect(find.text('Czynsz'), findsOneWidget);
    await tester.tap(find.text('Mieszkanie').first);
    await tester.pumpAndSettle();

    expect(find.text('Czynsz'), findsOneWidget);
    expect(find.text('Fundusz awaryjny'), findsNothing);
  });
}
