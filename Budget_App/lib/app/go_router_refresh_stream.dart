import 'dart:async';

import 'package:flutter/foundation.dart';

/// Bridges a Bloc/Cubit's state stream (e.g. AuthBloc) to GoRouter's
/// `refreshListenable`, so route `redirect` re-evaluates on every auth
/// state change. Standard go_router + bloc integration pattern.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
