import 'package:flutter/material.dart';

import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../workspace/presentation/pages/workspace_page.dart' show workspaceNavDestinations;

/// Entry point for scanning a receipt; captured images are handed to the
/// external OCR service and the recognized expense is inserted into the
/// budget sheet (see architecture.c4: ocrScanner -> sheetEngine).
class OcrScannerPage extends StatelessWidget {
  const OcrScannerPage({
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
      appBar: AppBar(title: const Text('Skaner paragonów')),
      bottomNavigationBar: AppBottomNavBar(
        destinations: workspaceNavDestinations,
        selectedIndex: selectedBottomIndex,
        onDestinationSelected: onBottomDestinationSelected,
      ),
      body: GradientBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.document_scanner_outlined, size: 64),
              const SizedBox(height: 16),
              const Text('Zeskanuj paragon, aby dodać wydatek'),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Otwórz aparat'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
