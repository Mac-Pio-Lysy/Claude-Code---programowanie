import 'package:flutter_bloc/flutter_bloc.dart';

/// Selected budget category id, shared by the desktop sidebar rail and the
/// mobile pill-tab switcher so both stay in sync.
class CategoryFilterCubit extends Cubit<String?> {
  CategoryFilterCubit() : super(null);

  void select(String? categoryId) => emit(categoryId);
}
