import 'package:flutter/material.dart';

/// Status płatności dostawcy (VENDOR_STATUSES w zrodlo-web/script.js).
class VendorStatus {
  const VendorStatus(this.value, this.label, this.color);
  final String value;
  final String label;
  final Color color;

  static const all = [
    VendorStatus('contacted', 'Skontaktowano', Color(0xFF3B82F6)),
    VendorStatus('confirmed', 'Potwierdzony', Color(0xFF10B981)),
    VendorStatus('paid', 'Opłacony', Color(0xFF6D28D9)),
    VendorStatus('cancelled', 'Anulowany', Color(0xFFEF4444)),
  ];

  static VendorStatus byValue(String? v) =>
      all.firstWhere((s) => s.value == v, orElse: () => all.first);
}

/// Kategorie dostawców (VENDOR_CATS).
const List<String> kVendorCategories = [
  'Fotograf',
  'Kamerzysta',
  'Muzyka',
  'Kwiaty',
  'Tort',
  'Catering',
  'Transport',
  'Inne',
];

/// Kategorie budżetowe dla powiązania dostawcy (bcats w wersji web).
const List<String> kVendorBudgetCategories = [
  'Sala',
  'Strój',
  'Dokumenty',
  'Dekoracje',
  'Inne',
];

/// Rata płatności dostawcy `{id, label, amount, dueDate, status}`.
class VendorInstallment {
  VendorInstallment(this.raw);
  final Map<String, dynamic> raw;

  int? get id => (raw['id'] as num?)?.toInt();
  String get label => (raw['label'] as String?) ?? '';
  double get amount => (raw['amount'] as num?)?.toDouble() ?? 0;
  String get dueDate => (raw['dueDate'] as String?) ?? '';
  String get status => (raw['status'] as String?) ?? 'due';
  bool get isPaid => status == 'paid';
}

/// Sumy rat dostawcy.
class VendorInstallmentSums {
  const VendorInstallmentSums(this.total, this.paid, this.remaining);
  final double total;
  final double paid;
  final double remaining;
}

/// Dostawca — nakładka na surową mapę (zachowuje wszystkie pola z wersji web).
class Vendor {
  Vendor(this.raw);
  final Map<String, dynamic> raw;

  int? get id => (raw['id'] as num?)?.toInt();
  String get category => (raw['category'] as String?) ?? 'Inne';
  String get customCategory => (raw['customCategory'] as String?) ?? '';
  String get companyName => (raw['companyName'] as String?) ?? '';
  String get contactName => (raw['contactName'] as String?) ?? '';
  String get phone => (raw['phone'] as String?) ?? '';
  String get email => (raw['email'] as String?) ?? '';
  double get price => (raw['price'] as num?)?.toDouble() ?? 0;
  String get paymentStatus => (raw['paymentStatus'] as String?) ?? 'contacted';
  String get notes => (raw['notes'] as String?) ?? '';
  String get mapUrl => (raw['mapUrl'] as String?) ?? '';

  bool get isBudgetLinked => raw['isBudgetLinked'] == true;
  double get contractAmount => (raw['contractAmount'] as num?)?.toDouble() ?? 0;
  String get budgetCategory => (raw['budgetCategory'] as String?) ?? '';
  int? get budgetExpenseId => (raw['budgetExpenseId'] as num?)?.toInt();

  List<VendorInstallment> get installments {
    final v = raw['installments'];
    if (v is! List) return const [];
    return v
        .whereType<Map>()
        .map((e) => VendorInstallment(Map<String, dynamic>.from(e)))
        .toList();
  }

  VendorStatus get status => VendorStatus.byValue(paymentStatus);

  /// Wyświetlana kategoria (własna dla „Inne").
  String get displayCategory =>
      category == 'Inne' && customCategory.isNotEmpty ? customCategory : category;

  /// Etykieta (vendorLabel w wersji web).
  String get label {
    if (companyName.isNotEmpty) return companyName;
    if (contactName.isNotEmpty) return contactName;
    if (displayCategory.isNotEmpty) return displayCategory;
    return 'Dostawca';
  }

  VendorInstallmentSums get installmentSums {
    var total = 0.0, paid = 0.0;
    for (final i in installments) {
      total += i.amount;
      if (i.isPaid) paid += i.amount;
    }
    return VendorInstallmentSums(total, paid, total - paid < 0 ? 0 : total - paid);
  }
}
