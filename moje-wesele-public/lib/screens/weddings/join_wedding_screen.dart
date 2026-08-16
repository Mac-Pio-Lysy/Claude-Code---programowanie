import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../services/wedding_service.dart';
import 'qr_scan_screen.dart';
import '../../utils/app_format.dart';
import '../../l10n/app_text.dart';
import '../../models/join_code.dart';

/// Ekran „Dołącz do wesela" — gość podaje kod, datę i nazwisko Państwa Młodych.
/// Po pomyślnej potrójnej weryfikacji zostaje dodany jako GOŚĆ.
///
/// Zwraca `weddingId` (String) przez `Navigator.pop`, gdy dołączono/już należy;
/// `null`, gdy anulowano.
class JoinWeddingScreen extends StatefulWidget {
  const JoinWeddingScreen({super.key, required this.userId});

  final String userId;

  @override
  State<JoinWeddingScreen> createState() => _JoinWeddingScreenState();
}

class _JoinWeddingScreenState extends State<JoinWeddingScreen> {
  final WeddingService _weddings = WeddingService();
  final _codeCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  DateTime? _date;

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _surnameCtrl.dispose();
    super.dispose();
  }

  Future<void> _scanQr() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrScanScreen()),
    );
    if (code != null && code.trim().isNotEmpty) {
      setState(() => _codeCtrl.text = JoinCode.normalize(code));
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 10),
      helpText: AppText.t.settings_weddingDate,
      cancelText: AppText.t.common_cancel,
      confirmText: AppText.t.common_select,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    final code = _codeCtrl.text.trim();
    final surname = _surnameCtrl.text.trim();
    if (code.isEmpty || _date == null || surname.isEmpty) {
      setState(() => _error = AppText.t.jw_fillAll);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });

    final dateStr = '${_date!.year.toString().padLeft(4, '0')}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}';

    final result = await _weddings.joinAsGuest(
      userId: widget.userId,
      code: code,
      date: dateStr,
      surname: surname,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    switch (result.outcome) {
      case JoinOutcome.success:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              content: Text(AppText.t.jw_joined)));
        Navigator.of(context).pop(result.weddingId);
      case JoinOutcome.alreadyMember:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              content: Text(AppText.t.jw_alreadyMember)));
        Navigator.of(context).pop(result.weddingId);
      case JoinOutcome.invalid:
        setState(() => _error = AppText.t.jw_badData);
      case JoinOutcome.error:
        setState(() => _error = AppText.t.jw_connectionError);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGradient.last,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        title: Text(
          AppText.t.jw_title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.45, 1.0],
            colors: AppColors.bgGradient,
          ),
        ),
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              _infoCard(),
              const SizedBox(height: 18),
              _label(AppText.t.settings_weddingCode),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        UpperCaseFormatter(),
                        LengthLimitingTextInputFormatter(JoinCode.length + 4),
                      ],
                      style: GoogleFonts.robotoMono(
                          fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 2),
                      decoration: _dec(AppText.t.jw_codeHint),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _scanQr,
                      icon: const Icon(Icons.qr_code_scanner, size: 20),
                      label: Text(AppText.t.jw_scan),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        side: const BorderSide(color: AppColors.accent),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _label(AppText.t.settings_weddingDate),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: _dec(''),
                  child: Row(
                    children: [
                      const Icon(Icons.event, size: 20, color: AppColors.accent),
                      const SizedBox(width: 10),
                      Text(
                        _date == null ? AppText.t.people_pickDate : _dateLabel(_date!),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color:
                              _date == null ? AppColors.textLight : AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _label(AppText.t.settings_coupleSurname),
              const SizedBox(height: 6),
              TextField(
                controller: _surnameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _dec(AppText.t.jw_surnameHint),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                _errorBox(_error!),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    _submitting ? AppText.t.jw_checking : AppText.t.jw_title,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withValues(alpha: 0.10),
            AppColors.accent2.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E4FB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppText.t.jw_intro,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.45,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: Color(0xFFC0392B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                  fontSize: 13, height: 1.4, color: const Color(0xFFC0392B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
      );

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: AppColors.textLight, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF8FAFF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDCE4F2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      );

  static String _dateLabel(DateTime date) =>
      AppFormat.dateLong(date);
}

/// Zamienia wpisywany tekst na WIELKIE litery (kod wesela).
class UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
