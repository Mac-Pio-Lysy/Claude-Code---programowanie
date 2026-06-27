import '../navigation/app_sections.dart';
import '../utils/format.dart';
import 'payment_item.dart' show isDueSoon, isOverdue;
import 'sala_summary.dart';
import 'wedding_data.dart';

/// Statystyka kafelka dashboardu (liczba + podpis + flaga alarmu).
class DashStat {
  const DashStat(this.value, this.sub, {this.alert = false});
  final String value;
  final String sub;
  final bool alert;
}

/// Definicja kafelka dashboardu (odwzorowane z DASH_WIDGETS w script.js).
class DashWidgetDef {
  const DashWidgetDef({
    required this.id,
    required this.icon,
    required this.title,
    required this.target,
    required this.compute,
  });

  final String id;
  final String icon;
  final String title;

  /// Sekcja, do której prowadzi kliknięcie kafelka.
  final AppSection target;

  /// Statystyki na żywo z danych Firestore.
  final DashStat Function(WeddingData? data) compute;
}

/// Rejestr wszystkich dostępnych kafelków dashboardu.
class DashWidgets {
  DashWidgets._();

  /// Domyślny układ (jak DEFAULT_DASH_LAYOUT w wersji web).
  static const List<String> defaultLayout = [
    'countdown',
    'guests',
    'budget',
    'tasks',
    'payments',
    'rsvp',
    'schedule',
    'vendors',
  ];

  static DashWidgetDef? byId(String id) {
    for (final w in all) {
      if (w.id == id) return w;
    }
    return null;
  }

