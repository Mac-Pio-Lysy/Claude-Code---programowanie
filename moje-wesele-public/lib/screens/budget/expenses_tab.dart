import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../layout/responsive.dart';
import '../../models/expense.dart';
import '../../models/gift.dart';
import '../../models/guest_basis.dart';
import '../../models/wedding_data.dart';
import '../../navigation/app_sections.dart';
import '../../services/budget_service.dart';
import '../../utils/format.dart';
import '../../widgets/added_in_chip.dart';
import '../../widgets/filter_toggle_button.dart';
import 'expense_form_sheet.dart';
import '../../l10n/app_text.dart';

enum _Status { all, paid, partial, unpaid }

enum _Person { all, p1, p2, both }

/// Podzakładka „Wydatki" (Moje wydatki) — podsumowanie, filtry, sortowanie,
/// lista wydatków z dodawaniem/edycją/usuwaniem.
class ExpensesTab extends StatefulWidget {
  const ExpensesTab({
    super.key,
    required this.data,
    required this.service,
    this.onOpenSection,
    this.honeymoonTabIndex = 5,
  });

  final WeddingData? data;
  final BudgetService service;

  /// Przejście do innej sekcji aplikacji (np. Dostawcy) — dla linków „Dodano w".
  final void Function(AppSection section)? onOpenSection;

  /// Indeks podzakładki „Podróż poślubna" w budżecie (dla wiersza referencyjnego).
  final int honeymoonTabIndex;

  @override
  State<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<ExpensesTab> {
  _Status _status = _Status.all;
  _Person _person = _Person.all;
  String _categoryFilter = 'all';
  String? _sortField; // null = ręcznie (kolejność expenseOrder)
  bool _sortAsc = true;
  bool _quickVisible = true;
  bool _filtersVisible = false;

  Map<String, dynamic> get _bd {
    final v = widget.data?.raw['budgetData'];
    return v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
  }

  List<String> get _coupleNames {
    final v = _bd['coupleNames'];
    if (v is List && v.length >= 2) {
      return [v[0]?.toString() ?? AppText.t.couple_personNumbered(1), v[1]?.toString() ?? AppText.t.couple_personNumbered(2)];
    }
    return [AppText.t.couple_personNumbered(1), AppText.t.couple_personNumbered(2)];
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
      constraints: const BoxConstraints(maxWidth: kSheetMaxWidth),
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
      _toast(AppText.t.budget_expenseAddedShort);
    } catch (e) {
      _toast(AppText.t.common_saveErrorToast('$e'));
    }
  }

  Map<String, dynamic>? _vendorById(int? id) {
    if (id == null) return null;
    final v = widget.data?.raw['vendors'];
    if (v is! List) return null;
    for (final e in v.whereType<Map>()) {
      if ((e['id'] as num?)?.toInt() == id) {
        return Map<String, dynamic>.from(e);
      }
    }
    return null;
  }

