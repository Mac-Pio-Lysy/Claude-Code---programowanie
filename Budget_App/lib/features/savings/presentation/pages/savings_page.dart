import 'package:flutter/material.dart';

import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../workspace/presentation/pages/workspace_page.dart' show workspaceNavDestinations;

class SavingsPage extends StatelessWidget {
  const SavingsPage({
    super.key,
    required this.selectedBottomIndex,
    required this.onBottomDestinationSelected,
  });

  final int selectedBottomIndex;
  final ValueChanged<int> onBottomDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Oszczędności')),
      body: const GradientBackground(
        child: Center(child: Text('Cele oszczędnościowe')),
      ),
      bottomNavigationBar: AppBottomNavBar(
        destinations: workspaceNavDestinations,
        selectedIndex: selectedBottomIndex,
        onDestinationSelected: onBottomDestinationSelected,
      ),
    );
  }
}
