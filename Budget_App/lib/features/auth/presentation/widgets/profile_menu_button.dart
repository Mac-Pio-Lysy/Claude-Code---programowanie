import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Avatar + e-mail + "Wyloguj" — the top-right profile menu required by
/// AB-2. Reads AuthBloc directly since it's provided at the app root.
class ProfileMenuButton extends StatelessWidget {
  const ProfileMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    if (state is! Authenticated) return const SizedBox.shrink();

    final user = state.user;
    final initial = (user.displayName?.isNotEmpty ?? false)
        ? user.displayName![0].toUpperCase()
        : user.email[0].toUpperCase();

    return PopupMenuButton<String>(
      tooltip: 'Profil',
      onSelected: (value) {
        if (value == 'sign_out') context.read<AuthBloc>().add(const SignOut());
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Text(user.email, style: Theme.of(context).textTheme.bodySmall),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'sign_out',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18, color: AppColors.negative),
              SizedBox(width: 8),
              Text('Wyloguj'),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primaryIndigo.withValues(alpha: 0.15),
          child: Text(
            initial,
            style: const TextStyle(color: AppColors.primaryIndigo, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
