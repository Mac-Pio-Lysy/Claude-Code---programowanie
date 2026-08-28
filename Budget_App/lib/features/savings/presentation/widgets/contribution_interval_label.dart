import '../../domain/models/contribution_interval.dart';

String contributionIntervalLabel(ContributionInterval interval) => switch (interval) {
      ContributionInterval.weekly => 'co tydzień',
      ContributionInterval.biWeekly => 'co 2 tygodnie',
      ContributionInterval.monthly => 'co miesiąc',
      ContributionInterval.quarterly => 'co kwartał',
    };

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

/// "Aby osiągnąć cel do 01.06.2026, odkładaj 350,00 zł co miesiąc" — or null
/// when the goal has no target date to pace against.
String? pacingMessage({
  required DateTime? targetDate,
  required double requiredContribution,
  required ContributionInterval interval,
  required String Function(num) formatCurrency,
}) {
  if (targetDate == null) return null;
  return 'Aby osiągnąć cel do ${_formatDate(targetDate)}, odkładaj '
      '${formatCurrency(requiredContribution)} ${contributionIntervalLabel(interval)}';
}
