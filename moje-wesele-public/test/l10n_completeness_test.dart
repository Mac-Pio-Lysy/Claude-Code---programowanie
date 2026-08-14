import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Pilnuje spójności plików tłumaczeń.
///
/// Bez tego brakujące tłumaczenie ujawnia się dopiero u użytkownika — jako
/// polski tekst w angielskim interfejsie. Test czyta pliki `.arb` wprost,
/// więc łapie problem przed generowaniem klas.
void main() {
  /// Klucze tłumaczeń (bez metadanych `@...` i nagłówka `@@locale`).
  Set<String> keysOf(String path) {
    final json = jsonDecode(File(path).readAsStringSync()) as Map;
    return json.keys
        .cast<String>()
        .where((k) => !k.startsWith('@'))
        .toSet();
  }

  Map<String, dynamic> rawOf(String path) =>
      (jsonDecode(File(path).readAsStringSync()) as Map).cast<String, dynamic>();

  const plPath = 'lib/l10n/app_pl.arb';

  /// Wszystkie języki poza wzorcowym — nowy plik `.arb` automatycznie
  /// wchodzi do testu, bez dopisywania go tutaj.
  List<String> otherLocales() => Directory('lib/l10n')
      .listSync()
      .whereType<File>()
      .map((f) => f.path.replaceAll(r'\', '/'))
      .where((p) => p.endsWith('.arb') && p != plPath)
      .toList();

  test('polski jest plikiem wzorcowym i nie jest pusty', () {
    final keys = keysOf(plPath);
    expect(keys, isNotEmpty);
    expect(rawOf(plPath)['@@locale'], 'pl');
  });

  test('każdy język ma KOMPLET kluczy z polskiego', () {
    final base = keysOf(plPath);

    for (final path in otherLocales()) {
      final other = keysOf(path);

      final missing = base.difference(other).toList()..sort();
      expect(
        missing,
        isEmpty,
        reason: 'W $path brakuje tłumaczeń: ${missing.join(', ')}',
      );
    }
  });

  test('żaden język nie ma kluczy spoza wzorca', () {
    // Klucz istniejący tylko w tłumaczeniu to zwykle literówka albo
    // pozostałość po zmianie nazwy — nigdzie się nie wyświetli.
    final base = keysOf(plPath);

    for (final path in otherLocales()) {
      final extra = keysOf(path).difference(base).toList()..sort();
      expect(
        extra,
        isEmpty,
        reason: 'W $path są klucze nieznane wzorcowi: ${extra.join(', ')}',
      );
    }
  });

  test('placeholdery zgadzają się między językami', () {
    // Tłumacz, który pominie `{error}`, wyprodukuje komunikat bez treści
    // błędu — a kod i tak przekaże argument.
    final pl = rawOf(plPath);
    // Tylko domknięte `{nazwa}`. Luźne `{` z konstrukcji ICU
    // (`{count, plural, =0{Brak gości}}`) to treść formy, nie podstawienie.
    final placeholderPattern = RegExp(r'\{(\w+)\}');

    Set<String> placeholders(String text) =>
        placeholderPattern.allMatches(text).map((m) => m.group(1)!).toSet();

    for (final path in otherLocales()) {
      final other = rawOf(path);
      for (final key in keysOf(plPath)) {
        final basePh = placeholders(pl[key] as String);
        final otherPh = placeholders(other[key] as String);
        expect(
          otherPh,
          basePh,
          reason: 'Klucz „$key" w $path ma inne podstawienia niż wzorzec',
        );
      }
    }
  });

  test('konwencja nazw: domena_element, bez wielkich liter na starcie', () {
    final wrong = keysOf(plPath)
        .where((k) => !RegExp(r'^[a-z][a-zA-Z0-9]*_[a-zA-Z0-9_]+$').hasMatch(k))
        .toList()
      ..sort();

    expect(wrong, isEmpty,
        reason: 'Klucze niezgodne z konwencją domena_element: '
            '${wrong.join(', ')}');
  });

  test('żadne tłumaczenie nie jest puste', () {
    for (final path in [plPath, ...otherLocales()]) {
      final raw = rawOf(path);
      final empty = keysOf(path)
          .where((k) => (raw[k] as String).trim().isEmpty)
          .toList()
        ..sort();
      expect(empty, isEmpty, reason: 'Puste teksty w $path: ${empty.join(', ')}');
    }
  });
}
