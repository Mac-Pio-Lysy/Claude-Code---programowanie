import 'package:flutter_test/flutter_test.dart';
import 'package:moje_wesele/models/guest.dart';
import 'package:moje_wesele/services/guest_service.dart';

/// Testy powiązania osoby towarzyszącej (zgłoszenia #4, #3, #5) — krok 1.
///
/// Sprawdzają CZYSTĄ logikę budowania rekordu i odczytu modelu, bez dotykania
/// Firestore'a. Zapis i usuwanie wymagają atrapy bazy (`fake_cloud_firestore`),
/// której projekt nie ma — te ścieżki są opisane w instrukcji testu ręcznego.
void main() {
  

  GuestDraft draft({
    String companionFirstName = '',
    String companionLastName = '',
    String? relation,
    bool namePending = false,
    String? companionCategory,
  }) =>
      GuestDraft(
        firstName: 'Jan',
        lastName: 'Kowalski',
        invitedBy: 'bride',
        category: 'Praca',
        gender: 'M',
        witness: null,
        menuChoice: '',
        hasCompanion: true,
        companionFirstName: companionFirstName,
        companionLastName: companionLastName,
        needsAccommodation: false,
        companionRelation: relation,
        companionNamePending: namePending,
        companionCategory: companionCategory,
      );

  Guest build(GuestDraft d) => Guest(GuestService.buildCompanionRecord(
        id: 2,
        draft: d,
        inviterId: 1,
        inviterLastName: 'Kowalski',
        inviterCategory: d.category,
        inviterInvitedBy: d.invitedBy,
      ));

  test('#4 rekord towarzyszącej wskazuje na zapraszającego', () {
    final g = build(draft(companionFirstName: 'Anna', companionLastName: 'Nowak'));
    expect(g.companionOfId, 1);
    expect(g.isCompanion, isTrue);
    expect(g.firstName, 'Anna');
    expect(g.lastName, 'Nowak');
    expect(g.namePending, isFalse);
  });

  test('#3 typ relacji trafia do rekordu', () {
    final g = build(draft(
        companionFirstName: 'Anna', relation: CompanionRelation.partner));
    expect(g.relationType, CompanionRelation.partner);
    expect(CompanionRelation.label(g.relationType), 'Para');
  });

  test('#3 „Rodzina" podpowiada kategorię Rodzina zamiast dziedziczenia', () {
    final g = build(
        draft(companionFirstName: 'Ewa', relation: CompanionRelation.family));
    expect(g.category, 'Rodzina');
  });

  test('bez typu relacji dziedziczy kategorię zapraszającego', () {
    final g = build(draft(companionFirstName: 'Ewa'));
    expect(g.category, 'Praca');
  });

  test('jawnie wybrana kategoria wygrywa z podpowiedzią', () {
    final g = build(draft(
      companionFirstName: 'Ewa',
      relation: CompanionRelation.family,
      companionCategory: 'Znajomi',
    ));
    expect(g.category, 'Znajomi');
  });

  test('#5 brak imienia → nazwa zastępcza z nazwiskiem zapraszającego', () {
    final g = build(draft(namePending: true, relation: CompanionRelation.unknown));
    expect(g.namePending, isTrue);
    expect(g.firstName, CompanionRelation.placeholderFirstName);
    expect(g.lastName, 'Kowalski');
    expect(g.fullName, 'Osoba towarzysząca Kowalski');
  });

  test('#5 pusty formularz też daje rekord „do potwierdzenia"', () {
    final g = build(draft());
    expect(g.namePending, isTrue);
    expect(g.relationType, CompanionRelation.unknown);
  });

  test('towarzysząca nigdy nie jest w kategorii „Państwo Młodzi"', () {
    final d = GuestDraft(
      firstName: 'Ona',
      lastName: 'Młoda',
      invitedBy: 'bride',
      category: 'Państwo Młodzi',
      gender: 'K',
      witness: null,
      menuChoice: '',
      hasCompanion: true,
      companionFirstName: 'On',
      companionLastName: 'Młody',
      needsAccommodation: false,
    );
    final g = Guest(GuestService.buildCompanionRecord(
      id: 2,
      draft: d,
      inviterId: 1,
      inviterLastName: 'Młoda',
      inviterCategory: 'Państwo Młodzi',
      inviterInvitedBy: 'bride',
    ));
    expect(g.category, isNot('Państwo Młodzi'));
  });

  group('zgodność ze starymi danymi', () {
    test('gość bez nowych pól jest samodzielny', () {
      final old = Guest({
        'id': 1,
        'firstName': 'Stary',
        'lastName': 'Gość',
        'hasCompanion': true,
        'companionName': 'Maria Stara',
      });
      expect(old.companionOfId, isNull);
      expect(old.isCompanion, isFalse);
      expect(old.relationType, isNull);
      expect(old.namePending, isFalse);
      // Stary „+1" bez rekordu zostaje nietknięty.
      expect(old.hasCompanion, isTrue);
      expect(old.companionName, 'Maria Stara');
    });

    test('pusty rekord nie wywraca modelu', () {
      final g = Guest(const {});
      expect(g.companionOfId, isNull);
      expect(g.isCompanion, isFalse);
      expect(g.namePending, isFalse);
      expect(g.hasCompanion, isFalse);
    });
  });
}
