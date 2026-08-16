import 'dart:math';

import 'sala_summary.dart';
import 'wedding_data.dart';
import '../l10n/app_text.dart';
import 'expense.dart';

/// Źródło płatności w zbiorczym widoku „Płatności".
enum PaymentSource { sala, expenses, honeymoon, vendor }

extension PaymentSourceX on PaymentSource {
  String get label => switch (this) {
        PaymentSource.sala => AppText.t.pay_sala,
        PaymentSource.expenses => AppText.t.pay_expenses,
        PaymentSource.honeymoon => AppText.t.pay_honeymoon,
        PaymentSource.vendor => AppText.t.pay_vendor,
      };

  String get icon => switch (this) {
        PaymentSource.sala => '🏠',
        PaymentSource.expenses => '📋',
        PaymentSource.honeymoon => '✈️',
        PaymentSource.vendor => '🏢',
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
            : AppText.t.pay_generic,
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

  // KOSZT SALI — obliczony na podstawie gości/obsługi (SalaSummary.cateringTotal,
  // ten sam model co podzakładka „Sala" i karta „w tym sala" w Podsumowaniu).
  // To osobny mechanizm od ręcznie wpisywanych rat w `payments[]` powyżej —
  // dodajemy go, żeby filtr „Sala" pokazywał rzeczywisty koszt sali, nawet
  // gdy nikt nie założył ręcznego harmonogramu rat.
  final salaCost = SalaSummary.from(data).cateringTotal;
  if (salaCost > 0) {
    items.add(PaymentItem(
      source: PaymentSource.sala,
      name: AppText.t.pay_salaComputed,
      effective: salaCost,
      paid: 0,
      remaining: salaCost,
      isPredicted: true,
      overdue: false,
      soon: false,
      dueDate: '',
    ));
  }

  final bd = raw['budgetData'];
  final budget = bd is Map ? bd : const {};

  // WYDATKI — expenses[] (pomijamy wydatki pochodzące z Dostawców — ich raty
  // pokazujemy w wierszu dostawcy, by uniknąć podwójnego liczenia).
  final expenses = budget['expenses'];
  if (expenses is List) {
    for (final e in expenses.whereType<Map>()) {
      if (_expenseOrigin(e) == 'vendors') continue;
      final confirmed = _d(e['planned']);
      final estimated = _d(e['estimatedAmount']);
      final effective = confirmed > 0 ? confirmed : estimated;
      final paid = _d(e['paid']);
      final dd = (e['paymentDate'] as String?) ?? '';
      final cat = (e['category'] as String?) ?? 'Inne';
      final custom = (e['customName'] as String?) ?? '';
      items.add(PaymentItem(
        source: PaymentSource.expenses,
        name: cat == 'Inne' && custom.isNotEmpty
            ? custom
            : ExpenseCategories.labelFor(cat),
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
            : AppText.t.pay_honeymoon,
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

  // DOSTAWCY — raty/płatności do konkretnego dostawcy.
  // Pomijamy dostawców będących tylko „widokiem" wydatku (pochodzenie
  // 'expenses') — ich płatność reprezentuje wpis w Wydatkach.
  final vendors = raw['vendors'];
  final expList = expenses is List ? expenses : const [];
  if (vendors is List) {
    for (final v in vendors.whereType<Map>()) {
      final linked = v['isBudgetLinked'] == true;
      if (linked) {
        final expId = (v['budgetExpenseId'] as num?)?.toInt();
        Map? exp;
        for (final e in expList.whereType<Map>()) {
          if ((e['id'] as num?)?.toInt() == expId) {
            exp = e;
            break;
          }
        }
        if (exp != null && _expenseOrigin(exp) == 'expenses') continue;
      }
      final insts = _instList(v['installments']);
      final effective = linked ? _d(v['contractAmount']) : _d(v['price']);
      if (effective <= 0 && insts.isEmpty) continue;
      final paid = _paidSum(insts);
      items.add(PaymentItem(
        source: PaymentSource.vendor,
        name: AppText.t.pay_vendorInstalment(_vendorLabel(v)),
        effective: effective,
        paid: paid,
        remaining: max(0.0, effective - paid),
        isPredicted: false,
        overdue: insts.any((i) => isOverdue(i.$2, i.$3)),
        soon: insts.any((i) => i.$3 != 'paid' && isDueSoon(i.$2)),
        dueDate: _nearestDue(insts),
      ));
    }
  }

  return items;
}

/// Sekcja źródłowa wydatku ('expenses' | 'vendors').
String _expenseOrigin(Map e) {
  final o = (e['origin'] as String?)?.trim();
  if (o != null && o.isNotEmpty) return o;
  return e['vendorId'] != null ? 'vendors' : 'expenses';
}

/// Etykieta dostawcy (firma / kontakt / kategoria).
String _vendorLabel(Map v) {
  final company = (v['companyName'] as String?)?.trim() ?? '';
  if (company.isNotEmpty) return company;
  final contact = (v['contactName'] as String?)?.trim() ?? '';
  if (contact.isNotEmpty) return contact;
  final cat = (v['category'] as String?) ?? '';
  if (cat == 'Inne') {
    final custom = (v['customCategory'] as String?)?.trim() ?? '';
    if (custom.isNotEmpty) return custom;
  } else if (cat.isNotEmpty) {
    return cat;
  }
  return AppText.t.pay_vendor;
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
