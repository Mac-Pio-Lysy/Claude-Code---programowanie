import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../models/bank_profile.dart';
import '../models/bank_transaction.dart';
import 'bank_transaction_categorizer.dart';
import 'windows1250.dart';

const _uuid = Uuid();

/// Thrown when a CSV file can't be parsed under the selected [BankProfile]
/// at all (e.g. its header row is missing or unrecognizable) — as opposed
/// to a single bad row, which is just skipped.
class BankCsvParseException implements Exception {
  const BankCsvParseException(this.message);

  final String message;

  @override
  String toString() => message;
}

enum _DateLayout { dayMonthYearDot, dayMonthYearDash, yearMonthDayDash, yearMonthDayDashTime }

/// Parses a bank statement CSV export into [BankTransaction]s. Each Polish
/// bank formats its export differently (delimiter, column order, date
/// format, character encoding) — real, undocumented quirks that shift
/// between export versions — so this targets one representative, simplified
/// layout per bank (documented alongside its parse method) rather than
/// chasing every historical variant, the same way MockOcrEngine stands in
/// for a real OCR backend.
class BankCsvParserService {
  const BankCsvParserService();

  List<BankTransaction> parse({required List<int> fileBytes, required BankProfile profile}) {
    final text = _decodeBytes(fileBytes, profile);
    final lines = text
        .split(RegExp(r'\r\n|\r|\n'))
        .where((line) => line.trim().isNotEmpty)
        .toList(growable: false);

    if (lines.isEmpty) {
      throw const BankCsvParseException('Plik CSV jest pusty.');
    }

    return switch (profile) {
      BankProfile.pkoBp => _parsePkoBp(lines),
      BankProfile.mBank => _parseMBank(lines),
      BankProfile.santander => _parseSantander(lines),
      BankProfile.ing => _parseIng(lines),
      BankProfile.millennium => _parseMillennium(lines),
      BankProfile.revolut => _parseRevolut(lines),
      BankProfile.universal => _parseUniversal(lines),
    };
  }

  // ---------------------------------------------------------------------
  // Encoding
  // ---------------------------------------------------------------------

  String _decodeBytes(List<int> fileBytes, BankProfile profile) {
    const windows1250Profiles = {BankProfile.pkoBp, BankProfile.mBank, BankProfile.millennium};

    if (windows1250Profiles.contains(profile)) {
      return Windows1250.decode(fileBytes);
    }
    if (profile == BankProfile.universal) {
      try {
        return utf8.decode(fileBytes);
      } on FormatException {
        return Windows1250.decode(fileBytes);
      }
    }
    // Santander, ING, Revolut export as UTF-8.
    return utf8.decode(fileBytes, allowMalformed: true);
  }

  // ---------------------------------------------------------------------
  // PKO BP / Inteligo — ";", Windows-1250
  // Data operacji;Data waluty;Opis operacji;Kontrahent;Kwota;Waluta
  // ---------------------------------------------------------------------

  List<BankTransaction> _parsePkoBp(List<String> lines) {
    return _parseFixedColumns(
      lines.skip(1),
      delimiter: ';',
      dateIndex: 0,
      titleIndex: 2,
      counterpartyIndex: 3,
      amountIndex: 4,
      dateLayout: _DateLayout.dayMonthYearDot,
      minColumns: 5,
    );
  }

  // ---------------------------------------------------------------------
  // mBank — ";", Windows-1250. Real exports lead with several metadata
  // lines before the actual header, and often suffix amounts with " PLN".
  // #Data operacji;#Opis operacji;#Kontrahent;#Kategoria;#Kwota
  // ---------------------------------------------------------------------

  List<BankTransaction> _parseMBank(List<String> lines) {
    final headerIndex = lines.indexWhere((line) => line.startsWith('#Data operacji'));
    if (headerIndex == -1) {
      throw const BankCsvParseException(
        'Nie znaleziono nagłówka "#Data operacji" w pliku mBanku.',
      );
    }

    return _parseFixedColumns(
      lines.skip(headerIndex + 1),
      delimiter: ';',
      dateIndex: 0,
      titleIndex: 1,
      counterpartyIndex: 2,
      categoryIndex: 3,
      amountIndex: 4,
      dateLayout: _DateLayout.yearMonthDayDash,
      minColumns: 5,
    );
  }

