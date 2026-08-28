/// Safe, offline fallback mid rates (PLN per 1 unit of the foreign
/// currency) — used whenever the NBP API is unreachable, and in tests that
/// don't want to depend on network access. Approximate, illustrative
/// values; not a substitute for a live rate on anything that matters.
const fallbackExchangeRates = <String, double>{
  'EUR': 4.30,
  'USD': 4.00,
  'GBP': 5.05,
  'CHF': 4.55,
};
