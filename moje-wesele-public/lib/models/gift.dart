import '../l10n/app_text.dart';

/// Prezent otrzymany `{id, from, description, value, thanked}`.
class Gift {
  Gift(this.raw);
  final Map<String, dynamic> raw;

  int? get id => (raw['id'] as num?)?.toInt();
  String get from => (raw['from'] as String?) ?? '';
  String get description => (raw['description'] as String?) ?? '';
  double? get value => (raw['value'] as num?)?.toDouble();
  bool get thanked => raw['thanked'] == true;
}

/// Kategoria odbiorców upominków (GIFT_GUEST_CATS).
class GiftGuestCat {
  const GiftGuestCat(this.key, this.label, this.icon);
  final String key;
  final String label;
  final String icon;

  // Getter, nie stała: etykiety są tłumaczone.
  static List<GiftGuestCat> get all => [
    GiftGuestCat('guests', AppText.t.giftCat_guests, '🎁'),
    GiftGuestCat('witnesses', AppText.t.giftCat_witnesses, '🤝'),
    GiftGuestCat('parents', AppText.t.giftCat_parents, '👪'),
    GiftGuestCat('distinction', AppText.t.giftCat_distinction, '⭐'),
  ];
}

/// Upominek dla gości `{id, category, name, qty, cost, guestIds[]}`.
class GiftForGuest {
  GiftForGuest(this.raw);
  final Map<String, dynamic> raw;

  int? get id => (raw['id'] as num?)?.toInt();
  String get category => (raw['category'] as String?) ?? 'guests';
  String get name => (raw['name'] as String?) ?? '';
  double get qty => (raw['qty'] as num?)?.toDouble() ?? 0;
  double get cost => (raw['cost'] as num?)?.toDouble() ?? 0;

  List<int> get guestIds {
    final v = raw['guestIds'];
    return v is List
        ? v.map((e) => (e as num?)?.toInt()).whereType<int>().toList()
        : <int>[];
  }
}

/// Propozycja prezentu / lista życzeń `{id, title, desc, link, showToGuests}`.
class GiftProposal {
  GiftProposal(this.raw);
  final Map<String, dynamic> raw;

  int? get id => (raw['id'] as num?)?.toInt();
  String get title => (raw['title'] as String?) ?? '';
  String get desc => (raw['desc'] as String?) ?? '';
  String get link => (raw['link'] as String?) ?? '';
  bool get showToGuests => raw['showToGuests'] == true;
}
