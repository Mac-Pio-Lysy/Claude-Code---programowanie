import '../l10n/app_text.dart';
/// Status noclegu gościa.
class AccommodationStatus {
  const AccommodationStatus(this.value, this.label);
  final String value;
  final String label;

  // Gettery, nie stałe: `value` (wartość w bazie) zostaje, etykieta jest
  // tłumaczona i musi powstawać po zmianie języka na nowo.
  static AccommodationStatus get reserved =>
      AccommodationStatus('reserved', AppText.t.gs_roomReserved);
  static AccommodationStatus get pending =>
      AccommodationStatus('pending', AppText.t.gs_roomPending);
  static AccommodationStatus get self =>
      AccommodationStatus('self', AppText.t.gs_roomSelf);

  static List<AccommodationStatus> get all => [reserved, pending, self];

  static String labelOf(String? value) =>
      all.where((s) => s.value == value).map((s) => s.label).firstOrNull ??
      AppText.t.common_statusHint;
}

/// Hotel / miejsce noclegowe — nakładka na surową mapę.
class Hotel {
  Hotel(this.raw);
  final Map<String, dynamic> raw;

  int? get id => (raw['id'] as num?)?.toInt();
  String get name => (raw['name'] as String?) ?? '';
  String get address => (raw['address'] as String?) ?? '';
  String get phone => (raw['phone'] as String?) ?? '';
  double get pricePerNight => (raw['pricePerNight'] as num?)?.toDouble() ?? 0;
  int get personsPerRoom => (raw['personsPerRoom'] as num?)?.toInt() ?? 1;
  String get bookingLink => (raw['bookingLink'] as String?) ?? '';
  String get notes => (raw['notes'] as String?) ?? '';
  bool get inComplex => raw['inComplex'] == true;

  /// Koszt = cena za osobę za noc × liczba osób w pokoju (jak w wersji web).
  double get cost => pricePerNight * (personsPerRoom <= 0 ? 1 : personsPerRoom);
}
