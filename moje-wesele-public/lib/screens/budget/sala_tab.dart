import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/sala_summary.dart';
import '../../models/wedding_data.dart';
import '../../services/budget_service.dart';
import '../../utils/format.dart';
import 'budget_fields.dart';
import '../../l10n/app_text.dart';
import '../../utils/app_format.dart';

/// Podzakładka „Sala" — koszt sali/cateringu: cena za osobę, goście przypisani/
/// nieprzypisani, obsługa (osobna pula i stawka), goście wirtualni, dodatki do
/// menu, dekoracje stołów oraz podsumowanie z rozbiciem na grupy.
class SalaTab extends StatelessWidget {
  const SalaTab({super.key, required this.data, required this.service});

  final WeddingData? data;
  final BudgetService service;

  List<Map<String, dynamic>> get _menuAddons => _list('menuAddons');
  List<Map<String, dynamic>> get _cateringMenuAddons => _list('cateringMenuAddons');
  List<Map<String, dynamic>> get _honorAddons => _decoList('honorAddons');
  List<Map<String, dynamic>> get _regularAddons => _decoList('regularAddons');

  List<Map<String, dynamic>> _list(String key) {
    final bd = data?.raw['budgetData'];
    final v = (bd is Map) ? bd[key] : null;
    return v is List
        ? v.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];
  }

  List<Map<String, dynamic>> _decoList(String key) {
    final bd = data?.raw['budgetData'];
    final deco = (bd is Map) ? bd['tableDeco'] : null;
    final v = (deco is Map) ? deco[key] : null;
    return v is List
        ? v.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];
  }

  @override
  Widget build(BuildContext context) {
    final s = SalaSummary.from(data);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _childrenCard(s),
        const SizedBox(height: 16),
        _salaCard(s),
        const SizedBox(height: 16),
        if (s.cateringSeparate) ...[
          _cateringCard(s),
          const SizedBox(height: 16),
        ],
        _staffCard(s),
        const SizedBox(height: 16),
        _menuAddonsCard(s),
        const SizedBox(height: 16),
        _tableDecoCard(s),
        const SizedBox(height: 16),
        _summaryCard(s),
      ],
    );
  }

  // ── Karta „Wesele z dziećmi" (znacznik na początku sekcji Sala) ──
  Widget _childrenCard(SalaSummary s) {
    return _card(
      title: AppText.t.budget_withChildrenTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.accent,
            title: Text(AppText.t.budget_withChildrenSwitch,
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text(
              AppText.t.budget_withChildrenHint,
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
            ),
            value: s.withChildren,
            onChanged: service.setWithChildren,
          ),
          if (s.withChildren) ...[
            const SizedBox(height: 8),
            // Tryb liczenia dzieci: z listy gości albo ręcznie. Rozwiązuje
            // rozjazd — wcześniej liczba żyła osobno od listy gości.
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.accent,
              title: Text(AppText.t.budget_childrenAuto,
                  style: GoogleFonts.inter(fontSize: 13)),
              subtitle: Text(
                s.children.auto
                    ? AppText.t.budget_childrenAutoOn
                    : AppText.t.budget_childrenAutoOff,
                style:
                    GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
              ),
              value: s.children.auto,
              onChanged: (v) => service.setChildrenCountAuto(v,
                  currentCount: s.childrenCount),
            ),
            const SizedBox(height: 8),
            if (s.children.auto)
              _infoRow(AppText.t.budget_childrenFromGuests,
                  '${s.children.fromGuests}')
            else
              BudgetNumberField(
                key: const ValueKey('childrenCount'),
                label: AppText.t.budget_childrenCount,
                suffix: AppText.t.budget_childrenSuffix,
                integer: true,
                initial: s.childrenCount.toDouble(),
                onSaved: service.setChildrenCount,
              ),
            // W trybie ręcznym ostrzegamy o rozjeździe z listą gości — to
            // najczęstsze źródło błędnej kalkulacji cateringu.
            if (s.children.manualMismatch)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  AppText.t.budget_childrenMismatch(
                      '${s.children.fromGuests}', '${s.childrenCount}'),
                  style: GoogleFonts.inter(
                      fontSize: 11, color: const Color(0xFFB45309)),
                ),
              ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.accent,
              title: Text(AppText.t.budget_childMenuSeparate,
                  style: GoogleFonts.inter(fontSize: 13)),
              subtitle: Text(
                s.childMenuSeparate
                    ? AppText.t.budget_childMenuOn(s.childBilledCount.round())
                    : AppText.t.budget_childMenuOff,
                style:
                    GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
              ),
              value: s.childMenuSeparate,
              onChanged: service.setChildMenuSeparate,
            ),
            if (s.childMenuSeparate) ...[
              const SizedBox(height: 8),
              BudgetNumberField(
                key: const ValueKey('childMenuPricePerPerson'),
                label: AppText.t.budget_childMenuPrice,
                suffix: AppFormat.currency.symbol,
                initial: s.childMenuPricePerPerson,
                onSaved: service.setChildMenuPricePerPerson,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _infoRow(AppText.t.budget_childMenuCost,
                    formatPlnZl(s.childMenuTotal),
                    bold: true),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ── Karta „Catering" (gdy oddzielny od sali) — jak Sala: cena/os. + dodatki ──
  Widget _cateringCard(SalaSummary s) {
    final addons = _cateringMenuAddons;
    return _card(
      title: AppText.t.budget_cateringSeparateCard,
      trailing: _addButton(() => service.addCateringMenuAddon()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppText.t.budget_cateringSeparateHint,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
          ),
          const SizedBox(height: 10),
          BudgetNumberField(
            key: const ValueKey('cateringPricePerPerson'),
            label: AppText.t.budget_cateringPricePerPerson,
            suffix: AppFormat.currency.symbol,
            initial: s.cateringPricePerPerson,
            onSaved: service.setCateringPricePerPerson,
          ),
          const SizedBox(height: 12),
          Text(AppText.t.budget_cateringAddons,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text)),
          const SizedBox(height: 6),
          if (addons.isEmpty)
            _emptyHint(AppText.t.budget_noAddons)
          else
            for (final a in addons)
              _AddonRow(
                key: ValueKey('cmenu-${a['id']}'),
                name: (a['name'] as String?) ?? '',
                amount: _d(a['pricePerPerson']),
                amountSuffix: AppText.t.budget_perPersonShort(AppFormat.currency.symbol),
                lineTotal: _d(a['pricePerPerson']) * s.addonsPersonCount,
                onNameSaved: (v) =>
                    service.updateCateringMenuAddon(_id(a), name: v),
                onAmountSaved: (v) =>
                    service.updateCateringMenuAddon(_id(a), pricePerPerson: v),
                onDelete: () => service.deleteCateringMenuAddon(_id(a)),
              ),
          const Divider(height: 20),
          _infoRow(AppText.t.budget_peopleForCalc,
              '${s.addonsPersonCount.round()}'),
          _infoRow(AppText.t.sala_cateringBase,
              formatPlnZl(s.addonsPersonCount * s.cateringPricePerPerson)),
          _infoRow(AppText.t.sala_cateringExtras, formatPlnZl(s.cateringMenuAddonsTotal)),
          _infoRow(AppText.t.budget_cateringTotal, formatPlnZl(s.cateringSeparateTotal),
              bold: true),
        ],
      ),
    );
  }

  // ── Karta „Sala" (cena/os., goście, wirtualni) ──
  Widget _salaCard(SalaSummary s) {
    return _card(
      title: 'Sala',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BudgetNumberField(
            key: const ValueKey('pricePerPerson'),
            label: AppText.t.budget_pricePerPerson,
            suffix: AppFormat.currency.symbol,
            initial: s.pricePerPerson,
            onSaved: service.setPricePerPerson,
          ),
          const SizedBox(height: 12),
          BudgetNumberField(
            key: const ValueKey('venueMinGuests'),
            label: AppText.t.budget_venueMinGuests,
            suffix: AppText.t.common_personsShort,
            integer: true,
            initial: s.venueMinGuests,
            onSaved: service.setVenueMinGuests,
          ),
          const SizedBox(height: 12),
          BudgetNumberField(
            key: const ValueKey('plannedGuests'),
            label: AppText.t.budget_plannedGuests,
            suffix: AppText.t.common_personsShort,
            integer: true,
            initial: s.plannedGuests,
            onSaved: service.setPlannedGuests,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 2),
            child: Text(
              AppText.t.budget_plannedGuestsHint,
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _infoRow(AppText.t.budget_guestsAssigned, '${s.assignedCount}'),
                _infoRow(AppText.t.budget_guestsUnassigned, '${s.unassignedCount}'),
                const Divider(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    AppText.t.budget_effectiveBreakdown(
                      '${s.guestCount}',
                      '${s.venueMinGuests.round()}',
                      '${s.plannedGuests.round()}',
                      '${s.effectiveGuestCount.round()}',
                    ),
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text),
                  ),
                ),
                const Divider(height: 14),
                _infoRow(AppText.t.budget_guestsCost, formatPlnZl(s.guestCost)),
              ],
            ),
          ),
          if (s.plannedGuests > 0 && s.guestCount > s.plannedGuests) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD6E4FB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppText.t.budget_moreThanPlannedInfo(
                      '${(s.guestCount - s.plannedGuests).round()}',
                      '${s.guestCount}',
                    ),
                    style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppText.t.budget_moreThanPlannedNote,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textLight),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.accent,
            title: Text(AppText.t.budget_cateringSeparateAsk,
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text(
              s.cateringSeparate
                  ? AppText.t.budget_cateringSeparateNote
                  : AppText.t.budget_cateringIncluded,
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
            ),
            value: s.cateringSeparate,
            onChanged: service.setCateringSeparate,
          ),
        ],
      ),
    );
  }

  // ── Karta „Obsługa" (osobna pula, własna stawka) ──
  Widget _staffCard(SalaSummary s) {
    final headcount = s.staffCalcMode == StaffCalcMode.headcount;
    final perGuest = s.staffCalcMode == StaffCalcMode.perGuest;
    return _card(
      title: AppText.t.budget_staff,
      trailing: headcount
          // Nazwa trafia do bazy — zapisujemy w bieżącym języku.
          ? _addButton(() => service.addStaffTable(AppText.t.budget_staff, 1))
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppText.t.budget_staffHint,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [
            _staffModeChip(
                StaffCalcMode.headcount, AppText.t.budget_staffModeHeadcount, s),
            _staffModeChip(
                StaffCalcMode.perGuest, AppText.t.budget_staffModePerGuest, s),
            _staffModeChip(
                StaffCalcMode.manual, AppText.t.budget_staffModeManual, s),
          ]),
          const SizedBox(height: 12),
          if (headcount) ...[
            if (s.staff.isEmpty)
              _emptyHint(AppText.t.budget_staffEmpty)
            else
              for (final t in s.staff)
                _StaffRow(
                  key: ValueKey('staff-${t.id}'),
                  name: t.name,
                  persons: t.persons,
                  includeInCost: t.includeInCost,
                  onNameSaved: (v) => service.updateStaffTable(t.id, name: v),
                  onPersonsSaved: (v) =>
                      service.updateStaffTable(t.id, persons: v),
                  onIncludeChanged: (v) =>
                      service.updateStaffTable(t.id, includeInCost: v),
                  onDelete: () => service.deleteStaffTable(t.id),
                ),
            const SizedBox(height: 12),
            BudgetNumberField(
              key: const ValueKey('staffPricePerPerson'),
              label: AppText.t.budget_staffRate,
              suffix: AppFormat.currency.symbol,
              initial: s.staffPricePerPerson,
              onSaved: service.setStaffPricePerPerson,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 2),
              child: Text(
                AppText.t.budget_staffRateFallbackHint,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
              ),
            ),
          ] else if (perGuest) ...[
            _infoRow(AppText.t.budget_peopleForCalc,
                '${s.effectiveGuestCount.round()}'),
            const SizedBox(height: 8),
            BudgetNumberField(
              key: const ValueKey('staffPricePerPerson'),
              label: AppText.t.budget_staffRate,
              suffix: AppFormat.currency.symbol,
              initial: s.staffPricePerPerson,
              onSaved: service.setStaffPricePerPerson,
            ),
          ] else ...[
            BudgetNumberField(
              key: const ValueKey('staffManualAmount'),
              label: AppText.t.budget_staffManualAmount,
              suffix: AppFormat.currency.symbol,
              initial: s.staffManualAmount,
              onSaved: service.setStaffManualAmount,
            ),
          ],
          const SizedBox(height: 4),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.accent,
            title: Text(AppText.t.budget_staffInclude,
                style: GoogleFonts.inter(fontSize: 13)),
            subtitle: headcount
                ? Text(
                    AppText.t.budget_staffIncludeHint,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textLight),
                  )
                : null,
            value: s.includeStaff,
            onChanged: service.setIncludeStaff,
          ),
          const Divider(height: 16),
          if (headcount) ...[
            _infoRow(AppText.t.budget_staffCountTotal, '${s.staffPersonCount.round()}'),
            _infoRow(AppText.t.sala_inCosts, '${s.staffCostPersonCount.round()}'),
            _infoRow(AppText.t.budget_staffRateShort, formatPlnZl(s.staffRate)),
          ],
          _infoRow(AppText.t.budget_staffCost, formatPlnZl(s.staffCost), bold: true),
        ],
      ),
    );
  }

  Widget _staffModeChip(String mode, String label, SalaSummary s) {
    final selected = s.staffCalcMode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => service.setStaffCalcMode(mode),
      showCheckmark: false,
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: selected ? Colors.white : AppColors.textLight,
      ),
      selectedColor: AppColors.accent,
      backgroundColor: Colors.white,
      side: BorderSide(
          color: selected ? AppColors.accent : const Color(0xFFDCE4F2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _menuAddonsCard(SalaSummary s) {
    final addons = _menuAddons;
    return _card(
      title: AppText.t.budget_menuAddons,
      trailing: _addButton(() => service.addMenuAddon()),
      child: Column(
        children: [
          if (addons.isEmpty)
            _emptyHint(AppText.t.budget_noAddons)
          else
            for (final a in addons)
              _AddonRow(
                key: ValueKey('menu-${a['id']}'),
                name: (a['name'] as String?) ?? '',
                amount: _d(a['pricePerPerson']),
                amountSuffix: AppText.t.budget_perPersonShort(AppFormat.currency.symbol),
                lineTotal: _d(a['pricePerPerson']) * s.addonsPersonCount,
                onNameSaved: (v) =>
                    service.updateMenuAddon(_id(a), name: v),
                onAmountSaved: (v) =>
                    service.updateMenuAddon(_id(a), pricePerPerson: v),
                onDelete: () => service.deleteMenuAddon(_id(a)),
              ),
          if (addons.isNotEmpty) ...[
            const Divider(height: 20),
            _infoRow(AppText.t.budget_peopleForCalc,
                '${s.addonsPersonCount.round()}'),
            _infoRow(AppText.t.budget_menuAddonsTotal,
                formatPlnZl(s.menuAddonsTotal),
                bold: true),
          ],
        ],
      ),
    );
  }

  Widget _tableDecoCard(SalaSummary s) {
    final honor = _honorAddons;
    final regular = _regularAddons;
    return _card(
      title: AppText.t.budget_tableDecor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _subHeader(AppText.t.budget_honorTable, () => service.addTableDeco('honor')),
          if (honor.isEmpty)
            _emptyHint(AppText.t.budget_honorTableEmpty)
          else
            for (final a in honor)
              _AddonRow(
                key: ValueKey('honor-${a['id']}'),
                name: (a['name'] as String?) ?? '',
                amount: _d(a['price']),
                amountSuffix: AppFormat.currency.symbol,
                onNameSaved: (v) =>
                    service.updateTableDeco('honor', _id(a), name: v),
                onAmountSaved: (v) =>
                    service.updateTableDeco('honor', _id(a), value: v),
                onDelete: () => service.deleteTableDeco('honor', _id(a)),
              ),
          const SizedBox(height: 12),
          _subHeader(AppText.t.budget_regularTables(s.regularTableCount),
              () => service.addTableDeco('regular')),
          if (regular.isEmpty)
            _emptyHint(AppText.t.budget_regularTablesEmpty)
          else
            for (final a in regular)
              _AddonRow(
                key: ValueKey('regular-${a['id']}'),
                name: (a['name'] as String?) ?? '',
                amount: _d(a['pricePerTable']),
                amountSuffix: AppText.t.budget_perTableShort(AppFormat.currency.symbol),
                lineTotal: _d(a['pricePerTable']) * s.regularTableCount,
                onNameSaved: (v) =>
                    service.updateTableDeco('regular', _id(a), name: v),
                onAmountSaved: (v) =>
                    service.updateTableDeco('regular', _id(a), value: v),
                onDelete: () => service.deleteTableDeco('regular', _id(a)),
              ),
          const Divider(height: 20),
          _infoRow(AppText.t.budget_honorTableDecor,
              formatPlnZl(s.honorDecoTotal)),
          _infoRow(AppText.t.budget_regularTablesDecor,
              formatPlnZl(s.regularDecoTotal)),
          _infoRow(AppText.t.budget_decorTotal, formatPlnZl(s.tableDecoTotal),
              bold: true),
        ],
      ),
    );
  }

  Widget _summaryCard(SalaSummary s) {
    return _card(
      title: AppText.t.budget_venueSummary,
      child: Column(
        children: [
          _infoRow(AppText.t.budget_guestsCostCount(s.effectiveGuestCount.round()),
              formatPlnZl(s.guestCost)),
          if (s.childMenuSeparate && s.childBilledCount > 0)
            _infoRow(
                'w tym menu dzieci (${s.childBilledCount.round()} os.)',
                formatPlnZl(s.childMenuTotal)),
          if (s.virtualGuests > 0)
            _infoRow(AppText.t.budget_virtualCostCount(s.virtualGuests.round()),
                formatPlnZl(s.virtualCost)),
          _infoRow(
              s.staffCalcMode != StaffCalcMode.headcount
                  ? AppText.t.budget_staffCost
                  : s.includeStaff
                      ? AppText.t.budget_staffCostCount(
                          s.staffCostPersonCount.round())
                      : AppText.t.budget_staffCostCountExcluded(
                          s.staffCostPersonCount.round()),
              formatPlnZl(s.staffCost)),
          _infoRow(AppText.t.sala_menuExtras, formatPlnZl(s.menuAddonsTotal)),
          _infoRow(AppText.t.budget_tableDecorTotal, formatPlnZl(s.tableDecoTotal)),
          if (s.cateringSeparate)
            _infoRow(AppText.t.sala_separateCatering,
                formatPlnZl(s.cateringSeparateTotal)),
          const Divider(height: 20),
          _infoRow(AppText.t.sala_venueTotal, formatPlnZl(s.cateringTotal),
              bold: true, big: true),
        ],
      ),
    );
  }

  // ── Pomocnicze widgety ──

  Widget _card({required String title, Widget? trailing, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EAF7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _addButton(VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: const Icon(Icons.add_circle_outline),
      color: AppColors.accent,
      tooltip: 'Dodaj',
    );
  }

  /// Odmiana rzeczownika „dziecko" — jedyne miejsce, gdzie liczba dzieci
  /// trafia do zdania.

  Widget _subHeader(String text, VoidCallback onAdd) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
          InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.add, size: 20, color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyHint(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(text,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight)),
      );

  Widget _infoRow(String label, String value,
      {bool bold = false, bool big = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: big ? 14 : 13,
                    color: bold ? AppColors.text : AppColors.textLight,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
          ),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: big ? 17 : 14,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: bold ? AppColors.accent : AppColors.text)),
        ],
      ),
    );
  }

  static double _d(dynamic v) => v is num ? v.toDouble() : 0.0;
  static int _id(Map<String, dynamic> m) => (m['id'] as num?)?.toInt() ?? 0;
}

