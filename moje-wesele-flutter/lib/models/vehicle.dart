/// Typy pojazdów (VEHICLE_TYPES) — podpowiedzi; pole „typ" jest wolnym tekstem,
/// więc można wpisać własną nazwę (np. „Pojazd Kuby", „Bus wynajęty").
const List<String> kVehicleTypes = [
  'Auto wynajęte',
  'Auto własne',
  'Auto rodziców Pana Młodego',
  'Auto rodziców Panny Młodej',
  'Bus',
  'Taxi/Uber',
  'Inne',
];

/// Pojazd transportu — nakładka na surową mapę.
class Vehicle {
  Vehicle(this.raw);
  final Map<String, dynamic> raw;

  int? get id => (raw['id'] as num?)?.toInt();
  String get type => (raw['type'] as String?) ?? '';
  String get description => (raw['description'] as String?) ?? '';
  String get driver => (raw['driver'] as String?) ?? '';
  int get seats => (raw['seats'] as num?)?.toInt() ?? 0;
  String get route => (raw['route'] as String?) ?? '';
  String get departureTime => (raw['departureTime'] as String?) ?? '';
  double get cost => (raw['cost'] as num?)?.toDouble() ?? 0;

  List<int> get guestIds {
    final v = raw['guestIds'];
    return v is List
        ? v.map((e) => (e as num?)?.toInt()).whereType<int>().toList()
        : <int>[];
  }

  int get occupied => guestIds.length;
  int get freeSeats {
    final f = seats - occupied;
    return f < 0 ? 0 : f;
  }

  bool get isFull => occupied >= seats;
}

/// Transport wewnętrzny (Bolt/Taxi/inne) `{id, type, info, showToGuests}`.
class InternalTransport {
  InternalTransport(this.raw);
  final Map<String, dynamic> raw;

  int? get id => (raw['id'] as num?)?.toInt();
  String get type => (raw['type'] as String?) ?? '';
  String get info => (raw['info'] as String?) ?? '';
  bool get showToGuests => raw['showToGuests'] == true;
}
