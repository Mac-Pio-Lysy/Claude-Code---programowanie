import 'package:flutter/material.dart';

enum MobileRowAction { edit, comment, delete }

/// Long-press action sheet: Edycja / Komentarz / Usuń. [includeComment]
/// hides the comment action for entries that don't support one (liabilities).
Future<MobileRowAction?> showMobileRowActions(
  BuildContext context, {
  bool includeComment = true,
}) {
  return showModalBottomSheet<MobileRowAction>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edycja'),
            onTap: () => Navigator.of(sheetContext).pop(MobileRowAction.edit),
          ),
          if (includeComment)
            ListTile(
              leading: const Icon(Icons.comment_outlined),
              title: const Text('Komentarz'),
              onTap: () => Navigator.of(sheetContext).pop(MobileRowAction.comment),
            ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Usuń'),
            onTap: () => Navigator.of(sheetContext).pop(MobileRowAction.delete),
          ),
        ],
      ),
    ),
  );
}
