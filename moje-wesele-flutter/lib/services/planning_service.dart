import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/planning_step.dart';
import 'firestore_service.dart';

/// Operacje na liście „Od czego zacząć?" (`planningSteps`). Dane współdzielone
/// z wersją web i drugą osobą z pary — zapis przez `merge` (jak inne sekcje).
class PlanningService {
  PlanningService({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService();

  final FirestoreService _firestore;

  /// Odczytuje kroki z surowych danych wesela; gdy brak — zwraca domyślną listę.
  static List<PlanningStep> fromRaw(Map<String, dynamic>? raw) {
    final list = raw?['planningSteps'];
    if (list is List && list.isNotEmpty) {
      return [
        for (final e in list)
          if (e is Map) PlanningStep.fromMap(e),
      ];
    }
    return PlanningStep.defaultList();
  }

  /// Zapisuje całą listę kroków (scala z dokumentem wesela).
  Future<void> save(List<PlanningStep> steps) => _firestore.mainDoc.set(
        {'planningSteps': [for (final s in steps) s.toMap()]},
        SetOptions(merge: true),
      );
}
