import 'package:flutter_test/flutter_test.dart';
import 'package:moje_wesele/models/guest.dart';
import 'package:moje_wesele/models/guest_summary.dart';
import 'package:moje_wesele/screens/guests/guest_filters.dart';
import 'package:moje_wesele/services/guest_service.dart';

/// Testy kroku 1 partii DZIECI (#6): flaga `isChild` na gościu, filtr i
/// agregaty. Czysta logika, bez Firestore'a.
void main() {
  Guest guest({bool? isChild, String category = 'Rodzina', int id = 1}) =>
      Guest({
        'id': id,
        'firstName': 'Jan',
        'lastName': 'Kowalski',
        'category': category,
        // `?isChild` pomija klucz, gdy null — tak odwzorowujemy stary rekord
        // bez tego pola.
        'isChild': ?isChild,
      });

  GuestDraft draft({
    bool isChild = false,
    bool hasCompanion = false,
    bool companionIsChild = false,
  }) =>
      GuestDraft(
        firstName: 'Jan',
        lastName: 'Kowalski',
        invitedBy: 'bride',
        category: 'Rodzina',
        gender: 'M',
        witness: null,
        menuChoice: '',
        hasCompanion: hasCompanion,
        companionFirstName: '',
        companionLastName: '',
        needsAccommodation: false,
        isChild: isChild,
        companionIsChild: companionIsChild,
      );

  group('flaga isChild na modelu', () {
    test('brak pola → dorosły (zgodność wsteczna)', () {
      expect(guest().isChild, isFalse);
    });

    test('false i true czytane wprost', () {
      expect(guest(isChild: false).isChild, isFalse);
      expect(guest(isChild: true).isChild, isTrue);
    });

    test('flaga jest niezależna od kategorii', () {
      // Dziecko kuzynki zostaje w „Rodzinie" — o to chodziło we fladze
      // zamiast osobnej kategorii.
      final g = guest(isChild: true, category: 'Rodzina');
      expect(g.isChild, isTrue);
      expect(g.category, 'Rodzina');
    });
  });

  group('filtr „Dzieci"', () {
    final guests = [
      guest(id: 1, isChild: true),
      guest(id: 2, isChild: false),
      guest(id: 3), // stary rekord bez pola
    ];

    test('wybiera wyłącznie dzieci', () {
      final out = filterGuests(
          guests, const GuestFilter(quick: GuestQuick.children));
      expect(out.map((g) => g.id), [1]);
    });

    test('filtr „wszyscy" nie gubi nikogo', () {
      expect(filterGuests(guests, const GuestFilter()), hasLength(3));
    });

    test('kategoria i flaga działają razem', () {
      final mixed = [
        guest(id: 1, isChild: true, category: 'Rodzina'),
        guest(id: 2, isChild: true, category: 'Znajomi'),
      ];
      final out = filterGuests(
        mixed,
        const GuestFilter(quick: GuestQuick.children, category: 'Znajomi'),
      );
      expect(out.map((g) => g.id), [2]);
    });
  });

  group('agregaty podsumowania', () {
    test('liczy dzieci i dorosłych', () {
      final stats = GuestSummaryStats.from([
        guest(id: 1, isChild: true),
        guest(id: 2, isChild: true),
        guest(id: 3, isChild: false),
        guest(id: 4), // bez pola = dorosły
      ], const [], const [], const []);

      expect(stats.children, 2);
      expect(stats.adults, 2);
      expect(stats.total, 4);
    });

    test('wesele bez dzieci → zero (karta się nie pokaże)', () {
      final stats =
          GuestSummaryStats.from([guest()], const [], const [], const []);
      expect(stats.children, 0);
      expect(stats.adults, 1);
    });
  });

  group('zapis rekordu osoby towarzyszącej', () {
    test('towarzysząca dziedziczy flagę dziecka z formularza', () {
      final rec = GuestService.buildCompanionRecord(
        id: 7,
        draft: draft(hasCompanion: true, companionIsChild: true),
        inviterId: 1,
        inviterLastName: 'Kowalski',
        inviterCategory: 'Rodzina',
        inviterInvitedBy: 'bride',
      );
      expect(rec['isChild'], isTrue);
      // Flaga nie miesza się z pozostałymi polami powiązania.
      expect(rec['companionOfId'], 1);
      expect(rec['category'], 'Rodzina');
    });

    test('domyślnie towarzysząca jest dorosła', () {
      final rec = GuestService.buildCompanionRecord(
        id: 7,
        draft: draft(hasCompanion: true),
        inviterId: 1,
        inviterLastName: 'Kowalski',
        inviterCategory: 'Rodzina',
        inviterInvitedBy: 'bride',
      );
      expect(rec['isChild'], isFalse);
    });
  });

  group('opcja menu dziecięcego', () {
    test('jest na domyślnej liście menu', () {
      expect(GuestOptions.defaultMenuOptions,
          contains(GuestOptions.childMenuOption));
    });

    test('stała ma wartość zgodną z dotychczasową opcją', () {
      // Wartość zapisywana w `menuChoice` — zmiana zerwałaby stare dane.
      expect(GuestOptions.childMenuOption, 'Dla dziecka');
    });
  });
}