  static final List<DashWidgetDef> all = [
    DashWidgetDef(
      id: 'countdown',
      icon: '💍',
      title: 'Licznik do ślubu',
      target: AppSection.settings,
      compute: (d) {
        final days = d?.daysUntilWedding;
        if (d?.weddingDate == null || days == null) {
          return const DashStat('—', 'Ustaw datę w Ustawieniach');
        }
        if (days == 0) return const DashStat('🎉', 'To dziś!');
        return DashStat('$days', days == 1 ? 'dzień do ślubu' : 'dni do ślubu');
      },
    ),
    DashWidgetDef(
      id: 'guests',
      icon: '👥',
      title: 'Goście',
      target: AppSection.guests,
      compute: (d) {
        final guests = d?.guests ?? const [];
        final rsvp = _raw(d, 'rsvpEntries');
        final attending = rsvp
            .whereType<Map>()
            .where((e) => e['guestId'] != null && e['status'] == 'attending')
            .length;
        final noRsvp = guests.where((g) {
          final id = (g is Map) ? g['id'] : null;
          return !rsvp.whereType<Map>().any((e) => e['guestId'] == id);
        }).length;
        return DashStat('${guests.length}',
            '$attending potwierdzeń · $noRsvp bez odpowiedzi');
      },
    ),
    DashWidgetDef(
      id: 'tables',
      icon: '🪑',
      title: 'Stoły',
      target: AppSection.room,
      compute: (d) {
        final tables = d?.tables ?? const [];
        final seats = tables.fold<int>(
            0, (s, t) => s + ((t is Map ? (t['seats'] as num?)?.toInt() : 0) ?? 0));
        return DashStat('${tables.length}', '$seats miejsc');
      },
    ),
    DashWidgetDef(
      id: 'budget',
      icon: '💰',
      title: 'Budżet',
      target: AppSection.budget,
      compute: (d) {
        final bd = _bd(d);
        final expenses = _rawL(bd['expenses']);
        final expPlanned =
            expenses.whereType<Map>().fold<double>(0, (s, e) => s + _d(e['planned'])) +
                _alcohol(bd) +
                _soft(bd);
        final catering = SalaSummary.from(d).cateringTotal;
        return DashStat('${formatPln(catering + expPlanned)} zł',
            'Limit: ${formatPln(_d(bd['total']))} zł');
      },
    ),
    DashWidgetDef(
      id: 'schedule',
      icon: '📅',
      title: 'Harmonogram',
      target: AppSection.schedule,
      compute: (d) =>
          DashStat('${_raw(d, 'scheduleEvents').length}', 'punktów programu'),
    ),
    DashWidgetDef(
      id: 'tasks',
      icon: '✅',
      title: 'Zadania',
      target: AppSection.tasks,
      compute: (d) {
        final tasks = _raw(d, 'tasks');
        final done =
            tasks.whereType<Map>().where((t) => t['status'] == 'done').length;
        return DashStat('$done/${tasks.length}', '${tasks.length - done} pozostało');
      },
    ),
    DashWidgetDef(
      id: 'transport',
      icon: '🚗',
      title: 'Transport',
      target: AppSection.transport,
      compute: (d) {
        final vehicles = _raw(d, 'vehicles');
        final inCars = <int>{};
        for (final v in vehicles.whereType<Map>()) {
          for (final g in (v['guestIds'] is List ? v['guestIds'] as List : const [])) {
            final id = (g as num?)?.toInt();
            if (id != null) inCars.add(id);
          }
        }
        final without = (d?.guests ?? const []).where((g) {
          final id = (g is Map) ? (g['id'] as num?)?.toInt() : null;
          return !inCars.contains(id) && (g is Map && g['ownTransport'] != true);
        }).length;
        return DashStat('${vehicles.length}', '$without gości bez transportu');
      },
    ),
    DashWidgetDef(
      id: 'accommodation',
      icon: '🏨',
      title: 'Noclegi',
      target: AppSection.accommodation,
      compute: (d) {
        final guests = (d?.guests ?? const []).whereType<Map>();
        final needs = guests.where((g) => g['needsAccommodation'] == true).length;
        final reserved =
            guests.where((g) => g['accommodationStatus'] == 'reserved').length;
        return DashStat('$needs', '$reserved zarezerwowanych');
      },
    ),
    DashWidgetDef(
      id: 'gifts',
      icon: '🎁',
      title: 'Prezenty',
      target: AppSection.gifts,
      compute: (d) {
        final gifts = _raw(d, 'gifts');
        final thanked =
            gifts.whereType<Map>().where((g) => g['thanked'] == true).length;
        return DashStat('${gifts.length}', '$thanked z podziękowaniem');
      },
    ),
    DashWidgetDef(
      id: 'rsvp',
      icon: '📋',
      title: 'Potwierdzenia',
      target: AppSection.rsvp,
      compute: (d) {
        final rsvp = _raw(d, 'rsvpEntries').whereType<Map>();
        final attending = rsvp
            .where((e) => e['guestId'] != null && e['status'] == 'attending')
            .length;
        final declined = rsvp
            .where((e) => e['guestId'] != null && e['status'] == 'not_attending')
            .length;
        return DashStat('$attending', '$declined odmów · ${rsvp.length} odpowiedzi');
      },
    ),
    DashWidgetDef(
      id: 'alcohol',
      icon: '🍾',
      title: 'Alkohol',
      target: AppSection.budget,
      compute: (d) {
        final bd = _bd(d);
        final items = _rawL(bd['alcoholItems']).whereType<Map>();
        final total =
            items.fold<double>(0, (s, i) => s + _d(i['bottles']) * _d(i['pricePerBottle']));
        final bottles = items.fold<double>(0, (s, i) => s + _d(i['bottles']));
        return DashStat('${formatPln(total)} zł', '${bottles.toStringAsFixed(0)} butelek');
      },
    ),
    DashWidgetDef(
      id: 'honeymoon',
      icon: '✈️',
      title: 'Podróż poślubna',
      target: AppSection.budget,
      compute: (d) {
        final h = _bd(d)['honeymoon'];
        final hm = h is Map ? h : const {};
        final name = (hm['name'] as String?)?.trim();
        return DashStat('${formatPln(_d(hm['totalAmount']))} zł',
            (name == null || name.isEmpty) ? 'Podróż poślubna' : name);
      },
    ),
    DashWidgetDef(
      id: 'payments',
      icon: '💳',
      title: 'Płatności',
      target: AppSection.budget,
      compute: (d) {
        final payments = _raw(d, 'payments');
        var overdue = 0, soon = 0;
        for (final p in payments.whereType<Map>()) {
          for (final i
              in (p['installments'] is List ? p['installments'] as List : const [])
                  .whereType<Map>()) {
            final status = (i['status'] as String?) ?? '';
            final due = (i['dueDate'] as String?) ?? '';
            if (status == 'paid') continue;
            if (isOverdue(due, status)) {
              overdue++;
            } else if (isDueSoon(due)) {
              soon++;
            }
          }
        }
        return DashStat('${overdue + soon}', '$overdue zaległych · $soon wkrótce',
            alert: overdue > 0);
      },
    ),
    DashWidgetDef(
      id: 'vendors',
      icon: '👨‍🍳',
      title: 'Dostawcy',
      target: AppSection.vendors,
      compute: (d) {
        final vendors = _raw(d, 'vendors').whereType<Map>();
        final confirmed = vendors
            .where((v) =>
                v['paymentStatus'] == 'confirmed' || v['paymentStatus'] == 'paid')
            .length;
        return DashStat('${vendors.length}', '$confirmed potwierdzonych');
      },
    ),
    DashWidgetDef(
      id: 'gallery',
      icon: '📸',
      title: 'Galeria',
      target: AppSection.gallery,
      // Liczbę plików dostarcza StreamBuilder w UI (osobna kolekcja `gallery`).
      compute: (d) => const DashStat('—', 'zdjęć i filmów'),
    ),
  ];

  // ── Pomocnicze ──
  static double _d(dynamic v) => v is num ? v.toDouble() : 0;

  static List<dynamic> _raw(WeddingData? d, String key) =>
      d?.raw[key] is List ? d!.raw[key] as List : const [];

  static List<dynamic> _rawL(dynamic v) => v is List ? v : const [];

  static Map<dynamic, dynamic> _bd(WeddingData? d) =>
      d?.raw['budgetData'] is Map ? d!.raw['budgetData'] as Map : const {};

  static double _alcohol(Map<dynamic, dynamic> bd) =>
      _rawL(bd['alcoholItems'])
          .whereType<Map>()
          .fold<double>(0, (s, i) => s + _d(i['bottles']) * _d(i['pricePerBottle']));

  static double _soft(Map<dynamic, dynamic> bd) =>
      _rawL(bd['softItems'])
          .whereType<Map>()
          .fold<double>(0, (s, i) => s + _d(i['bottles']) * _d(i['pricePerBottle']));
}
