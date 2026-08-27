import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

/// Formats amounts as Polish złoty (e.g. "1 234,50 zł").
abstract final class CurrencyFormatter {
  static final NumberFormat _format = NumberFormat.simpleCurrency(
    locale: AppConstants.defaultLocale,
    name: AppConstants.defaultCurrencyCode,
  );

  static String format(num amount) => _format.format(amount);
}
