import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/app_text.dart';
import 'couple.dart';

/// Momenty imprezy (MUSIC_MOMENTS w zrodlo-web/script.js) — luźna kategoria
/// utworu (do filtrów). NIE mylić z „utworami specjalnymi" (kluczowe momenty).
///
/// Getter, bo etykiety są tłumaczone. Wartość zapisana przy utworze zostaje
/// taka, jaka była w chwili zapisu — nie migrujemy danych pary.
List<String> get kMusicMoments => [
      AppText.t.musicMoment_firstDance,
      AppText.t.musicMoment_entrance,
      AppText.t.musicMoment_games,
      AppText.t.musicMoment_slow,
      AppText.t.musicMoment_party,
      AppText.t.musicMoment_other,
    ];

/// Domyślne „kluczowe momenty" wesela dla utworów specjalnych (kolejność =
/// chronologia). Konfigurowalne: zapisane w top-level `specialMoments`.
List<String> get kDefaultSpecialMoments => [
      AppText.t.specialMoment_firstDance,
      AppText.t.specialMoment_firstSong,
      AppText.t.specialMoment_coupleEntrance,
      AppText.t.specialMoment_cake,
      AppText.t.specialMoment_games,
      AppText.t.specialMoment_lastDance,
      AppText.t.specialMoment_toast,
    ];

/// Kluczowy moment → jego ikona, opisane raz dla wszystkich języków.
///
/// `name` wyciąga etykietę z DOWOLNEGO zestawu tłumaczeń, `icon` daje ikonę.
const List<({String Function(AppLocalizations t) name, String icon})>
    _specialMomentIcons = [
  (name: _firstDance, icon: '💃'),
  (name: _firstSong, icon: '🎵'),
  (name: _coupleEntrance, icon: ''), // ikona zależy od typu pary — niżej
  (name: _cake, icon: '🎂'),
  (name: _games, icon: '🎉'),
  (name: _lastDance, icon: '🌙'),
  (name: _toast, icon: '🥂'),
];

String _firstDance(AppLocalizations t) => t.specialMoment_firstDance;
String _firstSong(AppLocalizations t) => t.specialMoment_firstSong;
String _coupleEntrance(AppLocalizations t) => t.specialMoment_coupleEntrance;
String _cake(AppLocalizations t) => t.specialMoment_cake;
String _games(AppLocalizations t) => t.specialMoment_games;
String _lastDance(AppLocalizations t) => t.specialMoment_lastDance;
String _toast(AppLocalizations t) => t.specialMoment_toast;

/// Ikona kluczowego momentu (fallback ⭐ dla własnych etykiet).
///
/// ⚠️ Dopasowanie idzie po WSZYSTKICH obsługiwanych językach, a nie tylko po
/// bieżącym. Nazwa momentu jest ZAPISANA w bazie w języku, w którym zakładano
/// wesele — wesele polskie ma „Tort", angielskie „Cake". Gdyby sprawdzać sam
/// język interfejsu, po jego przełączeniu wszystkie momenty spadłyby do ⭐.
/// Kolejny język dokłada się sam, razem z plikiem `.arb`
/// (patrz [AppText.allLocales]).
String specialMomentIcon(String label) {
  final needle = label.trim().toLowerCase();
  if (needle.isEmpty) return '⭐';
  for (final t in AppText.allLocales) {
    for (final m in _specialMomentIcons) {
      if (m.name(t).trim().toLowerCase() != needle) continue;
      // Wejście Pary Młodej ma ikonę zależną od typu uroczystości.
      return m.name == _coupleEntrance
          ? CoupleLabels.current.coupleEmoji
          : m.icon;
    }
  }
  return '⭐';
}

/// Lista kluczowych momentów z konfiguracji (`specialMoments`) lub domyślna.
List<String> resolveSpecialMoments(Map<String, dynamic> raw) {
  final v = raw['specialMoments'];
  if (v is List) {
    final list = v
        .map((e) => e?.toString() ?? '')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (list.isNotEmpty) return list;
  }
  return kDefaultSpecialMoments;
}

/// Status utworu (MUSIC_STATUSES).
class MusicStatus {
  const MusicStatus(this.id, this.label, this.icon, this.color);
  final String id;
  final String label;
  final String icon;
  final Color color;

  // Gettery, nie stałe: `id` (wartość w bazie) zostaje, etykieta jest
  // tłumaczona i musi powstawać po każdej zmianie języka na nowo.
  static MusicStatus get proposal => MusicStatus(
      'proposal', AppText.t.musicStatus_proposal, '💡', const Color(0xFFF59E0B));
  static MusicStatus get approved => MusicStatus(
      'approved', AppText.t.musicStatus_approved, '✅', const Color(0xFF10B981));
  static MusicStatus get rejected => MusicStatus(
      'rejected', AppText.t.musicStatus_rejected, '✖️', const Color(0xFFEF4444));
  static MusicStatus get dj => MusicStatus(
      'dj', AppText.t.musicStatus_dj, '🎧', const Color(0xFF7C3AED));

  static List<MusicStatus> get all => [proposal, approved, rejected, dj];

  static MusicStatus byId(String? id) =>
      all.firstWhere((s) => s.id == id, orElse: () => proposal);
}

/// Utwór muzyczny — nakładka na surową mapę.
/// `{id, title, artist, cover, preview, moment, genre, status, fromGuest, guestName, unmatched}`
class Song {
  Song(this.raw);
  final Map<String, dynamic> raw;

  int? get id => (raw['id'] as num?)?.toInt();
  String get title => (raw['title'] as String?) ?? '';
  String get artist => (raw['artist'] as String?) ?? '';
  String get cover => (raw['cover'] as String?) ?? '';
  String get preview => (raw['preview'] as String?) ?? '';
  String get moment =>
      (raw['moment'] as String?) ?? AppText.t.musicMoment_other;
  String get genre => (raw['genre'] as String?) ?? '';
  String get statusId => (raw['status'] as String?) ?? 'proposal';
  bool get fromGuest => raw['fromGuest'] == true;
  String get guestName => (raw['guestName'] as String?) ?? '';
  bool get unmatched => raw['unmatched'] == true;

  /// Kluczowy moment wesela (etykieta) — '' gdy utwór nie jest specjalny.
  String get specialMoment => (raw['specialMoment'] as String?)?.trim() ?? '';
  bool get isSpecial => specialMoment.isNotEmpty;

  MusicStatus get status => MusicStatus.byId(statusId);
}
