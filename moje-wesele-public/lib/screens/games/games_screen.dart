import 'package:flutter/material.dart';

import '../../models/wedding_data.dart';
import '../../services/firestore_service.dart';
import '../../widgets/tabbed_section_scaffold.dart';
import '../bingo/bingo_screen.dart';
import 'photo_challenge_screen.dart';
import 'photo_guess_screen.dart';
import 'quiz_screen.dart';
import 'true_false_screen.dart';
import 'wheel_screen.dart';
import '../../l10n/app_text.dart';

/// Sekcja „Ślubne gry" — zbiorcza zakładka na zabawy dla gości.
///
/// Każda gra jest osobną podzakładką. Dodanie kolejnej gry = dopisanie wpisu
/// do listy [_games] (TabBar/TabBarView budują się automatycznie).
class GamesScreen extends StatelessWidget {
  const GamesScreen({
    super.key,
    required this.data,
    required this.firestore,
  });

  final WeddingData? data;
  final FirestoreService firestore;

  List<SectionTab> get _games => [
        (
          label: AppText.t.games_bingo,
          view: BingoScreen(
            data: data,
            firestore: firestore,
            showHeader: false,
          ),
        ),
        (
          label: AppText.t.games_quiz,
          view: QuizScreen(data: data, firestore: firestore),
        ),
        (
          label: AppText.t.games_trueFalse,
          view: TrueFalseScreen(data: data, firestore: firestore),
        ),
        (
          label: AppText.t.games_photoGuess,
          view: PhotoGuessScreen(data: data, firestore: firestore),
        ),
        (
          label: AppText.t.games_wheel,
          view: WheelScreen(data: data, firestore: firestore),
        ),
        (
          label: AppText.t.games_photoChallenge,
          view: PhotoChallengeScreen(data: data, firestore: firestore),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return TabbedSectionScaffold(title: AppText.t.games_title, tabs: _games);
  }
}
