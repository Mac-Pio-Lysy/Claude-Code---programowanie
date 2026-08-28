import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../monetization/presentation/cubit/monetization_cubit.dart';
import '../../domain/models/budget_workspace.dart';
import '../../domain/models/workspace_tag.dart';
import '../bloc/workspaces_bloc.dart';
import '../bloc/workspaces_event.dart';
import 'workspace_tag_ui.dart';

const _uuid = Uuid();

/// Premium-only "add a budget" form (Free never reaches this — it's routed
/// to SupportUsView instead once it hits its 1-budget limit).
Future<void> showCreateBudgetDialog(BuildContext context) {
  final workspacesBloc = context.read<WorkspacesBloc>();
  final canShare = context.read<MonetizationCubit>().canShareBudgets;

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _CreateBudgetForm(
            canShare: canShare,
            onSubmit: (workspace) {
              workspacesBloc.add(AddWorkspace(workspace));
              Navigator.of(dialogContext).pop();
            },
          ),
        ),
      ),
    ),
  );
}

class _CreateBudgetForm extends StatefulWidget {
  const _CreateBudgetForm({required this.canShare, required this.onSubmit});

  final bool canShare;
  final ValueChanged<BudgetWorkspace> onSubmit;

  @override
  State<_CreateBudgetForm> createState() => _CreateBudgetFormState();
}

class _CreateBudgetFormState extends State<_CreateBudgetForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  WorkspaceTag _tag = WorkspaceTag.general;
  bool _isShared = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(
      BudgetWorkspace(
        id: _uuid.v4(),
        title: _titleController.text.trim(),
        tag: _tag,
        isShared: widget.canShare && _isShared,
        isOnline: true,
        ownerId: 'demo-user',
        createdAt: DateTime.now(),
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
          Text('Nowy budżet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nazwa budżetu'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Podaj nazwę' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<WorkspaceTag>(
            initialValue: _tag,
            decoration: const InputDecoration(labelText: 'Tag'),
            items: [
              for (final tag in WorkspaceTag.values)
                DropdownMenuItem(value: tag, child: Text(workspaceTagLabel(tag))),
            ],
            onChanged: (value) => setState(() => _tag = value ?? _tag),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Budżet współdzielony'),
            subtitle: widget.canShare
                ? const Text('Zaproś innych z poziomu ustawień budżetu')
                : const Text('Dostępne w wersji Premium'),
            value: widget.canShare && _isShared,
            onChanged: widget.canShare ? (value) => setState(() => _isShared = value) : null,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(onPressed: _submit, child: const Text('Utwórz')),
          ),
        ],
      ),
    );
  }
}
