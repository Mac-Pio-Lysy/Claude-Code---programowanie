import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the user's theme preference. Defaults to following the system.
final themeModeProvider = NotifierProvider<ThemeModeController, ThemeModeOption>(
  ThemeModeController.new,
);

enum ThemeModeOption { system, light, dark }

class ThemeModeController extends Notifier<ThemeModeOption> {
  @override
  ThemeModeOption build() => ThemeModeOption.system;

  void set(ThemeModeOption option) => state = option;
}
