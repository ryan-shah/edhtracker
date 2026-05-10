import 'package:edhtracker/game_logger.dart';
import 'package:edhtracker/game_stats_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/game_logger_factory.dart';

void main() {
  group('GameStatsUtility', () {
    test('skipped turns are filtered out and do not inflate counts', () {
      final logger = FakeGameBuilder()
          .addTurn(
            activePlayerIndex: 0,
            turnNumber: 1,
            durationSeconds: 60,
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
            durationSeconds: 30,
            playerStates: List.filled(4, null),
          )
          .build();

      final stats = GameStatsUtility(logger);
      expect(stats.turnLog, hasLength(2));
      expect(stats.allPlayerStats[1].timeStats.turnCount, 0);
    });

    test('longestTurn picks the turn with max duration', () {
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
            durationSeconds: 120,
            playerStates: List.filled(4, null),
          )
          .addTurn(
            activePlayerIndex: 2,
            turnNumber: 1,
            durationSeconds: 45,
            playerStates: List.filled(4, null),
          )
          .build();

      final stats = GameStatsUtility(logger);
      expect(stats.longestTurn, isNotNull);
      expect(stats.longestTurn!.duration.inSeconds, 120);
      expect(stats.longestTurn!.playerIndex, 1);
    });

    test('overall damage stats use first-turn delta vs starting life', () {
      // First turn: player 0 active, player 1 takes 5 life loss vs starting 40.
      final logger = FakeGameBuilder()
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
          .build();

      final stats = GameStatsUtility(logger);
      // 5 damage attributed to active player 0; starting life - actual = 5 for
      // player 1, plus 0 for everyone else => total turn damage 5.
      expect(stats.overallDamageStats!.mostDamagePlayer!.key, 0);
      expect(stats.overallDamageStats!.mostDamagePlayer!.value, 5);
    });

    test('subsequent-turn damage uses prev snapshot delta and only positive deltas', () {
      final logger = FakeGameBuilder()
          .addTurn(
            activePlayerIndex: 0,
            turnNumber: 1,
            durationSeconds: 30,
            playerStates: [
              snapshot(playerIndex: 0, life: 40),
              snapshot(playerIndex: 1, life: 40),
              snapshot(playerIndex: 2, life: 40),
              snapshot(playerIndex: 3, life: 40),
            ],
          )
          .addTurn(
            activePlayerIndex: 1,
            turnNumber: 1,
            durationSeconds: 30,
            playerStates: [
              snapshot(playerIndex: 0, life: 35), // -5
              snapshot(playerIndex: 1, life: 40), // 0
              snapshot(playerIndex: 2, life: 45), // life gain (+5) — not damage
              snapshot(playerIndex: 3, life: 38), // -2
            ],
          )
          .build();

      final stats = GameStatsUtility(logger);
      // 7 damage credited to active player 1 on turn 2.
      expect(stats.overallDamageStats!.mostDamagePlayer!.key, 1);
      expect(stats.overallDamageStats!.mostDamagePlayer!.value, 7);
    });

    test('commander damage attributed by source/commander key, partners separated', () {
      // Setup: player 0 has a partner pair (Tymna + Thrasios), player 1 takes
      // damage from each commander separately.
      final logger = FakeGameBuilder(
        playerCommanderNames: const [
          ['Tymna the Weaver', 'Thrasios, Triton Hero'],
          ['Krenko, Mob Boss'],
          ['Kaalia of the Vast'],
          ['Sliver Overlord'],
        ],
      )
          .addTurn(
            activePlayerIndex: 0,
            turnNumber: 1,
            durationSeconds: 30,
            playerStates: [
              snapshot(playerIndex: 0, life: 40),
              snapshot(
                playerIndex: 1,
                life: 33,
                commanderDamageTaken: [
                  CommanderDamageTaken(
                    sourcePlayerIndex: 0,
                    commanderName: 'Tymna the Weaver',
                    damage: 4,
                  ),
                  CommanderDamageTaken(
                    sourcePlayerIndex: 0,
                    commanderName: 'Thrasios, Triton Hero',
                    damage: 3,
                  ),
                ],
              ),
              snapshot(playerIndex: 2, life: 40),
              snapshot(playerIndex: 3, life: 40),
            ],
          )
          .build();

      final stats = GameStatsUtility(logger);
      // Both commanders contribute to player 0's commander-damage total.
      expect(stats.overallDamageStats!.mostCmdDamagePlayer!.key, 0);
      expect(stats.overallDamageStats!.mostCmdDamagePlayer!.value, 7);
      // The single-commander max is whichever has more (Tymna with 4).
      expect(stats.overallDamageStats!.mostCmdDamageCommander!.name,
          'Tymna the Weaver');
      expect(stats.overallDamageStats!.mostCmdDamageCommander!.value, 4);
    });

    test('action stats first turn uses current value, later uses delta', () {
      final logger = FakeGameBuilder()
          .addTurn(
            activePlayerIndex: 0,
            turnNumber: 1,
            durationSeconds: 10,
            playerStates: [
              snapshot(
                playerIndex: 0,
                life: 40,
                actions: const {
                  'life_paid': 2,
                  'cards_milled': 0,
                  'extra_turns': 0,
                  'cards_drawn': 1,
                },
              ),
              snapshot(playerIndex: 1, life: 40),
              snapshot(playerIndex: 2, life: 40),
              snapshot(playerIndex: 3, life: 40),
            ],
          )
          .addTurn(
            activePlayerIndex: 1,
            turnNumber: 1,
            durationSeconds: 10,
            playerStates: [
              snapshot(
                playerIndex: 0,
                life: 40,
                actions: const {
                  'life_paid': 5, // delta = 3
                  'cards_milled': 0,
                  'extra_turns': 0,
                  'cards_drawn': 1,
                },
              ),
              snapshot(playerIndex: 1, life: 40),
              snapshot(playerIndex: 2, life: 40),
              snapshot(playerIndex: 3, life: 40),
            ],
          )
          .build();

      final stats = GameStatsUtility(logger);
      // Action stats track max increment per player; player 0 had increments 2 and 3.
      expect(stats.overallActionStats['Life Paid']?[0], 3);
    });

    test('counter stats track max value across turns', () {
      final logger = FakeGameBuilder()
          .addTurn(
            activePlayerIndex: 0,
            turnNumber: 1,
            durationSeconds: 10,
            playerStates: [
              snapshot(playerIndex: 0, life: 40, counters: const {'Energy': 3}),
              snapshot(playerIndex: 1, life: 40),
              snapshot(playerIndex: 2, life: 40),
              snapshot(playerIndex: 3, life: 40),
            ],
          )
          .addTurn(
            activePlayerIndex: 1,
            turnNumber: 1,
            durationSeconds: 10,
            playerStates: [
              snapshot(playerIndex: 0, life: 40, counters: const {'Energy': 7}),
              snapshot(playerIndex: 1, life: 40, counters: const {'Poison': 4}),
              snapshot(playerIndex: 2, life: 40),
              snapshot(playerIndex: 3, life: 40),
            ],
          )
          .build();

      final stats = GameStatsUtility(logger);
      expect(stats.overallCounterStats['Energy']?['value'], 7);
      expect(stats.overallCounterStats['Energy']?['playerIndex'], 0);
      expect(stats.overallCounterStats['Poison']?['value'], 4);
    });

    test('player time stats sum durations per player and average', () {
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
            durationSeconds: 60,
            playerStates: List.filled(4, null),
          )
          .addTurn(
            activePlayerIndex: 0,
            turnNumber: 2,
            durationSeconds: 90,
            playerStates: List.filled(4, null),
          )
          .build();

      final stats = GameStatsUtility(logger);
      final p0 = stats.allPlayerStats[0].timeStats;
      expect(p0.turnCount, 2);
      expect(p0.totalDuration.inSeconds, 120);
      expect(p0.longestDuration.inSeconds, 90);
      expect(p0.averageDuration.inSeconds, 60);
    });

    test('seat number formula respects starting player offset', () {
      // First turn's activePlayerIndex defines the starting seat, so player 2
      // active first means: seat 1 = index 2, seat 2 = index 3, seat 3 = index 0,
      // seat 4 = index 1.
      final logger = FakeGameBuilder()
          .addTurn(
            activePlayerIndex: 2,
            turnNumber: 1,
            durationSeconds: 30,
            playerStates: List.filled(4, null),
          )
          .build();
      final stats = GameStatsUtility(logger);
      expect(stats.allPlayerStats[2].seatNumber, 1);
      expect(stats.allPlayerStats[3].seatNumber, 2);
      expect(stats.allPlayerStats[0].seatNumber, 3);
      expect(stats.allPlayerStats[1].seatNumber, 4);
    });

    test('setReviewDetails writes review block into JSON', () {
      final logger = FakeGameBuilder()
          .addTurn(
            activePlayerIndex: 0,
            turnNumber: 1,
            durationSeconds: 30,
            playerStates: List.filled(4, null),
          )
          .build();
      final stats = GameStatsUtility(logger);
      stats.setReviewDetails(
        false,
        1,
        'Combat damage',
        ['Mana Crypt', '', 'Sol Ring'],
        [false, true, false, false],
        2,
      );

      final json = stats.toJson();
      final review = json['review_details'] as Map<String, dynamic>;
      expect(review['is_draw'], false);
      expect(review['win_condition'], 'Combat damage');
      expect(review['key_cards'], ['Mana Crypt', 'Sol Ring']);
      // user_seat: player 2 against starting player 0 → seat 3.
      expect(review['user_seat'], 3);
      // winner_seat_number: player 1 → seat 2.
      expect(review['winner_seat_number'], 2);
      final fastMana = review['fast_mana_players'] as List;
      expect(fastMana[1]['had_fast_mana'], true);
    });
  });
}
