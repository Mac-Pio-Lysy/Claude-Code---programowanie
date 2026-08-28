import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/sinking_fund.dart';
import '../bloc/savings_bloc.dart';
import '../bloc/savings_event.dart';

const _uuid = Uuid();

double? _parseAmount(String text) => double.tryParse(text.trim().replaceAll(',', '.'));

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

/// Modal form to add a new sinking fund, or edit an existing one when
/// [existing] is provided. Dispatches AddSinkingFund/UpdateSinkingFund on
/// the ambient SavingsBloc.
Future<void> showAddSinkingFundDialog(BuildContext context, {SinkingFund? existing}) {
  final bloc = context.read<SavingsBloc>();

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: _AddSinkingFundForm(
              existing: existing,
              onSubmit: (fund) {
                bloc.add(existing == null ? AddSinkingFund(fund) : UpdateSinkingFund(fund));
                Navigator.of(dialogContext).pop();
              },
            ),
          ),
        ),
      ),
    ),
  );
}

class _AddSinkingFundForm extends StatefulWidget {
  const _AddSinkingFundForm({required this.existing, required this.onSubmit});

  final SinkingFund? existing;
  final ValueChanged<SinkingFund> onSubmit;

  @override
  State<_AddSinkingFundForm> createState() => _AddSinkingFundFormState();
}

class _AddSinkingFundFormState extends State<_AddSinkingFundForm> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController = TextEditingController(text: widget.existing?.title ?? '');
  late final _targetController = TextEditingController(
    text: widget.existing == null ? '' : widget.existing!.targetAmount.toStringAsFixed(2),
  );
  late final _currentController = TextEditingController(
    text: widget.existing == null ? '0' : widget.existing!.currentAccumulated.toStringAsFixed(2),
  );
  late DateTime _targetDate =
      widget.existing?.targetDate ?? DateTime.now().add(const Duration(days: 180));

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
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(
      SinkingFund(
        id: widget.existing?.id ?? _uuid.v4(),
        title: _titleController.text.trim(),
        targetAmount: _parseAmount(_targetController.text) ?? 0,
        currentAccumulated: _parseAmount(_currentController.text) ?? 0,
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
            widget.existing == null ? 'Nowy fundusz celowy' : 'Edytuj fundusz',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Nazwa (np. Ubezpieczenie OC/AC, Podatek, Święta)',
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
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Termin płatności'),
              child: Text(_formatDate(_targetDate)),
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
