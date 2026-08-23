import '../l10n/app_text.dart';
import 'couple.dart';

/// Typy pojazdów (VEHICLE_TYPES) — podpowiedzi; pole „typ" jest wolnym tekstem,
/// więc można wpisać własną nazwę (np. „Pojazd Kuby", „Bus wynajęty").
///
/// Getter, a nie stała, bo pozycje „auto rodziców" zależą od typu uroczystości
/// (patrz [CoupleLabels]) i od języka.
///
/// Frazy z osobą są PEŁNYMI kluczami, nie sklejeniem przedrostka z rolą:
/// polski wymaga tu dopełniacza („Auto rodziców Panny Młodej"), a angielski
/// dzierżawczego („Bride's parents' car") — takiej konstrukcji nie da się
/// złożyć z kawałków w sposób przenośny między językami.
List<String> get kVehicleTypes {
  final labels = CoupleLabels.current;
  return [
    AppText.t.vehicle_rented,
    AppText.t.vehicle_own,
    labels.usesNames
        ? AppText.t.vehicle_parentsNamed(labels.personPlain(2))
        : AppText.t.vehicle_parentsGroom,
    labels.usesNames
        ? AppText.t.vehicle_parentsNamed(labels.personPlain(1))
        : AppText.t.vehicle_parentsBride,
    AppText.t.vehicle_bus,
    AppText.t.vehicle_taxi,
    AppText.t.vehicle_other,
  ];
}

/// Przeznaczenie pojazdu (DO CZEGO służy) — niezależne od [Vehicle.type]
/// (CZYJ/jaki to pojazd: wynajęty/własny/auto rodziców itd.). Opcjonalne;
/// puste pole traktujemy jak [other] (patrz [Vehicle.purposeOrFallback]).
List<String> get kVehiclePurposes => [
      AppText.t.vehicle_purposeChurch,
      AppText.t.vehicle_purposeCouple,
      AppText.t.vehicle_purposeReception,
      AppText.t.vehicle_purposeOther,
    ];

/// Pojazd transportu — nakładka na surową mapę.
class Vehicle {
  Vehicle(this.raw);
  final Map<String, dynamic> raw;

  int? get id => (raw['id'] as num?)?.toInt();
  String get type => (raw['type'] as String?) ?? '';

  /// Przeznaczenie — wolny tekst (jak [type]), opcjonalne. Puste → `''`;
  /// do pokazania użytkownikowi patrz [purposeOrFallback].
  String get purpose => (raw['purpose'] as String?) ?? '';

  /// Przeznaczenie do WYŚWIETLENIA — puste pole pokazujemy jako „Inny",
  /// zamiast zostawiać pustkę na karcie pojazdu.
  String get purposeOrFallback =>
      purpose.isEmpty ? AppText.t.vehicle_purposeOther : purpose;

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