  Future<void> _editExpense(Expense expense) async {
    final draft = await showModalBottomSheet<ExpenseDraft>(
      context: context,
      constraints: const BoxConstraints(maxWidth: kSheetMaxWidth),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExpenseFormSheet(
        existing: expense,
        categories: _categories,
        coupleNames: _coupleNames,
        linkedVendor: _vendorById(expense.vendorId),
      ),
    );
    if (draft == null || expense.id == null) return;
    try {
      await widget.service.updateExpense(expense.id!, draft);
      _toast(AppText.t.common_savedToast);
    } catch (e) {
      _toast(AppText.t.common_saveErrorToast('$e'));
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppText.t.budget_expenseDeleteTitle),
        content: Text(AppText.t.budget_expenseDeleteBody(expense.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppText.t.common_cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC0392B)),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppText.t.common_delete),
          ),
        ],
      ),
    );
    if (ok != true || expense.id == null) return;
    try {
      await widget.service.deleteExpense(expense.id!);
      _toast(AppText.t.budget_expenseDeletedToast);
    } catch (e) {
      _toast(AppText.t.common_deleteErrorToast('$e'));
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
              _quickAddSection(),
              const SizedBox(height: 14),
              _filtersBar(names),
              const SizedBox(height: 12),
              _honeymoonRow(),
              ..._giftRows(),
              if (all.isEmpty)
                _empty(AppText.t.budget_expensesEmpty)
              else if (filtered.isEmpty)
                _empty(AppText.t.budget_expensesEmptyFiltered)
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
                      onOpenSource: e.fromVendors
                          ? () => widget.onOpenSection?.call(AppSection.vendors)
                          : e.fromTasks
                              ? () => widget.onOpenSection?.call(AppSection.tasks)
                              : null,
                      sourceLabel: e.fromVendors
                          ? 'Dostawcy'
                          : e.fromTasks
                              ? 'Zadania'
                              : null,
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
                label: Text(AppText.t.budget_addExpense),
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

  Future<void> _addQuick(String name) async {
    try {
      await widget.service.addExpenseForCategory(name);
      _toast(AppText.t.budget_expenseAddedToast(name));
    } catch (e) {
      _toast(AppText.t.common_saveErrorToast('$e'));
    }
  }

  /// Sekcja „⚡ Szybkie pozycje" — gotowe wydatki z konfigurowalnych kategorii
  /// (spójne z listą kategorii). Chowana przyciskiem.
  /// Czy kategoria dotyczy sali/cateringu — takie pozycje NIE pojawiają się
  /// w szybkich pozycjach (mają własną, dedykowaną sekcję „Sala").
  static bool _isSalaOrCatering(String c) {
    final l = c.toLowerCase();
    return l.contains('sala') || l.contains('catering');
  }

  Widget _quickAddSection() {
    // „Sala" i „Catering" usunięte z szybkich pozycji — konfiguruje się je
    // w dedykowanej sekcji „Sala" (Budżet → Sala).
    final cats = _categories
        .where((c) => c != 'Inne' && !_isSalaOrCatering(c))
        .toList();
    final counts = <String, int>{};
    for (final e in _allExpenses) {
      counts[e.category] = (counts[e.category] ?? 0) + 1;
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() => _quickVisible = !_quickVisible),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(AppText.t.budget_quickItems,
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text)),
                  ),
                  Text(_quickVisible ? AppText.t.budget_collapse : AppText.t.budget_expand,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textLight)),
                  AnimatedRotation(
                    turns: _quickVisible ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child:
                        const Icon(Icons.expand_more, color: AppColors.accent),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            curve: Curves.easeInOut,
            child: _quickVisible
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppText.t.budget_expensesQuickAdd,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.textLight),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final c in cats) _quickChip(c, counts[c] ?? 0),
                            _quickCustomChip(),
                          ],
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _quickChip(String name, int count) {
    final added = count > 0;
    return InkWell(
      onTap: () => _addQuick(name),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: added ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: added ? AppColors.accent : const Color(0xFFDCE4F2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ExpenseCategories.iconFor(name),
                style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(name,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: added ? AppColors.accent : const Color(0xFFEEF3FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(added ? '$count' : '+',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: added ? Colors.white : AppColors.accent)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickCustomChip() {
    return InkWell(
      onTap: _addExpense,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDCE4F2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 16, color: AppColors.accent),
            const SizedBox(width: 6),
            Text(AppText.t.budget_customItem,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent)),
          ],
        ),
      ),
    );
  }

  /// Pasek filtrów z przyciskiem chowania (filtry + sortowanie).
  Widget _filtersBar(List<String> names) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(AppText.t.budget_filtersSort,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textLight)),
            ),
            FilterToggleButton(
              expanded: _filtersVisible,
              onTap: () => setState(() => _filtersVisible = !_filtersVisible),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          curve: Curves.easeInOut,
          child: _filtersVisible
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _filters(names))
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _summaryCard() {
    final expenses = _allExpenses;
    // Kwota orientacyjna = ostateczna lub (gdy brak) orientacyjna z danych.
    double sum(double Function(Expense) f) =>
        expenses.fold(0.0, (s, e) => s + f(e));
    // Ukryte panele napojów nie wchodzą do sumy (dane zachowane).
    final alcohol =
        _bd['alcoholPanelHidden'] == true ? 0.0 : _bevTotal('alcoholItems');
    final soft = _bd['softPanelHidden'] == true ? 0.0 : _bevTotal('softItems');
    final orientacyjnie = sum((e) => e.effective) + alcohol + soft;
    final paid = sum((e) => e.paid);
    final remaining = max(0.0, orientacyjnie - paid);

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
          _summaryItem('Orientacyjnie', orientacyjnie, const Color(0xFF1D4ED8)),
          _summaryItem(AppText.t.budget_paid, paid, const Color(0xFF059669)),
          _summaryItem(AppText.t.budget_left, remaining, const Color(0xFFEA580C)),
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
          _chip(AppText.t.budget_statusPaid, _status == _Status.paid,
              () => setState(() => _status = _Status.paid)),
          _chip(AppText.t.budget_statusPartial, _status == _Status.partial,
              () => setState(() => _status = _Status.partial)),
          _chip(AppText.t.budget_statusUnpaid, _status == _Status.unpaid,
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
              DropdownMenuItem(
                  value: 'all', child: Text(AppText.t.budget_allCategories)),
              for (final c in _categories)
                DropdownMenuItem(
                    value: c, child: Text('${ExpenseCategories.iconFor(c)} ${ExpenseCategories.labelFor(c)}')),
            ],
            onChanged: (v) => setState(() => _categoryFilter = v ?? 'all'),
          ),
        ),
        const SizedBox(height: 8),
        _filterLabel('Sortuj'),
        _chipRow([
          _sortChip(AppText.t.budget_manual, null),
          _sortChip('Orientacyjnie', 'planned'),
          _sortChip(AppText.t.budget_statusPaidShort, 'paid'),
          _sortChip(AppText.t.budget_left, 'remaining'),
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

  // ── Upominki dla gości (referencje z sekcji „Prezenty") ──────────────
  // Pokazane jako wiersze WIRTUALNE (czytane z `giftsForGuests`), nie kopie —
  // edycja przez przejście do sekcji „Prezenty". Kwota się nie dubluje.

  List<GiftForGuest> get _giftsForGuests => [
        for (final e in widget.data?.raw['giftsForGuests'] ?? const [])
          if (e is Map) GiftForGuest(Map<String, dynamic>.from(e)),
      ];

  String get _giftBasis {
    final b = widget.data?.raw['giftForGuestsBasis'];
    return (b == 'real' || b == 'realvirtual') ? b as String : '';
  }

  /// Liczba osób użyta do przeliczenia, gdy włączona podstawa „na gości".
  ///
  /// Wariant „z dopłatą" woła WSPÓLNĄ efektywną liczbę gości z
  /// `GuestBasis` (ten sam mechanizm co Sala/Napoje/Prezenty) — zero
  /// własnej arytmetyki.
  int get _giftPersonCount {
    final guests = widget.data?.guests ?? const [];
    final basis = _giftBasis;
    if (basis == 'real') return guests.length;
    if (basis == 'realvirtual') {
      return GuestBasis.from(widget.data).effective.round();
    }
    return 0;
  }

  /// Wiersze referencyjne upominków „Dla gości" z kosztem > 0 (z podziałem na
  /// odbiorców). Edycja w sekcji „Prezenty" — ten sam rekord, bez duplikacji.
  List<Widget> _giftRows() {
    final items = _giftsForGuests;
    if (items.isEmpty) return const [];
    final basis = _giftBasis;
    final personCount = _giftPersonCount;
    final rows = <Widget>[];
    for (final cat in GiftGuestCat.all) {
      for (final it in items.where((i) => i.category == cat.key)) {
        final qty = basis.isNotEmpty ? personCount.toDouble() : it.qty;
        final total = qty * it.cost;
        if (total <= 0) continue;
        final name = it.name.trim();
        final title = name.isNotEmpty
            ? 'Upominek: ${cat.label} · $name'
            : 'Upominek: ${cat.label}';
        rows.add(Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ReferenceCard(
            icon: cat.icon,
            title: title,
            effective: total,
            paid: 0,
            isPredicted: false,
            sectionLabel: 'Prezenty',
            onOpenSource: () => widget.onOpenSection?.call(AppSection.gifts),
          ),
        ));
      }
    }
    return rows;
  }

  /// Wiersz referencyjny podróży poślubnej (ten sam rekord co w zakładce
  /// „Podróż poślubna" — pokazany tu, edytowany tam). NIE jest osobnym
  /// wydatkiem, więc kwota nie dubluje się w podsumowaniu.
  Widget _honeymoonRow() {
    final hm = _bd['honeymoon'];
    if (hm is! Map) return const SizedBox.shrink();
    final confirmed = (hm['totalAmount'] as num?)?.toDouble() ?? 0;
    final estimated = (hm['estimatedAmount'] as num?)?.toDouble() ?? 0;
    final insts = hm['installments'];
    final hasInst = insts is List && insts.isNotEmpty;
    if (confirmed <= 0 && estimated <= 0 && !hasInst) {
      return const SizedBox.shrink();
    }
    final effective = confirmed > 0 ? confirmed : estimated;
    var paid = 0.0;
    if (insts is List) {
      for (final i in insts.whereType<Map>()) {
        if (i['status'] == 'paid') {
          paid += (i['amount'] as num?)?.toDouble() ?? 0;
        }
      }
    }
    final name = ((hm['name'] as String?)?.trim().isNotEmpty ?? false)
        ? (hm['name'] as String).trim()
        : AppText.t.budget_tabHoneymoon;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _ReferenceCard(
        icon: '✈️',
        title: name,
        effective: effective,
        paid: paid,
        isPredicted: confirmed == 0 && estimated > 0,
        sectionLabel: AppText.t.budget_tabHoneymoon,
        onOpenSource: () => DefaultTabController.maybeOf(context)
            ?.animateTo(widget.honeymoonTabIndex),
      ),
    );
  }
}

