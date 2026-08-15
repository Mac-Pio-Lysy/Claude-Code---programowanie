import 'package:flutter/material.dart';

import '../app_colors.dart';
import 'app_localizations.dart';
import 'locale_controller.dart';

/// Nazwa języka na liście — TŁUMACZONA, więc po angielsku widać „Polish",
/// a po polsku „Polski". Wspólna dla Ustawień i strefy gości.
String languageName(AppLocalizations t, String code) => switch (code) {
      'pl' => t.language_pl,
      'en' => t.language_en,
      _ => code.toUpperCase(),
    };

/// Globus w nagłówku STREFY GOŚCIA — jedyny sposób, w jaki gość zmienia język.
///
/// Gość wchodzi z linku/QR, nie ma konta ani ekranu Ustawień, więc wybór nie
/// może wisieć pod `uid`. Zapis idzie pod wspólny klucz `locale_guest`
/// ([LocaleController.setGuest]), czyli na webie do `localStorage`.
///
/// Bez zapisu obowiązuje język przeglądarki, a przy nieobsługiwanym —
/// polski ([LocaleController.fallback]). Dlatego pozycja „jak w systemie"
/// jest tu pełnoprawnym wyborem, a nie tylko wartością startową.
class GuestLanguageButton extends StatelessWidget {
  const GuestLanguageButton({super.key});

  /// Wartość menu dla „jak w przeglądarce". Nie koliduje z kodem języka.
  static const String _system = '__system';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ValueListenableBuilder<Locale?>(
      valueListenable: LocaleController.locale,
      builder: (context, current, _) => PopupMenuButton<String>(
        tooltip: t.gw_language,
        icon: const Icon(Icons.language, size: 20, color: AppColors.accent),
        onSelected: (code) => LocaleController.setGuest(
            code == _system ? null : Locale(code)),
        itemBuilder: (context) => [
          _item(_system, t.settings_languageSystem, current == null),
          for (final locale in LocaleController.supported)
            _item(
              locale.languageCode,
              languageName(t, locale.languageCode),
              current?.languageCode == locale.languageCode,
            ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _item(String value, String label, bool selected) =>
      PopupMenuItem<String>(
        value: value,
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: selected ? AppColors.accent : AppColors.textLight,
            ),
            const SizedBox(width: 10),
            Text(label),
          ],
        ),
      );
}
