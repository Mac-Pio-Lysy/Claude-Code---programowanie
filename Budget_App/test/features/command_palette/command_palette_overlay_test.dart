import 'package:budget_app/features/budget_sheet/presentation/bloc/budget_sheet_bloc.dart';
import 'package:budget_app/features/command_palette/presentation/widgets/command_palette_overlay.dart';
import 'package:budget_app/features/currency/domain/repositories/exchange_rate_repository.dart';
import 'package:budget_app/features/workspace/presentation/cubit/active_workspace_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fixed-rate stand-in so these tests don't depend on network access —
/// NbpExchangeRateRepository itself is covered separately.
class _FakeExchangeRateRepository implements ExchangeRateRepository {
  @override
  Future<double> getExchangeRate(String currencyCode, {DateTime? date}) async {
    if (currencyCode == 'PLN') return 1.0;
    return 4.30; // matches EUR's fallback rate, close enough for a fixed test rate.
  }
}

void main() {
  late BudgetSheetBloc budgetSheetBloc;

  Future<void> pumpPaletteHost(WidgetTester tester) async {
    budgetSheetBloc = BudgetSheetBloc();
    addTearDown(budgetSheetBloc.close);

    // Providers must wrap MaterialApp itself (as app.dart's real tree does)
    // rather than live inside a single route's subtree — showDialog pushes
    // a sibling route on the same Navigator, so a provider scoped only
    // inside `home` wouldn't be visible to it.
    await tester.pumpWidget(
      RepositoryProvider<ExchangeRateRepository>(
        create: (_) => _FakeExchangeRateRepository(),
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: budgetSheetBloc),
            BlocProvider(create: (_) => ActiveWorkspaceCubit()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showCommandPaletteOverlay(context),
                  child: const Text('open palette'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open palette'));
    await tester.pumpAndSettle();
  }

  testWidgets('"kino 45 zachcianki" adds a PLN expense to BudgetSheetBloc', (tester) async {
    await pumpPaletteHost(tester);

    await tester.enterText(find.byType(TextField), 'kino 45 zachcianki');
    await tester.pump();

    expect(find.textContaining('Wydatek: kino'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Wykonaj'));
    await tester.pumpAndSettle();

    expect(budgetSheetBloc.state.expenses, hasLength(1));
    final expense = budgetSheetBloc.state.expenses.single;
    expect(expense.name, 'kino');
    expect(expense.amount, 45.0);
    expect(expense.currency, 'PLN');
    expect(expense.originalAmount, isNull);
    expect(expense.exchangeRate, isNull);
  });

  testWidgets('"paliwo 250 eur" converts to PLN via the exchange rate repository',
      (tester) async {
    await pumpPaletteHost(tester);

    await tester.enterText(find.byType(TextField), 'paliwo 250 eur');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Wykonaj'));
    await tester.pumpAndSettle();

    expect(budgetSheetBloc.state.expenses, hasLength(1));
    final expense = budgetSheetBloc.state.expenses.single;
    expect(expense.name, 'paliwo');
    expect(expense.currency, 'EUR');
    expect(expense.originalAmount, 250.0);
    expect(expense.exchangeRate, 4.30);
    expect(expense.amount, 1075.0); // 250 * 4.30
  });

  testWidgets('"premia 1500 wplyw" adds an income entry', (tester) async {
    await pumpPaletteHost(tester);

    await tester.enterText(find.byType(TextField), 'premia 1500 wplyw');
    await tester.pump();

    expect(find.textContaining('Wpływ: premia'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Wykonaj'));
    await tester.pumpAndSettle();

    expect(budgetSheetBloc.state.incomes, hasLength(1));
    expect(budgetSheetBloc.state.incomes.single.title, 'premia');
    expect(budgetSheetBloc.state.incomes.single.netAmount, 1500.0);
  });

  testWidgets('an unrecognized query shows an error and adds nothing', (tester) async {
    await pumpPaletteHost(tester);

    await tester.enterText(find.byType(TextField), 'kupic mleko jutro');
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Wykonaj'));
    await tester.pump();

    expect(find.text('Nie rozpoznano polecenia.'), findsOneWidget);
    expect(budgetSheetBloc.state.expenses, isEmpty);
    expect(budgetSheetBloc.state.incomes, isEmpty);
  });
}
