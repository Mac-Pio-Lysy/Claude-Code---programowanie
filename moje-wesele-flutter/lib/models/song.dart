import 'package:flutter/material.dart';

/// Momenty imprezy (MUSIC_MOMENTS w zrodlo-web/script.js).
const List<String> kMusicMoments = [
  'Pierwszy taniec',
  'Wejście',
  'Oczepiny',
  'Wolne',
  'Imprezowe',
  'Inne',
];

/// Status utworu (MUSIC_STATUSES).
class MusicStatus {
  const MusicStatus(this.id, this.label, this.icon, this.color);
  final String id;
  final String label;
  final String icon;
  final Color color;

  static const proposal =
      MusicStatus('proposal', 'Propozycja', '💡', Color(0xFFF59E0B));
  static const approved =
      MusicStatus('approved', 'Zatwierdzone', '✅', Color(0xFF10B981));
  static const rejected =
      MusicStatus('rejected', 'Odrzucone', '✖️', Color(0xFFEF4444));
  static const dj =
      MusicStatus('dj', 'Do decyzji DJa', '🎧', Color(0xFF7C3AED));

  static const all = [proposal, approved, rejected, dj];

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
  String get moment => (raw['moment'] as String?) ?? 'Inne';
  String get genre => (raw['genre'] as String?) ?? '';
  String get statusId => (raw['status'] as String?) ?? 'proposal';
  bool get fromGuest => raw['fromGuest'] == true;
  String get guestName => (raw['guestName'] as String?) ?? '';
  bool get unmatched => raw['unmatched'] == true;

  MusicStatus get status => MusicStatus.byId(statusId);
}
