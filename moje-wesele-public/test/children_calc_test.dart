import 'package:flutter_test/flutter_test.dart';
import 'package:moje_wesele/models/beverage.dart';
import 'package:moje_wesele/models/children.dart';
import 'package:moje_wesele/models/wedding_data.dart';

/// Testy kroku 2 partii DZIECI: tryb liczenia dzieci (`auto` / `manual`)
/// jako wspólne źródło dla kalkulacji sali i napojów.
void main() {
  List<dynamic> guests(int children, int adults) => [
        for (var i = 0; i < children; i++) {'id': i, 'isChild': true},
        for (var i = 0; i < adults; i++) {'id': 100 + i},
      ];

  group('ChildrenSettings — wybór źródła', () {
    test('brak trybu = ręczny (zgodność ze starymi weselami)', () {
      final c = ChildrenSettings.from(
          {'withChildren': true, 'childrenCount': 4}, guests(0, 10));

      expect(c.auto, isFalse);
      expect(c.count, 4); // ręczna liczba NIE zostaje podmieniona na zero
    });

    test('auto liczy z listy gości', () {
      final c = ChildrenSettings.from({
        'withChildren': true,
        ChildrenSettings.modeKey: ChildrenSettings.modeAuto,
        'childrenCount': 99,
      }, guests(3, 7));

      expect(c.auto, isTrue);
      expect(c.fromGuests, 3);
      expect(c.count, 3);
    });

    test('wesele bez dzieci → zero niezależnie od trybu i flag', () {
      final auto = ChildrenSettings.from({
        ChildrenSettings.modeKey: ChildrenSettings.modeAuto,
      }, guests(5, 5));
      final manual =
          ChildrenSettings.from({'childrenCount': 5}, guests(5, 5));

      expect(auto.count, 0);
      expect(manual.count, 0);
    });

    test('ujemna liczba w danych jest przycinana do zera', () {
      final c = ChildrenSettings.from(
          {'withChildren': true, 'childrenCount': -3}, const []);
      expect(c.count, 0);
    });

    test('puste dane nie wywracają odczytu', () {
      final c = ChildrenSettings.from(const {}, const []);
      expect(c.count, 0);
      expect(c.enabled, isFalse);
      expect(c.manualMismatch, isFalse);
    });
  });

  group('ostrzeżenie o rozjeździe', () {
    test('tryb ręczny + inna liczba na liście → ostrzeżenie', () {
      final c = ChildrenSettings.from(
          {'withChildren': true, 'childrenCount': 2}, guests(5, 5));
      expect(c.manualMismatch, isTrue);
    });

    test('zgodne liczby → brak ostrzeżenia', () {
      final c = ChildrenSettings.from(
          {'withChildren': true, 'childrenCount': 5}, guests(5, 5));
      expect(c.manualMismatch, isFalse);
    });

    test('nikt nieoznaczony → brak ostrzeżenia (para nie używa flag)', () {
      final c = ChildrenSettings.from(
          {'withChildren': true, 'childrenCount': 4}, guests(0, 10));
      expect(c.manualMismatch, isFalse);
    });

    test('tryb auto nigdy nie ostrzega — nie ma o co', () {
      final c = ChildrenSettings.from({
        'withChildren': true,
        ChildrenSettings.modeKey: ChildrenSettings.modeAuto,
        'childrenCount': 2,
      }, guests(5, 5));
      expect(c.manualMismatch, isFalse);
    });
  });

  group('nowe wesele — pola startowe (krok 4)', () {
    /// Ustawienia odczytane tak, jak zrobią to kalkulacje po utworzeniu.
    ChildrenSettings settingsFor({
      required bool withChildren,
      required int count,
      List<dynamic> weddingGuests = const [],
    }) =>
        ChildrenSettings.from(
          ChildrenSettings.initialBudgetFields(
              withChildren: withChildren, childrenCount: count),
          weddingGuests,
        );

    test('bez podanej liczby → tryb auto', () {
      final fields = ChildrenSettings.initialBudgetFields(
          withChildren: true, childrenCount: 0);

      expect(fields[ChildrenSettings.modeKey], ChildrenSettings.modeAuto);
      expect(fields.containsKey('childrenCount'), isFalse);
      expect(fields['withChildren'], isTrue);
    });

    test('podana liczba → tryb ręczny, żeby działała od razu', () {
      // Lista gości jest przy zakładaniu pusta — w trybie auto wpisane „8"
      // dałoby 0 w kalkulacjach.
      final s = settingsFor(withChildren: true, count: 8);

      expect(s.auto, isFalse);
      expect(s.count, 8);
    });

    test('auto liczy z listy, gdy goście się pojawią', () {
      final s = settingsFor(
        withChildren: true,
        count: 0,
        weddingGuests: guests(2, 5),
      );

      expect(s.auto, isTrue);
      expect(s.count, 2);
    });

    test('wesele bez dzieci → flaga false i zero w kalkulacjach', () {
      final s = settingsFor(withChildren: false, count: 0);

      expect(s.enabled, isFalse);
      expect(s.count, 0);
    });

    test('liczba podana przy wyłączonych dzieciach jest ignorowana', () {
      final fields = ChildrenSettings.initialBudgetFields(
          withChildren: false, childrenCount: 5);

      expect(fields.containsKey('childrenCount'), isFalse);
      expect(fields[ChildrenSettings.modeKey], ChildrenSettings.modeAuto);
    });
  });

  group('podpowiedź przy sadzaniu (krok 3)', () {
    test('dziecko przy stole dla dzieci → cisza', () {
      expect(
        ChildrenSettings.seatingHint(
            guestIsChild: true,
            tableIsChildTable: true,
            childTableExists: true),
        isNull,
      );
    });

    test('dorosły przy stole dla dzieci → podpowiedź o opiekunie', () {
      final hint = ChildrenSettings.seatingHint(
          guestIsChild: false,
          tableIsChildTable: true,
          childTableExists: true);
      expect(hint, isNotNull);
      expect(hint, contains('opiekun'));
    });

    test('dziecko przy zwykłym stole, gdy jest stół dziecięcy', () {
      final hint = ChildrenSettings.seatingHint(
          guestIsChild: true,
          tableIsChildTable: false,
          childTableExists: true);
      expect(hint, isNotNull);
      expect(hint, contains('stół dla dzieci'));
    });

    test('dziecko przy zwykłym stole, gdy NIE ma stołu dziecięcego → cisza', () {
      // Nie proponujemy stołu, którego wesele nie ma.
      expect(
        ChildrenSettings.seatingHint(
            guestIsChild: true,
            tableIsChildTable: false,
            childTableExists: false),
        isNull,
      );
    });

    test('dorosły przy zwykłym stole → cisza', () {
      expect(
        ChildrenSettings.seatingHint(
            guestIsChild: false,
            tableIsChildTable: false,
            childTableExists: true),
        isNull,
      );
    });
  });

  group('wykrywanie stołu dla dzieci', () {
    test('znajduje stół z flagą', () {
      expect(
        ChildrenSettings.hasChildTable([
          {'id': 1},
          {'id': 2, 'isChildTable': true},
        ]),
        isTrue,
      );
    });

    test('brak flagi → false', () {
      expect(
        ChildrenSettings.hasChildTable([
          {'id': 1},
          {'id': 2, 'isHonorTable': true},
        ]),
        isFalse,
      );
    });

    test('pusta lista i śmieci nie wywracają odczytu', () {
      expect(ChildrenSettings.hasChildTable(const []), isFalse);
      expect(ChildrenSettings.hasChildTable(['nie mapa', 42]), isFalse);
    });
  });

  group('alkohol wyklucza dzieci', () {
    WeddingData wedding(Map<String, dynamic> budgetExtras) =>
        WeddingData.fromMap({
          'guests': guests(3, 7), // 10 osób, w tym 3 dzieci
          'budgetData': {
            'withChildren': true,
            'alcoholItems': [
              {'id': 1, 'bottles': 20, 'pricePerBottle': 50},
            ],
            ...budgetExtras,
          },
        });

    test('auto: baza alkoholu to dorośli z listy', () {
      final s = BeverageSummary.from(
          wedding({ChildrenSettings.modeKey: 'auto'}), BeverageKind.alcohol);
      expect(s.personCount, 7); // 10 - 3 dzieci
    });

    test('auto: napoje bezalkoholowe liczą wszystkich', () {
      final s = BeverageSummary.from(
          wedding({ChildrenSettings.modeKey: 'auto'}), BeverageKind.soft);
      expect(s.personCount, 10);
    });

    test('ręczny: baza alkoholu wg wpisanej liczby', () {
      final s = BeverageSummary.from(
          wedding({'childrenCount': 6}), BeverageKind.alcohol);
      expect(s.personCount, 4); // 10 - 6 wpisanych
    });

    test('liczba dzieci większa niż gości nie daje ujemnej bazy', () {
      final s = BeverageSummary.from(
          wedding({'childrenCount': 50}), BeverageKind.alcohol);
      expect(s.personCount, 0);
    });
  });
}
