import 'dart:convert';

import 'package:edhtracker/game_logger.dart';

/// Builds a populated [GameLogger] from a JSON-style description so unit tests
/// don't need to spin up real PlayerCard widgets to call recordTurn.
class FakeGameBuilder {
  final List<String> playerNames;
  final List<List<String>> playerCommanderNames;
  final int startingLife;
  final int startingPlayerIndex;
  final int playerCount;
  final DateTime startTime;

  final List<TurnLogEntry> _turns = [];

  FakeGameBuilder({
    this.playerNames = const ['Alice', 'Bob', 'Carol', 'Dave'],
    this.playerCommanderNames = const [
      ['Atraxa, Praetors\' Voice'],
      ['Krenko, Mob Boss'],
      ['Kaalia of the Vast'],
      ['Sliver Overlord'],
    ],
    this.startingLife = 40,
    this.startingPlayerIndex = 0,
    this.playerCount = 4,
    DateTime? startTime,
  }) : startTime = startTime ?? DateTime(2026, 1, 1, 12, 0, 0);

  /// Adds a real (non-skipped) turn lasting [durationSeconds]. The
  /// [playerStates] argument supplies the snapshot for each player; pass null
  /// at an index to reuse the previous snapshot for that player (or default
  /// starting state if there is none yet).
  FakeGameBuilder addTurn({
    required int activePlayerIndex,
    required int turnNumber,
    required int durationSeconds,
    required List<PlayerStateSnapshot?> playerStates,
  }) {
    final start = _turns.isEmpty ? startTime : _turns.last.turnEndTime;
    final end = start.add(Duration(seconds: durationSeconds));
    _turns.add(
      TurnLogEntry(
        turnNumber: turnNumber,
        activePlayerIndex: activePlayerIndex,
        playerStates: _resolveStates(playerStates),
        turnStartTime: start,
        turnEndTime: end,
      ),
    );
    return this;
  }

  FakeGameBuilder addSkippedTurn({
    required int activePlayerIndex,
    required int turnNumber,
    required List<PlayerStateSnapshot?> playerStates,
  }) {
    final ts = _turns.isEmpty ? startTime : _turns.last.turnEndTime;
    _turns.add(
      TurnLogEntry(
        turnNumber: turnNumber,
        activePlayerIndex: activePlayerIndex,
        playerStates: _resolveStates(playerStates),
        turnStartTime: ts,
        turnEndTime: ts,
        skipped: true,
      ),
    );
    return this;
  }

  List<PlayerStateSnapshot> _resolveStates(List<PlayerStateSnapshot?> states) {
    final resolved = <PlayerStateSnapshot>[];
    for (int i = 0; i < playerCount; i++) {
      final s = states[i];
      if (s != null) {
        resolved.add(s);
      } else {
        // Look back for the most recent snapshot for this player.
        PlayerStateSnapshot? prior;
        for (final turn in _turns.reversed) {
          for (final snap in turn.playerStates) {
            if (snap.playerIndex == i) {
              prior = snap;
              break;
            }
          }
          if (prior != null) break;
        }
        resolved.add(
          prior ??
              PlayerStateSnapshot(
                playerIndex: i,
                life: startingLife,
                counters: const {},
                actionTrackers: const {
                  'life_paid': 0,
                  'cards_milled': 0,
                  'extra_turns': 0,
                  'cards_drawn': 0,
                },
                commanderDamageTaken: const [],
                isEliminated: false,
              ),
        );
      }
    }
    return resolved;
  }

  /// Build a JSON string in the same shape `GameLogger.fromJson` consumes,
  /// then return a fully-reconstructed GameLogger.
  GameLogger build() {
    final session = GameSession(
      playerNames: playerNames,
      playerCommanderNames: playerCommanderNames,
      playerArtUrls: List.generate(playerCount, (_) => const <String>[]),
      startingLife: startingLife,
      startingPlayerIndex: startingPlayerIndex,
      playerCount: playerCount,
      unconventionalCommanders: false,
      startTime: startTime,
    );
    final json = {
      'game_session': session.toJson(),
      'turn_log': _turns.map((t) => t.toJson()).toList(),
    };
    // Use the public fromJson path so reconstruction-side logic is exercised.
    final logger = GameLogger.fromJson(jsonEncode(json));
    // fromJson does not populate playerArtUrls (they aren't serialized);
    // restore them to per-player empty lists so summary-page rendering can
    // index playerArtUrls[i] without RangeError.
    logger.getSession().playerArtUrls
      ..clear()
      ..addAll(List.generate(playerCount, (_) => const <String>[]));
    return logger;
  }
}

/// Convenience builder for a [PlayerStateSnapshot] with sensible defaults.
PlayerStateSnapshot snapshot({
  required int playerIndex,
  required int life,
  Map<String, int> counters = const {},
  Map<String, int> actions = const {
    'life_paid': 0,
    'cards_milled': 0,
    'extra_turns': 0,
    'cards_drawn': 0,
  },
  List<CommanderDamageTaken> commanderDamageTaken = const [],
  bool isEliminated = false,
}) {
  return PlayerStateSnapshot(
    playerIndex: playerIndex,
    life: life,
    counters: counters,
    actionTrackers: actions,
    commanderDamageTaken: commanderDamageTaken,
    isEliminated: isEliminated,
  );
}
