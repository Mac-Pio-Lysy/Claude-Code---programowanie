import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/ad_banner_placeholder.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../monetization/presentation/cubit/monetization_cubit.dart';
import '../../../workspace/presentation/pages/workspace_page.dart' show workspaceNavDestinations;

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.selectedBottomIndex,
    required this.onBottomDestinationSelected,
  });

  final int selectedBottomIndex;
  final ValueChanged<int> onBottomDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final monetization = context.watch<MonetizationCubit>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Ustawienia')),
      body: GradientBackground(
        child: ListTile(
          leading: const Icon(Icons.workspace_premium_outlined),
          title: const Text('Wesprzyj / Premium'),
          subtitle: Text(monetization.isPremium ? 'Premium aktywne' : 'Wersja Free'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/support'),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        destinations: workspaceNavDestinations,
        selectedIndex: selectedBottomIndex,
        onDestinationSelected: onBottomDestinationSelected,
        adBanner: monetization.shouldShowAds ? const AdBannerPlaceholder() : null,
      ),
    );
  }
}
