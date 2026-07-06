import 'dart:math';

import 'wedding_data.dart';

/// Pole bazy bingo `{id, text, enabled}`.
class BingoField {
  BingoField(this.raw);
  final Map<String, dynamic> raw;

  int? get id => (raw['id'] as num?)?.toInt();
  String get text => (raw['text'] as String?) ?? '';
  bool get enabled => raw['enabled'] == true;
}

/// Generowanie puli i plansz bingo (odwzorowane z zrodlo-web/script.js).
class BingoEngine {
  BingoEngine._();

  /// Pełna pula tekstów: włączone pola statyczne + dynamiczne z harmonogramu,
  /// bez duplikatów.
  static List<String> pool(WeddingData? data) {
    final raw = data?.raw ?? const {};
    final seen = <String>{};
    final pool = <String>[];
    void add(String t) {
      final txt = t.trim();
      final key = txt.toLowerCase();
      if (txt.isNotEmpty && !seen.contains(key)) {
        seen.add(key);
        pool.add(txt);
      }
    }

    final fields = raw['bingoFields'];
    if (fields is List) {
      for (final f in fields) {
        if (f is Map && f['enabled'] == true) add((f['text'] as String?) ?? '');
      }
    }

    final useSchedule = raw['bingoUseSchedule'] != false; // domyślnie true
    if (useSchedule) {
      final exclude = _excludeSet(raw['bingoScheduleExclude']);
      final events = raw['scheduleEvents'];
      if (events is List) {
        for (final e in events) {
          if (e is! Map || e['private'] == true) continue;
          final name = (e['name'] as String?)?.trim() ?? '';
          final id = (e['id'] as num?)?.toInt();
          if (name.isEmpty || (id != null && exclude.contains(id))) continue;
          add('Bądź obecny/a na: $name');
        }
      }
    }
    return pool;
  }

  /// Środkowe pole planszy: „GRATIS" lub imiona Pary Młodej.
  static String centerLabel(WeddingData? data) {
    final raw = data?.raw ?? const {};
    if (raw['bingoCenterMode'] == 'names') {
      final bd = raw['budgetData'];
      final couple =
          (bd is Map && bd['coupleNames'] is List) ? bd['coupleNames'] as List : const [];
      String real(dynamic v) {
        final s = (v?.toString() ?? '').trim();
        return (s.isNotEmpty && s != 'Osoba 1' && s != 'Osoba 2') ? s : '';
      }

      final names = [
        real(couple.length > 1 ? couple[1] : null),
        real(couple.isNotEmpty ? couple[0] : null),
      ].where((s) => s.isNotEmpty).join(' & ');
      return names.isEmpty ? 'GRATIS' : names;
    }
    return 'GRATIS';
  }

  /// Losuje unikalny układ 24 pól (środek to pole darmowe).
  static List<String> generateBoard(List<String> pool, Random rng) {
    final a = [...pool];
    a.shuffle(rng);
    return a.take(24).toList();
  }

  static Set<int> _excludeSet(dynamic v) => v is List
      ? v.map((e) => (e as num?)?.toInt()).whereType<int>().toSet()
      : <int>{};
}
