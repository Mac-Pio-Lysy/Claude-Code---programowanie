import 'package:flutter_bloc/flutter_bloc.dart';

/// Which chart AnalyticsPanelCard is currently showing.
enum AnalyticsView { pie, comparison }

/// Toggled by the arrow button in AnalyticsPanelCard's header (AB-5).
class AnalyticsViewCubit extends Cubit<AnalyticsView> {
  AnalyticsViewCubit() : super(AnalyticsView.pie);

  void toggle() => emit(state == AnalyticsView.pie ? AnalyticsView.comparison : AnalyticsView.pie);
}
