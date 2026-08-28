import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/contribution_interval.dart';
import '../../domain/models/savings_goal.dart';
import '../bloc/savings_bloc.dart';
import '../bloc/savings_event.dart';
import 'contribution_interval_label.dart';

const _uuid = Uuid();

double? _parseAmount(String text) => double.tryParse(text.trim().replaceAll(',', '.'));

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

/// Modal form to add a new goal, or edit an existing one when [existing] is
/// provided. Dispatches AddSavingsGoal/UpdateSavingsGoal on the ambient
/// SavingsBloc.
Future<void> showAddSavingsGoalDialog(BuildContext context, {SavingsGoal? existing}) {
  final bloc = context.read<SavingsBloc>();

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: _AddSavingsGoalForm(
              existing: existing,
              onSubmit: (goal) {
                bloc.add(existing == null ? AddSavingsGoal(goal) : UpdateSavingsGoal(goal));
                Navigator.of(dialogContext).pop();
              },
            ),
          ),
        ),
      ),
    ),
  );
}

class _AddSavingsGoalForm extends StatefulWidget {
  const _AddSavingsGoalForm({required this.existing, required this.onSubmit});

  final SavingsGoal? existing;
  final ValueChanged<SavingsGoal> onSubmit;

  @override
  State<_AddSavingsGoalForm> createState() => _AddSavingsGoalFormState();
}

class _AddSavingsGoalFormState extends State<_AddSavingsGoalForm> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController = TextEditingController(text: widget.existing?.title ?? '');
  late final _targetController = TextEditingController(
    text: widget.existing == null ? '' : widget.existing!.targetAmount.toStringAsFixed(2),
  );
  late final _currentController = TextEditingController(
    text: widget.existing == null ? '0' : widget.existing!.currentAmount.toStringAsFixed(2),
  );
  late ContributionInterval _interval =
      widget.existing?.contributionInterval ?? ContributionInterval.monthly;
  late DateTime? _targetDate = widget.existing?.targetDate;

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _currentController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 180)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(
      SavingsGoal(
        id: widget.existing?.id ?? _uuid.v4(),
        title: _titleController.text.trim(),
        targetAmount: _parseAmount(_targetController.text) ?? 0,
        currentAmount: _parseAmount(_currentController.text) ?? 0,
        contributionInterval: _interval,
        targetDate: _targetDate,
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
            widget.existing == null ? 'Nowy cel oszczędnościowy' : 'Edytuj cel',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Nazwa celu (np. Wakacje, Wesele, Poduszka)',
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Podaj nazwę' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _targetController,
                  decoration: const InputDecoration(labelText: 'Kwota docelowa'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => _parseAmount(v ?? '') == null ? 'Nieprawidłowa kwota' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _currentController,
                  decoration: const InputDecoration(labelText: 'Zgromadzono już'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => _parseAmount(v ?? '') == null ? 'Nieprawidłowa kwota' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ContributionInterval>(
            initialValue: _interval,
            decoration: const InputDecoration(labelText: 'Częstotliwość odkładania'),
            items: [
              for (final interval in ContributionInterval.values)
                DropdownMenuItem(
                  value: interval,
                  child: Text(contributionIntervalLabel(interval)),
                ),
            ],
            onChanged: (value) => setState(() => _interval = value ?? _interval),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Termin (opcjonalnie)'),
              child: Text(_targetDate == null ? 'Brak terminu' : _formatDate(_targetDate!)),
            ),
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
