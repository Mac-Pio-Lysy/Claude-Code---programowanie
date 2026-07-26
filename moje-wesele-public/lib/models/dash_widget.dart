import '../navigation/app_sections.dart';
import '../utils/format.dart';
import 'budget_summary.dart';
import 'payment_item.dart' show isDueSoon, isOverdue;
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

  /// Domyślny układ startowy dla nowego użytkownika — 8 najważniejszych
  /// kafelków. Użytkownik może go dowolnie personalizować w trybie edycji
  /// (dodawanie/usuwanie/przesuwanie); tu ustalamy jedynie zestaw startowy.
  static const List<String> defaultLayout = [
    'countdown', // 💍 Licznik do dnia ślubu
    'guests', // 👥 Goście (potwierdzeni / odmowy / bez odpowiedzi)
    'budget', // 💰 Budżet (zaplanowane / opłacone / pozostało)
    'tasks', // ✅ Zadania (do zrobienia / w trakcie / zrobione)
    'payments', // 💳 Płatności (najbliższe z terminem)
    'schedule', // 📅 Harmonogram (najbliższe wydarzenie)
    'tables', // 🪑 Stoły (przypisani / wolne miejsca)
    'gifts', // 🎁 Prezenty (liczba / wartość otrzymanych)
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
        final rsvp = _raw(d, 'rsvpEntries').whereType<Map>();
        final attending = rsvp
            .where((e) => e['guestId'] != null && e['status'] == 'attending')
            .length;
        final declined = rsvp
            .where((e) => e['guestId'] != null && e['status'] == 'not_attending')
            .length;
        final noRsvp = guests.where((g) {
          final id = (g is Map) ? g['id'] : null;
          return !rsvp.any((e) => e['guestId'] == id);
        }).length;
        return DashStat('${guests.length}',
            '$attending potw. · $declined odmów · $noRsvp bez odp.');
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
        // Przypisani = goście z ustawionym stołem (tableId != null).
        final assigned = (d?.guests ?? const [])
            .where((g) => g is Map && g['tableId'] != null)
            .length;
        final free = (seats - assigned) < 0 ? 0 : seats - assigned;
        return DashStat(
            '${tables.length}', '$assigned przypisanych · $free wolnych miejsc');
      },
    ),
    DashWidgetDef(
      id: 'budget',
      icon: '💰',
      title: 'Budżet',
      target: AppSection.budget,
      compute: (d) {
        // Pełna logika budżetu (zaplanowane/opłacone/pozostało) — ta sama co
        // w sekcji Budżet i w wersji web (renderBudgetOverview).
        final b = BudgetSummary.from(d);
        return DashStat(
          '${formatPln(b.planForCalc)} zł',
          'Opłacono ${formatPln(b.totalPaid)} zł · zostało ${formatPln(b.remaining)} zł',
          alert: b.diff < 0,
        );
      },
    ),
    DashWidgetDef(
      id: 'schedule',
      icon: '📅',
      title: 'Harmonogram',
      target: AppSection.schedule,
      compute: (d) {
        final events =
            _raw(d, 'scheduleEvents').whereType<Map>().toList();
        if (events.isEmpty) return const DashStat('—', 'brak wydarzeń');
        // Harmonogram to jeden dzień — „najbliższe" = najwcześniejsze w programie.
        int mins(Map e) => (_d(e['hour']) * 60 + _d(e['minute'])).toInt();
        events.sort((a, b) => mins(a).compareTo(mins(b)));
        final ev = events.first;
        String p(num n) => n.toInt().toString().padLeft(2, '0');
        final time = '${p(_d(ev['hour']))}:${p(_d(ev['minute']))}';
        final name = (ev['name'] as String?)?.trim();
        return DashStat(
            time, (name == null || name.isEmpty) ? 'najbliższe wydarzenie' : name);
      },
    ),
    DashWidgetDef(
      id: 'tasks',
      icon: '✅',
      title: 'Zadania',
      target: AppSection.tasks,
      compute: (d) {
        final tasks = _raw(d, 'tasks').whereType<Map>();
        final done = tasks.where((t) => t['status'] == 'done').length;
        final inProgress =
            tasks.where((t) => t['status'] == 'inprogress').length;
        final todo = tasks.where((t) => t['status'] == 'todo').length;
        return DashStat(
            '$done/${tasks.length}', '$todo do zrobienia · $inProgress w trakcie');
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
        final gifts = _raw(d, 'gifts').whereType<Map>();
        final thanked = gifts.where((g) => g['thanked'] == true).length;
        final value = gifts.fold<double>(0, (s, g) => s + _d(g['value']));
        return DashStat('${gifts.length}',
            'łącznie ${formatPln(value)} zł · $thanked z podziękowaniem');
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
}