/// Wiersz obsługi: nazwa + liczba osób + „w kosztach" + usuń.
class _StaffRow extends StatelessWidget {
  const _StaffRow({
    super.key,
    required this.name,
    required this.persons,
    required this.includeInCost,
    required this.onNameSaved,
    required this.onPersonsSaved,
    required this.onIncludeChanged,
    required this.onDelete,
  });

  final String name;
  final int persons;
  final bool includeInCost;
  final ValueChanged<String> onNameSaved;
  final ValueChanged<num> onPersonsSaved;
  final ValueChanged<bool> onIncludeChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: BudgetTextField(
                  hint: AppText.t.sala_staffNameHint,
                  initial: name,
                  onSaved: onNameSaved,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: BudgetNumberField(
                  suffix: AppText.t.common_personsShort,
                  integer: true,
                  initial: persons.toDouble(),
                  compact: true,
                  onSaved: onPersonsSaved,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.close, size: 18),
                color: const Color(0xFFC0392B),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Row(
            children: [
              Checkbox(
                value: includeInCost,
                activeColor: AppColors.accent,
                onChanged: (v) => onIncludeChanged(v ?? false),
              ),
              Expanded(
                child: Text(AppText.t.budget_includeInVenueCost,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.text)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Wiersz dodatku: nazwa + kwota + (opcjonalny) wynik linii + usuń.
class _AddonRow extends StatelessWidget {
  const _AddonRow({
    super.key,
    required this.name,
    required this.amount,
    required this.amountSuffix,
    required this.onNameSaved,
    required this.onAmountSaved,
    required this.onDelete,
    this.lineTotal,
  });

  final String name;
  final double amount;
  final String amountSuffix;
  final double? lineTotal;
  final ValueChanged<String> onNameSaved;
  final ValueChanged<num> onAmountSaved;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: BudgetTextField(
                  hint: 'Nazwa',
                  initial: name,
                  onSaved: onNameSaved,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: BudgetNumberField(
                  suffix: amountSuffix,
                  initial: amount,
                  compact: true,
                  onSaved: onAmountSaved,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.close, size: 18),
                color: const Color(0xFFC0392B),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (lineTotal != null && lineTotal! > 0)
            Padding(
              padding: const EdgeInsets.only(right: 40, top: 2),
              child: Text(
                '= ${formatPlnZl(lineTotal!)}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
