import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../auth/presentation/widgets/profile_menu_button.dart';
import '../../../monetization/presentation/cubit/monetization_cubit.dart';
import '../../../monetization/presentation/widgets/support_us_modal.dart';
import '../bloc/workspaces_bloc.dart';
import '../bloc/workspaces_state.dart';
import '../widgets/budget_card_widget.dart';
import '../widgets/create_budget_dialog.dart';

/// AB-3/AB-4: entry point after launch — pick which budget to open. Adding a
/// new one is gated by MonetizationCubit's Free-tier limit (AB-1).
class WorkspaceSelectionPage extends StatelessWidget {
  const WorkspaceSelectionPage({super.key});

  Future<void> _handleAddPressed(BuildContext context, int currentCount) async {
    final monetization = context.read<MonetizationCubit>();
    if (monetization.canCreateBudget(currentCount)) {
      await showCreateBudgetDialog(context);
    } else {
      await showSupportUsModal(
        context,
        limitMessage:
            'Wersja Free pozwala na ${MonetizationCubit.freeBudgetLimit} budżet. '
            'Przejdź na Premium, aby dodać kolejny.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(AppConstants.appName),
        actions: const [ProfileMenuButton(), SizedBox(width: 8)],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: BlocBuilder<WorkspacesBloc, WorkspacesState>(
            builder: (context, state) {
              if (state.status == WorkspacesStatus.loading ||
                  state.status == WorkspacesStatus.initial) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.status == WorkspacesStatus.error) {
                return Center(child: Text(state.errorMessage ?? 'Błąd wczytywania.'));
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Twoje budżety', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 900
                              ? 4
                              : constraints.maxWidth >= 600
                                  ? 3
                                  : 2;
                          return GridView.builder(
                            itemCount: state.workspaces.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              mainAxisExtent: 150,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemBuilder: (context, index) {
                              final workspace = state.workspaces[index];
                              return BudgetCardWidget(
                                workspace: workspace,
                                onTap: () => context.go('/budget/${workspace.id}'),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: BlocBuilder<WorkspacesBloc, WorkspacesState>(
        builder: (context, state) => FloatingActionButton(
          tooltip: 'Dodaj nowy budżet',
          onPressed: () => _handleAddPressed(context, state.workspaces.length),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
