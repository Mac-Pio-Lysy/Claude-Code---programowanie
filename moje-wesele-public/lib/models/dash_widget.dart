import '../navigation/app_sections.dart';
import 'budget_summary.dart';
import 'payment_item.dart' show isDueSoon, isOverdue;
import 'wedding_data.dart';
import '../l10n/app_text.dart';
import '../utils/app_format.dart';

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
      title: AppText.t.dash_countdown,
      target: AppSection.settings,
      compute: (d) {
        final days = d?.daysUntilWedding;
        if (d?.weddingDate == null || days == null) {
          return DashStat(AppText.t.common_none, AppText.t.dash_setDate);
        }
        if (days == 0) return DashStat('🎉', AppText.t.dash_today);
        return DashStat('$days', AppText.t.dash_daysLeft(days));
      },
    ),
    DashWidgetDef(
      id: 'guests',
      icon: '👥',
      title: AppText.t.section_guests,
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
            AppText.t.dash_guestsSub(attending, declined, noRsvp));
      },
    ),
    DashWidgetDef(
      id: 'tables',
      icon: '🪑',
      title: AppText.t.tables_statTables,
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
            '${tables.length}', AppText.t.dash_tablesSub(assigned, free));
      },
    ),
    DashWidgetDef(
      id: 'budget',
      icon: '💰',
      title: AppText.t.section_budget,
      target: AppSection.budget,
      compute: (d) {
        // Pełna logika budżetu (zaplanowane/opłacone/pozostało) — ta sama co
        // w sekcji Budżet i w wersji web (renderBudgetOverview).
        final b = BudgetSummary.from(d);
        return DashStat(
          AppFormat.money(b.planForCalc),
          AppText.t.dash_budgetSub(AppFormat.money(b.totalPaid), AppFormat.money(b.remaining)),
          alert: b.diff < 0,
        );
      },
    ),
    DashWidgetDef(
      id: 'schedule',
      icon: '📅',
      title: AppText.t.section_schedule,
      target: AppSection.schedule,
      compute: (d) {
        final events =
            _raw(d, 'scheduleEvents').whereType<Map>().toList();
        if (events.isEmpty) return DashStat(AppText.t.common_none, AppText.t.dash_noEvents);
        // Harmonogram to jeden dzień — „najbliższe" = najwcześniejsze w programie.
        int mins(Map e) => (_d(e['hour']) * 60 + _d(e['minute'])).toInt();
        events.sort((a, b) => mins(a).compareTo(mins(b)));
        final ev = events.first;
        String p(num n) => n.toInt().toString().padLeft(2, '0');
        final time = '${p(_d(ev['hour']))}:${p(_d(ev['minute']))}';
        final name = (ev['name'] as String?)?.trim();
        return DashStat(
            time, (name == null || name.isEmpty) ? AppText.t.dash_nextEvent : name);
      },
    ),
    DashWidgetDef(
      id: 'tasks',
      icon: '✅',
      title: AppText.t.section_tasks,
      target: AppSection.tasks,
      compute: (d) {
        final tasks = _raw(d, 'tasks').whereType<Map>();
        final done = tasks.where((t) => t['status'] == 'done').length;
        final inProgress =
            tasks.where((t) => t['status'] == 'inprogress').length;
        final todo = tasks.where((t) => t['status'] == 'todo').length;
        return DashStat(
            '$done/${tasks.length}', AppText.t.dash_tasksSub(todo, inProgress));
      },
    ),
    DashWidgetDef(
      id: 'transport',
      icon: '🚗',
      title: AppText.t.section_transport,
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
        return DashStat('${vehicles.length}', AppText.t.dash_transportSub(without));
      },
    ),
    DashWidgetDef(
      id: 'accommodation',
      icon: '🏨',
      title: AppText.t.section_accommodation,
      target: AppSection.accommodation,
      compute: (d) {
        final guests = (d?.guests ?? const []).whereType<Map>();
        final needs = guests.where((g) => g['needsAccommodation'] == true).length;
        final reserved =
            guests.where((g) => g['accommodationStatus'] == 'reserved').length;
        return DashStat('$needs', AppText.t.dash_roomsSub(reserved));
      },
    ),
    DashWidgetDef(
      id: 'gifts',
      icon: '🎁',
      title: AppText.t.section_gifts,
      target: AppSection.gifts,
      compute: (d) {
        final gifts = _raw(d, 'gifts').whereType<Map>();
        final thanked = gifts.where((g) => g['thanked'] == true).length;
        final value = gifts.fold<double>(0, (s, g) => s + _d(g['value']));
        return DashStat('${gifts.length}',
            AppText.t.dash_giftsSub(AppFormat.money(value), thanked));
      },
    ),
    DashWidgetDef(
      id: 'rsvp',
      icon: '📋',
      title: AppText.t.section_rsvp,
      target: AppSection.rsvp,
      compute: (d) {
        final rsvp = _raw(d, 'rsvpEntries').whereType<Map>();
        final attending = rsvp
            .where((e) => e['guestId'] != null && e['status'] == 'attending')
            .length;
        final declined = rsvp
            .where((e) => e['guestId'] != null && e['status'] == 'not_attending')
            .length;
        return DashStat('$attending', AppText.t.dash_rsvpSub(declined, rsvp.length));
      },
    ),
    DashWidgetDef(
      id: 'alcohol',
      icon: '🍾',
      title: AppText.t.beverage_alcohol,
      target: AppSection.budget,
      compute: (d) {
        final bd = _bd(d);
        final items = _rawL(bd['alcoholItems']).whereType<Map>();
        final total =
            items.fold<double>(0, (s, i) => s + _d(i['bottles']) * _d(i['pricePerBottle']));
        final bottles = items.fold<double>(0, (s, i) => s + _d(i['bottles']));
        return DashStat(AppFormat.money(total), AppText.t.dash_bottles(bottles.toStringAsFixed(0)));
      },
    ),
    DashWidgetDef(
      id: 'honeymoon',
      icon: '✈️',
      title: AppText.t.pay_honeymoon,
      target: AppSection.budget,
      compute: (d) {
        final h = _bd(d)['honeymoon'];
        final hm = h is Map ? h : const {};
        final name = (hm['name'] as String?)?.trim();
        return DashStat(AppFormat.money(_d(hm['totalAmount'])),
            (name == null || name.isEmpty) ? 'Podróż poślubna' : name);
      },
    ),
    DashWidgetDef(
      id: 'payments',
      icon: '💳',
      title: AppText.t.budget_payments,
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
        return DashStat('${overdue + soon}', AppText.t.dash_paymentsSub(overdue, soon),
            alert: overdue > 0);
      },
    ),
    DashWidgetDef(
      id: 'vendors',
      icon: '👨‍🍳',
      title: AppText.t.section_vendors,
      target: AppSection.vendors,
      compute: (d) {
        final vendors = _raw(d, 'vendors').whereType<Map>();
        final confirmed = vendors
            .where((v) =>
                v['paymentStatus'] == 'confirmed' || v['paymentStatus'] == 'paid')
            .length;
        return DashStat('${vendors.length}', AppText.t.dash_vendorsSub(confirmed));
      },
    ),
    DashWidgetDef(
      id: 'gallery',
      icon: '📸',
      title: AppText.t.section_gallery,
      target: AppSection.gallery,
      // Liczbę plików dostarcza StreamBuilder w UI (osobna kolekcja `gallery`).
      compute: (d) => DashStat(AppText.t.common_none, AppText.t.dash_gallerySub),
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
