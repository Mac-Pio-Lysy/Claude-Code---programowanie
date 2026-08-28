import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/ad_banner_placeholder.dart';
import '../../../../core/widgets/top_level_page_scaffold.dart';
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

    return TopLevelPageScaffold(
      title: 'Ustawienia',
      destinations: workspaceNavDestinations,
      selectedIndex: selectedBottomIndex,
      onDestinationSelected: onBottomDestinationSelected,
      adBanner: monetization.shouldShowAds ? const AdBannerPlaceholder() : null,
      body: ListTile(
        leading: const Icon(Icons.workspace_premium_outlined),
        title: const Text('Wesprzyj / Premium'),
        subtitle: Text(monetization.isPremium ? 'Premium aktywne' : 'Wersja Free'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/support'),
      ),
    );
  }
}
