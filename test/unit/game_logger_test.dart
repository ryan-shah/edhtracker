import 'dart:convert';

import 'package:edhtracker/game_logger.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/game_logger_factory.dart';

void main() {
  group('GameLogger', () {
    test('endGame sets session endTime', () {
      final logger = GameLogger(
        playerNames: ['A', 'B'],
        playerCommanderNames: const [['X'], ['Y']],
        playerArtUrls: const [[], []],
        startingLife: 40,
        startingPlayerIndex: 0,
        playerCount: 2,
        unconventionalCommanders: false,
      );
      expect(logger.getSession().endTime, isNull);
      logger.endGame();
      expect(logger.getSession().endTime, isNotNull);
    });

    test('goToPreviousTurn returns null on empty log', () {
      final logger = GameLogger(
        playerNames: ['A', 'B'],
        playerCommanderNames: const [['X'], ['Y']],
        playerArtUrls: const [[], []],
        startingLife: 40,
        startingPlayerIndex: 0,
        playerCount: 2,
        unconventionalCommanders: false,
      );
      expect(logger.goToPreviousTurn(), isNull);
      expect(logger.getTurnLog(), isEmpty);
    });

    test('goToPreviousTurn pops last entry and returns it', () {
      final logger = FakeGameBuilder()
          .addTurn(
            activePlayerIndex: 0,
            turnNumber: 1,
            durationSeconds: 30,
            playerStates: List.filled(4, null),
          )
          .addTurn(
            activePlayerIndex: 1,
            turnNumber: 1,
            durationSeconds: 45,
            playerStates: List.filled(4, null),
          )
          .build();

      expect(logger.getTurnLog(), hasLength(2));
      final removed = logger.goToPreviousTurn();
      expect(removed, isNotNull);
      expect(removed!.turnNumber, 1);
      expect(removed.activePlayerIndex, 1);
      expect(logger.getTurnLog(), hasLength(1));
    });

    test('skipped recordTurn collapses start/end and does not advance baseline', () {
      // Build a game where a skipped turn sits between two real turns. After
      // popping the second real turn, _lastTurnEndTime should match the first
      // real turn's end (not the skipped entry's collapsed timestamp).
      final logger = FakeGameBuilder()
          .addTurn(
            activePlayerIndex: 0,
            turnNumber: 1,
            durationSeconds: 30,
            playerStates: List.filled(4, null),
          )
          .addSkippedTurn(
            activePlayerIndex: 1,
            turnNumber: 1,
            playerStates: List.filled(4, null),
          )
          .addTurn(
            activePlayerIndex: 2,
            turnNumber: 1,
            durationSeconds: 60,
            playerStates: List.filled(4, null),
          )
          .build();

      final turns = logger.getTurnLog();
      expect(turns, hasLength(3));
      // Skipped entry shares end time with prior turn.
      expect(turns[1].skipped, isTrue);
      expect(turns[1].turnStartTime, equals(turns[0].turnEndTime));
      expect(turns[1].turnEndTime, equals(turns[0].turnEndTime));
      // The third (real) turn starts where the skipped entry "is" (which is
      // the first turn's end, since the skipped entry didn't advance).
      expect(turns[2].turnStartTime, equals(turns[0].turnEndTime));
    });

    test('toJsonString round-trips through fromJson', () {
      final original = FakeGameBuilder(
        playerNames: ['Alice', 'Bob'],
        playerCommanderNames: const [
          ['Atraxa, Praetors\' Voice'],
          ['Krenko, Mob Boss'],
        ],
        playerCount: 2,
      )
          .addTurn(
            activePlayerIndex: 0,
            turnNumber: 1,
            durationSeconds: 90,
            playerStates: [
              snapshot(
                playerIndex: 0,
                life: 38,
                actions: const {
                  'life_paid': 2,
                  'cards_milled': 0,
                  'extra_turns': 0,
                  'cards_drawn': 1,
                },
              ),
              snapshot(playerIndex: 1, life: 40),
            ],
          )
          .addTurn(
            activePlayerIndex: 1,
            turnNumber: 1,
            durationSeconds: 75,
            playerStates: [
              snapshot(playerIndex: 0, life: 38),
              snapshot(
                playerIndex: 1,
                life: 36,
                commanderDamageTaken: [
                  CommanderDamageTaken(
                    sourcePlayerIndex: 0,
                    commanderName: 'Atraxa, Praetors\' Voice',
                    damage: 4,
                  ),
                ],
              ),
            ],
          )
          .build();
      original.endGame();

      final json = original.toJsonString();
      final reconstructed = GameLogger.fromJson(json);

      expect(reconstructed.getTurnLog(), hasLength(2));
      expect(reconstructed.getSession().playerNames, ['Alice', 'Bob']);
      expect(reconstructed.getSession().startingLife, 40);
      expect(reconstructed.getSession().playerCount, 2);
      expect(reconstructed.getTurnLog()[1].playerStates[1].life, 36);
      expect(
        reconstructed
            .getTurnLog()[1]
            .playerStates[1]
            .commanderDamageTaken
            .first
            .damage,
        4,
      );
    });

    test('fromJson handles missing endTime gracefully', () {
      final json = jsonEncode({
        'game_session': {
          'start_time': DateTime(2026, 1, 1).toIso8601String(),
          'starting_life': 40,
          'player_count': 2,
          'players': [
            {'player_index': 0, 'name': 'A', 'commanders': ['X']},
            {'player_index': 1, 'name': 'B', 'commanders': ['Y']},
          ],
        },
        'turn_log': [],
      });

      final logger = GameLogger.fromJson(json);
      expect(logger.getSession().endTime, isNull);
      expect(logger.getTurnLog(), isEmpty);
    });

    test('fromJson defaults unconventionalCommanders to false', () {
      final json = jsonEncode({
        'game_session': {
          'start_time': DateTime(2026, 1, 1).toIso8601String(),
          'starting_life': 40,
          'player_count': 2,
          'players': [
            {'player_index': 0, 'name': 'A', 'commanders': ['X']},
            {'player_index': 1, 'name': 'B', 'commanders': ['Y']},
          ],
        },
        'turn_log': [],
      });

      final logger = GameLogger.fromJson(json);
      expect(logger.getSession().unconventionalCommanders, isFalse);
    });

    test('skipped flag survives JSON round-trip', () {
      final original = FakeGameBuilder()
          .addTurn(
            activePlayerIndex: 0,
            turnNumber: 1,
            durationSeconds: 10,
            playerStates: List.filled(4, null),
          )
          .addSkippedTurn(
            activePlayerIndex: 1,
            turnNumber: 1,
            playerStates: List.filled(4, null),
          )
          .build();

      final reconstructed = GameLogger.fromJson(original.toJsonString());
      expect(reconstructed.getTurnLog()[0].skipped, isFalse);
      expect(reconstructed.getTurnLog()[1].skipped, isTrue);
    });
  });
}
