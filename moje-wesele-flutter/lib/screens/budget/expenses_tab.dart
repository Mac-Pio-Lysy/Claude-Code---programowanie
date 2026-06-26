import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/expense.dart';
import '../../models/wedding_data.dart';
import '../../services/budget_service.dart';
import '../../utils/format.dart';
import 'expense_form_sheet.dart';

enum _Status { all, paid, partial, unpaid }

enum _Person { all, p1, p2, both }

/// Podzakładka „Wydatki" (Moje wydatki) — podsumowanie, filtry, sortowanie,
/// lista wydatków z dodawaniem/edycją/usuwaniem.
class ExpensesTab extends StatefulWidget {
  const ExpensesTab({super.key, required this.data, required this.service});

  final WeddingData? data;
  final BudgetService service;

  @override
  State<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<ExpensesTab> {
  _Status _status = _Status.all;
  _Person _person = _Person.all;
  String _categoryFilter = 'all';
  String? _sortField; // null = ręcznie (kolejność expenseOrder)
  bool _sortAsc = true;

  Map<String, dynamic> get _bd {
    final v = widget.data?.raw['budgetData'];
    return v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
  }

  List<String> get _coupleNames {
    final v = _bd['coupleNames'];
    if (v is List && v.length >= 2) {
      return [v[0]?.toString() ?? 'Osoba 1', v[1]?.toString() ?? 'Osoba 2'];
    }
    return ['Osoba 1', 'Osoba 2'];
  }

  List<String> get _categories => ExpenseCategories.resolve(widget.data?.raw ?? {});

  List<Expense> get _allExpenses {
    final v = _bd['expenses'];
    if (v is! List) return [];
    return v
        .whereType<Map>()
        .map((e) => Expense(Map<String, dynamic>.from(e)))
        .toList();
  }

  List<int> get _order {
    final v = widget.data?.raw['expenseOrder'];
    return v is List
        ? v.map((e) => (e as num?)?.toInt()).whereType<int>().toList()
        : <int>[];
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addExpense() async {
    final draft = await showModalBottomSheet<ExpenseDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExpenseFormSheet(
        categories: _categories,
        coupleNames: _coupleNames,
      ),
    );
    if (draft == null) return;
    try {
      await widget.service.addExpense(draft);
      _toast('Dodano wydatek');
    } catch (e) {
      _toast('Błąd zapisu: $e');
    }
  }

  Future<void> _editExpense(Expense expense) async {
    final draft = await showModalBottomSheet<ExpenseDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExpenseFormSheet(
        existing: expense,
        categories: _categories,
        coupleNames: _coupleNames,
      ),
    );
    if (draft == null || expense.id == null) return;
    try {
      await widget.service.updateExpense(expense.id!, draft);
      _toast('Zapisano zmiany');
    } catch (e) {
      _toast('Błąd zapisu: $e');
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunąć wydatek?'),
        content: Text('Czy na pewno usunąć „${expense.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC0392B)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (ok != true || expense.id == null) return;
    try {
      await widget.service.deleteExpense(expense.id!);
      _toast('Usunięto wydatek');
    } catch (e) {
      _toast('Błąd usuwania: $e');
    }
  }

  List<Expense> _ordered(List<Expense> expenses) {
    final byId = {for (final e in expenses) e.id: e};
    final result = <Expense>[];
    for (final id in _order) {
      final e = byId.remove(id);
      if (e != null) result.add(e);
    }
    result.addAll(expenses.where((e) => byId.containsKey(e.id)));
    return result;
  }

  bool _matches(Expense e) {
    switch (_status) {
      case _Status.paid:
        if (!e.filterPaid) return false;
      case _Status.partial:
        if (!e.filterPartial) return false;
      case _Status.unpaid:
        if (e.filterPaid || e.filterPartial) return false;
      case _Status.all:
        break;
    }
    switch (_person) {
      case _Person.p1:
        if (e.splitP1 <= 0) return false;
      case _Person.p2:
        if (e.splitP2 <= 0) return false;
      case _Person.both:
        if (e.splitP1 <= 0 || e.splitP2 <= 0) return false;
      case _Person.all:
        break;
    }
    if (_categoryFilter != 'all' && e.category != _categoryFilter) return false;
    return true;
  }

  void _sorted(List<Expense> list) {
    if (_sortField == null) return;
    final dir = _sortAsc ? 1 : -1;
    list.sort((a, b) {
      final cmp = switch (_sortField) {
        'planned' => a.planned.compareTo(b.planned),
        'paid' => a.paid.compareTo(b.paid),
        'remaining' => a.remaining.compareTo(b.remaining),
        'paymentDate' => (a.paymentDate.isEmpty ? '9999' : a.paymentDate)
            .compareTo(b.paymentDate.isEmpty ? '9999' : b.paymentDate),
        'category' => a.category.compareTo(b.category),
        _ => 0,
      };
      return cmp * dir;
    });
  }

  void _setSort(String? field) {
    setState(() {
      if (_sortField == field) {
        _sortAsc = !_sortAsc;
      } else {
        _sortField = field;
        _sortAsc = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final all = _allExpenses;
    final ordered = _ordered(all);
    final filtered = ordered.where(_matches).toList();
    _sorted(filtered);

    final names = _coupleNames;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              _summaryCard(),
              const SizedBox(height: 14),
              _filters(names),
              const SizedBox(height: 12),
              if (all.isEmpty)
                _empty('Brak wydatków. Dodaj pierwszy przyciskiem poniżej.')
              else if (filtered.isEmpty)
                _empty('Brak wydatków spełniających kryteria filtrów.')
              else
                for (final e in filtered)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ExpenseCard(
                      key: ValueKey(e.id),
                      expense: e,
                      coupleNames: names,
                      onEdit: () => _editExpense(e),
                      onDelete: () => _deleteExpense(e),
                    ),
                  ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addExpense,
                icon: const Icon(Icons.add),
                label: const Text('Dodaj wydatek'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard() {
    final expenses = _allExpenses;
    double sum(double Function(Expense) f) =>
        expenses.fold(0.0, (s, e) => s + f(e));
    final alcohol = _bevTotal('alcoholItems');
    final soft = _bevTotal('softItems');
    final planned = sum((e) => e.planned) + alcohol + soft;
    final estimated = sum((e) => e.estimatedAmount);
    final paid = sum((e) => e.paid);
    final remaining = max(0.0, planned - paid);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EAF7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _summaryItem('Zaplanowano', planned, const Color(0xFF1D4ED8)),
          _summaryItem('Przewidywane', estimated, const Color(0xFFB45309)),
          _summaryItem('Opłacono', paid, const Color(0xFF059669)),
          _summaryItem('Pozostało', remaining, const Color(0xFFEA580C)),
        ],
      ),
    );
  }

  double _bevTotal(String key) {
    final v = _bd[key];
    if (v is! List) return 0;
    return v.whereType<Map>().fold(0.0, (s, i) {
      final bottles = (i['bottles'] as num?)?.toDouble() ?? 0;
      final price = (i['pricePerBottle'] as num?)?.toDouble() ?? 0;
      return s + bottles * price;
    });
  }

  Widget _summaryItem(String label, double value, Color color) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(formatPlnZl(value),
              style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _filters(List<String> names) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _filterLabel('Status'),
        _chipRow([
          _chip('Wszystkie', _status == _Status.all,
              () => setState(() => _status = _Status.all)),
          _chip('✓ Opłacone', _status == _Status.paid,
              () => setState(() => _status = _Status.paid)),
          _chip('⚡ Częściowo', _status == _Status.partial,
              () => setState(() => _status = _Status.partial)),
          _chip('✗ Nieopłacone', _status == _Status.unpaid,
              () => setState(() => _status = _Status.unpaid)),
        ]),
        const SizedBox(height: 8),
        _filterLabel('Osoba'),
        _chipRow([
          _chip('Wszyscy', _person == _Person.all,
              () => setState(() => _person = _Person.all)),
          _chip(names[0], _person == _Person.p1,
              () => setState(() => _person = _Person.p1)),
          _chip(names[1], _person == _Person.p2,
              () => setState(() => _person = _Person.p2)),
          _chip('Oboje', _person == _Person.both,
              () => setState(() => _person = _Person.both)),
        ]),
        const SizedBox(height: 8),
        _filterLabel('Kategoria'),
        SizedBox(
          width: double.infinity,
          child: DropdownButtonFormField<String>(
            initialValue: _categoryFilter,
            isExpanded: true,
            decoration: _filterDropdownDecoration(),
            items: [
              const DropdownMenuItem(
                  value: 'all', child: Text('Wszystkie kategorie')),
              for (final c in _categories)
                DropdownMenuItem(
                    value: c, child: Text('${ExpenseCategories.iconFor(c)} $c')),
            ],
            onChanged: (v) => setState(() => _categoryFilter = v ?? 'all'),
          ),
        ),
        const SizedBox(height: 8),
        _filterLabel('Sortuj'),
        _chipRow([
          _sortChip('Ręcznie', null),
          _sortChip('Planowane', 'planned'),
          _sortChip('Opłacone', 'paid'),
          _sortChip('Pozostało', 'remaining'),
          _sortChip('Data', 'paymentDate'),
          _sortChip('Kategoria', 'category'),
        ]),
      ],
    );
  }

  Widget _filterLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textLight)),
      );

  Widget _chipRow(List<Widget> chips) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final c in chips) Padding(padding: const EdgeInsets.only(right: 8), child: c),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: selected ? Colors.white : AppColors.textLight,
      ),
      selectedColor: AppColors.accent,
      backgroundColor: Colors.white,
      side: BorderSide(
          color: selected ? AppColors.accent : const Color(0xFFDCE4F2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _sortChip(String label, String? field) {
    final selected = _sortField == field;
    final arrow = selected && field != null ? (_sortAsc ? ' ↑' : ' ↓') : '';
    return _chip('$label$arrow', selected, () => _setSort(field));
  }

  InputDecoration _filterDropdownDecoration() => InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDCE4F2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDCE4F2)),
        ),
      );

  Widget _empty(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Text(text,
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.inter(fontSize: 14, color: AppColors.textLight)),
        ),
      );
}

