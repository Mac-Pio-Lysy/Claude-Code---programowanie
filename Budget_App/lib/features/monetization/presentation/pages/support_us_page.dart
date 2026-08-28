import 'package:flutter/material.dart';

import '../../../../core/widgets/gradient_background.dart';
import '../widgets/support_us_view.dart';

/// Routable page for `/support`.
class SupportUsPage extends StatelessWidget {
  const SupportUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Wesprzyj / Premium')),
      body: const GradientBackground(child: SupportUsView()),
    );
  }
}
