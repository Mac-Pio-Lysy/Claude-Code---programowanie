import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Pojedyncza kopia zapasowa (lokalna).
class Backup {
  Backup(this.timestamp, this.json);
  final DateTime timestamp;
  final String json;
}

/// Lokalne kopie zapasowe danych (3 ostatnie) — przechowywane na urządzeniu
/// przez shared_preferences (odpowiednik kopii w localStorage w wersji web).
class BackupService {
  static const _key = 'mojewesele_backups';
  static const _maxBackups = 3;

  Future<List<Backup>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    return raw.map((s) {
      final m = jsonDecode(s) as Map<String, dynamic>;
      return Backup(
        DateTime.fromMillisecondsSinceEpoch((m['ts'] as num).toInt()),
        m['data'] as String,
      );
    }).toList();
  }

  /// Tworzy nową kopię (zachowuje maks. [_maxBackups] najnowszych).
  Future<void> create(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? <String>[];
    final entry = jsonEncode({
      'ts': DateTime.now().millisecondsSinceEpoch,
      'data': jsonEncode(data),
    });
    raw.insert(0, entry);
    while (raw.length > _maxBackups) {
      raw.removeLast();
    }
    await prefs.setStringList(_key, raw);
  }

  Future<Map<String, dynamic>> decode(Backup backup) async =>
      jsonDecode(backup.json) as Map<String, dynamic>;
}