  // ---------------------------------------------------------------------
  // Santander Bank Polska — ";", UTF-8
  // Data księgowania;Tytuł;Odbiorca/Nadawca;Kwota;Waluta
  // ---------------------------------------------------------------------

  List<BankTransaction> _parseSantander(List<String> lines) {
    return _parseFixedColumns(
      lines.skip(1),
      delimiter: ';',
      dateIndex: 0,
      titleIndex: 1,
      counterpartyIndex: 2,
      amountIndex: 3,
      dateLayout: _DateLayout.yearMonthDayDash,
      minColumns: 4,
    );
  }

  // ---------------------------------------------------------------------
  // ING Bank Śląski — ";", UTF-8
  // Data transakcji;Dane kontrahenta;Tytuł;Kwota;Waluta
  // ---------------------------------------------------------------------

  List<BankTransaction> _parseIng(List<String> lines) {
    return _parseFixedColumns(
      lines.skip(1),
      delimiter: ';',
      dateIndex: 0,
      titleIndex: 2,
      counterpartyIndex: 1,
      amountIndex: 3,
      dateLayout: _DateLayout.dayMonthYearDash,
      minColumns: 4,
    );
  }

  // ---------------------------------------------------------------------
  // Bank Millennium — ";", Windows-1250
  // Data operacji;Opis operacji;Kontrahent;Kwota
  // ---------------------------------------------------------------------

  List<BankTransaction> _parseMillennium(List<String> lines) {
    return _parseFixedColumns(
      lines.skip(1),
      delimiter: ';',
      dateIndex: 0,
      titleIndex: 1,
      counterpartyIndex: 2,
      amountIndex: 3,
      dateLayout: _DateLayout.dayMonthYearDot,
      minColumns: 4,
    );
  }

  // ---------------------------------------------------------------------
  // Revolut — ",", UTF-8, English headers, ISO dates, dot-decimal amounts.
  // Type,Product,Started Date,Completed Date,Description,Amount,Fee,
  // Currency,State,Balance
  // ---------------------------------------------------------------------

  List<BankTransaction> _parseRevolut(List<String> lines) {
    return _parseFixedColumns(
      lines.skip(1),
      delimiter: ',',
      dateIndex: 2,
      titleIndex: 4,
      counterpartyIndex: 4,
      amountIndex: 5,
      dateLayout: _DateLayout.yearMonthDayDashTime,
      minColumns: 6,
    );
  }

  // ---------------------------------------------------------------------
  // Uniwersalny szablon — auto-detects "," vs ";" and locates the Data/
  // Kwota/Tytuł(/Kontrahent) columns by fuzzy (PL/EN) header matching.
  // ---------------------------------------------------------------------

  List<BankTransaction> _parseUniversal(List<String> lines) {
    final header = lines.first;
    final semicolons = ';'.allMatches(header).length;
    final commas = ','.allMatches(header).length;
    final delimiter = semicolons >= commas ? ';' : ',';

    final columns = _splitCsvLine(header, delimiter).map((c) => c.trim().toLowerCase()).toList();

    int findColumn(List<String> candidates) {
      for (var i = 0; i < columns.length; i++) {
        if (candidates.any(columns[i].contains)) return i;
      }
      return -1;
    }

    final dateIndex = findColumn(['data']);
    final amountIndex = findColumn(['kwota', 'amount']);
    final titleIndex = findColumn(['tytuł', 'tytul', 'opis', 'title', 'description']);
    final counterpartyIndex = findColumn(['kontrahent', 'nadawca', 'odbiorca', 'counterparty']);

    if (dateIndex == -1 || amountIndex == -1 || titleIndex == -1) {
      throw const BankCsvParseException(
        'Nie rozpoznano nagłówków pliku CSV (oczekiwano kolumn Data, Kwota, Tytuł).',
      );
    }

    return _parseFixedColumns(
      lines.skip(1),
      delimiter: delimiter,
      dateIndex: dateIndex,
      titleIndex: titleIndex,
      counterpartyIndex: counterpartyIndex == -1 ? titleIndex : counterpartyIndex,
      amountIndex: amountIndex,
      dateLayout: null, // auto-detected per row.
      minColumns: columns.length,
    );
  }

