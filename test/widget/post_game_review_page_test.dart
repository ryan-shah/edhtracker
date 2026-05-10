import 'package:edhtracker/game_stats_utility.dart';
import 'package:edhtracker/post_game_review_page.dart';
import 'package:edhtracker/scryfall_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_scryfall_client.dart';
import '../helpers/game_logger_factory.dart';

void main() {
  late MockHttpClient client;

  setUpAll(() {
    registerHttpFallbacks();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    client = MockHttpClient();
    when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
      (_) async => okJson('{"object":"list","data":[]}'),
    );
    ScryfallService.setDefaultInstance(ScryfallService(client: client));
  });

  tearDown(() {
    ScryfallService.resetDefaultInstance();
  });

  GameStatsUtility sampleStats() {
    final logger = FakeGameBuilder(
      playerNames: ['Alice', 'Bob', 'Carol', 'Dave'],
    )
        .addTurn(
          activePlayerIndex: 0,
          turnNumber: 1,
          durationSeconds: 30,
          playerStates: List.filled(4, null),
        )
        .build();
    logger.endGame();
    return GameStatsUtility(logger);
  }

  Future<void> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1400));
    final stats = sampleStats();
    await tester.pumpWidget(MaterialApp(
      home: PostGameReviewPage(gameStatsUtility: stats),
    ));
    await tester.pumpAndSettle();
  }

  group('PostGameReviewPage', () {
    testWidgets('toggling Draw hides winner / win condition / your seat', (tester) async {
      await pump(tester);
      expect(find.text('Game Winner'), findsOneWidget);
      expect(find.text('Win Condition'), findsOneWidget);
      expect(find.text('Your Seat'), findsOneWidget);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(find.text('Game Winner'), findsNothing);
      expect(find.text('Win Condition'), findsNothing);
      expect(find.text('Your Seat'), findsNothing);
    });

    testWidgets('Submit Review calls setReviewDetails with current state', (tester) async {
      // Build the stats utility manually so we can assert against it.
      final logger = FakeGameBuilder(
        playerNames: ['Alice', 'Bob', 'Carol', 'Dave'],
      )
          .addTurn(
            activePlayerIndex: 0,
            turnNumber: 1,
            durationSeconds: 30,
            playerStates: List.filled(4, null),
          )
          .build();
      logger.endGame();
      final stats = GameStatsUtility(logger);

      await tester.binding.setSurfaceSize(const Size(600, 1400));
      await tester.pumpWidget(MaterialApp(
        home: PostGameReviewPage(gameStatsUtility: stats),
      ));
      await tester.pumpAndSettle();

      // Toggle Bob's fast-mana checkbox (index 1).
      final bobTile = find.widgetWithText(CheckboxListTile, 'Bob');
      await tester.tap(bobTile);
      await tester.pumpAndSettle();

      // Submit (winner defaults to Alice / index 0).
      await tester.ensureVisible(find.text('Submit Review'));
      await tester.tap(find.text('Submit Review'));
      await tester.pumpAndSettle();

      // The result-JSON dialog should be open.
      expect(find.text('Review Details JSON'), findsOneWidget);

      // Stats utility now has the review block.
      final json = stats.toJson();
      final review = json['review_details'] as Map<String, dynamic>;
      expect(review['is_draw'], false);
      expect(review['winner_seat_number'], 1); // Alice = seat 1 since startingPlayer=0
      final fastMana = review['fast_mana_players'] as List;
      expect(fastMana[1]['had_fast_mana'], true);
      expect(fastMana[0]['had_fast_mana'], false);
    });

    testWidgets('Win Condition dropdown lists all conditions', (tester) async {
      await pump(tester);
      final dropdown = find.ancestor(
        of: find.text('Win Condition'),
        matching: find.byType(DropdownButtonFormField<String>),
      );
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      // Spot-check a few options.
      for (final cond in ['combat damage', 'commander damage', 'concession']) {
        expect(find.text(cond), findsAtLeastNWidgets(1));
      }
    });
  });
}
