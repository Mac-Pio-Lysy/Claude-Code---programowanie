import 'package:budget_app/features/currency/data/repositories/fallback_exchange_rates.dart';
import 'package:budget_app/features/currency/data/repositories/nbp_exchange_rate_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('NbpExchangeRateRepository — PLN', () {
    test('always returns 1.0 for PLN without making a network call', () async {
      final repository = NbpExchangeRateRepository(
        client: MockClient((request) async => throw StateError('should not be called')),
      );

      expect(await repository.getExchangeRate('PLN'), 1.0);
      expect(await repository.getExchangeRate('pln'), 1.0); // case-insensitive
    });
  });

  group('NbpExchangeRateRepository — successful response', () {
    test('parses the mid rate from a table-A style JSON payload', () async {
      final repository = NbpExchangeRateRepository(
        client: MockClient((request) async {
          expect(request.url.toString(), 'https://api.nbp.pl/api/exchangerates/rates/a/EUR/?format=json');
          return http.Response(
            '{"table":"A","currency":"euro","code":"EUR","rates":[{"no":"001/A/NBP/2026","effectiveDate":"2026-01-02","mid":4.32}]}',
            200,
          );
        }),
      );

      expect(await repository.getExchangeRate('EUR'), 4.32);
    });

    test('builds a date-specific URL when a date is provided', () async {
      final repository = NbpExchangeRateRepository(
        client: MockClient((request) async {
          expect(
            request.url.toString(),
            'https://api.nbp.pl/api/exchangerates/rates/a/USD/2026-01-15/?format=json',
          );
          return http.Response(
            '{"rates":[{"mid":4.05}]}',
            200,
          );
        }),
      );

      expect(await repository.getExchangeRate('USD', date: DateTime(2026, 1, 15)), 4.05);
    });
  });

  group('NbpExchangeRateRepository — fallback on failure', () {
    test('falls back on a non-200 response', () async {
      final repository = NbpExchangeRateRepository(
        client: MockClient((request) async => http.Response('Not Found', 404),
        ),
      );

      expect(await repository.getExchangeRate('GBP'), fallbackExchangeRates['GBP']);
    });

    test('falls back when the request throws (offline)', () async {
      final repository = NbpExchangeRateRepository(
        client: MockClient((request) async => throw Exception('SocketException')),
      );

      expect(await repository.getExchangeRate('CHF'), fallbackExchangeRates['CHF']);
    });

    test('falls back on an unexpected payload shape', () async {
      final repository = NbpExchangeRateRepository(
        client: MockClient((request) async => http.Response('{"rates": []}', 200)),
      );

      expect(await repository.getExchangeRate('USD'), fallbackExchangeRates['USD']);
    });

    test('falls back on malformed JSON', () async {
      final repository = NbpExchangeRateRepository(
        client: MockClient((request) async => http.Response('not json at all', 200)),
      );

      expect(await repository.getExchangeRate('EUR'), fallbackExchangeRates['EUR']);
    });

    test('an unknown currency with no fallback entry defaults to 1.0', () async {
      final repository = NbpExchangeRateRepository(
        client: MockClient((request) async => http.Response('Not Found', 404)),
      );

      expect(await repository.getExchangeRate('JPY'), 1.0);
    });
  });
}
