import 'package:flutter_test/flutter_test.dart';
import 'package:moje_wesele/models/invite_package.dart';
import 'package:moje_wesele/services/invite_code_service.dart';

/// Kody paczek (etap 2) — czysta logika indeksu i wykrywania nieaktualnych
/// składów. Bez Firestore'a: testujemy to, co decyduje o poprawności, a nie
/// warstwę sieci.
void main() {
  Map<String, dynamic> g(
    int id,
    String first, {
    int? companionOf,
    bool namePending = false,
  }) =>
      {
        'id': id,
        'firstName': first,
        'lastName': '',
        'companionOfId': ?companionOf,
        if (namePending) 'namePending': true,
      };

  Map<String, dynamic> rawWith(List<dynamic> guests,
          [Map<String, dynamic>? index]) =>
      {
        'guests': guests,
        InviteCodeService.indexField: ?index,
      };

  group('odcisk składu paczki', () {
    test('ten sam skład daje ten sam odcisk', () {
      final a = InvitePackage.buildAll([g(1, 'Ania'), g(2, 'Wojtek', companionOf: 1)]).single;
      final b = InvitePackage.buildAll([g(1, 'Ania'), g(2, 'Wojtek', companionOf: 1)]).single;
      expect(a.rosterFingerprint, b.rosterFingerprint);
    });

    test('zmiana imienia zmienia odcisk', () {
      final a = InvitePackage.buildAll([g(1, 'Ania')]).single;
      final b = InvitePackage.buildAll([g(1, 'Anna')]).single;
      expect(a.rosterFingerprint, isNot(b.rosterFingerprint));
    });

    test('dodanie osoby do paczki zmienia odcisk', () {
      final a = InvitePackage.buildAll([g(1, 'Ania')]).single;
      final b = InvitePackage.buildAll(
          [g(1, 'Ania'), g(2, 'Wojtek', companionOf: 1)]).single;
      expect(a.rosterFingerprint, isNot(b.rosterFingerprint));
    });

    test('USUNIĘCIE osoby z paczki zmienia odcisk', () {
      // Ryzyko #2 z planu: kod zostaje, ale organizator musi zobaczyć,
      // że wydrukowany skład już się nie zgadza.
      final przed = InvitePackage.buildAll(
          [g(1, 'Ania'), g(2, 'Wojtek', companionOf: 1)]).single;
      final po = InvitePackage.buildAll([g(1, 'Ania')]).single;
      expect(przed.rosterFingerprint, isNot(po.rosterFingerprint));
    });

    test('dane spoza rosteru NIE unieważniają kodu', () {
      // Dieta, stół i kategoria nigdy nie opuszczają dokumentu wesela,
      // więc ich zmiana nie ma powodu odświeżać publicznego składu.
      final bez = InvitePackage.buildAll([g(1, 'Ania')]).single;
      final zeZmianami = InvitePackage.buildAll([
        {...g(1, 'Ania'), 'diet': 'vegan', 'tableId': 3, 'category': 'Rodzina'},
      ]).single;
      expect(bez.rosterFingerprint, zeZmianami.rosterFingerprint);
    });

    test('uzupełnienie imienia osoby towarzyszącej zmienia odcisk', () {
      final przed = InvitePackage.buildAll(
          [g(1, 'Ania'), g(2, '', companionOf: 1, namePending: true)]).single;
      final po = InvitePackage.buildAll(
          [g(1, 'Ania'), g(2, 'Wojtek', companionOf: 1)]).single;
      expect(przed.rosterFingerprint, isNot(po.rosterFingerprint));
    });
  });

  group('odczyt prywatnego indeksu', () {
    test('brak pola = pusty indeks (wesele bez kodów)', () {
      expect(InviteCodeService.indexOf(const {}), isEmpty);
      expect(InviteCodeService.indexOf(rawWith([g(1, 'Ania')])), isEmpty);
    });

    test('czyta kod, stan unieważnienia i odcisk', () {
      final index = InviteCodeService.indexOf(rawWith([], {
        '7': {'code': 'ABCDEFGHJKMN', 'revoked': true, 'roster': 'x'},
      }));
      expect(index[7]!.code, 'ABCDEFGHJKMN');
      expect(index[7]!.revoked, isTrue);
      expect(index[7]!.roster, 'x');
    });

    test('wpisy uszkodzone są pomijane, reszta zostaje', () {
      final index = InviteCodeService.indexOf(rawWith([], {
        'nie-liczba': {'code': 'AAAA'},
        '2': 'nie-mapa',
        '3': {'code': ''},
        '4': {'code': 'BBBB'},
      }));
      expect(index.keys, [4]);
    });
  });

  group('wykrywanie nieaktualnych kodów', () {
    test('zgodny odcisk = kod aktualny', () {
      final p = InvitePackage.buildAll([g(1, 'Ania')]).single;
      final index = {
        1: PackageCode(
            packageId: 1,
            code: 'AAAA',
            revoked: false,
            roster: p.rosterFingerprint),
      };
      expect(InviteCodeService.staleOf([p], index), isEmpty);
    });

    test('rozjechany odcisk = kod nieaktualny', () {
      final p = InvitePackage.buildAll([g(1, 'Ania')]).single;
      final index = {
        1: const PackageCode(
            packageId: 1, code: 'AAAA', revoked: false, roster: 'stare'),
      };
      expect(InviteCodeService.staleOf([p], index).single.id, 1);
    });

    test('paczka BEZ kodu nie jest nieaktualna — jest po prostu bez kodu', () {
      final p = InvitePackage.buildAll([g(1, 'Ania')]).single;
      expect(InviteCodeService.staleOf([p], const {}), isEmpty);
    });

    test('unieważniony kod też bywa nieaktualny', () {
      // Unieważnienie nie zwalnia z odświeżenia — organizator może go
      // przywrócić i skład musi się zgadzać.
      final p = InvitePackage.buildAll([g(1, 'Ania')]).single;
      final index = {
        1: const PackageCode(
            packageId: 1, code: 'AAAA', revoked: true, roster: 'stare'),
      };
      expect(InviteCodeService.staleOf([p], index), hasLength(1));
    });
  });

  group('zapis indeksu', () {
    test('mapa zawiera dokładnie to, co czytamy z powrotem', () {
      const pc = PackageCode(
          packageId: 3, code: 'ABCD', revoked: true, roster: 'r1');
      final back = PackageCode.fromMap(3, pc.toMap());
      expect(back.code, pc.code);
      expect(back.revoked, pc.revoked);
      expect(back.roster, pc.roster);
    });
  });
}
