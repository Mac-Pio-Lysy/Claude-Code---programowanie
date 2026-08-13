import 'package:flutter_test/flutter_test.dart';
import 'package:moje_wesele/models/wedding_data.dart';
import 'package:moje_wesele/models/wedding_tier.dart';

/// Testy przygotowania pod monetyzację: flaga `tier` i jedno miejsce decyzji.
///
/// Na tym etapie flaga NICZEGO nie ogranicza — testy pilnują właśnie tego,
/// żeby przypadkowe włączenie premium nie przeszło niezauważone.
void main() {
  WeddingData data([Map<String, dynamic>? raw]) =>
      WeddingData.fromMap(raw ?? const {});

  group('odczyt poziomu konta', () {
    test('brak pola → free (stare wesela działają)', () {
      expect(WeddingTier.fromRaw(null), WeddingTier.free);
      expect(PremiumAccess.tierOf(data()), WeddingTier.free);
    });

    test('zapisane wartości czytają się wprost', () {
      expect(WeddingTier.fromRaw('free'), WeddingTier.free);
      expect(WeddingTier.fromRaw('premium'), WeddingTier.premium);
    });

    test('nieznana wartość → free, bez wyjątku', () {
      // Zachowawczo: dziwne dane nie mogą wywrócić odczytu wesela.
      expect(WeddingTier.fromRaw('zloty-plan'), WeddingTier.free);
      expect(WeddingTier.fromRaw(42), WeddingTier.free);
      expect(WeddingTier.fromRaw(true), WeddingTier.free);
    });

    test('brak danych wesela → free', () {
      expect(PremiumAccess.tierOf(null), WeddingTier.free);
      expect(PremiumAccess.tierOfRaw(null), WeddingTier.free);
    });

    test('odczyt z surowej mapy działa tak samo', () {
      expect(PremiumAccess.tierOfRaw({'tier': 'premium'}), WeddingTier.premium);
      expect(PremiumAccess.tierOfRaw(const {}), WeddingTier.free);
    });
  });

  group('etap przygotowania — nikt nie jest premium', () {
    test('monetyzacja jest wyłączona', () {
      expect(PremiumAccess.monetizationEnabled, isFalse);
    });

    test('wesele bez pola nie jest premium', () {
      expect(PremiumAccess.isPremium(data()), isFalse);
    });

    test('nawet zapisane „premium" nie daje premium', () {
      // Kluczowe zabezpieczenie: dopóki monetyzacja jest wyłączona, ręczna
      // edycja dokumentu nie odblokowuje niczego.
      final withFlag = data({'tier': 'premium'});

      expect(PremiumAccess.tierOf(withFlag), WeddingTier.premium);
      expect(PremiumAccess.isPremium(withFlag), isFalse);
    });

    test('brak danych nie jest premium', () {
      expect(PremiumAccess.isPremium(null), isFalse);
    });
  });

  group('nowe wesele', () {
    test('startuje jako darmowe', () {
      final fields = PremiumAccess.initialFields();

      expect(fields['tier'], 'free');
      expect(PremiumAccess.tierOfRaw(fields), WeddingTier.free);
    });

    test('zapisany klucz zgadza się z odczytem', () {
      // Gdyby klucz kiedyś się rozjechał, nowe wesela czytałyby się jako free
      // mimo zapisu — ten test to wyłapie.
      for (final t in WeddingTier.values) {
        expect(WeddingTier.fromRaw(t.key), t);
      }
    });
  });
}
