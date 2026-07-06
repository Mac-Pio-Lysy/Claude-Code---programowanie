import 'package:flutter/material.dart';

import '../navigation/app_sections.dart';
import 'onboarding_steps.dart';

/// Wkładka dla ekranów z `DefaultTabController` — w trakcie przewodnika
/// przełącza widoczną podzakładkę zgodnie z [OnboardingTabBus].
///
/// Umieść tuż pod `DefaultTabController` jako jego dziecko:
/// `DefaultTabController(length: n, child: TourTabSync(section: ..., child: Column(...)))`.
class TourTabSync extends StatefulWidget {
  const TourTabSync({super.key, required this.section, required this.child});

  final AppSection section;
  final Widget child;

  @override
  State<TourTabSync> createState() => _TourTabSyncState();
}

class _TourTabSyncState extends State<TourTabSync> {
  @override
  void initState() {
    super.initState();
    OnboardingTabBus.request.addListener(_apply);
    // Zastosuj żądanie oczekujące, gdy ekran zamontował się PO jego ustawieniu
    // (np. przewodnik najpierw przełączył sekcję, potem ekran się pojawił).
    WidgetsBinding.instance.addPostFrameCallback((_) => _apply());
  }

  @override
  void dispose() {
    OnboardingTabBus.request.removeListener(_apply);
    super.dispose();
  }

  void _apply() {
    if (!mounted) return;
    final req = OnboardingTabBus.request.value;
    if (req == null || req.section != widget.section) return;
    final controller = DefaultTabController.maybeOf(context);
    if (controller == null) return;
    if (req.index >= 0 && req.index < controller.length) {
      controller.animateTo(req.index);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
