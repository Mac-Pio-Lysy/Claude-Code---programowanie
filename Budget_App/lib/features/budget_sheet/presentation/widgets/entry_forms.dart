import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/models/expense_category_type.dart';
import '../../domain/models/expense_entry.dart';
import '../../domain/models/income_entry.dart';
import '../../domain/models/income_type.dart';
import '../../domain/models/installment_liability.dart';
import '../bloc/budget_sheet_bloc.dart';
import '../bloc/budget_sheet_event.dart';

const _uuid = Uuid();

double? _parseAmount(String text) => double.tryParse(text.trim().replaceAll(',', '.'));

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

String _incomeTypeLabel(IncomeType type) => switch (type) {
      IncomeType.uop => 'Umowa o pracę',
      IncomeType.b2b => 'B2B',
      IncomeType.mandateContract => 'Umowa zlecenie',
      IncomeType.other => 'Inne',
    };

String _categoryTypeLabel(ExpenseCategoryType type) => switch (type) {
      ExpenseCategoryType.mandatory => 'Wymagane',
      ExpenseCategoryType.utility => 'Użytkowe',
      ExpenseCategoryType.wants => 'Zachcianki',
    };

/// Shows [builder]'s content as a dialog on wide screens, or a scrollable
/// bottom sheet (that avoids the keyboard) on narrow ones.
Future<void> _showResponsiveForm(BuildContext context, {required WidgetBuilder builder}) {
  final isNarrow = MediaQuery.sizeOf(context).width < AppConstants.desktopBreakpoint;

  if (isNarrow) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: builder(sheetContext),
          ),
        ),
      ),
    );
  }

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(child: builder(dialogContext)),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Income
// ---------------------------------------------------------------------------

Future<void> showIncomeForm(BuildContext context, {IncomeEntry? existing}) {
  final bloc = context.read<BudgetSheetBloc>();

  return _showResponsiveForm(
    context,
    builder: (dialogContext) => _IncomeForm(
      existing: existing,
      onSubmit: (entry) {
        bloc.add(existing == null ? AddIncomeEntry(entry) : UpdateIncomeEntry(entry));
        Navigator.of(dialogContext).pop();
      },
    ),
  );
}

class _IncomeForm extends StatefulWidget {
  const _IncomeForm({required this.existing, required this.onSubmit});

  final IncomeEntry? existing;
  final ValueChanged<IncomeEntry> onSubmit;

  @override
  State<_IncomeForm> createState() => _IncomeFormState();
}

