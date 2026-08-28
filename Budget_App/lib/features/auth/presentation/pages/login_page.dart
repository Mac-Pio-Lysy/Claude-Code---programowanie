import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// AB-2: SSO + email/password at the top, the app logo as subtle branding
/// *below* the login options, and a guest/demo entry point at the bottom.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUpMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitEmailForm(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    context.read<AuthBloc>().add(
          _isSignUpMode
              ? SignUpWithEmail(email: email, password: password)
              : SignInWithEmail(email: email, password: password),
        );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: BlocConsumer<AuthBloc, AuthState>(
                  listener: (context, state) {
                    if (state is AuthFailure) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(content: Text(state.message)));
                    }
                  },
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GlassCard(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  _isSignUpMode ? 'Zarejestruj się' : 'Zaloguj się',
                                  style: textTheme.titleLarge,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                OutlinedButton.icon(
                                  onPressed: isLoading
                                      ? null
                                      : () => context.read<AuthBloc>().add(const SignInWithGoogle()),
                                  icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
                                  label: const Text('Kontynuuj z Google'),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: isLoading
                                      ? null
                                      : () => context.read<AuthBloc>().add(const SignInWithApple()),
                                  icon: const Icon(Icons.apple_rounded, size: 22),
                                  label: const Text('Kontynuuj z Apple ID'),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    const Expanded(child: Divider()),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text('lub e-mailem', style: textTheme.labelSmall),
                                    ),
                                    const Expanded(child: Divider()),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(labelText: 'E-mail'),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty) ? 'Podaj e-mail' : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  decoration: const InputDecoration(labelText: 'Hasło'),
                                  validator: (v) =>
                                      (v == null || v.isEmpty) ? 'Podaj hasło' : null,
                                  onFieldSubmitted: (_) => _submitEmailForm(context),
                                ),
                                const SizedBox(height: 16),
                                FilledButton(
                                  onPressed: isLoading ? null : () => _submitEmailForm(context),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : Text(_isSignUpMode ? 'Zarejestruj się' : 'Zaloguj się'),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: isLoading
                                      ? null
                                      : () => setState(() => _isSignUpMode = !_isSignUpMode),
                                  child: Text(
                                    _isSignUpMode
                                        ? 'Masz już konto? Zaloguj się'
                                        : 'Nie masz konta? Zarejestruj się',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        // AB-2: logo appears below the login options, as
                        // subtle branding rather than a hero element.
                        Opacity(
                          opacity: 0.85,
                          child: Column(
                            children: [
                              const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: AppColors.pureWhite,
                                size: 28,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                AppConstants.appName,
                                style: textTheme.labelLarge?.copyWith(color: AppColors.pureWhite),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () => context.read<AuthBloc>().add(const SignInAsGuest()),
                          style: TextButton.styleFrom(foregroundColor: AppColors.pureWhite),
                          child: const Text('Kontynuuj jako gość (Demo / Tryb testowy)'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