/// Karta rekordu pokazanego z innej sekcji (referencja, nie kopia).
class _ReferenceCard extends StatelessWidget {
  const _ReferenceCard({
    required this.icon,
    required this.title,
    required this.effective,
    required this.paid,
    required this.isPredicted,
    required this.sectionLabel,
    required this.onOpenSource,
  });

  final String icon;
  final String title;
  final double effective;
  final double paid;
  final bool isPredicted;
  final String sectionLabel;
  final VoidCallback onOpenSource;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpenSource,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFCFE0FB)),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text)),
                  const SizedBox(height: 6),
                  AddedInChip(section: sectionLabel, onTap: onOpenSource),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${formatPlnZl(effective)}${isPredicted ? ' ~' : ''}',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text)),
                Text(AppText.t.budget_paidShortPrefix(formatPlnZl(paid)),
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textLight)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Rozwijana karta wydatku.
class _ExpenseCard extends StatefulWidget {
  const _ExpenseCard({
    super.key,
    required this.expense,
    required this.coupleNames,
    required this.onEdit,
    required this.onDelete,
    this.onOpenSource,
    this.sourceLabel,
  });

  final Expense expense;
  final List<String> coupleNames;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Gdy rekord pochodzi z innej sekcji (np. Dostawcy/Zadania) — przejście do źródła.
  final VoidCallback? onOpenSource;

