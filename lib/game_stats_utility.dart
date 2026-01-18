import 'dart:convert';
import 'dart:math';

import 'constants.dart';
import 'game_logger.dart';

class GameStatsUtility {
  final GameLogger gameLogger;
  final GameSession session;
  final List<TurnLogEntry> turnLog;

  // Class-level objects for calculated stats
  LongestTurn? longestTurn;
  OverallDamageStats? overallDamageStats;
  Map<String, Map<int, int>> overallActionStats = {};
  Map<String, Map<String, dynamic>> overallCounterStats = {};
  late List<PlayerStatsSummary> allPlayerStats;

  // New fields for Post Game Review
  bool _isDraw = false;
  int? _winnerIndex;
  String? _winCondition;
  List<String> _keyCards = [];
  List<bool> _fastManaPlayers = [];
  int? _userSeat; // Added field for user seat

  GameStatsUtility(this.gameLogger)
    : session = gameLogger.getSession(),
      turnLog = gameLogger.getTurnLog() {
    _calculateAll();
  }

  void _calculateAll() {
    longestTurn = _calculateLongestTurn();
    overallDamageStats = _calculateOverallDamageStats();
    overallActionStats = _calculateOverallActionStats();
    overallCounterStats = _calculateOverallCounterStats();

    final int startingPlayerInferredIndex = turnLog.isNotEmpty
        ? turnLog.first.activePlayerIndex
        : session.startingPlayerIndex;

    final Map<int, int> playerIndexToSeatNumber = {};
    for (int i = 0; i < session.playerNames.length; i++) {
      final int seatNumber =
          (i - startingPlayerInferredIndex + session.playerNames.length) %
              session.playerNames.length +
          1;
      playerIndexToSeatNumber[i] = seatNumber;
    }

    allPlayerStats = List.generate(session.playerNames.length, (i) {
      return PlayerStatsSummary(
        playerIndex: i,
        seatNumber: playerIndexToSeatNumber[i]!,
        timeStats: _calculatePlayerTimeStats(i),
        damageStats: _calculatePlayerDamageStats(i),
        actionStats: _calculatePlayerActionStats(i),
        counterStats: _calculatePlayerCounterStats(i),
      );
    });
  }

