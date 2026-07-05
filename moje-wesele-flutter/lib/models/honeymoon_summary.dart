import 'dart:math';

import 'wedding_data.dart';

/// Rata podróży poślubnej.
class HoneymoonInstallment {
  HoneymoonInstallment(this.raw);
  final Map<String, dynamic> raw;

  int? get id => (raw['id'] as num?)?.toInt();
  double get amount => (raw['amount'] as num?)?.toDouble() ?? 0;
  String get dueDate => (raw['dueDate'] as String?) ?? '';
  String get paidBy => (raw['paidBy'] as String?) ?? 'both';
  String get status => (raw['status'] as String?) ?? 'pending';
  bool get isPaid => status == 'paid';
}

/// Wariant/propozycja podróży poślubnej.
class HoneymoonOption {
  HoneymoonOption(this.raw);
  final Map<String, dynamic> raw;

  int? get id => (raw['id'] as num?)?.toInt();
  String get name => (raw['name'] as String?) ?? '';
  String get link => (raw['link'] as String?) ?? '';
  double get amount => (raw['amount'] as num?)?.toDouble() ?? 0;
}

/// Podsumowanie podróży poślubnej (`budgetData.honeymoon`).
class HoneymoonSummary {
  const HoneymoonSummary({
    required this.name,
    required this.link,
    required this.totalAmount,
    required this.estimatedAmount,
    required this.paid,
    required this.installments,
    required this.options,
    required this.selectedOptionId,
    required this.useHigher,
  });

  final String name;
  final String link;
  final double totalAmount;
  final double estimatedAmount;
  final double paid;
  final List<HoneymoonInstallment> installments;

  /// Warianty podróży. Pusta lista = tryb pojedynczej kwoty (klasyczny).
  final List<HoneymoonOption> options;
  final int? selectedOptionId;
  final bool useHigher;

  bool get hasOptions => options.isNotEmpty;

  double get effective => totalAmount > 0 ? totalAmount : estimatedAmount;
  bool get isPredicted => totalAmount == 0 && estimatedAmount > 0;
  double get remaining => max(0.0, effective - paid);

  /// Wariant, który faktycznie wchodzi do budżetu (najdroższy gdy [useHigher]).
  HoneymoonOption? get budgetedOption {
    if (options.isEmpty) return null;
    if (useHigher) {
      return options.reduce((a, b) => a.amount >= b.amount ? a : b);
    }
    for (final o in options) {
      if (o.id == selectedOptionId) return o;
    }
    return options.first;
  }

  factory HoneymoonSummary.from(WeddingData? data) {
    final raw = data?.raw ?? const {};
    final bd = raw['budgetData'];
    final budget = bd is Map ? bd : const {};
    final h = budget['honeymoon'];
    final hm = h is Map ? Map<String, dynamic>.from(h) : <String, dynamic>{};

    final instRaw = hm['installments'];
    final installments = <HoneymoonInstallment>[];
    double paid = 0;
    if (instRaw is List) {
      for (final e in instRaw) {
        if (e is Map) {
          final inst = HoneymoonInstallment(Map<String, dynamic>.from(e));
          installments.add(inst);
          if (inst.isPaid) paid += inst.amount;
        }
      }
    }

    final optRaw = hm['options'];
    final options = <HoneymoonOption>[];
    if (optRaw is List) {
      for (final e in optRaw) {
        if (e is Map) {
          options.add(HoneymoonOption(Map<String, dynamic>.from(e)));
        }
      }
    }

    return HoneymoonSummary(
      name: (hm['name'] as String?) ?? '',
      link: (hm['link'] as String?) ?? '',
      totalAmount: (hm['totalAmount'] as num?)?.toDouble() ?? 0,
      estimatedAmount: (hm['estimatedAmount'] as num?)?.toDouble() ?? 0,
      paid: paid,
      installments: installments,
      options: options,
      selectedOptionId: (hm['selectedOptionId'] as num?)?.toInt(),
      useHigher: hm['useHigher'] == true,
    );
  }
}
