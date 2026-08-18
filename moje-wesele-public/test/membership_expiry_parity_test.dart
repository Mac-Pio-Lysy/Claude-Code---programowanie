import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moje_wesele/services/membership_service.dart';

/// Stara implementacja `expiresAtTimestamp` (SPRZED refaktoru), przepisana
/// jeden do jednego, żeby empirycznie porównać wynik ze STAREGO i NOWEGO kodu
/// na tych samych wejściach — w tym przypadkach brzegowych (koniec miesiąca,
/// przestępny rok, wejścia nieprawidłowe).
///
/// Porównujemy obiekty [Timestamp] (nie [DateTime]) — `Timestamp.==` liczy
/// się z sekund/nanosekund (patrz cloud_firestore_platform_interface), więc
/// jest odporne na pułapkę `DateTime.==`, które NIE uznaje za równe dwóch
/// DateTime reprezentujących tę samą chwilę, jeśli jeden ma `isUtc: true`
/// a drugi `false` (nawet gdy `microsecondsSinceEpoch` jest identyczne).
Timestamp? oldExpiresAt(String? ymd) {
  if (ymd == null) return null;
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(ymd);
  if (m == null) return null;
  final next = DateTime.utc(
      int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!) + 1);
  return Timestamp.fromDate(next);
}

void main() {
  final cases = <String?>[
    null,
    '',
    'nie-data',
    '2027-06-12',
    '2027-12-31', // przejscie roku
    '2028-02-29', // przestepny luty (2028 jest przestepny)
    '2027-02-28', // nieprzestepny luty
    '2027-01-31', // koniec stycznia
    '2027-06-12T10:00:00Z', // z czescia czasowa
  ];

  test('nowa expiresAtTimestamp() daje identyczny wynik jak stara implementacja', () {
    for (final c in cases) {
      final oldResult = oldExpiresAt(c);
      final newResult = expiresAtTimestamp(c);
      expect(newResult, oldResult, reason: 'rozjazd dla wejscia: ${c ?? "null"}');
      if (oldResult != null) {
        expect(newResult!.seconds, oldResult.seconds);
        expect(newResult.nanoseconds, oldResult.nanoseconds);
      }
    }
  });
}