  // Setter for review details
  void setReviewDetails(
    bool isDraw,
    int? winnerIndex,
    String? winCondition,
    List<String> keyCards,
    List<bool> fastManaPlayers,
    int? userSeat, // Added parameter for user seat
  ) {
    _isDraw = isDraw;
    _winnerIndex = winnerIndex;
    _winCondition = winCondition;
    _keyCards = keyCards;
    _fastManaPlayers = fastManaPlayers;
    _userSeat = userSeat; // Store user seat
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  Map<String, dynamic> toJson() {
    final int startingPlayerInferredIndex = turnLog.isNotEmpty
        ? turnLog.first.activePlayerIndex
        : session.startingPlayerIndex;

    final Map<int, int> playerIndexToSeatNumber = {};
    for (int i = 0; i < session.playerNames.length; i++) {
      final int seatNumber =
          (i - startingPlayerInferredIndex + session.playerNames.length) %
              session.playerNames.length +
          1;
      playerIndexToSeatNumber[i] = seatNumber;
    }

    // Find the user's stats, falling back to the first player's stats if not found
    PlayerStatsSummary? userStats;
    if (_userSeat != null) {
      try {
        userStats = allPlayerStats.firstWhere(
          (ps) => ps.seatNumber == _userSeat,
        );
      } catch (e) {
        userStats = allPlayerStats.isNotEmpty ? allPlayerStats.first : null;
      }
    } else {
      userStats = allPlayerStats.isNotEmpty ? allPlayerStats.first : null;
    }

    final Map<String, dynamic> jsonOutput = {
      'game_session': {
        'session_id': 'edh-${session.startTime.millisecondsSinceEpoch}',
        'start_time': session.startTime.toIso8601String(),
        'end_time': session.endTime?.toIso8601String(),
        'starting_life': session.startingLife,
        'total_turns': turnLog.length,
        'players': List.generate(session.playerNames.length, (i) {
          return {
            'seat_number': playerIndexToSeatNumber[i],
            'commanders': session.playerCommanderNames[i],
          };
        }),
      },
      if (userStats != null) 'player_stats': userStats.toJson(),
    };

    // Add review details if available
    if (_isDraw ||
        _winnerIndex != null ||
        _winCondition != null ||
        _keyCards.isNotEmpty ||
        _fastManaPlayers.any((e) => e) ||
        _userSeat != null) {
      // Check if userSeat is available
      jsonOutput['review_details'] = {
        'is_draw': _isDraw,
        if (!_isDraw)
          'winner_seat_number': playerIndexToSeatNumber[_winnerIndex!],
        if (!_isDraw) 'win_condition': _winCondition,
        'key_cards': _keyCards.where((card) => card.isNotEmpty).toList(),
        'fast_mana_players': List.generate(session.playerNames.length, (index) {
          return {
            'player_index': index,
            'had_fast_mana': _fastManaPlayers[index],
          };
        }),
        if (_userSeat != null) // Add userSeat if not null
          'user_seat': playerIndexToSeatNumber[_userSeat],
      };
    }

    return jsonOutput;
  }

  // ==========================================================================
  // Internal Overall Stats Calculations
  // ==========================================================================

  LongestTurn? _calculateLongestTurn() {
    int longestTurnDuration = 0;
    int longestTurnNumber = -1;
    int longestTurnPlayerIndex = -1;

    for (final turn in turnLog) {
      final duration = turn.turnEndTime
          .difference(turn.turnStartTime)
          .inSeconds;
      if (duration > longestTurnDuration) {
        longestTurnDuration = duration;
        longestTurnNumber = turn.turnNumber;
        longestTurnPlayerIndex = turn.activePlayerIndex;
      }
    }

    if (longestTurnNumber == -1) return null;

    return LongestTurn(
      duration: Duration(seconds: longestTurnDuration),
      turnNumber: longestTurnNumber,
      playerIndex: longestTurnPlayerIndex,
    );
  }

  OverallDamageStats _calculateOverallDamageStats() {
    if (turnLog.isEmpty) return OverallDamageStats();

    final damageDealtByPlayer = <int, int>{};
    final commanderDamageDealtByPlayer = <int, int>{};
    final totalDamagePerTurn = <int, int>{};
    final totalCommanderDamagePerTurn = <int, int>{};
    final commanderDamageOverall = <String, int>{};
    final commanderDamageSourcePlayer = <String, int>{};

    for (int i = 0; i < turnLog.length; i++) {
      final turn = turnLog[i];
      int turnDamage = 0;
      int turnCmdDamage = 0;

      for (final playerState in turn.playerStates) {
        final startingLife = session.startingLife;
        if (i == 0) {
          final diff = startingLife - playerState.life;
          damageDealtByPlayer.update(
            turn.activePlayerIndex,
            (v) => v + diff,
            ifAbsent: () => diff,
          );
          turnDamage += diff;
        } else {
          final previousState = turnLog[i - 1].playerStates.firstWhere(
            (p) => p.playerIndex == playerState.playerIndex,
          );
          final lifeDifference = previousState.life - playerState.life;
          if (lifeDifference > 0) {
            damageDealtByPlayer.update(
              turn.activePlayerIndex,
              (v) => v + lifeDifference,
              ifAbsent: () => lifeDifference,
            );
            turnDamage += lifeDifference;
          }
        }

        if (i == 0) {
          for (final cmdDamage in playerState.commanderDamageTaken) {
            commanderDamageDealtByPlayer.update(
              cmdDamage.sourcePlayerIndex,
              (v) => v + cmdDamage.damage,
              ifAbsent: () => cmdDamage.damage,
            );
            commanderDamageOverall.update(
              cmdDamage.commanderName,
              (v) => v + cmdDamage.damage,
              ifAbsent: () => cmdDamage.damage,
            );
            commanderDamageSourcePlayer[cmdDamage.commanderName] =
                cmdDamage.sourcePlayerIndex;
            turnCmdDamage += cmdDamage.damage;
          }
        } else {
          final previousState = turnLog[i - 1].playerStates.firstWhere(
            (p) => p.playerIndex == playerState.playerIndex,
          );
          final previousCmdDamageMap = <String, int>{};
          for (final prevCmdDamage in previousState.commanderDamageTaken) {
            final key =
                '${prevCmdDamage.sourcePlayerIndex}:${prevCmdDamage.commanderName}';
            previousCmdDamageMap[key] =
                (previousCmdDamageMap[key] ?? 0) + prevCmdDamage.damage;
          }
          for (final cmdDamage in playerState.commanderDamageTaken) {
            final key =
                '${cmdDamage.sourcePlayerIndex}:${cmdDamage.commanderName}';
            final previousDamage = previousCmdDamageMap[key] ?? 0;
            final newDamage = cmdDamage.damage - previousDamage;
            if (newDamage > 0) {
              commanderDamageDealtByPlayer.update(
                cmdDamage.sourcePlayerIndex,
                (v) => v + newDamage,
                ifAbsent: () => newDamage,
              );
              commanderDamageOverall.update(
                cmdDamage.commanderName,
                (v) => v + newDamage,
                ifAbsent: () => newDamage,
              );
              commanderDamageSourcePlayer[cmdDamage.commanderName] =
                  cmdDamage.sourcePlayerIndex;
              turnCmdDamage += newDamage;
            }
          }
        }
      }
      if (turnDamage > 0) totalDamagePerTurn[i] = turnDamage;
      if (turnCmdDamage > 0) totalCommanderDamagePerTurn[i] = turnCmdDamage;
    }

    final mostDamagePlayer = damageDealtByPlayer.isEmpty
        ? null
        : damageDealtByPlayer.entries.reduce(
            (a, b) => a.value > b.value ? a : b,
          );
    final maxTurnDamage = totalDamagePerTurn.isEmpty
        ? null
        : totalDamagePerTurn.entries.reduce(
            (a, b) => a.value > b.value ? a : b,
          );
    final mostCmdDamagePlayer = commanderDamageDealtByPlayer.isEmpty
        ? null
        : commanderDamageDealtByPlayer.entries.reduce(
            (a, b) => a.value > b.value ? a : b,
          );
    final mostCmdDamageCommander = commanderDamageOverall.isEmpty
        ? null
        : commanderDamageOverall.entries.reduce(
            (a, b) => a.value > b.value ? a : b,
          );
    final maxTurnCmdDamage = totalCommanderDamagePerTurn.isEmpty
        ? null
        : totalCommanderDamagePerTurn.entries.reduce(
            (a, b) => a.value > b.value ? a : b,
          );

    return OverallDamageStats(
      mostDamagePlayer: mostDamagePlayer,
      maxTurnDamage: maxTurnDamage != null
          ? OverallMaxDamageTurn(
              value: maxTurnDamage.value,
              turnNumber: turnLog[maxTurnDamage.key].turnNumber,
              playerIndex: turnLog[maxTurnDamage.key].activePlayerIndex,
            )
          : null,
      mostCmdDamagePlayer: mostCmdDamagePlayer,
      mostCmdDamageCommander: mostCmdDamageCommander != null
          ? OverallMostCmdDamageCommander(
              name: mostCmdDamageCommander.key,
              value: mostCmdDamageCommander.value,
              sourcePlayerIndex:
                  commanderDamageSourcePlayer[mostCmdDamageCommander.key]!,
            )
          : null,
      maxTurnCmdDamage: maxTurnCmdDamage != null
          ? OverallMaxDamageTurn(
              value: maxTurnCmdDamage.value,
              turnNumber: turnLog[maxTurnCmdDamage.key].turnNumber,
              playerIndex: turnLog[maxTurnCmdDamage.key].activePlayerIndex,
            )
          : null,
    );
  }

  Map<String, Map<int, int>> _calculateOverallActionStats() {
    final actionMaxPerPlayer = <String, Map<int, int>>{};
    const actions = ['Life Paid', 'Cards Milled', 'Extra Turns', 'Cards Drawn'];

    for (final action in actions) {
      actionMaxPerPlayer[action] = {};
      final key = action.toLowerCase().replaceAll(' ', '_');

      for (int i = 0; i < turnLog.length; i++) {
        final turn = turnLog[i];
        for (final playerState in turn.playerStates) {
          final currentValue = playerState.actionTrackers[key] ?? 0;
          int actionIncrement = 0;
          if (i == 0) {
            actionIncrement = currentValue;
          } else {
            final previousState = turnLog[i - 1].playerStates.firstWhere(
              (p) => p.playerIndex == playerState.playerIndex,
            );
            final previousValue = previousState.actionTrackers[key] ?? 0;
            actionIncrement = currentValue - previousValue;
          }
          if (actionIncrement > 0) {
            actionMaxPerPlayer[action]!.update(
              playerState.playerIndex,
              (v) => v > actionIncrement ? v : actionIncrement,
              ifAbsent: () => actionIncrement,
            );
          }
        }
      }
    }
    return actionMaxPerPlayer;
  }

  Map<String, Map<String, dynamic>> _calculateOverallCounterStats() {
    final counterStats = <String, Map<String, dynamic>>{};

    for (final counterName in UIConstants.playerCounterTypes) {
      int maxValue = 0;
      int maxPlayerIndex = -1;

      for (final turn in turnLog) {
        for (final playerState in turn.playerStates) {
          final value = playerState.counters[counterName] ?? 0;
          if (value > maxValue) {
            maxValue = value;
            maxPlayerIndex = playerState.playerIndex;
          }
        }
      }

      if (maxValue > 0) {
        counterStats[counterName] = {
          'value': maxValue,
          'playerIndex': maxPlayerIndex,
        };
      }
    }
    return counterStats;
  }

  // ==========================================================================
  // Internal Player-Specific Stats Calculations
  // ==========================================================================

  PlayerTimeStats _calculatePlayerTimeStats(int playerIndex) {
    final playerTurns = turnLog
        .where((t) => t.activePlayerIndex == playerIndex)
        .toList();
    if (playerTurns.isEmpty) return PlayerTimeStats.empty();

    int totalDuration = 0;
    int longestDuration = 0;

    for (final turn in playerTurns) {
      final duration = turn.turnEndTime
          .difference(turn.turnStartTime)
          .inSeconds;
      totalDuration += duration;
      longestDuration = max(longestDuration, duration);
    }

    return PlayerTimeStats(
      totalDuration: Duration(seconds: totalDuration),
      longestDuration: Duration(seconds: longestDuration),
      averageDuration: Duration(seconds: totalDuration ~/ playerTurns.length),
      turnCount: playerTurns.length,
    );
  }

  PlayerDamageStats _calculatePlayerDamageStats(int playerIndex) {
    final playerTurnsCount = turnLog
        .where((t) => t.activePlayerIndex == playerIndex)
        .length;
    if (playerTurnsCount == 0) return PlayerDamageStats.empty();

    int totalDamage = 0;
    int maxDamageInTurn = 0;
    int totalCommanderDamage = 0;
    int maxCommanderDamageInTurn = 0;

    for (int i = 0; i < turnLog.length; i++) {
      final turn = turnLog[i];
      if (turn.activePlayerIndex != playerIndex) continue;

      int turnDamage = 0;
      int turnCommanderDamage = 0;

      for (final playerState in turn.playerStates) {
        if (i == 0) {
          final diff = session.startingLife - playerState.life;
          if (diff > 0) turnDamage += diff;
        } else {
          final previousState = turnLog[i - 1].playerStates.firstWhere(
            (p) => p.playerIndex == playerState.playerIndex,
          );
          final diff = previousState.life - playerState.life;
          if (diff > 0) turnDamage += diff;
        }

        if (i == 0) {
          for (final cmdDamage in playerState.commanderDamageTaken) {
            if (cmdDamage.sourcePlayerIndex == playerIndex) {
              turnCommanderDamage += cmdDamage.damage;
            }
          }
        } else {
          final previousState = turnLog[i - 1].playerStates.firstWhere(
            (p) => p.playerIndex == playerState.playerIndex,
          );
          final previousCmdDamageMap = <String, int>{};
          for (final prevCmdDamage in previousState.commanderDamageTaken) {
            if (prevCmdDamage.sourcePlayerIndex == playerIndex) {
              previousCmdDamageMap[prevCmdDamage.commanderName] =
                  (previousCmdDamageMap[prevCmdDamage.commanderName] ?? 0) +
                  prevCmdDamage.damage;
            }
          }
          for (final cmdDamage in playerState.commanderDamageTaken) {
            if (cmdDamage.sourcePlayerIndex == playerIndex) {
              final prev = previousCmdDamageMap[cmdDamage.commanderName] ?? 0;
              final newDamage = cmdDamage.damage - prev;
              if (newDamage > 0) turnCommanderDamage += newDamage;
            }
          }
        }
      }

      totalDamage += turnDamage;
      maxDamageInTurn = max(maxDamageInTurn, turnDamage);
      totalCommanderDamage += turnCommanderDamage;
      maxCommanderDamageInTurn = max(
        maxCommanderDamageInTurn,
        turnCommanderDamage,
      );
    }

    return PlayerDamageStats(
      totalDamage: totalDamage,
      maxDamageInTurn: maxDamageInTurn,
      averageDamage: totalDamage ~/ playerTurnsCount,
      totalCommanderDamage: totalCommanderDamage,
      maxCommanderDamageInTurn: maxCommanderDamageInTurn,
      averageCommanderDamage: totalCommanderDamage ~/ playerTurnsCount,
    );
  }

  Map<String, dynamic> _calculatePlayerActionStats(int playerIndex) {
    const actions = ['Life Paid', 'Cards Milled', 'Extra Turns', 'Cards Drawn'];
    final duringYourTurnStats = <String, Map<String, int>>{};
    final duringOpponentTurnStats = <String, Map<String, int>>{};

    int yourTurnsCount = 0;
    int opponentTurnsCount = 0;

    // Initialize stats maps for each action
    for (final action in actions) {
      duringYourTurnStats[action] = {'max': 0, 'total': 0, 'average': 0};
      duringOpponentTurnStats[action] = {'max': 0, 'total': 0, 'average': 0};
    }

    // Iterate through turns and collect action stats
    for (int i = 0; i < turnLog.length; i++) {
      final turn = turnLog[i];
      final isYourTurn = turn.activePlayerIndex == playerIndex;

      if (isYourTurn) {
        yourTurnsCount++;
      } else {
        opponentTurnsCount++;
      }

      // Find this player's state in the turn
      final playerState = turn.playerStates.firstWhere(
        (p) => p.playerIndex == playerIndex,
      );

      final targetMap = isYourTurn
          ? duringYourTurnStats
          : duringOpponentTurnStats;

      // Track each action
      for (final action in actions) {
        final key = action.toLowerCase().replaceAll(' ', '_');
        final current = playerState.actionTrackers[key] ?? 0;
        int increment = 0;

        if (i == 0) {
          increment = current;
        } else {
          final previousState = turnLog[i - 1].playerStates.firstWhere(
            (p) => p.playerIndex == playerIndex,
          );
          final previous = previousState.actionTrackers[key] ?? 0;
          increment = current - previous;
        }

        if (increment > 0) {
          targetMap[action]!['max'] = max(
            targetMap[action]!['max']!,
            increment,
          );
          targetMap[action]!['total'] =
              targetMap[action]!['total']! + increment;
        }
      }
    }

    // Calculate averages
    for (final action in actions) {
      duringYourTurnStats[action]!['average'] = yourTurnsCount > 0
          ? duringYourTurnStats[action]!['total']! ~/ yourTurnsCount
          : 0;
      duringOpponentTurnStats[action]!['average'] = opponentTurnsCount > 0
          ? duringOpponentTurnStats[action]!['total']! ~/ opponentTurnsCount
          : 0;
    }

    return {
      'duringYourTurn': duringYourTurnStats,
      'duringOpponentTurn': duringOpponentTurnStats,
      'yourTurnsCount': yourTurnsCount,
      'opponentTurnsCount': opponentTurnsCount,
    };
  }

  Map<String, dynamic> _calculatePlayerCounterStats(int playerIndex) {
    final duringYourTurnStats = <String, Map<String, int>>{};
    final duringOpponentTurnStats = <String, Map<String, int>>{};

    int yourTurnsCount = 0;
    int opponentTurnsCount = 0;

    for (final counterName in UIConstants.playerCounterTypes) {
      duringYourTurnStats[counterName] = {'max': 0, 'total': 0, 'average': 0};
      duringOpponentTurnStats[counterName] = {
        'max': 0,
        'total': 0,
        'average': 0,
      };
    }

    for (final turn in turnLog) {
      final playerState = turn.playerStates.firstWhere(
        (p) => p.playerIndex == playerIndex,
      );
      final isYourTurn = turn.activePlayerIndex == playerIndex;

      if (isYourTurn) {
        yourTurnsCount++;
      } else {
        opponentTurnsCount++;
      }

      for (final counterName in UIConstants.playerCounterTypes) {
        final value = playerState.counters[counterName] ?? 0;
        final targetMap = isYourTurn
            ? duringYourTurnStats
            : duringOpponentTurnStats;
        targetMap[counterName]!['max'] = max(
          targetMap[counterName]!['max']!,
          value,
        );
        targetMap[counterName]!['total'] =
            targetMap[counterName]!['total']! + value;
      }
    }

    // Calculate averages
    for (final counterName in UIConstants.playerCounterTypes) {
      duringYourTurnStats[counterName]!['average'] = yourTurnsCount > 0
          ? duringYourTurnStats[counterName]!['total']! ~/ yourTurnsCount
          : 0;
      duringOpponentTurnStats[counterName]!['average'] = opponentTurnsCount > 0
          ? duringOpponentTurnStats[counterName]!['total']! ~/
                opponentTurnsCount
          : 0;
    }

    return {
      'duringYourTurn': duringYourTurnStats,
      'duringOpponentTurn': duringOpponentTurnStats,
      'yourTurnsCount': yourTurnsCount,
      'opponentTurnsCount': opponentTurnsCount,
    };
  }
}

// ==========================================================================
// Stat Classes
// ==========================================================================

class LongestTurn {
  final Duration duration;
  final int turnNumber;
  final int playerIndex;

