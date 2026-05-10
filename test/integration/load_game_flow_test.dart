import 'dart:convert';

import 'package:edhtracker/game_log_file_service.dart';
import 'package:edhtracker/game_setup_page.dart';
import 'package:edhtracker/game_summary_page.dart';
import 'package:edhtracker/scryfall_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_file_service.dart';
import '../helpers/fake_scryfall_client.dart';
import '../helpers/game_logger_factory.dart';

void main() {
  late MockHttpClient client;
  late FakeGameLogFileService fakeFileService;

  setUpAll(() {
    registerHttpFallbacks();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    client = MockHttpClient();
    // Return a response without an art_crop so getCardArtUrl yields null —
    // avoids network loads of fake URLs in the summary page.
    when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
      (_) async => okJson(jsonEncode({'image_uris': {}})),
    );
    ScryfallService.setDefaultInstance(ScryfallService(client: client));
    fakeFileService = FakeGameLogFileService();
    GameLogFileService.setDefaultInstance(fakeFileService);
  });

  tearDown(() {
    ScryfallService.resetDefaultInstance();
    GameLogFileService.resetDefaultInstance();
  });

  testWidgets('Load Game from setup → land on summary with stats from fixture',
      (tester) async {
    // Build a known game and serialize it to JSON.
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
          durationSeconds: 90, // longest turn
          playerStates: [
            snapshot(playerIndex: 0, life: 38),
            snapshot(playerIndex: 1, life: 35),
            snapshot(playerIndex: 2, life: 40),
            snapshot(playerIndex: 3, life: 38),
          ],
        )
        .build();
    logger.endGame();
    final fixtureJson = logger.toJsonString();

    // Wire the fake file service to return this JSON when asked.
    fakeFileService.nextLoad = LoadedGameFile(fixtureJson, 'fixture.json');

    await tester.binding.setSurfaceSize(const Size(600, 1400));
    await tester.pumpWidget(const MaterialApp(home: GameSetupPage()));
    await tester.pump();

    await tester.tap(find.byTooltip('Load Game'));
    await tester.pumpAndSettle();

    // We should land on the summary page for the loaded game.
    expect(find.byType(GameSummaryPage), findsOneWidget);
    expect(find.text('Game Session'), findsOneWidget);
  });

  testWidgets('Load Game with no file selected stays on setup', (tester) async {
    fakeFileService.nextLoad = null;

    await tester.binding.setSurfaceSize(const Size(600, 1400));
    await tester.pumpWidget(const MaterialApp(home: GameSetupPage()));
    await tester.pump();

    await tester.tap(find.byTooltip('Load Game'));
    await tester.pumpAndSettle();

    expect(find.byType(GameSetupPage), findsOneWidget);
    expect(find.byType(GameSummaryPage), findsNothing);
  });

  testWidgets('Load Game with corrupt JSON shows snackbar and stays on setup',
      (tester) async {
    fakeFileService.nextLoad = LoadedGameFile('not valid json', 'bad.json');

    await tester.binding.setSurfaceSize(const Size(600, 1400));
    await tester.pumpWidget(const MaterialApp(home: GameSetupPage()));
    await tester.pump();

    await tester.tap(find.byTooltip('Load Game'));
    await tester.pumpAndSettle();

    expect(find.byType(GameSetupPage), findsOneWidget);
    expect(find.textContaining('Error loading game'), findsOneWidget);
  });
}
