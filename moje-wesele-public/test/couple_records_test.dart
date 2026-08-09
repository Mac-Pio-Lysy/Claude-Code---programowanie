import 'package:flutter_test/flutter_test.dart';
import 'package:moje_wesele/models/couple.dart';
import 'package:moje_wesele/services/guest_service.dart';

/// Testy kroku 2: rekordy Pary Młodej zakładane z weselem (#9), limit dwóch
/// osób (#13) i zakaz osoby towarzyszącej (#12).
///
/// Sprawdzają CZYSTĄ logikę — bez Firestore'a. Ścieżki zapisu (`addGuest`,
/// `updateGuest`) wołają dokładnie te same funkcje, więc reguła jest jedna.
void main() {
  Map<String, dynamic> guest(int id, String category) =>
      {'id': id, 'category': category};

  group('rekordy Pary Młodej', () {
    test('puste imiona → brak rekordów (wesele jak dotąd)', () {
      final r = GuestService.buildCoupleRecords(
        startId: 1,
        type: CoupleType.mixed,
        person1: '',
        person2: '   ',
      );
      expect(r, isEmpty);
    });

    test('jedno imię → jeden rekord', () {
      final r = GuestService.buildCoupleRecords(
        startId: 1,
        type: CoupleType.mixed,
        person1: 'Ania',
        person2: '',
      );
      expect(r, hasLength(1));
      expect(r.first['firstName'], 'Ania');
      expect(r.first['lastName'], '');
      expect(r.first['id'], 1);
    });

    test('kategoria i brak zapraszającego', () {
      final r = GuestService.buildCoupleRecords(
        startId: 5,
        type: CoupleType.mixed,
        person1: 'Ania',
        person2: 'Piotr',
      );
      expect(r, hasLength(2));
      for (final g in r) {
        expect(g['category'], CoupleLabels.coupleCategoryValue);
        expect(g['invitedBy'], isNull);
        expect(g['witness'], isNull);
        expect(g['hasCompanion'], false);
      }
      // ID nadawane kolejno od startId.
      expect(r.map((g) => g['id']), [5, 6]);
    });

    test('„Imię Nazwisko" rozdzielane po pierwszej spacji', () {
      final r = GuestService.buildCoupleRecords(
        startId: 1,
        type: CoupleType.mixed,
        person1: 'Ania Kowalska Nowak',
        person2: 'Piotr',
      );
      expect(r[0]['firstName'], 'Ania');
      expect(r[0]['lastName'], 'Kowalska Nowak');
      expect(r[1]['firstName'], 'Piotr');
      expect(r[1]['lastName'], '');
    });

    test('płeć wynika z typu uroczystości', () {
      List<dynamic> genders(CoupleType t) => GuestService.buildCoupleRecords(
            startId: 1,
            type: t,
            person1: 'A',
            person2: 'B',
          ).map((g) => g['gender']).toList();

      expect(genders(CoupleType.mixed), ['K', 'M']);
      expect(genders(CoupleType.women), ['K', 'K']);
      expect(genders(CoupleType.men), ['M', 'M']);
      expect(genders(CoupleType.neutral), ['N', 'N']);
    });

    test('drugie imię puste → rekord dostaje kolejne wolne ID', () {
      final r = GuestService.buildCoupleRecords(
        startId: 1,
        type: CoupleType.mixed,
        person1: '',
        person2: 'Piotr',
      );
      expect(r, hasLength(1));
      expect(r.first['id'], 1);
      expect(r.first['firstName'], 'Piotr');
      // Płeć wg pozycji w parze, nie wg kolejności na liście.
      expect(r.first['gender'], 'M');
    });
  });

  group('limit dwóch osób (#13)', () {
    final pair = [
      guest(1, CoupleLabels.coupleCategoryValue),
      guest(2, CoupleLabels.coupleCategoryValue),
      guest(3, 'Rodzina'),
    ];

    test('liczy tylko Parę Młodą', () {
      expect(GuestService.coupleCount(pair), 2);
    });

    test('trzecia osoba odrzucona', () {
      expect(
        () => GuestService.checkCoupleRules(pair,
            category: CoupleLabels.coupleCategoryValue, hasCompanion: false),
        throwsA(isA<GuestRuleException>()),
      );
    });

    test('edycja istniejącego wpisu Pary Młodej przechodzi', () {
      // Gość nr 2 zapisywany ponownie nie może blokować sam siebie.
      GuestService.checkCoupleRules(pair,
          category: CoupleLabels.coupleCategoryValue,
          hasCompanion: false,
          exceptId: 2);
    });

    test('druga osoba przechodzi, gdy jest dopiero jedna', () {
      GuestService.checkCoupleRules(
        [guest(1, CoupleLabels.coupleCategoryValue)],
        category: CoupleLabels.coupleCategoryValue,
        hasCompanion: false,
      );
    });

    test('inne kategorie bez limitu', () {
      GuestService.checkCoupleRules(pair,
          category: 'Rodzina', hasCompanion: true);
    });
  });

  group('Para Młoda bez osoby towarzyszącej (#12)', () {
    test('„+1" odrzucone', () {
      expect(
        () => GuestService.checkCoupleRules(const [],
            category: CoupleLabels.coupleCategoryValue, hasCompanion: true),
        throwsA(isA<GuestRuleException>()),
      );
    });

    test('bez „+1" przechodzi', () {
      GuestService.checkCoupleRules(const [],
          category: CoupleLabels.coupleCategoryValue, hasCompanion: false);
    });

    test('komunikat nadaje się do pokazania użytkownikowi', () {
      try {
        GuestService.checkCoupleRules(const [],
            category: CoupleLabels.coupleCategoryValue, hasCompanion: true);
        fail('oczekiwano wyjątku');
      } on GuestRuleException catch (e) {
        expect(e.message, contains('Para Młoda'));
        expect(e.toString(), e.message);
      }
    });
  });

  group('składanie „Osoby" z imion', () {
    test('oba imiona', () {
      expect(CoupleLabels.joinNames('Ania', 'Piotr'), 'Ania i Piotr');
    });

    test('jedno imię — bez wiszącego spójnika', () {
      expect(CoupleLabels.joinNames('Ania', ''), 'Ania');
      expect(CoupleLabels.joinNames('  ', 'Piotr'), 'Piotr');
    });

    test('brak imion → pusto (wywołujący zostawia własny wpis)', () {
      expect(CoupleLabels.joinNames('', ''), '');
    });
  });
}
