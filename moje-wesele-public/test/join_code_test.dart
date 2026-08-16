import 'package:flutter_test/flutter_test.dart';
import 'package:moje_wesele/models/join_code.dart';

/// Kod dołączenia do wesela — postać, długość i zgodność wsteczna.
void main() {
  group('alfabet', () {
    test('nie zawiera znaków mylących przy przepisywaniu', () {
      // 0/O oraz 1/I/L to najczęstsze pomyłki przy odczycie z kartki.
      for (final ch in ['0', 'O', '1', 'I', 'L']) {
        expect(JoinCode.alphabet.contains(ch), isFalse, reason: ch);
      }
    });

    test('same wielkie litery i cyfry', () {
      expect(RegExp(r'^[A-Z2-9]+$').hasMatch(JoinCode.alphabet), isTrue);
    });

    test('bez powtórzeń', () {
      expect(JoinCode.alphabet.split('').toSet().length,
          JoinCode.alphabet.length);
    });
  });

  group('normalizacja wpisanego kodu', () {
    test('separatory grup nie przeszkadzają', () {
      expect(JoinCode.normalize('ABCD-EFGH-JKMN'), 'ABCDEFGHJKMN');
      expect(JoinCode.normalize('ABCD EFGH JKMN'), 'ABCDEFGHJKMN');
      expect(JoinCode.normalize('ABCD.EFGH/JKMN'), 'ABCDEFGHJKMN');
    });

    test('małe litery i spacje wokół', () {
      expect(JoinCode.normalize('  abcd-efgh-jkmn '), 'ABCDEFGHJKMN');
    });

    test('znaki spoza alfabetu odpadają — także mylące', () {
      // Gość, który zobaczy „O" tam, gdzie jest „Q", nie wpisze zera
      // przypadkiem — takiego znaku po prostu w kodzie nie ma.
      expect(JoinCode.normalize('AB0CD'), 'ABCD');
      expect(JoinCode.normalize('A1B'), 'AB');
    });

    test('pusty i śmieciowy wpis daje pusty wynik', () {
      expect(JoinCode.normalize(''), '');
      expect(JoinCode.normalize('---'), '');
      expect(JoinCode.normalize('0110'), '');
    });
  });

  group('postać do pokazania', () {
    test('nowy kod dzieli się na trzy grupy po cztery', () {
      expect(JoinCode.format('ABCDEFGHJKMN'), 'ABCD-EFGH-JKMN');
    });

    test('stary, 6-znakowy kod też jest czytelny', () {
      expect(JoinCode.format('ABC234'), 'ABC2-34');
    });

    test('grupowanie nie zmienia wartości', () {
      const raw = 'ABCDEFGHJKMN';
      expect(JoinCode.normalize(JoinCode.format(raw)), raw);
    });

    test('wejście już sformatowane nie dubluje separatorów', () {
      expect(JoinCode.format('ABCD-EFGH-JKMN'), 'ABCD-EFGH-JKMN');
    });

    test('pusty kod nie produkuje samego myślnika', () {
      expect(JoinCode.format(''), '');
    });
  });

  group('zgodność wsteczna', () {
    test('obie długości uznajemy za możliwy kod', () {
      // Stare zaproszenia są już wydrukowane — ich kody muszą działać dalej.
      expect(JoinCode.looksValid('ABC234'), isTrue);
      expect(JoinCode.looksValid('ABCDEFGHJKMN'), isTrue);
      expect(JoinCode.looksValid('ABCD-EFGH-JKMN'), isTrue);
    });

    test('długości pośrednie i skrajne odrzucone', () {
      expect(JoinCode.looksValid('ABC'), isFalse);
      expect(JoinCode.looksValid('ABCDEFG'), isFalse);
      expect(JoinCode.looksValid('ABCDEFGHJKMNP'), isFalse);
      expect(JoinCode.looksValid(''), isFalse);
    });

    test('nowa długość to 12, stara 6', () {
      expect(JoinCode.length, 12);
      expect(JoinCode.legacyLength, 6);
    });

    test('kod gościa i kod roli mają JEDNĄ definicję długości', () {
      // Zaproszenie roli nadaje pełny panel, więc nie może być słabsze niż
      // dostęp gościa. Wspólna stała pilnuje, żeby nie rozjechały się przy
      // kolejnej zmianie.
      expect(JoinCode.length, greaterThan(JoinCode.legacyLength));
      expect(JoinCode.looksValid('ABCDEFGHJKMN'), isTrue);
    });
  });

  group('siła kodu', () {
    test('12 znaków daje o rzędy wielkości większą przestrzeń niż 6', () {
      final alphabet = JoinCode.alphabet.length;
      // Liczymy w double — dokładność nie ma tu znaczenia, chodzi o rząd.
      double pow(int base, int exp) {
        var r = 1.0;
        for (var i = 0; i < exp; i++) {
          r *= base;
        }
        return r;
      }

      final stary = pow(alphabet, JoinCode.legacyLength);
      final nowy = pow(alphabet, JoinCode.length);
      expect(nowy / stary, greaterThan(1e8));
      expect(nowy, greaterThan(1e17));
    });
  });
}
