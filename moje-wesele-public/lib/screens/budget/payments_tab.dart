import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/payment_item.dart';
import '../../models/wedding_data.dart';
import '../../utils/format.dart';

/// Terminy płatności (Sala, Wydatki, Podróż poślubna, raty dostawców) —
/// przypomnienia o zbliżających się/zaległych terminach oraz filtrowana lista
/// pozycji. Osadzany w podzakładce „Podsumowanie". Zbiorcze sumy (Opłacono/
/// Pozostało) są już pokazane wyżej w karcie wartości Podsumowania — nie
/// duplikujemy ich tutaj.
class PaymentsSection extends StatefulWidget {
  const PaymentsSection({super.key, required this.data});

  final WeddingData? data;

  @override
  State<PaymentsSection> createState() => _PaymentsSectionState();
}

class _PaymentsSectionState extends State<PaymentsSection> {
  PaymentSource? _filter; // null = wszystkie

  @override
  Widget build(BuildContext context) {
    final all = buildPaymentItems(widget.data);

    final upcoming = all.where((i) => i.soon || i.overdue).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final filtered =
        _filter == null ? all : all.where((i) => i.source == _filter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (upcoming.isNotEmpty) ...[
          _remindersCard(upcoming),
          const SizedBox(height: 16),
        ],
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text(
                'Brak płatności w tym widoku.',
                style:
                    GoogleFonts.inter(fontSize: 14, color: AppColors.textLight),
              ),
            ),
          )
        else
          for (final item in filtered)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PaymentCard(item: item),
            ),
        const SizedBox(height: 12),
        _filters(),
      ],
    );
  }

  Widget _remindersCard(List<PaymentItem> upcoming) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔔 Przypomnienia o płatnościach',
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFB45309)),
          ),
          const SizedBox(height: 8),
          for (final i in upcoming)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(i.source.icon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      i.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text),
                    ),
                  ),
                  if (i.dueDate.isNotEmpty)
                    Text(i.dueDate,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textLight)),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: i.overdue
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      i.overdue ? 'zaległa!' : 'wkrótce',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: i.overdue
                            ? const Color(0xFFC0392B)
                            : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _filters() {
    Widget chip(String label, PaymentSource? src) {
      final selected = _filter == src;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => setState(() => _filter = src),
          showCheckmark: false,
          labelStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textLight,
          ),
          selectedColor: AppColors.accent,
          backgroundColor: Colors.white,
          side: BorderSide(
              color: selected ? AppColors.accent : const Color(0xFFDCE4F2)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('Wszystkie', null),
          chip('🏠 Sala', PaymentSource.sala),
          chip('📋 Wydatki', PaymentSource.expenses),
          chip('🏢 Dostawcy', PaymentSource.vendor),
          chip('✈️ Podróż', PaymentSource.honeymoon),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.item});

  final PaymentItem item;

  ({Color bg, Color fg, String text}) get _badge {
    if (item.fullyPaid) {
      return (
        bg: const Color(0xFFECFDF5),
        fg: const Color(0xFF059669),
        text: '✓ Opłacone'
      );
    }
    if (item.paid > 0) {
      return (
        bg: const Color(0xFFFEF3C7),
        fg: const Color(0xFFB45309),
        text: '⚡ Częściowo'
      );
    }
    return (
      bg: const Color(0xFFFEE2E2),
      fg: const Color(0xFFC0392B),
      text: '✗ Nieopłacone'
    );
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badge;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: item.overdue
                ? const Color(0xFFE9A8A8)
                : const Color(0xFFE2EAF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${item.source.icon} ${item.source.label}',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textLight),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badge.bg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(badge.text,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: badge.fg)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.name,
            style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.text),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Kwota: ${formatPlnZl(item.effective)}${item.isPredicted ? ' ~' : ''}',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textLight),
                ),
              ),
              if (item.dueDate.isNotEmpty)
                Text(
                  '📅 ${item.dueDate}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: item.overdue
                        ? const Color(0xFFC0392B)
                        : AppColors.textLight,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Opłacono ${formatPlnZl(item.paid)} · Pozostało ${formatPlnZl(item.remaining)}',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}
