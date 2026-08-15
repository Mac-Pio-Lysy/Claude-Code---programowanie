import 'package:flutter/material.dart';

import '../../models/wedding_data.dart';
import '../../services/firestore_service.dart';
import '../../widgets/tabbed_section_scaffold.dart';
import 'advices_screen.dart';
import 'guest_map_screen.dart';
import 'guestbook_screen.dart';
import 'time_capsule_screen.dart';
import '../../l10n/app_text.dart';

/// Sekcja „Ślubne pamiątki" — zbiorcza zakładka na pamiątki z wesela.
///
/// Każda pamiątka jest osobną podzakładką. Dodanie kolejnej = dopisanie wpisu
/// do listy [_keepsakes] (TabBar/TabBarView budują się automatycznie).
/// `firestore` przekazywane dla przyszłych ekranów korzystających z planera.
class KeepsakesScreen extends StatelessWidget {
  const KeepsakesScreen({
    super.key,
    required this.data,
    required this.firestore,
  });

  final WeddingData? data;
  final FirestoreService firestore;

  List<SectionTab> get _keepsakes => [
        (
          label: AppText.t.keepsakes_guestbook,
          view: GuestbookScreen(data: data),
        ),
        (
          label: AppText.t.keepsakes_advices,
          view: AdvicesScreen(data: data),
        ),
        (
          label: AppText.t.keepsakes_timeCapsule,
          view: TimeCapsuleScreen(data: data),
        ),
        (
          label: AppText.t.keepsakes_guestMap,
          view: GuestMapScreen(data: data),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return TabbedSectionScaffold(title: AppText.t.keepsakes_title, tabs: _keepsakes);
  }
}