  LongestTurn({
    required this.duration,
    required this.turnNumber,
    required this.playerIndex,
  });
}

class OverallDamageStats {
  final MapEntry<int, int>? mostDamagePlayer;
  final OverallMaxDamageTurn? maxTurnDamage;
  final MapEntry<int, int>? mostCmdDamagePlayer;
  final OverallMostCmdDamageCommander? mostCmdDamageCommander;
  final OverallMaxDamageTurn? maxTurnCmdDamage;

  OverallDamageStats({
    this.mostDamagePlayer,
    this.maxTurnDamage,
    this.mostCmdDamagePlayer,
    this.mostCmdDamageCommander,
    this.maxTurnCmdDamage,
  });
}

class OverallMaxDamageTurn {
  final int value;
  final int turnNumber;
  final int playerIndex;

  OverallMaxDamageTurn({
    required this.value,
    required this.turnNumber,
    required this.playerIndex,
  });
}

class OverallMostCmdDamageCommander {
  final String name;
  final int value;
  final int sourcePlayerIndex;

  OverallMostCmdDamageCommander({
    required this.name,
    required this.value,
    required this.sourcePlayerIndex,
  });
}

class PlayerTimeStats {
  final Duration totalDuration;
  final Duration longestDuration;
  final Duration averageDuration;
  final int turnCount;

