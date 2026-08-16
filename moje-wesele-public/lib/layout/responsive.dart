import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_text.dart';

/// Tryb wyświetlania wybrany przez użytkownika w Ustawieniach.
enum DisplayMode {
  /// Domyślny — układ dobierany po szerokości ekranu.
  auto,

  /// Zawsze układ telefonowy (dolny pasek, dwie kolumny w siatkach).
  phone,

  /// Zawsze układ tabletowy (boczna szyna, więcej kolumn).
  tablet;

  String get label => switch (this) {
        DisplayMode.auto => 'Automatyczny',
        DisplayMode.phone => AppText.t.layout_forcePhone,
        DisplayMode.tablet => AppText.t.layout_forceTablet,
      };

  String get hint => switch (this) {
        DisplayMode.auto => AppText.t.layout_autoHint,
        DisplayMode.phone => AppText.t.layout_phoneHint,
        DisplayMode.tablet => AppText.t.layout_tabletHint,
      };
}

/// Szerokość, od której układ uznajemy za tabletowy (tryb automatyczny).
const double kTabletBreakpoint = 720;

/// Szerokość, od której warto pokazać maksymalną liczbę kolumn.
const double kWideBreakpoint = 1100;

/// Maksymalna szerokość kolumny treści — na szerokim ekranie nie rozciągamy
/// tekstu i formularzy przez cały ekran, bo wiersze robią się nieczytelne.
const double kContentMaxWidth = 1180;

/// Maksymalna szerokość formularza / okna modalnego na dużym ekranie.
const double kFormMaxWidth = 640;

/// Maksymalna szerokość arkusza dolnego (`showModalBottomSheet`).
///
/// Na telefonie ograniczenie nie ma znaczenia — arkusz i tak jest węższy.
/// Na tablecie bez tego formularz rozciągałby się na całą szerokość ekranu,
/// a pola tekstowe miałyby po kilkadziesiąt centymetrów.
const double kSheetMaxWidth = 720;

/// Globalny wybór trybu wyświetlania — zapisywany per użytkownik.
///
/// Trzymany jako [ValueNotifier], żeby zmiana w Ustawieniach natychmiast
/// przebudowała całą aplikację (nasłuch jest w korzeniu drzewa widoków).
/// Wzorzec taki sam jak `ActiveWedding` — globalny holder bez wstrzykiwania
/// przez wszystkie konstruktory.
class DisplayModeController {
  DisplayModeController._();

  static final ValueNotifier<DisplayMode> mode =
      ValueNotifier(DisplayMode.auto);

  static String _keyFor(String uid) => 'display_mode_$uid';

  /// Wczytuje zapisany wybór użytkownika (po zalogowaniu / wejściu w wesele).
  static Future<void> load(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_keyFor(uid));
    mode.value = DisplayMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => DisplayMode.auto,
    );
  }

  /// Zapisuje wybór i natychmiast go stosuje.
  static Future<void> set(String uid, DisplayMode value) async {
    mode.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFor(uid), value.name);
  }
}

/// Czy stosować układ tabletowy — z uwzględnieniem wymuszenia z Ustawień.
///
/// To JEDYNE miejsce, w którym zapada ta decyzja. Ekrany nie porównują już
/// szerokości samodzielnie, więc „Wymuś telefon/tablet" działa wszędzie tak
/// samo.
bool isTabletLayout(BuildContext context) => switch (DisplayModeController.mode.value) {
      DisplayMode.phone => false,
      DisplayMode.tablet => true,
      DisplayMode.auto =>
        MediaQuery.sizeOf(context).width >= kTabletBreakpoint,
    };

/// Liczba kolumn siatki dobrana do szerokości i trybu.
///
/// W trybie automatycznym decyduje sama szerokość. „Wymuś telefon" zawsze daje
/// [phone]. „Wymuś tablet" gwarantuje co najmniej [tablet] — nawet na wąskim
/// ekranie, bo taka była świadoma decyzja użytkownika.
int gridColumns(
  BuildContext context, {
  int phone = 2,
  int tablet = 3,
  int wide = 4,
}) {
  final m = DisplayModeController.mode.value;
  if (m == DisplayMode.phone) return phone;

  final w = MediaQuery.sizeOf(context).width;
  final auto = w >= kWideBreakpoint
      ? wide
      : (w >= kTabletBreakpoint ? tablet : phone);

  if (m == DisplayMode.tablet && auto < tablet) return tablet;
  return auto;
}

/// Ogranicza szerokość treści i wyśrodkowuje ją na dużym ekranie.
///
/// Bez tego układ telefonowy „rozjeżdża się" na tablecie: karty ciągną się
/// przez cały ekran, a wiersze tekstu stają się nieczytelnie długie.
class ContentWidth extends StatelessWidget {
  const ContentWidth({
    super.key,
    required this.child,
    this.maxWidth = kContentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}

/// Wersja [ContentWidth] dla formularzy i okien modalnych (węższa).
class FormWidth extends StatelessWidget {
  const FormWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      ContentWidth(maxWidth: kFormMaxWidth, child: child);
}
