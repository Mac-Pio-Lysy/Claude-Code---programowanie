import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/savings_bloc.dart';
import '../bloc/savings_event.dart';

/// Quick "Wpłać" amount entry for a sinking fund, dispatching
/// ContributeToSinkingFund on the ambient SavingsBloc.
Future<void> showContributeToFundDialog(
  BuildContext context, {
  required String fundId,
  required String fundTitle,
}) {
  final bloc = context.read<SavingsBloc>();
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Wpłać na „$fundTitle”'),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Kwota wpłaty'),
          validator: (v) {
            final amount = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
            return (amount == null || amount <= 0) ? 'Podaj kwotę większą od zera' : null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) return;
            final amount = double.parse(controller.text.trim().replaceAll(',', '.'));
            bloc.add(ContributeToSinkingFund(fundId, amount));
            Navigator.of(dialogContext).pop();
          },
          child: const Text('Wpłać'),
        ),
      ],
    ),
  );
}
