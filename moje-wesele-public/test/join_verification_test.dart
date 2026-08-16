import 'package:flutter_test/flutter_test.dart';
import 'package:moje_wesele/services/join_verification.dart';

/// Weryfikacja nazwiska przy dołączaniu gościa kodem.
///
/// Punkt wyjścia: zgłoszony błąd bezpieczeństwa — poprzednia wersja robiła
/// `contains()`, więc fragment nazwiska („Kow") otwierał cudze wesele.
void main() {
  bool ok(String input,
          {String surnames = '', String displayNames = ''}) =>
      JoinVerification.surnameMatches(
        input: input,
        surnames: surnames,
        displayNames: displayNames,
      );

  group('fragment NIE przechodzi (istota zgłoszenia)', () {
    test('początek nazwiska odrzucony', () {
      expect(ok('Kow', surnames: 'Kowalscy'), isFalse);
      expect(ok('Kowal', surnames: 'Kowalscy'), isFalse);
      expect(ok('Kowalsc', surnames: 'Kowalscy'), isFalse);
    });

    test('środek i koniec nazwiska odrzucone', () {
      expect(ok('owalsc', surnames: 'Kowalscy'), isFalse);
      expect(ok('scy', surnames: 'Kowalscy'), isFalse);
    });

    test('dwie litery — dawniej minimalna długość, dziś za mało', () {
      expect(ok('ko', surnames: 'Kowalscy'), isFalse);
      expect(ok('ow', surnames: 'Kowalscy'), isFalse);
    });

    test('nazwisko z doklejonym ogonem odrzucone', () {
      expect(ok('Kowalscy2', surnames: 'Kowalscy'), isFalse);
      expect(ok('Kowalscyy', surnames: 'Kowalscy'), isFalse);
    });

    test('fragment sklejony z dwóch pól nie przechodzi', () {
      // Dawniej pola były sklejane w jeden ciąg, więc „i pio" trafiało
      // w „ania i piotr”.
      expect(ok('i pio', displayNames: 'Ania i Piotr'), isFalse);
      expect(ok('cy ania', surnames: 'Kowalscy', displayNames: 'Ania i Piotr'),
          isFalse);
    });
  });

  group('pełne nazwisko przechodzi', () {
    test('dokładnie tak, jak wpisała para', () {
      expect(ok('Kowalscy', surnames: 'Kowalscy'), isTrue);
    });

    test('wielkość liter nie ma znaczenia', () {
      expect(ok('kowalscy', surnames: 'Kowalscy'), isTrue);
      expect(ok('KOWALSCY', surnames: 'Kowalscy'), isTrue);
      expect(ok('KoWaLsCy', surnames: 'Kowalscy'), isTrue);
    });

    test('spacje wiodące, końcowe i podwójne są pomijane', () {
      expect(ok('  Kowalscy  ', surnames: 'Kowalscy'), isTrue);
      expect(ok('Kowalski   Nowak', surnames: 'Kowalski Nowak'), isTrue);
      expect(ok('Kowalscy', surnames: '  Kowalscy '), isTrue);
    });

    test('polskie znaki diakrytyczne po obu stronach', () {
      expect(ok('Żółcińscy', surnames: 'Żółcińscy'), isTrue);
      expect(ok('Zolcinscy', surnames: 'Żółcińscy'), isTrue);
      expect(ok('Żółcińscy', surnames: 'Zolcinscy'), isTrue);
    });
  });

  group('dwa nazwiska — wystarczy jedno, ale w całości', () {
    const dwa = 'Kowalski Nowak';

    test('każde z nazwisk osobno', () {
      expect(ok('Kowalski', surnames: dwa), isTrue);
      expect(ok('Nowak', surnames: dwa), isTrue);
    });

    test('oba razem, w dowolnej kolejności', () {
      expect(ok('Kowalski Nowak', surnames: dwa), isTrue);
      expect(ok('Nowak Kowalski', surnames: dwa), isTrue);
    });

    test('fragment któregokolwiek nadal odrzucony', () {
      expect(ok('Kowal', surnames: dwa), isFalse);
      expect(ok('Now', surnames: dwa), isFalse);
    });

    test('obce nazwisko dołożone do prawdziwego nie przechodzi', () {
      expect(ok('Kowalski Wiśniewski', surnames: dwa), isFalse);
    });

    test('nazwisko dwuczłonowe z myślnikiem', () {
      expect(ok('Kowalska-Nowak', surnames: 'Kowalska-Nowak'), isTrue);
      expect(ok('Kowalska', surnames: 'Kowalska-Nowak'), isTrue);
      expect(ok('Nowak', surnames: 'Kowalska-Nowak'), isTrue);
      expect(ok('Kowal', surnames: 'Kowalska-Nowak'), isFalse);
    });
  });

  group('pole „Osoby" jako zapas (gdy nazwisko nieuzupełnione)', () {
    // Ustawienia wprost zapowiadają parze, że przy pustym polu nazwisk gość
    // poda „Osoby" — więc to źródło musi działać.
    const osoby = 'Ania i Piotr';

    test('imię w całości przechodzi', () {
      expect(ok('Ania', displayNames: osoby), isTrue);
      expect(ok('Piotr', displayNames: osoby), isTrue);
      expect(ok('Ania i Piotr', displayNames: osoby), isTrue);
    });

    test('spójnik „i" sam z siebie nie jest kluczem', () {
      expect(ok('i', displayNames: osoby), isFalse);
    });

    test('fragment imienia odrzucony', () {
      expect(ok('An', displayNames: osoby), isFalse);
      expect(ok('Pio', displayNames: osoby), isFalse);
    });
  });

  group('nazwa wydarzenia NIE otwiera wesela', () {
    // Największa dziura poprzedniej wersji: „Ceremonia Weselna" to wartość
    // domyślna, wspólna dla wielu wesel. Teraz nie bierze udziału w ogóle.
    test('domyślna nazwa wydarzenia nie przechodzi', () {
      expect(ok('Ceremonia Weselna', surnames: 'Kowalscy'), isFalse);
      expect(ok('Ceremonia', surnames: 'Kowalscy'), isFalse);
      expect(ok('Wesele', surnames: 'Kowalscy'), isFalse);
    });
  });

  group('przypadki brzegowe', () {
    test('pusty wpis odrzucony', () {
      expect(ok('', surnames: 'Kowalscy'), isFalse);
      expect(ok('   ', surnames: 'Kowalscy'), isFalse);
    });

    test('wesele bez żadnych danych nie wpuszcza nikogo', () {
      expect(ok('Kowalscy'), isFalse);
      expect(ok('cokolwiek', surnames: '  ', displayNames: ''), isFalse);
    });

    test('same znaki interpunkcyjne odrzucone', () {
      expect(ok('---', surnames: 'Kowalscy'), isFalse);
      expect(ok('/', surnames: 'Kowalscy'), isFalse);
    });

    test('oba pola naraz — wystarczy trafić w którekolwiek', () {
      expect(ok('Kowalscy', surnames: 'Kowalscy', displayNames: 'Ania i Piotr'),
          isTrue);
      expect(ok('Ania', surnames: 'Kowalscy', displayNames: 'Ania i Piotr'),
          isTrue);
      expect(ok('Nowakowie', surnames: 'Kowalscy', displayNames: 'Ania i Piotr'),
          isFalse);
    });
  });

  group('normalizacja', () {
    test('sprowadza zapis do porównywalnej postaci', () {
      expect(JoinVerification.normalize('  KOWALSCY  '), 'kowalscy');
      expect(JoinVerification.normalize('Ania   i    Piotr'), 'ania i piotr');
      expect(JoinVerification.normalize('Żółć'), 'zolc');
    });

    test('nie skraca tekstu — fragment zostaje fragmentem', () {
      expect(JoinVerification.normalize('Kow'), 'kow');
      expect(JoinVerification.normalize('Kowalscy'), 'kowalscy');
    });
  });
}
