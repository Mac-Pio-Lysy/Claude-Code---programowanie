import 'dart:math';

import 'wedding_data.dart';

/// Źródło płatności w zbiorczym widoku „Płatności".
enum PaymentSource { sala, expenses, honeymoon }

extension PaymentSourceX on PaymentSource {
  String get label => switch (this) {
        PaymentSource.sala => 'Sala',
        PaymentSource.expenses => 'Wydatki',
        PaymentSource.honeymoon => 'Podróż poślubna',
      };

  String get icon => switch (this) {
        PaymentSource.sala => '🏠',
        PaymentSource.expenses => '📋',
        PaymentSource.honeymoon => '✈️',
      };
}

/// Pojedyncza płatność w zbiorczym widoku (jak `buildPaymentItems()` w web).
class PaymentItem {
  PaymentItem({
    required this.source,
    required this.name,
    required this.effective,
    required this.paid,
    required this.remaining,
    required this.isPredicted,
    required this.overdue,
    required this.soon,
    required this.dueDate,
  });

  final PaymentSource source;
  final String name;
  final double effective;
  final double paid;
  final double remaining;
  final bool isPredicted;
  final bool overdue;
  final bool soon;
  final String dueDate;

  bool get fullyPaid => paid >= effective && effective > 0;
}

/// Czy termin wypada w ciągu najbliższych 7 dni (jak `isInstallmentDueSoon`).
bool isDueSoon(String dueDate) {
  final d = DateTime.tryParse(dueDate);
  if (d == null) return false;
  final diff = d.difference(DateTime.now()).inDays;
  return diff >= 0 && diff <= 7;
}

/// Czy termin minął, a płatność nieopłacona (jak `isInstallmentOverdue`).
bool isOverdue(String dueDate, String status) {
  if (status == 'paid') return false;
  final d = DateTime.tryParse(dueDate);
  if (d == null) return false;
  return d.isBefore(DateTime.now());
}

/// Buduje zbiorczą listę płatności ze wszystkich źródeł.
List<PaymentItem> buildPaymentItems(WeddingData? data) {
  final raw = data?.raw ?? const {};
  final items = <PaymentItem>[];

  // SALA — payments[]
  final payments = raw['payments'];
  if (payments is List) {
    for (final p in payments.whereType<Map>()) {
      final insts = _instList(p['installments']);
      final paid = _paidSum(insts);
      final confirmed = _d(p['totalAmount']);
      final estimated = _d(p['estimatedAmount']);
      final effective = confirmed > 0 ? confirmed : estimated;
      items.add(PaymentItem(
        source: PaymentSource.sala,
        name: (p['name'] as String?)?.trim().isNotEmpty == true
            ? p['name'] as String
            : 'Płatność',
        effective: effective,
        paid: paid,
        remaining: max(0.0, effective - paid),
        isPredicted: confirmed == 0 && estimated > 0,
        overdue: insts.any((i) => isOverdue(i.$2, i.$3)),
        soon: insts.any((i) => i.$3 != 'paid' && isDueSoon(i.$2)),
        dueDate: _nearestDue(insts),
      ));
    }
  }

  final bd = raw['budgetData'];
  final budget = bd is Map ? bd : const {};

  // WYDATKI — expenses[]
  final expenses = budget['expenses'];
  if (expenses is List) {
    for (final e in expenses.whereType<Map>()) {
      final confirmed = _d(e['planned']);
      final estimated = _d(e['estimatedAmount']);
      final effective = confirmed > 0 ? confirmed : estimated;
      final paid = _d(e['paid']);
      final dd = (e['paymentDate'] as String?) ?? '';
      final cat = (e['category'] as String?) ?? 'Inne';
      final custom = (e['customName'] as String?) ?? '';
      items.add(PaymentItem(
        source: PaymentSource.expenses,
        name: cat == 'Inne' && custom.isNotEmpty ? custom : cat,
        effective: effective,
        paid: paid,
        remaining: max(0.0, effective - paid),
        isPredicted: confirmed == 0 && estimated > 0,
        overdue: dd.isNotEmpty && paid < effective && isOverdue(dd, 'pending'),
        soon: dd.isNotEmpty && paid < effective && isDueSoon(dd),
        dueDate: dd,
      ));
    }
  }

  // PODRÓŻ POŚLUBNA
  final h = budget['honeymoon'];
  if (h is Map) {
    final insts = _instList(h['installments']);
    final confirmed = _d(h['totalAmount']);
    final estimated = _d(h['estimatedAmount']);
    if (confirmed > 0 || estimated > 0 || insts.isNotEmpty) {
      final paid = _paidSum(insts);
      final effective = confirmed > 0 ? confirmed : estimated;
      items.add(PaymentItem(
        source: PaymentSource.honeymoon,
        name: (h['name'] as String?)?.trim().isNotEmpty == true
            ? h['name'] as String
            : 'Podróż poślubna',
        effective: effective,
        paid: paid,
        remaining: max(0.0, effective - paid),
        isPredicted: confirmed == 0 && estimated > 0,
        overdue: insts.any((i) => isOverdue(i.$2, i.$3)),
        soon: insts.any((i) => i.$3 != 'paid' && isDueSoon(i.$2)),
        dueDate: _nearestDue(insts),
      ));
    }
  }

  return items;
}

// Rata reprezentowana jako (amount, dueDate, status).
List<(double, String, String)> _instList(dynamic v) {
  if (v is! List) return const [];
  return v.whereType<Map>().map((i) {
    return (
      _d(i['amount']),
      (i['dueDate'] as String?) ?? '',
      (i['status'] as String?) ?? 'pending',
    );
  }).toList();
}

double _paidSum(List<(double, String, String)> insts) =>
    insts.where((i) => i.$3 == 'paid').fold(0.0, (s, i) => s + i.$1);

/// Najbliższy termin wśród niezapłaconych rat (pusty, gdy brak).
String _nearestDue(List<(double, String, String)> insts) {
  final dates = insts
      .where((i) => i.$3 != 'paid' && i.$2.isNotEmpty)
      .map((i) => i.$2)
      .toList()
    ..sort();
  return dates.isEmpty ? '' : dates.first;
}

double _d(dynamic v) => v is num ? v.toDouble() : 0.0;
