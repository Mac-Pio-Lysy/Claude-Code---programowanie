import 'package:flutter_test/flutter_test.dart';
import 'package:moje_wesele/models/setup_task.dart';
import 'package:moje_wesele/models/wedding_data.dart';

/// Testy kreatora „Poprowadź mnie za rękę" (#17).
///
/// Sedno: stan zadań liczy się z danych wesela, nic nie jest zapisywane —
/// dlatego detektory muszą działać także dla wesel uzupełnianych ręcznie
/// albo w wersji web, z pominięciem kreatora.
void main() {
  final tasks = buildSetupTasks();

  SetupTask task(String id) => tasks.firstWhere((t) => t.id == id);
  bool done(String id, Map<String, dynamic> raw) =>
      task(id).done(WeddingData.fromMap(raw));

  /// Komplet danych spełniający WSZYSTKIE zadania.
  Map<String, dynamic> fullWedding() => {
        'appConfig': {
          'eventName': 'Wesele Ani i Piotra',
          'ceremonyPlace': 'Kościół św. Anny',
          'receptionPlace': 'Dworek Leśny',
          'coupleType': 'mixed',
          'verificationSurnames': 'Kowalscy',
          'menuOptions': ['Mięsne', 'Wege'],
          'expenseCategories': ['Sala', 'Muzyka'],
        },
        'weddingDate': '2027-06-12',
        'budgetData': {
          'coupleNames': ['Ania', 'Piotr'],
          'total': 50000,
          'pricePerPerson': 250,
          'withChildren': false,
        },
        'guests': [
          {'id': 1, 'witness': 'witness_bride', 'tableId': 1},
        ],
        'tables': [
          {'id': 1}
        ],
        'scheduleEvents': [
          {'id': 1, 'title': 'Ceremonia'}
        ],
        'guestVisibility': {'masterEnabled': true},
      };

  group('struktura listy zadań', () {
    test('są oba poziomy i identyfikatory się nie powtarzają', () {
      final ids = tasks.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(tasks.any((t) => t.level == SetupLevel.basic), isTrue);
      expect(tasks.any((t) => t.level == SetupLevel.advanced), isTrue);
    });

    test('każde zadanie mówi, co wpisać, i dokąd prowadzi', () {
      for (final t in tasks) {
        expect(t.label.trim(), isNotEmpty, reason: t.id);
        expect(t.hint.trim(), isNotEmpty, reason: t.id);
      }
    });
  });

  group('puste wesele', () {
    test('nic nie jest odhaczone', () {
      final empty = WeddingData.fromMap(const {});
      for (final t in tasks) {
        expect(t.done(empty), isFalse, reason: t.id);
      }
    });

    test('postęp startuje od zera i zna sumę', () {
      final p = setupProgress(tasks, WeddingData.fromMap(const {}));
      expect(p.done, 0);
      expect(p.total, tasks.length);
      expect(p.complete, isFalse);
    });

    test('brak danych (null) nie wywraca liczenia', () {
      final p = setupProgress(tasks, null);
      expect(p.done, 0);
      expect(p.ratio, 0);
    });
  });

  group('komplet danych', () {
    test('wszystkie zadania odhaczone', () {
      final data = WeddingData.fromMap(fullWedding());
      final unfinished = [
        for (final t in tasks)
          if (!t.done(data)) t.id
      ];
      expect(unfinished, isEmpty);
    });

    test('postęp pokazuje komplet', () {
      final p = setupProgress(tasks, WeddingData.fromMap(fullWedding()));
      expect(p.complete, isTrue);
      expect(p.left, 0);
      expect(p.ratio, 1);
    });
  });

  group('detektory wrażliwych przypadków', () {
    test('zastępcze „Osoba 1/2" nie liczą się jako imiona', () {
      expect(
        done('coupleNames', {
          'budgetData': {
            'coupleNames': ['Osoba 1', 'Osoba 2']
          }
        }),
        isFalse,
      );
      expect(
        done('coupleNames', {
          'budgetData': {
            'coupleNames': ['Ania', 'Piotr']
          }
        }),
        isTrue,
      );
    });

    test('jedno imię to za mało', () {
      expect(
        done('coupleNames', {
          'budgetData': {
            'coupleNames': ['Ania', '']
          }
        }),
        isFalse,
      );
    });

    test('decyzja o dzieciach: liczy się sam zapis, także „nie"', () {
      // „Nie będzie dzieci" to również podjęta decyzja.
      expect(done('withChildren', {
        'budgetData': {'withChildren': false}
      }), isTrue);
      expect(done('withChildren', {
        'budgetData': {'withChildren': true}
      }), isTrue);
      // Stare wesele bez tego pola — decyzji brak.
      expect(done('withChildren', {'budgetData': {}}), isFalse);
    });

    test('typ uroczystości: brak pola u starych wesel', () {
      expect(done('coupleType', {'appConfig': {}}), isFalse);
      expect(
        done('coupleType', {
          'appConfig': {'coupleType': 'women'}
        }),
        isTrue,
      );
    });

    test('świadkowie: pusty string nie liczy się jako rola', () {
      expect(
        done('witnesses', {
          'guests': [
            {'id': 1, 'witness': ''}
          ]
        }),
        isFalse,
      );
      expect(
        done('witnesses', {
          'guests': [
            {'id': 1, 'witness': 'witness_groom'}
          ]
        }),
        isTrue,
      );
    });

    test('rozsadzenie: wystarczy jeden gość przy stole', () {
      expect(
        done('seating', {
          'guests': [
            {'id': 1},
            {'id': 2, 'tableId': 3}
          ]
        }),
        isTrue,
      );
      expect(
        done('seating', {
          'guests': [
            {'id': 1, 'tableId': null}
          ]
        }),
        isFalse,
      );
    });

    test('budżet: zero to brak decyzji', () {
      expect(done('budgetTotal', {
        'budgetData': {'total': 0}
      }), isFalse);
      expect(done('budgetTotal', {
        'budgetData': {'total': 1000}
      }), isTrue);
    });

    test('puste teksty w konfiguracji nie liczą się jako uzupełnione', () {
      expect(done('ceremonyPlace', {
        'appConfig': {'ceremonyPlace': '   '}
      }), isFalse);
    });

    test('śmieci w danych nie wywracają detektorów', () {
      final junk = WeddingData.fromMap({
        'appConfig': 'to nie mapa',
        'budgetData': 42,
        'guests': 'nie lista',
        'guestVisibility': 7,
      });
      for (final t in tasks) {
        expect(() => t.done(junk), returnsNormally, reason: t.id);
        expect(t.done(junk), isFalse, reason: t.id);
      }
    });
  });

  group('poziomy', () {
    test('ukończenie podstaw nie domyka poziomu zaawansowanego', () {
      // Dokładnie o to chodzi w #17: po podstawowej zaawansowana wie, co
      // zostało zrobione, ale nadal ma swoje zadania.
      final basicOnly = WeddingData.fromMap({
        'appConfig': {
          'eventName': 'Wesele',
          'ceremonyPlace': 'Kościół',
          'receptionPlace': 'Sala',
          'coupleType': 'mixed',
          'verificationSurnames': 'Kowalscy',
        },
        'weddingDate': '2027-06-12',
        'budgetData': {
          'coupleNames': ['Ania', 'Piotr']
        },
        'guests': [
          {'id': 1}
        ],
      });

      final basic =
          tasks.where((t) => t.level == SetupLevel.basic).toList();
      expect(setupProgress(basic, basicOnly).complete, isTrue);
      expect(setupProgress(tasks, basicOnly).complete, isFalse);
      // Zaawansowany widok pokazuje oba poziomy — podstawy są już odhaczone.
      expect(setupProgress(tasks, basicOnly).done, basic.length);
    });
  });
}
