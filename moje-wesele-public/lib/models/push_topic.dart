import '../l10n/app_text.dart';

/// Rodzaje powiadomień, które w przyszłości trafią na telefon jako PUSH.
///
/// ⚠️ To NIE dotyczy dzwoneczka w aplikacji. Centrum powiadomień działa zawsze
/// i niezależnie od tych przełączników — one sterują wyłącznie tym, o czym
/// aplikacja zawiadomi użytkownika, gdy jej nie używa.
///
/// Lista jest szersza niż typy wykryte w etapie 1a (doszły „nowa osoba"
/// i „zbliżający się termin"): preferencje mają być gotowe, zanim push ruszy,
/// żeby po jego podłączeniu nie pytać użytkownika o zgody od nowa.
enum PushTopic {
  /// Gość potwierdził albo odwołał obecność.
  rsvp,

  /// Ktoś dodał zadanie.
  tasks,

  /// Nowy albo zmieniony punkt harmonogramu.
  schedule,

  /// Do wesela dołączył planer, współorganizator albo gość.
  memberJoined,

  /// Zbliża się termin płatności albo zadania.
  deadlines;

  /// Klucz zapisu — stały, niezależny od kolejności w enumie.
  String get key => name;

  String get label => switch (this) {
        PushTopic.rsvp => AppText.t.push_rsvp,
        PushTopic.tasks => AppText.t.push_tasks,
        PushTopic.schedule => AppText.t.push_schedule,
        PushTopic.memberJoined => AppText.t.push_memberJoined,
        PushTopic.deadlines => AppText.t.push_deadlines,
      };

  String get description => switch (this) {
        PushTopic.rsvp =>
          AppText.t.push_rsvpHint,
        PushTopic.tasks => AppText.t.push_tasksHint,
        PushTopic.schedule =>
          AppText.t.push_scheduleHint,
        PushTopic.memberJoined =>
          AppText.t.push_memberJoinedHint,
        PushTopic.deadlines =>
          AppText.t.push_deadlinesHint,
      };

  String get emoji => switch (this) {
        PushTopic.rsvp => '✉',
        PushTopic.tasks => '✅',
        PushTopic.schedule => '🕒',
        PushTopic.memberJoined => '🤝',
        PushTopic.deadlines => '⏰',
      };

  /// Odczyt z zapisanego klucza; nieznana wartość → `null`.
  static PushTopic? fromKey(String key) {
    for (final t in PushTopic.values) {
      if (t.key == key) return t;
    }
    return null;
  }
}

/// Zestaw włączonych tematów push.
///
/// Domyślnie WSZYSTKIE włączone: push i tak wymaga osobnej zgody systemowej,
/// więc na tym etapie nic nikomu nie wyśle. Użytkownik, który świadomie coś
/// wyłączy, ma to zapamiętane na moment podłączenia push.
class PushPrefs {
  const PushPrefs(this.enabled);

  final Set<PushTopic> enabled;

  static final PushPrefs allOn = PushPrefs(PushTopic.values.toSet());

  bool isOn(PushTopic topic) => enabled.contains(topic);

  int get onCount => enabled.length;

  bool get allDisabled => enabled.isEmpty;

  PushPrefs withTopic(PushTopic topic, bool on) {
    final next = enabled.toSet();
    if (on) {
      next.add(topic);
    } else {
      next.remove(topic);
    }
    return PushPrefs(next);
  }

  List<String> toKeys() => [for (final t in enabled) t.key]..sort();

  /// Odczyt zapisanych kluczy. `null` (brak zapisu) → wszystko włączone.
  static PushPrefs fromKeys(List<String>? keys) {
    if (keys == null) return allOn;
    return PushPrefs({
      for (final k in keys)
        if (PushTopic.fromKey(k) != null) PushTopic.fromKey(k)!,
    });
  }
}
