import 'package:flutter_test/flutter_test.dart';
import 'package:moje_wesele/models/invite_package.dart';

/// Paczki zaproszeniowe (etap 1) — wyliczanie z powiązań gości.
///
/// Kluczowa zasada, której pilnują te testy: paczka NIE jest przechowywana.
/// Powstaje z `companionOfId`, więc zmiana powiązania natychmiast zmienia
/// podział zaproszeń i nie ma czego migrować ani synchronizować.
void main() {
  Map<String, dynamic> g(
    int id,
    String first, {
    String last = '',
    int? companionOf,
    bool namePending = false,
  }) =>
      {
        'id': id,
        'firstName': first,
        'lastName': last,
        'companionOfId': ?companionOf,
        if (namePending) 'namePending': true,
      };

  group('tryb zapraszania', () {
    test('brak pola = tryb wspólny (zgodność wsteczna)', () {
      expect(InviteMode.fromRaw(const {}), InviteMode.shared);
      expect(InviteMode.fromRaw(const {'appConfig': {}}), InviteMode.shared);
    });

    test('nieznana wartość nie włącza trybu indywidualnego', () {
      expect(
        InviteMode.fromRaw(const {
          'appConfig': {'inviteMode': 'cokolwiek'}
        }),
        InviteMode.shared,
      );
    });

    test('zapisana wartość jest respektowana', () {
      expect(
        InviteMode.fromRaw(const {
          'appConfig': {'inviteMode': 'individual'}
        }),
        InviteMode.individual,
      );
    });
  });

  group('budowanie paczek', () {
    test('sami goście bez powiązań → same paczki jednoosobowe', () {
      final p = InvitePackage.buildAll([g(1, 'Ania'), g(2, 'Piotr')]);
      expect(p.length, 2);
      expect(p.every((x) => x.isSingle), isTrue);
      expect(p.every((x) => x.size == 1), isTrue);
    });

    test('gość z osobą towarzyszącą → jedna paczka dwuosobowa', () {
      final p = InvitePackage.buildAll([
        g(1, 'Ania'),
        g(2, 'Wojtek', companionOf: 1),
      ]);
      expect(p.length, 1);
      expect(p.single.size, 2);
      expect(p.single.main.firstName, 'Ania');
      expect(p.single.companions.single.firstName, 'Wojtek');
    });

    test('rodzice z dzieckiem → jedna paczka trzyosobowa', () {
      final p = InvitePackage.buildAll([
        g(1, 'Maria'),
        g(2, 'Jan', companionOf: 1),
        g(3, 'Zosia', companionOf: 1),
      ]);
      expect(p.single.size, 3);
      expect(p.single.everyone.map((x) => x.firstName),
          ['Maria', 'Jan', 'Zosia']);
    });

    test('identyfikatorem paczki jest id gościa głównego', () {
      final p = InvitePackage.buildAll([
        g(7, 'Ania'),
        g(8, 'Wojtek', companionOf: 7),
      ]);
      expect(p.single.id, 7);
    });

    test('towarzysząca wskazująca na USUNIĘTEGO gościa nie ginie', () {
      // Bez tego osoba wypadłaby z zaproszeń bez śladu — a wciąż przyjdzie
      // na wesele i liczy się do cateringu.
      final p = InvitePackage.buildAll([g(5, 'Kasia', companionOf: 99)]);
      expect(p.length, 1);
      expect(p.single.main.firstName, 'Kasia');
      expect(p.single.isSingle, isTrue);
    });

    test('pusta lista gości daje zero paczek', () {
      expect(InvitePackage.buildAll(const []), isEmpty);
    });

    test('wpisy niebędące mapą są pomijane', () {
      final p = InvitePackage.buildAll([g(1, 'Ania'), 'śmieć', 42]);
      expect(p.length, 1);
    });
  });

  group('skład paczki dla gościa', () {
    test('same imiona — bez nazwisk i innych danych', () {
      final p = InvitePackage.buildAll([
        g(1, 'Ania', last: 'Kowalska'),
        g(2, 'Wojtek', last: 'Nowak', companionOf: 1),
      ]).single;

      expect(p.members.map((m) => m.name), ['Ania', 'Wojtek']);
    });

    test('nazwisko dokładane TYLKO przy powtórzonym imieniu', () {
      final p = InvitePackage.buildAll([
        g(1, 'Anna', last: 'Kowalska'),
        g(2, 'Anna', last: 'Nowak', companionOf: 1),
        g(3, 'Wojtek', last: 'Zieliński', companionOf: 1),
      ]).single;

      final names = p.members.map((m) => m.name).toList();
      expect(names, ['Anna Kowalska', 'Anna Nowak', 'Wojtek']);
    });

    test('osoba bez imienia ma pusty tekst i własną flagę', () {
      final p = InvitePackage.buildAll([
        g(1, 'Ania'),
        g(2, '', companionOf: 1, namePending: true),
      ]).single;

      expect(p.hasPendingNames, isTrue);
      expect(p.members.last.namePending, isTrue);
      expect(p.members.last.name, isEmpty);
      // Gość główny nie jest oznaczony jako oczekujący.
      expect(p.members.first.namePending, isFalse);
    });

    test('gość główny jest oznaczony jako adresat', () {
      final p = InvitePackage.buildAll([
        g(1, 'Ania'),
        g(2, 'Wojtek', companionOf: 1),
      ]).single;

      expect(p.members.first.isMain, isTrue);
      expect(p.members.last.isMain, isFalse);
    });

    test('każdy członek niesie id rekordu gościa', () {
      final p = InvitePackage.buildAll([
        g(4, 'Ania'),
        g(9, 'Wojtek', companionOf: 4),
      ]).single;

      expect(p.members.map((m) => m.guestId), [4, 9]);
    });
  });

  group('podsumowanie', () {
    test('liczy zaproszenia, osoby, wieloosobowe i braki imion', () {
      final packages = InvitePackage.buildAll([
        g(1, 'Ania'),
        g(2, 'Wojtek', companionOf: 1),
        g(3, 'Marek'),
        g(4, 'Kasia'),
        g(5, '', companionOf: 4, namePending: true),
      ]);
      final s = InvitePackage.statsOf(packages);

      expect(s.packages, 3); // Ania+Wojtek, Marek, Kasia+?
      expect(s.people, 5);
      expect(s.multi, 2);
      expect(s.pendingNames, 1);
    });

    test('zero gości = zerowe podsumowanie', () {
      final s = InvitePackage.statsOf(InvitePackage.buildAll(const []));
      expect(s.packages, 0);
      expect(s.people, 0);
      expect(s.multi, 0);
      expect(s.pendingNames, 0);
    });
  });
}
