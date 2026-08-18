import 'package:flutter_test/flutter_test.dart';
import 'package:moje_wesele/models/guest_visibility.dart';

/// Etap 8 (indywidualne zaproszenia) — przełącznik „pokazuj imiona autorów"
/// per sekcja. Testujemy wyłącznie nowe pole [SectionVisibility.showAuthorNames]
/// — reszta modelu (daty, `outOfRange`) ma już swoje testy gdzie indziej.
void main() {
  group('SectionVisibility.showAuthorNames', () {
    test('domyślnie włączone — ukrycie imion zabiłoby sens księgi/mapy/rad',
        () {
      const v = SectionVisibility();
      expect(v.showAuthorNames, isTrue);
    });

    test('copyWith zmienia tylko to pole, reszta zostaje', () {
      const v = SectionVisibility(enabled: false, from: '2027-06-01');
      final updated = v.copyWith(showAuthorNames: false);
      expect(updated.showAuthorNames, isFalse);
      expect(updated.enabled, isFalse);
      expect(updated.from, '2027-06-01');
    });

    test('toMap/fromMap zachowuje wartość w obie strony', () {
      const v = SectionVisibility(showAuthorNames: false);
      final restored = SectionVisibility.fromMap(v.toMap());
      expect(restored.showAuthorNames, isFalse);
    });

    test('fromMap bez pola (stare wesela sprzed etapu 8) → domyślnie true', () {
      final v = SectionVisibility.fromMap({'enabled': true});
      expect(v.showAuthorNames, isTrue);
    });

    test('fromMap z niepoprawnym typem pola → domyślnie true', () {
      final v = SectionVisibility.fromMap({'showAuthorNames': 'nope'});
      expect(v.showAuthorNames, isTrue);
    });
  });
}
