import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/repositories/exchange_rate_repository.dart';
import 'fallback_exchange_rates.dart';

/// Fetches the mid exchange rate ("table A") from NBP's free public API.
/// Falls back to [fallbackExchangeRates] on any network error, a non-200
/// response, or an unexpected payload shape — a currency conversion should
/// never crash the app or block adding an expense just because the NBP API
/// is briefly down.
class NbpExchangeRateRepository implements ExchangeRateRepository {
  NbpExchangeRateRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _requestTimeout = Duration(seconds: 5);

  @override
  Future<double> getExchangeRate(String currencyCode, {DateTime? date}) async {
    final code = currencyCode.toUpperCase();
    if (code == 'PLN') return 1.0;

    try {
      final response = await _client.get(_buildUri(code, date)).timeout(_requestTimeout);
      if (response.statusCode != 200) return _fallbackRate(code);

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return _fallbackRate(code);

      final rates = decoded['rates'];
      if (rates is! List || rates.isEmpty) return _fallbackRate(code);

      final firstRate = rates.first;
      if (firstRate is! Map<String, dynamic>) return _fallbackRate(code);

      final mid = firstRate['mid'];
      return mid is num ? mid.toDouble() : _fallbackRate(code);
    } catch (_) {
      return _fallbackRate(code);
    }
  }

  Uri _buildUri(String code, DateTime? date) {
    final datePath = date == null ? '' : '/${_formatDate(date)}';
    return Uri.parse('https://api.nbp.pl/api/exchangerates/rates/a/$code$datePath/?format=json');
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  double _fallbackRate(String code) => fallbackExchangeRates[code] ?? 1.0;
}
