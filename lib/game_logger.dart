import 'dart:convert';

import 'package:flutter/material.dart';

import 'player_card.dart';

/// Represents the initial setup of a game session.
class GameSession {
  final List<String> playerNames;
  final List<List<String>> playerCommanderNames;
  final List<List<String>> playerArtUrls;
  final int startingLife;
  final int startingPlayerIndex;
  final bool unconventionalCommanders;
  final DateTime startTime;
  DateTime? endTime; // Added endTime

  GameSession({
    required this.playerNames,
    required this.playerCommanderNames,
    required this.playerArtUrls,
    required this.startingLife,
    required this.startingPlayerIndex,
    required this.unconventionalCommanders,
    required this.startTime,
    this.endTime, // Initialize endTime to null
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'start_time': startTime.toIso8601String(),
      'starting_life': startingLife,
      'players': List.generate(playerNames.length, (index) {
        return {
          'player_index': index,
          'name': playerNames[index],
          'commanders': playerCommanderNames[index],
        };
      }),
    };
    if (endTime != null) {
      json['end_time'] = endTime!.toIso8601String();
    }
    return json;
  }
}

/// Represents commander damage taken from a specific commander.
class CommanderDamageTaken {
  final int sourcePlayerIndex;
  final String commanderName;
  final int damage;

  CommanderDamageTaken({
    required this.sourcePlayerIndex,
    required this.commanderName,
    required this.damage,
  });

  Map<String, dynamic> toJson() {
    return {
      'source_player_index': sourcePlayerIndex,
      'commander_name': commanderName,
      'damage': damage,
    };
  }
}

/// Represents the state of a player at a specific point in time.
class PlayerStateSnapshot {
  final int playerIndex;
  final int life;
  final Map<String, int> counters;
  final Map<String, int> actionTrackers;
  final List<CommanderDamageTaken> commanderDamageTaken;
  final bool isEliminated;

  PlayerStateSnapshot({
    required this.playerIndex,
    required this.life,
    required this.counters,
    required this.actionTrackers,
    required this.commanderDamageTaken,
    required this.isEliminated,
  });

  Map<String, dynamic> toJson() {
    return {
      'player_index': playerIndex,
      'life': life,
      'counters': counters,
      'action_trackers': actionTrackers,
      'commander_damage_taken': commanderDamageTaken
          .map((e) => e.toJson())
          .toList(),
      'is_eliminated': isEliminated,
    };
  }
}

/// Represents a single turn in the game log.
class TurnLogEntry {
  final int turnNumber;
  final int activePlayerIndex;
  final List<PlayerStateSnapshot> playerStates;

  TurnLogEntry({
    required this.turnNumber,
    required this.activePlayerIndex,
    required this.playerStates,
  });

  Map<String, dynamic> toJson() {
    return {
      'turn_number': turnNumber,
      'active_player_index': activePlayerIndex,
      'player_states': playerStates.map((e) => e.toJson()).toList(),
    };
  }
}

/// Manages the logging of game setup and turn-by-turn state changes.
class GameLogger {
  final GameSession _session;
  final List<TurnLogEntry> _turnLog = [];

  GameLogger({
    required List<String> playerNames,
    required List<List<String>> playerCommanderNames,
    required List<List<String>> playerArtUrls,
    required int startingLife,
    required int startingPlayerIndex,
    required bool unconventionalCommanders,
  }) : _session = GameSession(
         playerNames: playerNames,
         playerCommanderNames: playerCommanderNames,
         playerArtUrls: playerArtUrls,
         startingLife: startingLife,
         startingPlayerIndex: startingPlayerIndex,
         unconventionalCommanders: unconventionalCommanders,
         startTime: DateTime.now(),
         endTime: null, // Initialize endTime to null
       );

  /// Records the state of all players at the end of a turn.
  void recordTurn(
    int activePlayerIndex,
    int turnNumber,
    List<GlobalKey<PlayerCardState>> playerCardKeys,
  ) {
    final playerStates = <PlayerStateSnapshot>[];
    for (int i = 0; i < playerCardKeys.length; i++) {
      final playerCardState = playerCardKeys[i].currentState;
      if (playerCardState != null) {
        playerStates.add(playerCardState.getCurrentState());
      }
    }
    _turnLog.add(
      TurnLogEntry(
        turnNumber: turnNumber,
        activePlayerIndex: activePlayerIndex,
        playerStates: playerStates,
      ),
    );
  }

  /// Sets the end time of the game.
  void endGame() {
    _session.endTime = DateTime.now();
  }

  /// Removes the last turn entry and returns the state of the previous turn.
  /// If no turns are left, returns null.
  TurnLogEntry? goToPreviousTurn() {
    return _turnLog.isNotEmpty ? _turnLog.removeLast() : null;
  }

  /// Outputs the entire game log as a JSON string.
  String toJsonString() {
    final gameData = {
      'game_session': _session.toJson(),
      'turn_log': _turnLog.map((e) => e.toJson()).toList(),
    };
    final jsonOutput = jsonEncode(gameData);

    return jsonOutput;
  }

  void logData() {
    print(_session.toJson());
    for (final turn in _turnLog) {
      print(turn.toJson());
    }
  }

  void logLastTurn() {
    print(_turnLog.last.toJson());
  }
}
