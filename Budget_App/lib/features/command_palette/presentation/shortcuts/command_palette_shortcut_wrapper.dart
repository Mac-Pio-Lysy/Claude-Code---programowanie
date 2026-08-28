import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/command_palette_overlay.dart';

/// Wraps the whole app (see `MaterialApp.router`'s `builder`) so Cmd+K
/// (macOS) / Ctrl+K (Windows/Linux/Web) opens the Command Palette from
/// anywhere, not just wherever the search icon happens to be visible.
class CommandPaletteShortcutWrapper extends StatelessWidget {
  const CommandPaletteShortcutWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK): () =>
            showCommandPaletteOverlay(context),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK): () =>
            showCommandPaletteOverlay(context),
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}
