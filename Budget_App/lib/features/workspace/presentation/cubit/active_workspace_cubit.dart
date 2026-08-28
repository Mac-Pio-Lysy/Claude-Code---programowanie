import 'package:flutter_bloc/flutter_bloc.dart';

/// Remembers which budget the user last opened, so bottom-nav taps from
/// Oszczędności/OCR/Ustawienia can jump back to the right `/budget/:id`
/// without needing that id in their own paths.
class ActiveWorkspaceCubit extends Cubit<String?> {
  ActiveWorkspaceCubit() : super(null);

  void setActive(String budgetId) => emit(budgetId);
}
