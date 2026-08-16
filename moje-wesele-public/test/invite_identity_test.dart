import 'package:flutter_test/flutter_test.dart';
import 'package:moje_wesele/models/invite_identity.dart';

/// Wejście kodem paczki (etap 3) — parsowanie dokumentu kodu i kształt
/// tożsamości. Bez Firestore'a: testujemy to, co decyduje o poprawności.
void main() {
  Map<String, dynamic> doc({
    String token = 'TOKEN123',
    bool revoked = false,
    List<Map<String, dynamic>>? members,
  }) =>
      {
        'weddingId': 'W1',
        'guestToken': token,
        'packageId': 7,
        'revoked': revoked,
        'members': members ??
            [
              {'guestId': 7, 'name': 'Ania', 'kind': 'main', 'namePending': false},
              {
                'guestId': 8,
                'name': 'Wojtek',
                'kind': 'companion',
                'namePending': false
              },
            ],
      };

  group('dokument kodu paczki', () {
    test('czyta token, paczkę i skład', () {
      final d = InviteCodeDoc.fromMap('ABCDEFGHJKMN', doc())!;
      expect(d.code, 'ABCDEFGHJKMN');
      expect(d.guestToken, 'TOKEN123');
      expect(d.packageId, 7);
      expect(d.members.map((m) => m.name), ['Ania', 'Wojtek']);
      expect(d.members.first.isMain, isTrue);
      expect(d.members.last.isMain, isFalse);
    });

    test('brak dokumentu → null', () {
      expect(InviteCodeDoc.fromMap('X', null), isNull);
    });

    test('kod nadaje się do wejścia tylko gdy ma token i nie jest unieważniony',
        () {
      expect(InviteCodeDoc.fromMap('X', doc())!.usable, isTrue);
      expect(InviteCodeDoc.fromMap('X', doc(revoked: true))!.usable, isFalse);
      expect(InviteCodeDoc.fromMap('X', doc(token: ''))!.usable, isFalse);
    });

    test('unieważniony kod NADAL się parsuje', () {
      // Świadomie: gość ma zobaczyć „zaproszenie nieaktualne", a nie
      // „nieprawidłowy link" — to dwie różne sytuacje.
      final d = InviteCodeDoc.fromMap('X', doc(revoked: true))!;
      expect(d.revoked, isTrue);
      expect(d.members, hasLength(2));
    });

    test('osoby bez imienia nie trafiają na kafelki wyboru', () {
      final d = InviteCodeDoc.fromMap(
          'X',
          doc(members: [
            {'guestId': 7, 'name': 'Ania', 'kind': 'main', 'namePending': false},
            {
              'guestId': 8,
              'name': '',
              'kind': 'companion',
              'namePending': true
            },
          ]))!;
      expect(d.named.map((m) => m.name), ['Ania']);
      expect(d.hasPending, isTrue);
    });

    test('paczka bez osób oczekujących nie proponuje wpisania imienia', () {
      expect(InviteCodeDoc.fromMap('X', doc())!.hasPending, isFalse);
    });

    test('uszkodzone wpisy w members są pomijane', () {
      final d = InviteCodeDoc.fromMap('X', {
        ...doc(),
        'members': [
          {'guestId': 7, 'name': 'Ania', 'kind': 'main'},
          'śmieć',
          42,
        ],
      })!;
      expect(d.members, hasLength(1));
    });
  });

  group('identyfikator dokumentu tożsamości', () {
    test('wskazana osoba → jedno IMIENNE miejsce w paczce', () {
      // Realizacja decyzji 0.4: paczka dwuosobowa ma dokładnie dwa możliwe
      // identyfikatory, więc nie da się wygenerować trzeciej tożsamości.
      const a = PackageIdentity(
          code: 'ABCD',
          guestId: 7,
          displayName: 'Ania',
          source: PackageIdentity.sourcePicked);
      expect(a.docId('uid-1'), 'ABCD__7');
      // Ten sam człowiek z innego telefonu trafia w to samo miejsce.
      expect(a.docId('uid-2'), 'ABCD__7');
    });

    test('„nie wiem, kim jestem" → miejsce w zakresie własnego konta', () {
      const x = PackageIdentity(
          code: 'ABCD',
          guestId: null,
          displayName: 'Kasia',
          source: PackageIdentity.sourceTyped);
      expect(x.docId('uid-1'), 'ABCD__xuid-1');
      // Dwoje różnych gości nie nadpisuje się nawzajem.
      expect(x.docId('uid-2'), isNot(x.docId('uid-1')));
    });

    test('przypisana i nieprzypisana tożsamość są rozróżnialne', () {
      expect(
        const PackageIdentity(
                code: 'A',
                guestId: 1,
                displayName: 'x',
                source: PackageIdentity.sourcePicked)
            .isAssigned,
        isTrue,
      );
      expect(
        const PackageIdentity(
                code: 'A',
                guestId: null,
                displayName: 'x',
                source: PackageIdentity.sourceTyped)
            .isAssigned,
        isFalse,
      );
    });
  });

  group('zapis tożsamości', () {
    test('dokument do Firestore niesie uid wołającego', () {
      const id = PackageIdentity(
          code: 'ABCD',
          guestId: 7,
          displayName: 'Ania',
          source: PackageIdentity.sourcePicked);
      final m = id.toMap('uid-9');
      expect(m['uid'], 'uid-9');
      expect(m['code'], 'ABCD');
      expect(m['guestId'], 7);
      expect(m['displayName'], 'Ania');
      expect(m['source'], 'picked');
    });

    test('zapis lokalny wraca w tej samej postaci', () {
      const id = PackageIdentity(
          code: 'ABCD',
          guestId: 7,
          displayName: 'Ania',
          source: PackageIdentity.sourcePicked);
      final back = PackageIdentity.fromLocal(id.toLocal())!;
      expect(back.code, id.code);
      expect(back.guestId, id.guestId);
      expect(back.displayName, id.displayName);
      expect(back.source, id.source);
    });

    test('zapis lokalny bez imienia jest odrzucany', () {
      expect(
        PackageIdentity.fromLocal({'code': 'ABCD', 'displayName': ''}),
        isNull,
      );
      expect(PackageIdentity.fromLocal(null), isNull);
    });

    test('klucz lokalny jest per KOD i odporny na separatory', () {
      // Rodzic może zeskanować też kod dziecka — dwa zaproszenia w jednej
      // przeglądarce nie mogą się nadpisać.
      expect(PackageIdentity.localKey('ABCD-EFGH-JKMN'),
          PackageIdentity.localKey('abcdefghjkmn'));
      expect(PackageIdentity.localKey('AAAA'),
          isNot(PackageIdentity.localKey('BBBB')));
    });
  });
}
