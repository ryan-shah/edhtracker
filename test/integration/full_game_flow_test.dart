import 'dart:convert';

import 'package:edhtracker/game_log_file_service.dart';
import 'package:edhtracker/game_setup_page.dart';
import 'package:edhtracker/game_summary_page.dart';
import 'package:edhtracker/life_tracker_page.dart';
import 'package:edhtracker/player_card.dart';
import 'package:edhtracker/scryfall_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_file_service.dart';
import '../helpers/fake_scryfall_client.dart';

PlayerCardState stateFor(WidgetTester tester, int playerIndex) {
  final cards = tester
      .widgetList<PlayerCard>(find.byType(PlayerCard))
      .toList();
  for (final card in cards) {
    if (card.playerIndex == playerIndex) {
      final element = find.byWidget(card).evaluate().single;
      return (element as StatefulElement).state as PlayerCardState;
    }
  }
  throw StateError('No PlayerCard found for index $playerIndex');
}

PlayerCard activeCard(WidgetTester tester) {
  return tester
      .widgetList<PlayerCard>(find.byType(PlayerCard))
      .firstWhere((c) => c.isCurrentTurn);
}

void main() {
  late MockHttpClient client;
  late FakeGameLogFileService fakeFileService;

  setUpAll(() {
    registerHttpFallbacks();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    client = MockHttpClient();
    when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
      (_) async => okJson(jsonEncode({
            'image_uris': {'art_crop': 'https://example.com/fake.jpg'},
          })),
    );
    ScryfallService.setDefaultInstance(ScryfallService(client: client));
    fakeFileService = FakeGameLogFileService();
    GameLogFileService.setDefaultInstance(fakeFileService);
  });

  tearDown(() {
    ScryfallService.resetDefaultInstance();
    GameLogFileService.resetDefaultInstance();
  });

  testWidgets('full game flow: setup → play → eliminate → undo → complete → summary',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));

    // 1. Start at setup, switch to 2 players (faster to drive), then start.
    await tester.pumpWidget(const MaterialApp(home: GameSetupPage()));
    await tester.pump();

    final playerCountDropdown = find.ancestor(
      of: find.text('Number of Players'),
      matching: find.byType(DropdownButtonFormField<int>),
    );
    await tester.tap(playerCountDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('2 Players').last);
    await tester.pumpAndSettle();

    // Default: starting player = Random which falls back to a valid index in
    // [0, playerCount). Tap Start Game.
    await tester.tap(find.text('Start Game'));
    await tester.pumpAndSettle();

    // 2. We are now on the LifeTrackerPage with 2 players.
    expect(find.byType(LifeTrackerPage), findsOneWidget);
    expect(find.byType(PlayerCard), findsNWidgets(2));

    // 3. Drive a few turns with life and counter changes.
    final starter = activeCard(tester).playerIndex;
    final other = 1 - starter;

    // Starter pays 3 life via in-state mutators (avoids overlay UI complexity).
    final starterState = stateFor(tester, starter);
    starterState.incrementLifePaid();
    starterState.incrementLifePaid();
    starterState.incrementLifePaid();
    await tester.pump();

    // End turn 1 → other player's turn.
    activeCard(tester).onTurnEnd();
    await tester.pump(const Duration(milliseconds: 50));

    // Other player deals 21 commander damage to starter.
    final receiverState = stateFor(tester, starter);
    for (int i = 0; i < 21; i++) {
      receiverState.incrementCommanderDamage(other, 0);
    }
    await tester.pump();
    expect(receiverState.isEliminated, isTrue);
    expect(find.text('ELIMINATED'), findsOneWidget);

    // Advance — should skip the eliminated starter.
    activeCard(tester).onTurnEnd();
    await tester.pump(const Duration(milliseconds: 50));
    expect(activeCard(tester).playerIndex, other);

    // 4. Undo back through the skipped entry.
    activeCard(tester).onTurnBack();
    await tester.pump(const Duration(milliseconds: 50));
    expect(activeCard(tester).playerIndex, other);

    // 5. Open menu → Complete Game → confirm.
    await tester.tap(find.byType(FloatingActionButton).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.check_circle_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End Game'));
    await tester.pumpAndSettle();

    // 6. Land on summary page; basic sections visible.
    expect(find.byType(GameSummaryPage), findsOneWidget);
    expect(find.text('Game Session'), findsOneWidget);
    expect(find.text('Damage Stats'), findsOneWidget);

    // 7. Download full log via injected fake file service.
    await tester.tap(find.byTooltip('Download game log'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Full Game Log'));
    await tester.pumpAndSettle();

    expect(fakeFileService.savedFiles, hasLength(1));
    expect(fakeFileService.savedFiles.first.jsonData, contains('turn_log'));
  });
}
