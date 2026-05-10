import 'package:edhtracker/game_setup_page.dart';
import 'package:edhtracker/game_summary_page.dart';
import 'package:edhtracker/life_tracker_page.dart';
import 'package:edhtracker/player_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

LifeTrackerPage buildPage({int playerCount = 4, int startingPlayer = 0}) {
  return LifeTrackerPage(
    playerNames: ['Alice', 'Bob', 'Carol', 'Dave']
        .take(playerCount)
        .toList(),
    playerCommanderNames: List.generate(
      playerCount,
      (i) => ['Commander ${i + 1}'],
    ),
    playerArtUrls: List.generate(playerCount, (_) => const <String>[]),
    startingLife: 40,
    startingPlayerIndex: startingPlayer,
    playerCount: playerCount,
  );
}

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

/// Returns the PlayerCard widget whose isCurrentTurn is true.
PlayerCard activeCard(WidgetTester tester) {
  return tester
      .widgetList<PlayerCard>(find.byType(PlayerCard))
      .firstWhere((c) => c.isCurrentTurn);
}

Future<void> pump(WidgetTester tester, {int playerCount = 4, int startingPlayer = 0}) async {
  await tester.binding.setSurfaceSize(const Size(1280, 720));
  await tester.pumpWidget(MaterialApp(
    home: buildPage(playerCount: playerCount, startingPlayer: startingPlayer),
  ));
  await tester.pump();
}

void main() {
  group('LifeTrackerPage', () {
    testWidgets('renders 4 player cards by default', (tester) async {
      await pump(tester);
      expect(find.byType(PlayerCard), findsNWidgets(4));
    });

    testWidgets('starting player has Turn 1 displayed; advancing increments cards drawn', (tester) async {
      await pump(tester);
      // Let post-frame callback for cardsDrawn + timer fire.
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Turn 1'), findsOneWidget);

      // Cards-Drawn auto-incremented for player 0 once.
      expect(stateFor(tester, 0).cardsDrawn, 1);

      // Invoke the active card's onTurnEnd to advance to player 1.
      activeCard(tester).onTurnEnd();
      await tester.pump(const Duration(milliseconds: 50));

      // Cards-Drawn auto-incremented for player 1.
      expect(stateFor(tester, 1).cardsDrawn, 1);
      expect(stateFor(tester, 0).cardsDrawn, 1);
    });

    testWidgets('turn count increments only after wrapping past starting player', (tester) async {
      await pump(tester);
      await tester.pump(const Duration(milliseconds: 50));

      // 4 advances walk: 0 -> 1 -> 2 -> 3 -> 0 (turn 2)
      for (int i = 0; i < 4; i++) {
        activeCard(tester).onTurnEnd();
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(activeCard(tester).turnCount, 2);
    });

    testWidgets('onTurnBack reverts cursor and decrements cardsDrawn', (tester) async {
      await pump(tester);
      await tester.pump(const Duration(milliseconds: 50));

      // Advance once: 0 -> 1
      activeCard(tester).onTurnEnd();
      await tester.pump(const Duration(milliseconds: 50));
      expect(stateFor(tester, 1).cardsDrawn, 1);

      // Undo: cardsDrawn for player 1 decrements, cursor back to 0.
      activeCard(tester).onTurnBack();
      await tester.pump(const Duration(milliseconds: 50));
      expect(stateFor(tester, 1).cardsDrawn, 0);
      expect(stateFor(tester, 0).cardsDrawn, 1);
      expect(activeCard(tester).playerIndex, 0);
    });

    testWidgets('central menu opens to reveal 4 surrounding buttons', (tester) async {
      await pump(tester);
      await tester.pump(const Duration(milliseconds: 50));

      // Initially only main menu FAB is in the tree.
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Open menu.
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Now help, new-game, complete-game, timer + main = 5 FABs.
      expect(find.byType(FloatingActionButton), findsNWidgets(5));
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
      expect(find.byIcon(Icons.restart_alt), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      // Timer is initially disabled, so timer_off icon is shown.
      expect(find.byIcon(Icons.timer_off_outlined), findsOneWidget);
    });

    testWidgets('reset dialog cancel keeps tracker; complete game navigates to summary', (tester) async {
      await pump(tester);
      await tester.pump(const Duration(milliseconds: 50));

      // Open menu and tap Complete Game.
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();
      // Confirmation dialog appears.
      expect(find.text('End Game?'), findsOneWidget);
      // Cancel keeps us on the page.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(LifeTrackerPage), findsOneWidget);

      // Open menu again and confirm End Game.
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('End Game'));
      await tester.pumpAndSettle();

      // Navigation lands on the summary page.
      expect(find.byType(GameSummaryPage), findsOneWidget);
    });

    testWidgets('reset cancel from new-game dialog returns to setup', (tester) async {
      await pump(tester);
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.restart_alt));
      await tester.pumpAndSettle();
      expect(find.text('New Game?'), findsOneWidget);
      await tester.tap(find.text('New Game (Clear Players)'));
      await tester.pumpAndSettle();
      expect(find.byType(GameSetupPage), findsOneWidget);
    });

    testWidgets('timer toggle flips the icon between off/on', (tester) async {
      await pump(tester);
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.timer_off_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.timer_off_outlined));
      await tester.pump();
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    });

    testWidgets('eliminated player is skipped on advance', (tester) async {
      await pump(tester);
      await tester.pump(const Duration(milliseconds: 50));

      // Eliminate player 1.
      final p1 = stateFor(tester, 1);
      for (int i = 0; i < 40; i++) {
        p1.decrementLife();
      }
      await tester.pump();
      expect(p1.isEliminated, isTrue);

      // Advance from player 0 → should skip player 1, land on player 2.
      activeCard(tester).onTurnEnd();
      await tester.pump(const Duration(milliseconds: 50));

      expect(activeCard(tester).playerIndex, 2);
      expect(stateFor(tester, 2).cardsDrawn, 1);
      expect(stateFor(tester, 1).cardsDrawn, 0);
    });

    testWidgets('undo across a skipped turn lands on the previous real turn', (tester) async {
      await pump(tester);
      await tester.pump(const Duration(milliseconds: 50));

      // Eliminate player 1.
      final p1 = stateFor(tester, 1);
      for (int i = 0; i < 40; i++) {
        p1.decrementLife();
      }
      await tester.pump();

      // Advance: log turn 1 (active=0), skip 1, land on 2.
      activeCard(tester).onTurnEnd();
      await tester.pump(const Duration(milliseconds: 50));
      expect(activeCard(tester).playerIndex, 2);

      // Undo back through the skipped entry → land on p0.
      activeCard(tester).onTurnBack();
      await tester.pump(const Duration(milliseconds: 50));
      expect(activeCard(tester).playerIndex, 0);
    });
  });
}