  /// Etykieta sekcji źródłowej (np. „Dostawcy", „Zadania") dla [AddedInChip].
  final String? sourceLabel;

  @override
  State<_ExpenseCard> createState() => _ExpenseCardState();
}

class _ExpenseCardState extends State<_ExpenseCard> {
  bool _expanded = false;

  ({Color bg, Color fg, String text}) get _badge => switch (widget.expense.status) {
        ExpenseStatus.paid =>
          (bg: const Color(0xFFECFDF5), fg: const Color(0xFF059669), text: AppText.t.budget_statusPaid),
        ExpenseStatus.partial =>
          (bg: const Color(0xFFFEF3C7), fg: const Color(0xFFB45309), text: AppText.t.budget_statusPartial),
        ExpenseStatus.unpaid =>
          (bg: const Color(0xFFFEE2E2), fg: const Color(0xFFC0392B), text: AppText.t.budget_statusUnpaid),
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
                          ],
                        ),
                        if (widget.onOpenSource != null) ...[
                          const SizedBox(height: 6),
                          AddedInChip(
                            section: widget.sourceLabel ?? 'Dostawcy',
                            onTap: widget.onOpenSource!,
                          ),
                        ],
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
                        AppText.t.budget_paidShortPrefix(formatPlnZl(e.paid)),
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
          _row('Orientacyjnie', formatPlnZl(e.effective)),
          _row(AppText.t.budget_paid, formatPlnZl(e.paid)),
          _row(AppText.t.budget_left, formatPlnZl(e.remaining)),
          if (e.paymentDate.isNotEmpty) _row(AppText.t.budget_paymentDate, e.paymentDate),
          if (e.splitP1 > 0 || e.splitP2 > 0)
            _row(AppText.t.budget_split,
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
                  label: Text(AppText.t.common_delete),
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
