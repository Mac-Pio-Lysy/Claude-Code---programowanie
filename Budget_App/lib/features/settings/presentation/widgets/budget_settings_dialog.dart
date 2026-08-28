import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../monetization/presentation/cubit/monetization_cubit.dart';
import '../../../workspace/domain/models/budget_workspace.dart';
import '../../../workspace/domain/models/workspace_tag.dart';
import '../../../workspace/presentation/bloc/workspaces_bloc.dart';
import '../../../workspace/presentation/bloc/workspaces_event.dart';
import '../../../workspace/presentation/widgets/workspace_tag_ui.dart';

/// Reached from the gear icon next to the budget name in the top bar.
/// Lets the owner rename the budget, change its tag/participants, and —
/// behind a double-confirmation Danger Zone (AB-7) — delete it outright.
Future<void> showBudgetSettingsDialog(BuildContext context, {required BudgetWorkspace workspace}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(child: _BudgetSettingsForm(workspace: workspace)),
        ),
      ),
    ),
  );
}

class _BudgetSettingsForm extends StatefulWidget {
  const _BudgetSettingsForm({required this.workspace});

  final BudgetWorkspace workspace;

  @override
  State<_BudgetSettingsForm> createState() => _BudgetSettingsFormState();
}

class _BudgetSettingsFormState extends State<_BudgetSettingsForm> {
  late final _titleController = TextEditingController(text: widget.workspace.title);
  late final _emailController = TextEditingController();
  late WorkspaceTag _tag = widget.workspace.tag;
  late final List<String> _sharedEmails = List.of(widget.workspace.sharedUserEmails);
  late bool _isShared = widget.workspace.isShared;

  @override
  void dispose() {
    _titleController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _addEmail() {
    final email = _emailController.text.trim();
    if (email.isEmpty || _sharedEmails.contains(email)) return;
    setState(() {
      _sharedEmails.add(email);
      _emailController.clear();
    });
  }

  void _save(bool canShare) {
    context.read<WorkspacesBloc>().add(
          UpdateWorkspace(
            widget.workspace.copyWith(
              title: _titleController.text.trim().isEmpty
                  ? widget.workspace.title
                  : _titleController.text.trim(),
              tag: _tag,
              isShared: canShare && _isShared,
              sharedUserEmails: canShare ? _sharedEmails : const [],
            ),
          ),
        );
    Navigator.of(context).pop();
  }

  Future<void> _handleDelete() async {
    final firstConfirmed = await showDialog<bool>(
      context: context,
      builder: (confirmContext) => AlertDialog(
        title: const Text('Usunąć budżet?'),
        content: Text(
          'Budżet „${widget.workspace.title}” oraz wszystkie jego dane zostaną trwale usunięte.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(confirmContext).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.negative),
            onPressed: () => Navigator.of(confirmContext).pop(true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (firstConfirmed != true || !mounted) return;

    final secondConfirmed = await showDialog<bool>(
      context: context,
      builder: (confirmContext) => AlertDialog(
        title: const Text('To nieodwracalne'),
        content: const Text('Potwierdź jeszcze raz, że na pewno chcesz usunąć ten budżet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(confirmContext).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.negative),
            onPressed: () => Navigator.of(confirmContext).pop(true),
            child: const Text('Usuń na stałe'),
          ),
        ],
      ),
    );
    if (secondConfirmed != true || !mounted) return;

    final router = GoRouter.of(context);
    context.read<WorkspacesBloc>().add(DeleteWorkspace(widget.workspace.id));
    Navigator.of(context).pop(); // close the settings dialog
    router.go('/workspace');
  }

  @override
  Widget build(BuildContext context) {
    final canShare = context.watch<MonetizationCubit>().canShareBudgets;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ustawienia budżetu', style: textTheme.titleMedium),
        const SizedBox(height: 16),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(labelText: 'Nazwa budżetu'),
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
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Budżet współdzielony'),
          subtitle: canShare ? null : const Text('Dostępne w wersji Premium'),
          value: canShare && _isShared,
          onChanged: canShare ? (value) => setState(() => _isShared = value) : null,
        ),
        if (canShare && _isShared) ...[
          const SizedBox(height: 8),
          Text('Uczestnicy', style: textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final email in _sharedEmails)
                Chip(
                  label: Text(email),
                  onDeleted: () => setState(() => _sharedEmails.remove(email)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Dodaj e-mail uczestnika'),
                  onSubmitted: (_) => _addEmail(),
                ),
              ),
              IconButton(onPressed: _addEmail, icon: const Icon(Icons.add)),
            ],
          ),
        ],
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(onPressed: () => _save(canShare), child: const Text('Zapisz')),
        ),
        const Divider(height: 32),
        Text(
          'Strefa niebezpieczna',
          style: textTheme.labelLarge?.copyWith(color: AppColors.negative),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.negative),
            onPressed: _handleDelete,
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Usuń ten budżet'),
          ),
        ),
      ],
    );
  }
}
