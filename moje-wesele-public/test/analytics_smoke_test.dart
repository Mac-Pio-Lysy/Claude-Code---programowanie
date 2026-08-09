import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moje_wesele/models/wedding_data.dart';
import 'package:moje_wesele/screens/analytics/analytics_screen.dart';

/// Test diagnostyczny do zgłoszenia #19 („Analityka jest pusta").
///
/// Sprawdza, czy ekran w ogóle się renderuje: przy braku danych, przy pustym
/// weselu i przy weselu z danymi. Jeśli którykolwiek przypadek rzuca wyjątek,
/// w aplikacji objawia się to pustą (albo szarą) sekcją.
void main() {
  Future<void> pump(WidgetTester tester, WeddingData? data) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 800,
          child: AnalyticsScreen(data: data),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('renderuje się przy data == null', (tester) async {
    await pump(tester, null);
    expect(tester.takeException(), isNull);
    expect(find.text('Analityka'), findsOneWidget);
  });

  testWidgets('przy pustym weselu pokazuje stan pusty, nie sześć kart „Brak…"',
      (tester) async {
    await pump(tester, WeddingData.fromMap(const <String, dynamic>{}));
    expect(tester.takeException(), isNull);
    expect(find.text('Brak danych do analizy'), findsOneWidget);
  });

  testWidgets('renderuje się przy weselu z danymi', (tester) async {
    final data = WeddingData.fromMap(<String, dynamic>{
      'weddingDate': '2026-09-12',
      'appConfig': {'eventName': 'Test', 'displayNames': 'A i B'},
      'guests': [
        {'id': 1, 'firstName': 'Anna', 'lastName': 'Kowalska', 'menuChoice': 'Mięsne'},
        {'id': 2, 'firstName': 'Jan', 'lastName': 'Nowak', 'diet': 'Wegetariańska'},
      ],
      'budgetData': {
        'total': 50000,
        'expenses': [
          {'id': 1, 'name': 'Sala', 'category': 'Sala', 'amount': 20000, 'paid': 20000},
          {'id': 2, 'name': 'Foto', 'category': 'Foto', 'amount': 5000, 'paid': 0},
        ],
      },
      'rsvpEntries': [
        {'guestId': 1, 'status': 'attending'},
      ],
    });
    await pump(tester, data);
    expect(tester.takeException(), isNull);
    // Są dane, więc zamiast stanu pustego ma być lista wykresów. Sprawdzamy
    // pierwszy tytuł — dalsze karty leżą poza ekranem i ListView ich nie buduje.
    expect(find.text('Brak danych do analizy'), findsNothing);
    expect(find.text('Budżet: planowany / orientacyjny / opłacony'),
        findsOneWidget);
  });
}