  // ---------------------------------------------------------------------
  // Shared row parsing
  // ---------------------------------------------------------------------

  /// Parses every row into a [BankTransaction], skipping (rather than
  /// failing the whole file over) any row that's short, blank, or has an
  /// unparsable amount/date — real exports often end with a "Saldo
  /// końcowe"-style summary footer that isn't a transaction at all.
  List<BankTransaction> _parseFixedColumns(
    Iterable<String> rows, {
    required String delimiter,
    required int dateIndex,
    required int titleIndex,
    required int counterpartyIndex,
    required int amountIndex,
    required _DateLayout? dateLayout,
    required int minColumns,
    int? categoryIndex,
  }) {
    final transactions = <BankTransaction>[];

    for (final row in rows) {
      final fields = _splitCsvLine(row, delimiter);
      if (fields.length < minColumns) continue;

      final amount = _tryParseAmount(fields[amountIndex]);
      final date = _tryParseDate(fields[dateIndex], dateLayout);
      if (amount == null || date == null) continue;

      final title = fields[titleIndex].trim();
      final counterparty = fields[counterpartyIndex].trim();
      final rawCategory = categoryIndex != null && categoryIndex < fields.length
          ? fields[categoryIndex].trim()
          : null;

      final (type, category, subCategory) = categorizeBankTransaction(
        title: title,
        counterparty: counterparty,
        amount: amount,
      );

      transactions.add(
        BankTransaction(
          id: _uuid.v4(),
          bookingDate: date,
          counterparty: counterparty.isEmpty ? title : counterparty,
          title: title,
          amount: amount,
          rawCategory: (rawCategory?.isEmpty ?? true) ? null : rawCategory,
          matchedType: type,
          suggestedCategory: category,
          suggestedSubCategory: subCategory,
        ),
      );
    }

    return transactions;
  }

  /// Splits one CSV line on [delimiter], respecting `"…"`-quoted fields
  /// that may themselves contain the delimiter (Revolut quotes its
  /// Description when it contains a comma).
  List<String> _splitCsvLine(String line, String delimiter) {
    final fields = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == delimiter && !inQuotes) {
        fields.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    fields.add(buffer.toString());
    return fields;
  }

  double? _tryParseAmount(String raw) {
    var value = raw.trim();
    value = value.replaceAll('PLN', '').replaceAll('zł', '').trim();
    value = value.replaceAll(' ', '').replaceAll(' ', '');
    if (value.isEmpty) return null;

    if (value.contains(',') && !value.contains('.')) {
      value = value.replaceAll(',', '.');
    } else if (value.contains(',') && value.contains('.')) {
      value = value.replaceAll(',', '');
    }
    return double.tryParse(value);
  }

  DateTime? _tryParseDate(String raw, _DateLayout? layout) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    final resolvedLayout = layout ?? _detectDateLayout(value);
    if (resolvedLayout == null) return null;

    try {
      switch (resolvedLayout) {
        case _DateLayout.dayMonthYearDot:
          final parts = value.split('.');
          return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        case _DateLayout.dayMonthYearDash:
          final parts = value.split('-');
          return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        case _DateLayout.yearMonthDayDash:
          final parts = value.split('-');
          return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        case _DateLayout.yearMonthDayDashTime:
          final datePart = value.split(' ').first;
          final parts = datePart.split('-');
          return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }
    } on FormatException {
      return null;
    }
  }

  /// For the universal template: guesses dd.mm.yyyy / dd-mm-yyyy /
  /// yyyy-mm-dd from which side of the separator holds the 4-digit year.
  _DateLayout? _detectDateLayout(String value) {
    if (value.contains('.')) return _DateLayout.dayMonthYearDot;
    if (value.contains('-')) {
      final parts = value.split('-');
      if (parts.isNotEmpty && parts.first.length == 4) return _DateLayout.yearMonthDayDash;
      return _DateLayout.dayMonthYearDash;
    }
    return null;
  }
}
