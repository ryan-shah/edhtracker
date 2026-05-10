import 'package:edhtracker/game_log_file_service.dart';
import 'package:edhtracker/game_logger.dart';
import 'package:edhtracker/game_summary_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_file_service.dart';
import '../helpers/game_logger_factory.dart';

void main() {
  late FakeGameLogFileService fakeFileService;

  setUp(() {
    fakeFileService = FakeGameLogFileService();
    GameLogFileService.setDefaultInstance(fakeFileService);
  });

  tearDown(() {
    GameLogFileService.resetDefaultInstance();
  });

  GameLogger sampleLogger() {
    final logger = FakeGameBuilder(
      playerNames: ['Alice', 'Bob', 'Carol', 'Dave'],
    )
        .addTurn(
          activePlayerIndex: 0,
          turnNumber: 1,
          durationSeconds: 30,
          playerStates: [
            snapshot(playerIndex: 0, life: 40),
            snapshot(playerIndex: 1, life: 35),
            snapshot(playerIndex: 2, life: 40),
            snapshot(playerIndex: 3, life: 40),
          ],
        )
        .addTurn(
          activePlayerIndex: 1,
          turnNumber: 1,
          durationSeconds: 60,
          playerStates: [
            snapshot(playerIndex: 0, life: 38),
            snapshot(playerIndex: 1, life: 35),
            snapshot(playerIndex: 2, life: 40),
            snapshot(playerIndex: 3, life: 38),
          ],
        )
        .build();
    logger.endGame();
    return logger;
  }

  Future<void> pump(WidgetTester tester, GameLogger logger) async {
    await tester.binding.setSurfaceSize(const Size(600, 1400));
    await tester.pumpWidget(MaterialApp(home: GameSummaryPage(gameLogger: logger)));
    await tester.pumpAndSettle();
  }

  group('GameSummaryPage', () {
    testWidgets('default view shows Overall Game Stats sections', (tester) async {
      await pump(tester, sampleLogger());
      expect(find.text('Game Session'), findsOneWidget);
      expect(find.text('Damage Stats'), findsOneWidget);
      // Total turns = 2 (no skipped), starting life = 40 — both rendered.
      expect(find.text('40'), findsAtLeastNWidgets(1));
      expect(find.text('2'), findsAtLeastNWidgets(1));
    });

    testWidgets('switching dropdown to a player shows that player\'s stats',
        (tester) async {
      await pump(tester, sampleLogger());
      // Dropdown is Overall by default — "Game Session" section is shown.
      expect(find.text('Game Session'), findsOneWidget);

      await tester.tap(find.text('Overall Game Stats'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alice Stats').last);
      await tester.pumpAndSettle();

      // Per-player view replaces the Game Session section with Turn Time Stats.
      expect(find.text('Game Session'), findsNothing);
      expect(find.text('Turn Time Stats'), findsOneWidget);
    });

    testWidgets('download icon → "Full Game Log" calls saveJson with logger JSON',
        (tester) async {
      await pump(tester, sampleLogger());
      await tester.tap(find.byTooltip('Download game log'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Full Game Log'));
      await tester.pumpAndSettle();

      expect(fakeFileService.savedFiles, hasLength(1));
      final saved = fakeFileService.savedFiles.first;
      expect(saved.filename, startsWith('full_game_log_'));
      expect(saved.jsonData, contains('game_session'));
      expect(saved.jsonData, contains('turn_log'));
    });

    testWidgets('download icon → "Player Stats Summary" calls saveJson with stats JSON',
        (tester) async {
      await pump(tester, sampleLogger());
      await tester.tap(find.byTooltip('Download game log'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Player Stats Summary'));
      await tester.pumpAndSettle();

      expect(fakeFileService.savedFiles, hasLength(1));
      final saved = fakeFileService.savedFiles.first;
      expect(saved.filename, startsWith('player_stats_summary_'));
      expect(saved.jsonData, contains('player_stats'));
    });

    testWidgets('download dialog Cancel does not call saveJson', (tester) async {
      await pump(tester, sampleLogger());
      await tester.tap(find.byTooltip('Download game log'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(fakeFileService.savedFiles, isEmpty);
    });
  });
}