  PlayerTimeStats({
    required this.totalDuration,
    required this.longestDuration,
    required this.averageDuration,
    required this.turnCount,
  });

  PlayerTimeStats.empty()
    : totalDuration = Duration.zero,
      longestDuration = Duration.zero,
      averageDuration = Duration.zero,
      turnCount = 0;

  Map<String, dynamic> toJson() => {
    'total_duration': _formatDuration(totalDuration),
    'average_duration': _formatDuration(averageDuration),
    'longest_duration': _formatDuration(longestDuration),
    'turn_count': turnCount,
  };

  static String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class PlayerDamageStats {
  final int totalDamage;
  final int maxDamageInTurn;
  final int averageDamage;
  final int totalCommanderDamage;
  final int maxCommanderDamageInTurn;
  final int averageCommanderDamage;

  PlayerDamageStats({
    required this.totalDamage,
    required this.maxDamageInTurn,
    required this.averageDamage,
    required this.totalCommanderDamage,
    required this.maxCommanderDamageInTurn,
    required this.averageCommanderDamage,
  });

  PlayerDamageStats.empty()
    : totalDamage = 0,
      maxDamageInTurn = 0,
      averageDamage = 0,
      totalCommanderDamage = 0,
      maxCommanderDamageInTurn = 0,
      averageCommanderDamage = 0;

  Map<String, dynamic> toJson() => {
    'total_damage': totalDamage,
    'max_damage_in_turn': maxDamageInTurn,
    'average_damage': averageDamage,
    'total_commander_damage': totalCommanderDamage,
    'max_commander_damage_in_turn': maxCommanderDamageInTurn,
    'average_commander_damage': averageCommanderDamage,
  };
}

class PlayerStatsSummary {
  final int playerIndex;
  final int seatNumber;
  final PlayerTimeStats timeStats;
  final PlayerDamageStats damageStats;
  final Map<String, dynamic> actionStats;
  final Map<String, dynamic> counterStats;

