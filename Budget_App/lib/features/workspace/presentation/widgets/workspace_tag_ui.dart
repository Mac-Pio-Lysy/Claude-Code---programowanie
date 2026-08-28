import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/workspace_tag.dart';

String workspaceTagLabel(WorkspaceTag tag) => switch (tag) {
      WorkspaceTag.general => 'Ogólny',
      WorkspaceTag.travel => 'Podróż',
      WorkspaceTag.wedding => 'Wesele',
      WorkspaceTag.renovation => 'Remont',
      WorkspaceTag.custom => 'Własny',
    };

Color workspaceTagColor(WorkspaceTag tag) => switch (tag) {
      WorkspaceTag.general => AppColors.primaryIndigo,
      WorkspaceTag.travel => const Color(0xFF26A69A),
      WorkspaceTag.wedding => const Color(0xFFEC407A),
      WorkspaceTag.renovation => const Color(0xFFFFA726),
      WorkspaceTag.custom => const Color(0xFF8D6E63),
    };
