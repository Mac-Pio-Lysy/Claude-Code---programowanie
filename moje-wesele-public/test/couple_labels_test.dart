import 'package:flutter_test/flutter_test.dart';
import 'package:moje_wesele/models/couple.dart';
import 'package:moje_wesele/models/vehicle.dart';
import 'package:moje_wesele/models/wedding_data.dart';

/// Testy etykiet Pary Młodej (krok 1: typ uroczystości + etykiety).
///
/// Sprawdzają CZYSTĄ logikę wyliczania tekstów — bez Firestore'a. Najważniejszy
/// jest przypadek zgodności wstecznej: wesele bez `coupleType` musi wyglądać
/// dokładnie tak jak przed zmianą.
void main() {
  Map<String, dynamic> raw({String? type, List<String>? names}) => {
        if (type != null) 'appConfig': {'coupleType': type},
        if (names != null) 'budgetData': {'coupleNames': names},
      };

  group('zgodność wsteczna', () {
    test('brak coupleType → mixed i dotychczasowe etykiety', () {
      final l = CoupleLabels.fromRaw(raw());
      expect(l.type, CoupleType.mixed);
      expect(l.person1, '👰 Panna Młoda');
      expect(l.person2, '🤵 Pan Młody');
      expect(l.invitedBy('bride'), '👰 Panna Młoda');
      expect(l.invitedBy('groom'), '🤵 Pan Młody');
      expect(l.witness('witness_bride'), 'Świadkowa');
      expect(l.witness('witness_groom'), 'Świadek');
      expect(l.coupleCategoryLabel, 'Państwo Młodzi');
    });

    test('nieznana wartość coupleType → mixed', () {
      expect(CoupleLabels.fromRaw(raw(type: 'kosmici')).type, CoupleType.mixed);
    });

    test('para mieszana ignoruje imiona — etykiety bez zmian', () {
      final l = CoupleLabels.fromRaw(raw(names: ['Patrycja', 'Piotr']));
      expect(l.person1, '👰 Panna Młoda');
      expect(l.person2, '🤵 Pan Młody');
    });
  });

  group('pary jednopłciowe', () {
    test('dwie kobiety z imionami → imiona', () {
      final l = CoupleLabels.fromRaw(
          raw(type: 'women', names: ['Ania', 'Kasia']));
      expect(l.person1, '👰 Ania');
      expect(l.person2, '👰 Kasia');
      expect(l.invitedBy('bride'), '👰 Ania');
      expect(l.coupleCategoryLabel, 'Panny Młode');
    });

    test('dwie kobiety bez imion → numerowanie awaryjne', () {
      final l = CoupleLabels.fromRaw(raw(type: 'women'));
      expect(l.person1, '👰 Panna Młoda 1');
      expect(l.person2, '👰 Panna Młoda 2');
    });

    test('zastępcze „Osoba 1/2" nie są traktowane jak imiona', () {
      final l = CoupleLabels.fromRaw(
          raw(type: 'men', names: ['Osoba 1', 'Osoba 2']));
      expect(l.person1, '🤵 Pan Młody 1');
      expect(l.person2, '🤵 Pan Młody 2');
    });

    test('dwóch mężczyzn z imionami', () {
      final l =
          CoupleLabels.fromRaw(raw(type: 'men', names: ['Adam', 'Bartek']));
      expect(l.person1, '🤵 Adam');
      expect(l.person2, '🤵 Bartek');
      expect(l.coupleCategoryLabel, 'Panowie Młodzi');
    });

    test('świadek rozróżniany imieniem, a bez imienia numerem', () {
      final withNames =
          CoupleLabels.fromRaw(raw(type: 'women', names: ['Ania', 'Kasia']));
      expect(withNames.witness('witness_bride'), 'Świadek/Świadkowa (Ania)');
      expect(withNames.witness('witness_groom'), 'Świadek/Świadkowa (Kasia)');

      final noNames = CoupleLabels.fromRaw(raw(type: 'women'));
      expect(noNames.witness('witness_bride'), 'Świadek/Świadkowa (osoba 1)');
    });
  });

  group('neutralne', () {
    test('bez imion → Osoba 1 / Osoba 2, bez emoji', () {
      final l = CoupleLabels.fromRaw(raw(type: 'neutral'));
      expect(l.person1, 'Osoba 1');
      expect(l.person2, 'Osoba 2');
      expect(l.coupleCategoryLabel, 'Para Młoda');
    });

    test('z imionami → same imiona', () {
      final l =
          CoupleLabels.fromRaw(raw(type: 'neutral', names: ['Alex', 'Sam']));
      expect(l.person1, 'Alex');
      expect(l.person2, 'Sam');
    });
  });

  group('wartości w bazie zostają nietknięte', () {
    test('kategoria zapisywana jest zawsze taka sama', () {
      expect(CoupleLabels.coupleCategoryValue, 'Państwo Młodzi');
    });

    test('nieznana rola daje bezpieczny placeholder', () {
      final l = CoupleLabels.fromRaw(raw(type: 'women'));
      expect(l.invitedBy(null), '—');
      expect(l.witness('cokolwiek'), 'Brak roli');
    });
  });

  group('etykiety w widokach (krok 3)', () {
    test('filtr „kto zaprosił" — dopełniacz przy parze mieszanej', () {
      final l = CoupleLabels.fromRaw(raw());
      expect(l.invitedByFilterLabel('bride'), 'Od Panny Młodej');
      expect(l.invitedByFilterLabel('groom'), 'Od Pana Młodego');
    });

    test('filtr przy parze jednopłciowej używa imion', () {
      final l =
          CoupleLabels.fromRaw(raw(type: 'women', names: ['Ania', 'Kasia']));
      expect(l.invitedByFilterLabel('bride'), 'Od: 👰 Ania');
      expect(l.invitedByFilterLabel('groom'), 'Od: 👰 Kasia');
    });

    test('etykieta bez emoji do podpowiedzi i treści', () {
      expect(CoupleLabels.fromRaw(raw()).personPlain(1), 'Panna Młoda');
      expect(
        CoupleLabels.fromRaw(raw(type: 'men', names: ['Adam', 'Bartek']))
            .personPlain(2),
        'Bartek',
      );
      expect(
        CoupleLabels.fromRaw(raw(type: 'women')).personPlain(1),
        'Panna Młoda 1',
      );
    });

    test('frazy z osobą wybierają wariant, nie sklejają gramatyki', () {
      // Zastąpiło `withPerson(prefix, index)`: każde miejsce ma teraz własny,
      // pełny klucz i pyta tylko, KTÓRY wariant wziąć.
      expect(CoupleLabels.fromRaw(raw()).usesNames, isFalse);
      expect(
        CoupleLabels.fromRaw(raw(type: 'women', names: ['Ania', 'Kasia']))
            .usesNames,
        isTrue,
      );

      // Efekt końcowy na przykładzie typów pojazdu.
      CoupleLabels.current = CoupleLabels.fromRaw(raw());
      expect(kVehicleTypes, contains('Auto rodziców Panny Młodej'));

      CoupleLabels.current =
          CoupleLabels.fromRaw(raw(type: 'women', names: ['Ania', 'Kasia']));
      expect(kVehicleTypes, contains('Auto rodziców (Kasia)'));
      CoupleLabels.current = CoupleLabels.fallback;
    });

    test('ikona pary zależy od typu', () {
      expect(CoupleLabels.fromRaw(raw()).coupleEmoji, '👰');
      expect(CoupleLabels.fromRaw(raw(type: 'men')).coupleEmoji, '🤵');
      expect(CoupleLabels.fromRaw(raw(type: 'neutral')).coupleEmoji, '💍');
    });
  });

  group('spinanie z odczytem wesela', () {
    test('WeddingData.fromMap ustawia globalne etykiety', () {
      CoupleLabels.current = CoupleLabels.fallback;

      WeddingData.fromMap(raw(type: 'men', names: ['Adam', 'Bartek']));
      expect(CoupleLabels.current.person1, '🤵 Adam');

      // Powrót do wesela bez konfiguracji nie może zostawić starych etykiet.
      WeddingData.fromMap(raw());
      expect(CoupleLabels.current.person1, '👰 Panna Młoda');
    });
  });
}