  PlayerStatsSummary({
    required this.playerIndex,
    required this.seatNumber,
    required this.timeStats,
    required this.damageStats,
    required this.actionStats,
    required this.counterStats,
  });

  Map<String, dynamic> toJson() {
    // Build action stats JSON with both own turn and opponent turn breakdowns
    final actionJson = <String, dynamic>{};
    final duringYourTurn =
        actionStats['duringYourTurn'] as Map<String, Map<String, int>>;
    final duringOpponentTurn =
        actionStats['duringOpponentTurn'] as Map<String, Map<String, int>>;
    final yourTurnsCount = actionStats['yourTurnsCount'] as int;
    final opponentTurnsCount = actionStats['opponentTurnsCount'] as int;

    duringYourTurn.forEach((action, data) {
      final actionKey = action.toLowerCase().replaceAll(' ', '_');
      if (data['total']! > 0) {
        actionJson['${actionKey}_during_own_turn'] = {
          'total': data['total'],
          'max': data['max'],
          'average': data['average'],
        };
      }
    });

    duringOpponentTurn.forEach((action, data) {
      final actionKey = action.toLowerCase().replaceAll(' ', '_');
      if (data['total']! > 0) {
        actionJson['${actionKey}_during_opponent_turn'] = {
          'total': data['total'],
          'max': data['max'],
          'average': data['average'],
        };
      }
    });

    // Build counter stats JSON with both own turn and opponent turn breakdowns
    final counterJson = <String, dynamic>{};
    final counterDuringYourTurn =
        counterStats['duringYourTurn'] as Map<String, Map<String, int>>;
    final counterDuringOpponentTurn =
        counterStats['duringOpponentTurn'] as Map<String, Map<String, int>>;

    counterDuringYourTurn.forEach((counterName, data) {
      if (data['total']! > 0) {
        counterJson['${counterName.toLowerCase()}_during_own_turn'] = {
          'total': data['total'],
          'max': data['max'],
          'average': data['average'],
        };
      }
    });

    counterDuringOpponentTurn.forEach((counterName, data) {
      if (data['total']! > 0) {
        counterJson['${counterName.toLowerCase()}_during_opponent_turn'] = {
          'total': data['total'],
          'max': data['max'],
          'average': data['average'],
        };
      }
    });

    return {
      'seat_number': seatNumber,
      'time_stats': timeStats.toJson(),
      'damage_stats': damageStats.toJson(),
      'action_stats': {
        'own_turn_count': yourTurnsCount,
        'opponent_turn_count': opponentTurnsCount,
        'actions': actionJson,
      },
      'counter_stats': {
        'own_turn_count': counterStats['yourTurnsCount'] as int,
        'opponent_turn_count': counterStats['opponentTurnsCount'] as int,
        'counters': counterJson,
      },
    };
  }
}
