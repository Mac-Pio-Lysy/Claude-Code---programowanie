import 'package:flutter/material.dart';

import 'support_us_view.dart';

/// Shows [SupportUsView] as a modal — used when the "+" add-budget action
/// hits the Free tier's 1-budget limit. MonetizationCubit is provided above
/// the app's root Navigator, so it's reachable from this dialog's context
/// without any extra re-wrapping.
Future<void> showSupportUsModal(BuildContext context, {String? limitMessage}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
        child: SupportUsView(limitMessage: limitMessage),
      ),
    ),
  );
}