class _IncomeFormState extends State<_IncomeForm> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController =
      TextEditingController(text: widget.existing?.title ?? '');
  late final _grossController = TextEditingController(
    text: widget.existing == null ? '' : widget.existing!.grossAmount.toStringAsFixed(2),
  );
  late final _netController = TextEditingController(
    text: widget.existing == null ? '' : widget.existing!.netAmount.toStringAsFixed(2),
  );
  late final _commentController =
      TextEditingController(text: widget.existing?.comment ?? '');
  late IncomeType _type = widget.existing?.type ?? IncomeType.uop;

  @override
  void dispose() {
    _titleController.dispose();
    _grossController.dispose();
    _netController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(
      IncomeEntry(
        id: widget.existing?.id ?? _uuid.v4(),
        title: _titleController.text.trim(),
        type: _type,
        grossAmount: _parseAmount(_grossController.text) ?? 0,
        netAmount: _parseAmount(_netController.text) ?? 0,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.existing == null ? 'Nowy wpływ' : 'Edytuj wpływ',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Nazwa'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Podaj nazwę' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<IncomeType>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Rodzaj umowy'),
            items: [
              for (final type in IncomeType.values)
                DropdownMenuItem(value: type, child: Text(_incomeTypeLabel(type))),
            ],
            onChanged: (value) => setState(() => _type = value ?? _type),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _grossController,
                  decoration: const InputDecoration(labelText: 'Kwota brutto'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => _parseAmount(v ?? '') == null ? 'Nieprawidłowa kwota' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _netController,
                  decoration: const InputDecoration(labelText: 'Kwota netto'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => _parseAmount(v ?? '') == null ? 'Nieprawidłowa kwota' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _commentController,
            decoration: const InputDecoration(labelText: 'Komentarz (opcjonalnie)'),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(onPressed: _submit, child: const Text('Zapisz')),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Expense
// ---------------------------------------------------------------------------

Future<void> showExpenseForm(
  BuildContext context, {
  ExpenseEntry? existing,
  ExpenseCategoryType? initialCategoryType,
}) {
  final bloc = context.read<BudgetSheetBloc>();

  return _showResponsiveForm(
    context,
    builder: (dialogContext) => _ExpenseForm(
      existing: existing,
      initialCategoryType: initialCategoryType,
      onSubmit: (entry) {
        bloc.add(existing == null ? AddExpenseEntry(entry) : UpdateExpenseEntry(entry));
        Navigator.of(dialogContext).pop();
      },
    ),
  );
}

class _ExpenseForm extends StatefulWidget {
  const _ExpenseForm({
    required this.existing,
    required this.initialCategoryType,
    required this.onSubmit,
  });

  final ExpenseEntry? existing;
  final ExpenseCategoryType? initialCategoryType;
  final ValueChanged<ExpenseEntry> onSubmit;

  @override
  State<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<_ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController =
      TextEditingController(text: widget.existing?.name ?? '');
  late final _amountController = TextEditingController(
    text: widget.existing == null ? '' : widget.existing!.amount.toStringAsFixed(2),
  );
  late final _subCategoryController =
      TextEditingController(text: widget.existing?.subCategory ?? '');
  late final _commentController =
      TextEditingController(text: widget.existing?.comment ?? '');
  late ExpenseCategoryType _categoryType = widget.existing?.categoryType ??
      widget.initialCategoryType ??
      ExpenseCategoryType.mandatory;
  late DateTime _date = widget.existing?.date ?? DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _subCategoryController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(
      ExpenseEntry(
        id: widget.existing?.id ?? _uuid.v4(),
        name: _nameController.text.trim(),
        amount: _parseAmount(_amountController.text) ?? 0,
        categoryType: _categoryType,
        subCategory: _subCategoryController.text.trim(),
        date: _date,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.existing == null ? 'Nowy wydatek' : 'Edytuj wydatek',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nazwa'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Podaj nazwę' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(labelText: 'Kwota'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) => _parseAmount(v ?? '') == null ? 'Nieprawidłowa kwota' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ExpenseCategoryType>(
            initialValue: _categoryType,
            decoration: const InputDecoration(labelText: 'Kategoria'),
            items: [
              for (final type in ExpenseCategoryType.values)
                DropdownMenuItem(value: type, child: Text(_categoryTypeLabel(type))),
            ],
            onChanged: (value) => setState(() => _categoryType = value ?? _categoryType),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _subCategoryController,
            decoration: const InputDecoration(
              labelText: 'Podkategoria (np. Mieszkanie, Multimedia)',
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Podaj podkategorię' : null,
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Data'),
              child: Text(_formatDate(_date)),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _commentController,
            decoration: const InputDecoration(labelText: 'Komentarz (opcjonalnie)'),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(onPressed: _submit, child: const Text('Zapisz')),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Installment liability
// ---------------------------------------------------------------------------

Future<void> showLiabilityForm(BuildContext context, {InstallmentLiability? existing}) {
  final bloc = context.read<BudgetSheetBloc>();

  return _showResponsiveForm(
    context,
    builder: (dialogContext) => _LiabilityForm(
      existing: existing,
      onSubmit: (liability) {
        bloc.add(
          existing == null
              ? AddInstallmentLiability(liability)
              : UpdateInstallmentLiability(liability),
        );
        Navigator.of(dialogContext).pop();
      },
    ),
  );
}

class _LiabilityForm extends StatefulWidget {
  const _LiabilityForm({required this.existing, required this.onSubmit});

  final InstallmentLiability? existing;
  final ValueChanged<InstallmentLiability> onSubmit;

  @override
  State<_LiabilityForm> createState() => _LiabilityFormState();
}

class _LiabilityFormState extends State<_LiabilityForm> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController =
      TextEditingController(text: widget.existing?.title ?? '');
  late final _amountController = TextEditingController(
    text:
        widget.existing == null ? '' : widget.existing!.monthlyAmount.toStringAsFixed(2),
  );
  late DateTime _startDate = widget.existing?.startDate ?? DateTime.now();
  late DateTime _endDate =
      widget.existing?.endDate ?? DateTime.now().add(const Duration(days: 365));

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => isStart ? _startDate = picked : _endDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_endDate.isAfter(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data końcowa musi być po dacie startu')),
      );
      return;
    }
    widget.onSubmit(
      InstallmentLiability(
        id: widget.existing?.id ?? _uuid.v4(),
        title: _titleController.text.trim(),
        monthlyAmount: _parseAmount(_amountController.text) ?? 0,
        startDate: _startDate,
        endDate: _endDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.existing == null ? 'Nowe zobowiązanie' : 'Edytuj zobowiązanie',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Nazwa (np. Kredyt hipoteczny)'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Podaj nazwę' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(labelText: 'Rata miesięczna'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) => _parseAmount(v ?? '') == null ? 'Nieprawidłowa kwota' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(isStart: true),
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Start'),
                    child: Text(_formatDate(_startDate)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(isStart: false),
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Koniec'),
                    child: Text(_formatDate(_endDate)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(onPressed: _submit, child: const Text('Zapisz')),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Comment editor (Income & Expense rows only — liabilities have no comment)
// ---------------------------------------------------------------------------

Future<void> showCommentEditor(
  BuildContext context, {
  required String? initialComment,
  required ValueChanged<String?> onSave,
}) {
  final controller = TextEditingController(text: initialComment ?? '');
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Komentarz'),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 3,
        decoration: const InputDecoration(hintText: 'Dodaj komentarz do pozycji…'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: () {
            final text = controller.text.trim();
            onSave(text.isEmpty ? null : text);
            Navigator.of(dialogContext).pop();
          },
          child: const Text('Zapisz'),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Delete confirmation
// ---------------------------------------------------------------------------

Future<void> confirmDelete(
  BuildContext context, {
  required String title,
  required VoidCallback onConfirmed,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Usunąć pozycję?'),
      content: Text('„$title” zostanie trwale usunięta.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Usuń'),
        ),
      ],
    ),
  );
  if (confirmed == true) onConfirmed();
}

// ---------------------------------------------------------------------------
// Quick "Zmień kategorię" — a fast single-field change without the full form
// ---------------------------------------------------------------------------

Future<void> showQuickExpenseCategoryMenu(
  BuildContext context, {
  required ExpenseEntry expense,
  required RelativeRect position,
}) async {
  final bloc = context.read<BudgetSheetBloc>();
  final selected = await showMenu<ExpenseCategoryType>(
    context: context,
    position: position,
    items: [
      for (final type in ExpenseCategoryType.values)
        PopupMenuItem(value: type, child: Text(_categoryTypeLabel(type))),
    ],
  );
  if (selected != null && selected != expense.categoryType) {
    bloc.add(UpdateExpenseEntry(expense.copyWith(categoryType: selected)));
  }
}

Future<void> showQuickIncomeTypeMenu(
  BuildContext context, {
  required IncomeEntry income,
  required RelativeRect position,
}) async {
  final bloc = context.read<BudgetSheetBloc>();
  final selected = await showMenu<IncomeType>(
    context: context,
    position: position,
    items: [
      for (final type in IncomeType.values)
        PopupMenuItem(value: type, child: Text(_incomeTypeLabel(type))),
    ],
  );
  if (selected != null && selected != income.type) {
    bloc.add(UpdateIncomeEntry(income.copyWith(type: selected)));
  }
}

// ---------------------------------------------------------------------------
// Mobile FAB: choose what kind of entry to add
// ---------------------------------------------------------------------------

Future<void> showAddEntryChooser(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.arrow_upward_rounded, color: Colors.green),
            title: const Text('Wpływ'),
            onTap: () {
              Navigator.of(sheetContext).pop();
              showIncomeForm(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.arrow_downward_rounded, color: Colors.deepOrange),
            title: const Text('Wydatek'),
            onTap: () {
              Navigator.of(sheetContext).pop();
              showExpenseForm(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.credit_card_outlined, color: Colors.blue),
            title: const Text('Rata / zobowiązanie'),
            onTap: () {
              Navigator.of(sheetContext).pop();
              showLiabilityForm(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.document_scanner_outlined, color: Colors.purple),
            title: const Text('Skanuj paragon'),
            onTap: () {
              Navigator.of(sheetContext).pop();
              GoRouter.of(context).push('/ocr');
            },
          ),
        ],
      ),
    ),
  );
}