/// Rozwijana karta wydatku.
class _ExpenseCard extends StatefulWidget {
  const _ExpenseCard({
    super.key,
    required this.expense,
    required this.coupleNames,
    required this.onEdit,
    required this.onDelete,
  });

  final Expense expense;
  final List<String> coupleNames;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_ExpenseCard> createState() => _ExpenseCardState();
}

class _ExpenseCardState extends State<_ExpenseCard> {
  bool _expanded = false;

  ({Color bg, Color fg, String text}) get _badge => switch (widget.expense.status) {
        ExpenseStatus.paid =>
          (bg: const Color(0xFFECFDF5), fg: const Color(0xFF059669), text: '✓ Opłacone'),
        ExpenseStatus.partial =>
          (bg: const Color(0xFFFEF3C7), fg: const Color(0xFFB45309), text: '⚡ Częściowo'),
        ExpenseStatus.unpaid =>
          (bg: const Color(0xFFFEE2E2), fg: const Color(0xFFC0392B), text: '✗ Nieopłacone'),
      };

  @override
  Widget build(BuildContext context) {
    final e = widget.expense;
    final badge = _badge;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Text(e.icon, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.displayName,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: badge.bg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                badge.text,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: badge.fg,
                                ),
                              ),
                            ),
                            if (e.isPredicted) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('~ przewidywany',
                                    style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: AppColors.textLight)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatPlnZl(e.effective),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        'opł. ${formatPlnZl(e.paid)}',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.textLight),
                      ),
                    ],
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.keyboard_arrow_down,
                        color: AppColors.textLight),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) _details(e),
        ],
      ),
    );
  }

  Widget _details(Expense e) {
    final n1 = widget.coupleNames[0];
    final n2 = widget.coupleNames[1];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 16),
          _row('Kwota ostateczna', formatPlnZl(e.planned)),
          if (e.estimatedAmount > 0)
            _row('Kwota przewidywana', formatPlnZl(e.estimatedAmount)),
          _row('Opłacono', formatPlnZl(e.paid)),
          _row('Pozostało', formatPlnZl(e.remaining)),
          if (e.paymentDate.isNotEmpty) _row('Data płatności', e.paymentDate),
          if (e.splitP1 > 0 || e.splitP2 > 0)
            _row('Podział',
                '$n1: ${formatPlnZl(e.splitP1)} · $n2: ${formatPlnZl(e.splitP2)}'),
          if (e.note.isNotEmpty) _row('Notatka', e.note),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edytuj'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Usuń'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC0392B),
                    side: const BorderSide(color: Color(0xFFE9A8A8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textLight)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text)),
          ),
        ],
      ),
    );
  }
}
