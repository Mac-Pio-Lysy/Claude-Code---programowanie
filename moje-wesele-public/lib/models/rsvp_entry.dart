/// Wpis potwierdzenia (RSVP) `{id, guestId, rawName, status, message, manual, companionName}`.
class RsvpEntry {
  RsvpEntry(this.raw);
  final Map<String, dynamic> raw;

  int? get id => (raw['id'] as num?)?.toInt();
  int? get guestId => (raw['guestId'] as num?)?.toInt();
  String get rawName => (raw['rawName'] as String?) ?? '';
  String get status => (raw['status'] as String?) ?? '';
  String get message => (raw['message'] as String?) ?? '';
  bool get manual => raw['manual'] == true;
  String get companionName => (raw['companionName'] as String?) ?? '';

  bool get isAttending => status == 'attending';
  bool get isNotAttending => status == 'not_attending';

  /// Nieprzypisany wpis (z publicznego formularza, bez dopasowanego gościa).
  bool get isUnmatched => guestId == null;
}
