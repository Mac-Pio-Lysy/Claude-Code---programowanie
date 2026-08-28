/// A bank/institution whose CSV export format `BankCsvParserService` knows
/// how to parse, plus a catch-all for anything else.
enum BankProfile {
  pkoBp,
  mBank,
  santander,
  ing,
  millennium,
  revolut,

  /// Auto-detects the delimiter (comma/semicolon) and locates the Data/
  /// Kwota/Tytuł columns by fuzzy header matching, for any bank not listed
  /// above.
  universal,
}
