import 'package:flutter/material.dart';

enum RowMenuAction { edit, comment, changeCategory, delete }

/// Right-click row menu: Edytuj / Dodaj komentarz / Zmień kategorię / Usuń
/// wiersz. [includeComment]/[includeCategory] hide the actions that don't
/// apply to the row's entry type (liabilities have neither).
Future<RowMenuAction?> showRowContextMenu(
  BuildContext context,
  Offset globalPosition, {
  bool includeComment = true,
  bool includeCategory = true,
}) {
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final position = RelativeRect.fromRect(
    Rect.fromPoints(globalPosition, globalPosition),
    Offset.zero & overlay.size,
  );

  return showMenu<RowMenuAction>(
    context: context,
    position: position,
    items: [
      const PopupMenuItem(value: RowMenuAction.edit, child: Text('Edytuj')),
      if (includeComment)
        const PopupMenuItem(
          value: RowMenuAction.comment,
          child: Text('Dodaj komentarz'),
        ),
      if (includeCategory)
        const PopupMenuItem(
          value: RowMenuAction.changeCategory,
          child: Text('Zmień kategorię'),
        ),
      const PopupMenuItem(value: RowMenuAction.delete, child: Text('Usuń wiersz')),
    ],
  );
}
