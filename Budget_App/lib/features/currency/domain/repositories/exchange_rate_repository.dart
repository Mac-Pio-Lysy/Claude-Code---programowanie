/// Clean interface a real exchange-rate backend (NBP today, possibly
/// another provider later) drops in behind, exactly like
/// ReceiptScannerService does for OCR.
abstract interface class ExchangeRateRepository {
  /// The mid exchange rate for 1 unit of [currencyCode] expressed in PLN,
  /// as of [date] (or the most recently published rate when omitted).
  /// Always `1.0` for `'PLN'` itself.
  Future<double> getExchangeRate(String currencyCode, {DateTime? date});
}
