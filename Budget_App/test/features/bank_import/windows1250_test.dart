import 'package:budget_app/features/bank_import/domain/services/windows1250.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Windows1250.decode', () {
    test('decodes 0x00-0x7F as plain ASCII', () {
      expect(Windows1250.decode('Hello 123!'.codeUnits), 'Hello 123!');
    });

    test('decodes the Polish diacritics used in bank statement exports', () {
      // Bytes per the Unicode Consortium's CP1250.TXT mapping (cross-checked
      // against Python's stdlib `cp1250` codec): Ą ć ę ł ń ó Ś ź ż.
      final bytes = [0xA5, 0xE6, 0xEA, 0xB3, 0xF1, 0xF3, 0x8C, 0x9F, 0xBF];
      expect(Windows1250.decode(bytes), 'ĄćęłńóŚźż');
    });

    test('round-trips a realistic Polish merchant title', () {
      // "Żabka - płatność kartą", encoded byte-for-byte in cp1250.
      const bytes = [
        175, 97, 98, 107, 97, 32, 45, 32, 112, 179, 97, 116, 110, 111, 156, 230,
        32, 107, 97, 114, 116, 185,
      ];
      expect(Windows1250.decode(bytes), 'Żabka - płatność kartą');
    });
  });
}
