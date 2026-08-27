/// Material 3 adaptive layout breakpoints (window width, logical pixels).
abstract final class Breakpoints {
  static const double compact = 600;
  static const double medium = 840;

  static bool isCompact(double width) => width < compact;
  static bool isMedium(double width) => width >= compact && width < medium;
  static bool isExpanded(double width) => width >= medium;
}
