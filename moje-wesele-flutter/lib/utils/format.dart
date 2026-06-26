/// Formatuje kwotę w stylu pl-PL (jak `fmt()` w wersji web):
/// spacja jako separator tysięcy, przecinek dziesiętny, zawsze 2 miejsca.
/// Przykład: 1234.5 → "1 234,50".
String formatPln(num value) {
  final v = value.toDouble();
  final negative = v < 0;
  final abs = v.abs();
  var whole = abs.floor();
  var cents = ((abs - whole) * 100).round();
  if (cents == 100) {
    whole += 1;
    cents = 0;
  }
  final wholeStr = _groupThousands(whole);
  final centsStr = cents.toString().padLeft(2, '0');
  return '${negative ? '-' : ''}$wholeStr,$centsStr';
}

/// Kwota z dopiskiem „zł".
String formatPlnZl(num value) => '${formatPln(value)} zł';

String _groupThousands(int value) {
  final digits = value.toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(' ');
    buf.write(digits[i]);
  }
  return buf.toString();
}

/// Parsuje kwotę wpisaną przez użytkownika (akceptuje spacje i przecinek).
/// Zwraca `null`, gdy nie da się sparsować.
num? parsePln(String input) {
  final cleaned = input
      .replaceAll(' ', '')
      .replaceAll(' ', '')
      .replaceAll('zł', '')
      .replaceAll(',', '.')
      .trim();
  if (cleaned.isEmpty) return 0;
  return num.tryParse(cleaned);
}
