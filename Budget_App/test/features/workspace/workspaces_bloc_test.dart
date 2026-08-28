import 'package:bloc_test/bloc_test.dart';
import 'package:budget_app/features/workspace/domain/models/budget_workspace.dart';
import 'package:budget_app/features/workspace/domain/models/workspace_tag.dart';
import 'package:budget_app/features/workspace/presentation/bloc/workspaces_bloc.dart';
import 'package:budget_app/features/workspace/presentation/bloc/workspaces_event.dart';
import 'package:budget_app/features/workspace/presentation/bloc/workspaces_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final wedding = BudgetWorkspace(
    id: 'ws-wedding',
    title: 'Wesele',
    tag: WorkspaceTag.wedding,
    isShared: true,
    isOnline: true,
    ownerId: 'demo-user',
    createdAt: DateTime(2026, 1, 1),
  );

  group('LoadWorkspaces', () {
    blocTest<WorkspacesBloc, WorkspacesState>(
      'seeds exactly one starter budget (Free tier starts at the limit)',
      build: WorkspacesBloc.new,
      act: (bloc) => bloc.add(const LoadWorkspaces()),
      expect: () => [
        isA<WorkspacesState>().having((s) => s.status, 'status', WorkspacesStatus.loading),
        isA<WorkspacesState>()
            .having((s) => s.status, 'status', WorkspacesStatus.loaded)
            .having((s) => s.workspaces.length, 'count', 1),
      ],
    );
  });

  group('AddWorkspace / UpdateWorkspace / DeleteWorkspace (AB-7)', () {
    blocTest<WorkspacesBloc, WorkspacesState>(
      'AddWorkspace appends a new budget',
      build: WorkspacesBloc.new,
      act: (bloc) => bloc.add(AddWorkspace(wedding)),
      verify: (bloc) => expect(bloc.state.workspaces, contains(wedding)),
    );

    blocTest<WorkspacesBloc, WorkspacesState>(
      'UpdateWorkspace replaces the matching budget by id',
      build: WorkspacesBloc.new,
      seed: () => WorkspacesState.initial().copyWith(workspaces: [wedding]),
      act: (bloc) => bloc.add(UpdateWorkspace(wedding.copyWith(title: 'Wesele 2027'))),
      verify: (bloc) => expect(bloc.state.findById('ws-wedding')?.title, 'Wesele 2027'),
    );

    blocTest<WorkspacesBloc, WorkspacesState>(
      'DeleteWorkspace removes exactly that budget, leaving the rest intact',
      build: WorkspacesBloc.new,
      seed: () => WorkspacesState.initial().copyWith(
        workspaces: [
          wedding,
          BudgetWorkspace(
            id: 'ws-home',
            title: 'Budżet domowy',
            tag: WorkspaceTag.general,
            isShared: false,
            isOnline: true,
            ownerId: 'demo-user',
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
      ),
      act: (bloc) => bloc.add(const DeleteWorkspace('ws-wedding')),
      verify: (bloc) {
        expect(bloc.state.findById('ws-wedding'), isNull);
        expect(bloc.state.findById('ws-home'), isNotNull);
      },
    );
  });
}
