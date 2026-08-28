import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Small corner marker for a row's comment: dim when empty, accented and
/// hoverable (tooltip preview) when a comment exists. Tapping either state
/// opens the comment editor.
class CommentIndicator extends StatelessWidget {
  const CommentIndicator({super.key, required this.comment, required this.onTap});

  final String? comment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasComment = comment != null && comment!.trim().isNotEmpty;
    final icon = Icon(
      Icons.comment,
      size: 14,
      color: hasComment
          ? AppColors.primaryIndigo
          : AppColors.textSecondary.withValues(alpha: 0.35),
    );

    return InkWell(
      onTap: onTap,
      child: hasComment ? Tooltip(message: comment!, child: icon) : icon,
    );
  }
}
