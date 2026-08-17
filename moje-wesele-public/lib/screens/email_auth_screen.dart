import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';
import '../l10n/app_text.dart';

/// Który formularz jest aktualnie widoczny na ekranie logowania e-mailem.
enum _Mode { signIn, register, resetPassword }

/// Ekran logowania / rejestracji / resetu hasła kontem e-mail (obok
/// logowania Google z [LoginScreen] — osobne konta, bez łączenia).
///
/// Sam nie zna Firebase — wywołania i tłumaczenie błędów robi [AuthGate]
/// przez przekazane callbacki. Zwrot `null` z callbacku = sukces (dla
/// logowania/rejestracji ekran sam się zamyka — `AuthGate` w tym czasie
/// dostał już aktualizację z `authStateChanges()` i pokazuje panel, tak
/// jak po Google). Zwrot tekstu = błąd do pokazania na miejscu.
class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({
    super.key,
    required this.onSignIn,
    required this.onRegister,
    required this.onResetPassword,
  });

  final Future<String?> Function(String email, String password) onSignIn;
  final Future<String?> Function(String email, String password) onRegister;
  final Future<String?> Function(String email) onResetPassword;

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  _Mode _mode = _Mode.signIn;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _resetSent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _switchMode(_Mode mode) {
    setState(() {
      _mode = mode;
      _error = null;
      _resetSent = false;
    });
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return AppText.t.emailAuth_errorEmailRequired;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return AppText.t.emailAuth_errorEmailInvalid;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return AppText.t.emailAuth_errorPasswordRequired;
    if (password.length < 6) return AppText.t.emailAuth_errorPasswordTooShort;
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value != _passwordController.text) {
      return AppText.t.emailAuth_errorPasswordMismatch;
    }
    return null;
  }

  Future<void> _submit() async {
    if (_loading) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final email = _emailController.text.trim();

    if (_mode == _Mode.resetPassword) {
      final result = await widget.onResetPassword(email);
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (result == null) {
          _resetSent = true;
        } else {
          _error = result;
        }
      });
      return;
    }

    final password = _passwordController.text;
    final result = _mode == _Mode.signIn
        ? await widget.onSignIn(email, password)
        : await widget.onRegister(email, password);
    if (!mounted) return;
    if (result == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _loading = false;
      _error = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.45, 1.0],
            colors: AppColors.bgGradient,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _buildCard(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2EAF7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.14),
            blurRadius: 44,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
                color: AppColors.text,
                tooltip: AppText.t.emailAuth_backButton,
              ),
            ),
            Text(
              _title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F1F4A),
              ),
            ),
            const SizedBox(height: 20),
            if (_mode == _Mode.resetPassword && _resetSent)
              _buildResetSentBody()
            else
              _buildForm(),
            if (_error != null) ...[
              const SizedBox(height: 16),
              _ErrorBox(message: _error!),
            ],
          ],
        ),
      ),
    );
  }

  String get _title {
    switch (_mode) {
      case _Mode.signIn:
        return AppText.t.emailAuth_titleSignIn;
      case _Mode.register:
        return AppText.t.emailAuth_titleRegister;
      case _Mode.resetPassword:
        return AppText.t.emailAuth_titleReset;
    }
  }

  Widget _buildResetSentBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppText.t.emailAuth_resetSentMessage,
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.5,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 20),
        _LinkButton(
          label: AppText.t.emailAuth_backToSignIn,
          onPressed: () => _switchMode(_Mode.signIn),
        ),
      ],
    );
  }

  Widget _buildForm() {
    final isReset = _mode == _Mode.resetPassword;
    final isRegister = _mode == _Mode.register;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isReset) ...[
          Text(
            AppText.t.emailAuth_resetIntro,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          AppText.t.emailAuth_emailLabel,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _emailController,
          enabled: !_loading,
          keyboardType: TextInputType.emailAddress,
          textInputAction:
              isReset ? TextInputAction.done : TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          decoration: _inputDecoration(AppText.t.emailAuth_emailHint),
          validator: _validateEmail,
          onFieldSubmitted: isReset ? (_) => _submit() : null,
        ),
        if (!isReset) ...[
          const SizedBox(height: 16),
          Text(
            AppText.t.emailAuth_passwordLabel,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordController,
            enabled: !_loading,
            obscureText: _obscurePassword,
            textInputAction:
                isRegister ? TextInputAction.next : TextInputAction.done,
            autofillHints: [
              isRegister ? AutofillHints.newPassword : AutofillHints.password,
            ],
            decoration: _inputDecoration(null).copyWith(
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: AppColors.textLight,
                ),
                tooltip: _obscurePassword
                    ? AppText.t.emailAuth_showPassword
                    : AppText.t.emailAuth_hidePassword,
              ),
            ),
            validator: _validatePassword,
            onFieldSubmitted: !isRegister ? (_) => _submit() : null,
          ),
        ],
        if (isRegister) ...[
          const SizedBox(height: 16),
          Text(
            AppText.t.emailAuth_confirmPasswordLabel,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmController,
            enabled: !_loading,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            decoration: _inputDecoration(null).copyWith(
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: AppColors.textLight,
                ),
                tooltip: _obscureConfirm
                    ? AppText.t.emailAuth_showPassword
                    : AppText.t.emailAuth_hidePassword,
              ),
            ),
            validator: _validateConfirm,
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 10),
          Text(
            AppText.t.emailAuth_verificationNote,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textLight,
            ),
          ),
        ],
        if (_mode == _Mode.signIn) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: _LinkButton(
              label: AppText.t.emailAuth_forgotPassword,
              onPressed: () => _switchMode(_Mode.resetPassword),
            ),
          ),
        ],
        const SizedBox(height: 12),
        _SubmitButton(isLoading: _loading, onPressed: _submit, label: _submitLabel),
        const SizedBox(height: 18),
        if (_mode == _Mode.signIn)
          _LinkButton(
            label: AppText.t.emailAuth_switchToRegister,
            onPressed: () => _switchMode(_Mode.register),
          )
        else if (isRegister)
          _LinkButton(
            label: AppText.t.emailAuth_switchToSignIn,
            onPressed: () => _switchMode(_Mode.signIn),
          )
        else
          _LinkButton(
            label: AppText.t.emailAuth_backToSignIn,
            onPressed: () => _switchMode(_Mode.signIn),
          ),
      ],
    );
  }

  String get _submitLabel {
    switch (_mode) {
      case _Mode.signIn:
        return AppText.t.emailAuth_submitSignIn;
      case _Mode.register:
        return AppText.t.emailAuth_submitRegister;
      case _Mode.resetPassword:
        return AppText.t.emailAuth_submitReset;
    }
  }

  InputDecoration _inputDecoration(String? hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF8FAFF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDCE4F2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDCE4F2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFCA5A5)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC0392B), width: 2),
        ),
      );
}

/// Główny przycisk formularza — akcentowy gradient, spinner podczas ładowania.
class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.isLoading,
    required this.onPressed,
    required this.label,
  });

  final bool isLoading;
  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.accent, AppColors.accent2],
            ),
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Prosty przycisk-link (zmiana trybu, „zapomniałem hasła" itp.).
class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.accent,
        ),
      ),
    );
  }
}

/// Ramka komunikatu błędu — jak w [LoginScreen].
class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
      ),
      child: Text(
        message,
        style: GoogleFonts.inter(
          fontSize: 13,
          height: 1.5,
          color: const Color(0xFFC0392B),
        ),
      ),
    );
  }
}
