import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/app/app.dart';

void main() {
  testWidgets('App shell shows Dashboard and navigates to Settings',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BudgetApp()));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsOneWidget);
  });
}
