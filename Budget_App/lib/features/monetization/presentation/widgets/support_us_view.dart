import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/models/subscription_tier.dart';
import '../cubit/monetization_cubit.dart';

/// "Wesprzyj / Przejdź na Premium" (AB-1): benefits of Premium plus a mock
/// activation button. [limitMessage], when set, explains why the user
/// landed here (e.g. the Free budget limit).
class SupportUsView extends StatelessWidget {
  const SupportUsView({super.key, this.limitMessage});

  final String? limitMessage;

  static const _benefits = [
    (Icons.dashboard_customize_outlined, 'Nielimitowana liczba budżetów'),
    (Icons.group_outlined, 'Współpraca z partnerem lub rodziną'),
    (Icons.block_outlined, 'Brak reklam'),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isPremium = context.watch<MonetizationCubit>().state == SubscriptionTier.premium;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (limitMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryIndigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primaryIndigo, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(limitMessage!, style: textTheme.bodySmall)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Wesprzyj / Przejdź na Premium', style: textTheme.titleMedium),
                const SizedBox(height: 16),
                for (final (icon, label) in _benefits)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(icon, color: AppColors.positive),
                        const SizedBox(width: 12),
                        Expanded(child: Text(label, style: textTheme.bodyMedium)),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isPremium
                        ? null
                        : () => context.read<MonetizationCubit>().activatePremium(),
                    child: Text(isPremium ? 'Premium aktywne' : 'Aktywuj Premium'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
