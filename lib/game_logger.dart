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

  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      playerNames: List<String>.from(json['players'].map((p) => p['name'])),
      playerCommanderNames: List<List<String>>.from(
        json['players'].map((p) => List<String>.from(p['commanders'])),
      ),
      playerArtUrls:
          [], // Player art URLs are not stored in the JSON, so we provide an empty list.
      startingLife: json['starting_life'],
      // The startingPlayerIndex from JSON is now a fallback, not the primary source
      startingPlayerIndex: json['players'][0]['player_index'],
      unconventionalCommanders:
          false, // This information is not stored in the JSON.
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'])
          : null,
    );
  }

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

  factory CommanderDamageTaken.fromJson(Map<String, dynamic> json) {
    return CommanderDamageTaken(
      sourcePlayerIndex: json['source_player_index'],
      commanderName: json['commander_name'],
      damage: json['damage'],
    );
  }

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

  factory PlayerStateSnapshot.fromJson(Map<String, dynamic> json) {
    return PlayerStateSnapshot(
      playerIndex: json['player_index'],
      life: json['life'],
      counters: Map<String, int>.from(json['counters']),
      actionTrackers: Map<String, int>.from(json['action_trackers']),
      commanderDamageTaken: List<CommanderDamageTaken>.from(
        json['commander_damage_taken']?.map(
              (e) => CommanderDamageTaken.fromJson(e),
            ) ??
            [],
      ),
      isEliminated: json['is_eliminated'],
    );
  }

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
  final DateTime turnStartTime;
  final DateTime turnEndTime;

  TurnLogEntry({
    required this.turnNumber,
    required this.activePlayerIndex,
    required this.playerStates,
    required this.turnStartTime,
    required this.turnEndTime,
  });

  factory TurnLogEntry.fromJson(Map<String, dynamic> json) {
    return TurnLogEntry(
      turnNumber: json['turn_number'],
      activePlayerIndex: json['active_player_index'],
      playerStates: List<PlayerStateSnapshot>.from(
        json['player_states'].map((e) => PlayerStateSnapshot.fromJson(e)),
      ),
      turnStartTime: DateTime.parse(json['turn_start_time']),
      turnEndTime: DateTime.parse(json['turn_end_time']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'turn_number': turnNumber,
      'active_player_index': activePlayerIndex,
      'player_states': playerStates.map((e) => e.toJson()).toList(),
      'turn_start_time': turnStartTime.toIso8601String(),
      'turn_end_time': turnEndTime.toIso8601String(),
    };
  }
}

/// Manages the logging of game setup and turn-by-turn state changes.
class GameLogger {
  final GameSession _session;
  List<TurnLogEntry> _turnLog = [];
  DateTime _lastTurnEndTime;

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
       ),
       _lastTurnEndTime = DateTime.now(); // Initialize _lastTurnEndTime

  factory GameLogger.fromJson(String jsonString) {
    final Map<String, dynamic> gameData = jsonDecode(jsonString);
    final GameSession session = GameSession.fromJson(gameData['game_session']);
    final List<TurnLogEntry> turnLog = List<TurnLogEntry>.from(
      gameData['turn_log'].map((e) => TurnLogEntry.fromJson(e)),
    );

    // Determine the starting player index from the first turn's active player index
    final int startingPlayerIndex = turnLog.isNotEmpty
        ? turnLog.first.activePlayerIndex
        : session
              .startingPlayerIndex; // Fallback to existing session data if no turns

    final DateTime lastTurnEndTime = turnLog.isNotEmpty
        ? turnLog.last.turnEndTime
        : session.startTime;

    // Update the GameSession with the correct starting player index
    final GameSession updatedSession = GameSession(
      playerNames: session.playerNames,
      playerCommanderNames: session.playerCommanderNames,
      playerArtUrls: session.playerArtUrls,
      startingLife: session.startingLife,
      startingPlayerIndex:
          startingPlayerIndex, // Use the determined starting player index
      unconventionalCommanders: session.unconventionalCommanders,
      startTime: session.startTime,
      endTime: session.endTime,
    );

    return GameLogger._reconstruct(
      session: updatedSession, // Use the updated session
      turnLog: turnLog,
      lastTurnEndTime: lastTurnEndTime,
    );
  }

  GameLogger._reconstruct({
    required GameSession session,
    required List<TurnLogEntry> turnLog,
    required DateTime lastTurnEndTime,
  }) : _session = session,
       _turnLog = turnLog,
       _lastTurnEndTime = lastTurnEndTime;

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

    final currentTurnStartTime = _lastTurnEndTime;
    final currentTurnEndTime = DateTime.now();

    _turnLog.add(
      TurnLogEntry(
        turnNumber: turnNumber,
        activePlayerIndex: activePlayerIndex,
        playerStates: playerStates,
        turnStartTime: currentTurnStartTime,
        turnEndTime: currentTurnEndTime,
      ),
    );
    _lastTurnEndTime = currentTurnEndTime; // Update for the next turn
  }

  /// Sets the end time of the game.
  void endGame() {
    _session.endTime = DateTime.now();
  }

  /// Removes the last turn entry and returns the state of the previous turn.
  /// If no turns are left, returns null.
  TurnLogEntry? goToPreviousTurn() {
    if (_turnLog.isNotEmpty) {
      final removedEntry = _turnLog.removeLast();
      if (_turnLog.isNotEmpty) {
        _lastTurnEndTime = _turnLog.last.turnEndTime;
      } else {
        _lastTurnEndTime = _session.startTime;
      }
      return removedEntry;
    }
    return null;
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

  GameSession getSession() {
    return _session;
  }

  /// Returns the turn log list.
  List<TurnLogEntry> getTurnLog() {
    return _turnLog;
  }
}
