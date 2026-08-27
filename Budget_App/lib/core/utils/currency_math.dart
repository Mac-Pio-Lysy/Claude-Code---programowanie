/// Rounds [value] to 2 decimal places using decimal-string rounding, which
/// avoids the classic binary floating-point drift (e.g. 0.1 + 0.2) that
/// plain multiply-and-round can produce for currency amounts.
///
/// Non-finite input (NaN/Infinity) safely collapses to 0.0 rather than
/// propagating into a summary.
double roundCurrency(double value) {
  if (value.isNaN || !value.isFinite) return 0.0;
  return double.parse(value.toStringAsFixed(2));
}
