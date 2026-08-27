import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/chart_mode.dart';

/// Toggles the workspace chart between the pie (category breakdown) and
/// line (spending trend) views via the arrow button on the chart card.
class ChartModeCubit extends Cubit<ChartMode> {
  ChartModeCubit() : super(ChartMode.pie);

  void toggle() => emit(state.next);
}
