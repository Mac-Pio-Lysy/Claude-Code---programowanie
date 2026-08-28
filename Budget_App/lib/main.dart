import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app/app.dart';

void main() {
  // This is an offline-first app (see architecture.c4): never block startup,
  // or crash, on a network fetch for typography. Falls back to the system
  // font when Inter isn't already bundled/cached.
  GoogleFonts.config.allowRuntimeFetching = false;

  runApp(const BudgetApp());
}
