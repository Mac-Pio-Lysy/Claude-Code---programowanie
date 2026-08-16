import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';
import '../layout/responsive.dart';
import '../models/app_notification.dart';
import '../navigation/app_sections.dart';
import '../services/notification_service.dart';
import '../l10n/app_text.dart';

/// Żądanie przejścia do sekcji, wybrane w centrum powiadomień.
class NotifJump {
  const NotifJump(this.section, this.subTab);

  final AppSection section;
  final int? subTab;
}

/// Dzwoneczek z licznikiem nieprzeczytanych (etap 1b).
///
/// Sam nie liczy niczego — dostaje gotową [NotificationInbox] i tylko ją
/// pokazuje. Wykrywanie zmian siedzi w [NotificationService].
class NotificationBell extends StatelessWidget {
  const NotificationBell({
    super.key,
    required this.inbox,
    required this.onOpen,
  });

  final NotificationInbox inbox;

  /// Otwarcie centrum powiadomień.
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final count = inbox.unreadCount;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: count == 0
              ? AppText.t.w_notifications
              : AppText.t.w_notificationsUnread(count),
          icon: Icon(
            count == 0 ? Icons.notifications_none : Icons.notifications,
            color: AppColors.accent,
          ),
          onPressed: onOpen,
        ),
        if (count > 0)
          Positioned(
            right: 4,
            top: 4,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFC0392B),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Centrum powiadomień — grupy po sekcjach, po rozwinięciu pojedyncze wpisy.
///
/// Zwraca [NotifJump], gdy użytkownik wybrał przejście do sekcji.
class NotificationCenter extends StatefulWidget {
  const NotificationCenter({super.key, required this.inbox});

  final NotificationInbox inbox;

  /// Otwiera centrum jako arkusz. Zwraca żądanie przejścia albo `null`.
  static Future<NotifJump?> open(
          BuildContext context, NotificationInbox inbox) =>
      showModalBottomSheet<NotifJump>(
        context: context,
        constraints: const BoxConstraints(maxWidth: kSheetMaxWidth),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => NotificationCenter(inbox: inbox),
      );

  @override
  State<NotificationCenter> createState() => _NotificationCenterState();
}

class _NotificationCenterState extends State<NotificationCenter> {
  /// Rozwinięte grupy (domyślnie wszystkie zwinięte — liczy się przegląd).
  final Set<NotifKind> _expanded = {};

  NotificationInbox get _inbox => widget.inbox;

  void _jump(AppNotification n) {
    // Wejście w powiadomienie jest równoznaczne z jego przeczytaniem.
    _inbox.markRead(n.id);
    Navigator.of(context).pop(NotifJump(n.section, n.subTab));
  }

  void _jumpGroup(NotifGroup g) {
    for (final n in g.items) {
      _inbox.markRead(n.id);
    }
    Navigator.of(context)
        .pop(NotifJump(g.kind.section, g.kind.subTab));
  }

  @override
  Widget build(BuildContext context) {
    final groups = _inbox.unreadGroups;
    final unread = _inbox.unreadCount;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD7DEEC),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _header(unread),
            const Divider(height: 1),
            Expanded(
              child: groups.isEmpty
                  ? _emptyState()
                  : ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                      children: [for (final g in groups) _groupTile(g)],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(int unread) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppText.t.w_notifications,
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
                if (unread > 0)
                  Text(AppText.t.w_unreadCount(unread),
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textLight)),
              ],
            ),
          ),
          if (unread > 0)
            TextButton(
              onPressed: () => setState(_inbox.markAllRead),
              style: TextButton.styleFrom(foregroundColor: AppColors.accent),
              child: Text(AppText.t.w_markAll),
            ),
        ],
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔔', style: TextStyle(fontSize: 34)),
              const SizedBox(height: 10),
              Text(AppText.t.w_noNotifications,
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text)),
              const SizedBox(height: 4),
              Text(
                AppText.t.w_noNotificationsBody,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 12.5, height: 1.45, color: AppColors.textLight),
              ),
            ],
          ),
        ),
      );

  Widget _groupTile(NotifGroup g) {
    final open = _expanded.contains(g.kind);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Column(
        children: [
          // Nagłówek grupy: rozwija listę, a strzałka po prawej prowadzi
          // wprost do sekcji (bez przeglądania pojedynczych wpisów).
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() {
              if (open) {
                _expanded.remove(g.kind);
              } else {
                _expanded.add(g.kind);
              }
            }),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                children: [
                  Text(g.kind.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(AppText.t.w_groupSummary(g.label, g.summary),
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text)),
                  ),
                  Icon(open ? Icons.expand_less : Icons.expand_more,
                      size: 20, color: AppColors.textLight),
                  IconButton(
                    tooltip: AppText.t.w_goToSection,
                    onPressed: () => _jumpGroup(g),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    color: AppColors.accent,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),
          if (open)
            for (final n in g.items) _itemTile(n),
        ],
      ),
    );
  }

  Widget _itemTile(AppNotification n) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEEF3FB))),
      ),
      child: InkWell(
        onTap: () => _jump(n),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.text,
                        style: GoogleFonts.inter(
                            fontSize: 13, height: 1.4, color: AppColors.text)),
                    const SizedBox(height: 2),
                    Text(_timeLabel(n.at),
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.textLight)),
                  ],
                ),
              ),
              IconButton(
                tooltip: AppText.t.w_markRead,
                onPressed: () => setState(() => _inbox.markRead(n.id)),
                icon: const Icon(Icons.check, size: 17),
                color: AppColors.textLight,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Czas wykrycia: „przed chwilą", „12 min temu", „14:35".
  static String _timeLabel(DateTime at) {
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return AppText.t.w_justNow;
    if (diff.inMinutes < 60) return AppText.t.w_minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) {
      final h = at.hour.toString().padLeft(2, '0');
      final m = at.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    return '${at.day}.${at.month.toString().padLeft(2, '0')}';
  }
}
