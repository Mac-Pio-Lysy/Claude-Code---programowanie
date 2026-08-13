import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/push_topic.dart';
import '../../services/notification_service.dart';

/// Zakładka „Powiadomienia" (sekcja Ustawienia).
///
/// Ekran dotyczy WYŁĄCZNIE przyszłych powiadomień push na telefon. Dzwoneczek
/// w aplikacji działa zawsze i nie zależy od tych przełączników — jest to
/// powiedziane wprost w dwóch miejscach, bo to najłatwiejsze do pomylenia.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key, required this.uid});

  final String uid;

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late final PushPrefsService _service = PushPrefsService(uid: widget.uid);

  PushPrefs? _prefs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await _service.load();
    if (mounted) setState(() => _prefs = prefs);
  }

  Future<void> _toggle(PushTopic topic, bool on) async {
    // Optymistycznie — przełącznik ma reagować od razu, a zapis lokalny
    // nie zawodzi w praktyce.
    setState(() => _prefs = _prefs!.withTopic(topic, on));
    await _service.toggle(topic, on);
  }

  @override
  Widget build(BuildContext context) {
    final prefs = _prefs;
    return Scaffold(
      backgroundColor: AppColors.bgGradient.last,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.text),
        title: Text(
          'Powiadomienia',
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
            colors: AppColors.bgGradient,
          ),
        ),
        child: prefs == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  _soonBanner(),
                  const SizedBox(height: 12),
                  _bellAlwaysOnCard(),
                  const SizedBox(height: 16),
                  _sectionLabel('Wyślij mi push, gdy:'),
                  for (final topic in PushTopic.values)
                    _topicTile(topic, prefs.isOn(topic)),
                  if (prefs.allDisabled) ...[
                    const SizedBox(height: 4),
                    _allOffHint(),
                  ],
                ],
              ),
      ),
    );
  }

  /// Baner „wkrótce" — użytkownik musi wiedzieć, że przełączniki zapisują
  /// wybór na przyszłość, a nie włączają działającą funkcję.
  Widget _soonBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCD9A6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⏳', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Powiadomienia na telefon — wkrótce',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF7C4A03),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Push jeszcze nie działa — wymaga włączenia powiadomień '
                  'systemowych i uruchomienia usługi po naszej stronie. '
                  'Twój wybór zapisujemy już teraz, więc po włączeniu push '
                  'wszystko zadziała bez ponownego ustawiania.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    height: 1.45,
                    color: const Color(0xFF7C4A03),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Rozróżnienie dzwoneczek ↔ push. Bez tego użytkownik wyłączyłby
  /// przełączniki i zdziwił się, że dzwoneczek nadal liczy.
  Widget _bellAlwaysOnCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.notifications_active_outlined,
            size: 20,
            color: AppColors.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dzwoneczek w aplikacji działa zawsze',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Centrum powiadomień w prawym górnym rogu pokazuje zmiany '
                  'niezależnie od poniższych ustawień. Te przełączniki '
                  'dotyczą wyłącznie powiadomień wysyłanych na telefon, gdy '
                  'nie korzystasz z aplikacji.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.45,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textLight,
      ),
    ),
  );

  Widget _topicTile(PushTopic topic, bool on) {
    // Tło daje Material, a nie Container — inaczej ListTile rysuje efekt
    // dotknięcia pod spodem i staje się on niewidoczny.
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE2EAF7)),
        ),
        clipBehavior: Clip.antiAlias,
        child: SwitchListTile.adaptive(
          contentPadding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
          activeThumbColor: AppColors.accent,
          title: Row(
            children: [
              Text(topic.emoji, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  topic.label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2, left: 23),
            child: Text(
              topic.description,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                height: 1.4,
                color: AppColors.textLight,
              ),
            ),
          ),
          value: on,
          onChanged: (v) => _toggle(topic, v),
        ),
      ),
    );
  }

  Widget _allOffHint() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Text(
      'Wszystko wyłączone — po uruchomieniu push nie dostaniesz żadnego '
      'powiadomienia na telefon. Dzwoneczek w aplikacji nadal będzie '
      'działał.',
      style: GoogleFonts.inter(
        fontSize: 11.5,
        height: 1.4,
        color: AppColors.textLight,
      ),
    ),
  );
}
