import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

import 'constants.dart';
import 'game_logger.dart';
import 'game_setup_page.dart';

class GameSummaryPage extends StatefulWidget {
  final GameLogger gameLogger;

  const GameSummaryPage({
    super.key,
    required this.gameLogger,
  });

  @override
  State<GameSummaryPage> createState() => _GameSummaryPageState();
}

class _GameSummaryPageState extends State<GameSummaryPage> {
  @override
  void initState() {
    super.initState();
    // Lock to portrait orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  Future<void> _downloadGameLog() async {
    try {
      final jsonData = widget.gameLogger.toJsonString();
      final timestamp = DateTime.now().toString().replaceAll(RegExp(r'[^\w\-]'), '_');
      final filename = 'game_log_$timestamp.json';

      if (!mounted) return;

      String? result = await FilePicker.platform.saveFile(
        dialogTitle: 'Please select an output file:',
        fileName: filename,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: utf8.encode(jsonData)
      );

      if (result == null && !kIsWeb) {
        // User canceled the picker
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File save cancelled.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // On web, the file is downloaded automatically by the browser due to 'bytes' param.
      // On mobile, FilePicker saves the file to the chosen location.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Game log saved to: ${kIsWeb ? filename : result}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving game log: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.gameLogger.getSession();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Summary'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download game log',
            onPressed: _downloadGameLog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildGameSessionInfoGrid(context, session, widget.gameLogger),
            const SizedBox(height: 24),
            _buildDamageStatsGrid(context, widget.gameLogger),
            const SizedBox(height: 24),
            _buildActionStatsGrid(context, widget.gameLogger),
            const SizedBox(height: 24),
            _buildCounterStatsGrid(context, widget.gameLogger),
            const SizedBox(height: 32),
            _buildNewGameButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildGameSessionInfoGrid(BuildContext context, GameSession session, GameLogger gameLogger) {
    final turnLog = gameLogger.getTurnLog();
    
    // Calculate longest turn
    int longestTurnDuration = 0;
    int longestTurnNumber = -1;
    int longestTurnPlayerIndex = -1;
    
    for (final turn in turnLog) {
      final duration = turn.turnEndTime.difference(turn.turnStartTime).inSeconds;
      if (duration > longestTurnDuration) {
        longestTurnDuration = duration;
        longestTurnNumber = turn.turnNumber;
        longestTurnPlayerIndex = turn.activePlayerIndex;
      }
    }

    final stats = <Map<String, dynamic>>[];

    stats.add({
      'label': 'Game Duration',
      'value': _formatDuration(session.endTime!.difference(session.startTime)),
      'urls': const <String>[],
    });

    stats.add({
      'label': 'Starting Life',
      'value': '${session.startingLife}',
      'urls': const <String>[],
    });

    stats.add({
      'label': 'Total Turns',
      'value': '${turnLog.length}',
      'urls': const <String>[],
    });

    if (longestTurnNumber > -1) {
      stats.add({
        'label': 'Longest Turn',
        'value': _formatDuration(Duration(seconds: longestTurnDuration)),
        'detail': 'Turn $longestTurnNumber',
        'urls': session.playerArtUrls[longestTurnPlayerIndex],
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Game Session',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final stat = stats[index];
            return StatCard(
              label: stat['label'],
              value: stat['value'],
              detail: stat['detail'],
              backgroundUrls: (stat['urls'] as List<dynamic>?)?.cast<String>() ?? [],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDamageStatsGrid(BuildContext context, GameLogger gameLogger) {
    final turnLog = gameLogger.getTurnLog();
    if (turnLog.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate most damage dealt overall
    final damageDealtByPlayer = <int, int>{};
    final commanderDamageDealtByPlayer = <int, int>{};
    final totalDamagePerTurn = <int, int>{};
    final totalCommanderDamagePerTurn = <int, int>{};
    final commanderDamagePerTurn = <String, int>{};
    final commanderDamageOverall = <String, int>{};
    final commanderDamageSourcePlayer = <String, int>{}; // Track which player has each commander

    for (int i = 0; i < turnLog.length; i++) {
      final turn = turnLog[i];
      int turnDamage = 0;
      int turnCmdDamage = 0;

      for (final playerState in turn.playerStates) {
        // Calculate damage dealt to this player
        final startingLife = gameLogger.getSession().startingLife;
        if (i == 0) {
          // First turn, compare to starting life
          damageDealtByPlayer.update(
            turn.activePlayerIndex,
            (v) => v + (startingLife - playerState.life),
            ifAbsent: () => startingLife - playerState.life,
          );
          turnDamage += startingLife - playerState.life;
        } else {
          // Subsequent turns, compare to previous state
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

        // Commander damage - calculate difference from previous turn
        if (i == 0) {
          // First turn, all commander damage is new
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
            commanderDamageSourcePlayer[cmdDamage.commanderName] = cmdDamage.sourcePlayerIndex;
            turnCmdDamage += cmdDamage.damage;
            commanderDamagePerTurn.update(
              cmdDamage.commanderName,
              (v) => v + cmdDamage.damage,
              ifAbsent: () => cmdDamage.damage,
            );
          }
        } else {
          // Subsequent turns, calculate incremental damage
          final previousState = turnLog[i - 1].playerStates.firstWhere(
            (p) => p.playerIndex == playerState.playerIndex,
          );

          // Create a map of previous commander damage for comparison
          final previousCmdDamageMap = <String, int>{};
          for (final prevCmdDamage in previousState.commanderDamageTaken) {
            final key = '${prevCmdDamage.sourcePlayerIndex}:${prevCmdDamage.commanderName}';
            previousCmdDamageMap[key] =
                (previousCmdDamageMap[key] ?? 0) + prevCmdDamage.damage;
          }

          // Calculate new damage for each commander
          for (final cmdDamage in playerState.commanderDamageTaken) {
            final key = '${cmdDamage.sourcePlayerIndex}:${cmdDamage.commanderName}';
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
              commanderDamageSourcePlayer[cmdDamage.commanderName] = cmdDamage.sourcePlayerIndex;
              turnCmdDamage += newDamage;
              commanderDamagePerTurn.update(
                cmdDamage.commanderName,
                (v) => v + newDamage,
                ifAbsent: () => newDamage,
              );
            }
          }
        }
      }

      if (turnDamage > 0) {
        totalDamagePerTurn[i] = turnDamage;
      }
      if (turnCmdDamage > 0) {
        totalCommanderDamagePerTurn[i] = turnCmdDamage;
      }
    }

    final session = gameLogger.getSession();
    final mostDamagePlayer = damageDealtByPlayer.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    final mostCmdDamagePlayer = commanderDamageDealtByPlayer.isEmpty
        ? null
        : commanderDamageDealtByPlayer.entries
            .reduce((a, b) => a.value > b.value ? a : b);
    final mostCmdDamageCommander = commanderDamageOverall.isEmpty
        ? null
        : commanderDamageOverall.entries
            .reduce((a, b) => a.value > b.value ? a : b);
    final maxTurnDamage = totalDamagePerTurn.isEmpty
        ? null
        : totalDamagePerTurn.entries.reduce((a, b) => a.value > b.value ? a : b);
    final maxTurnCmdDamage = totalCommanderDamagePerTurn.isEmpty
        ? null
        : totalCommanderDamagePerTurn.entries.reduce((a, b) => a.value > b.value ? a : b);

    final stats = <Map<String, dynamic>>[];

    stats.add({
      'label': 'Most Damage Dealt Overall',
      'value': '${mostDamagePlayer.value}',
      'playerIndex': mostDamagePlayer.key,
      'urls': session.playerArtUrls[mostDamagePlayer.key],
    });

    if (maxTurnDamage != null) {
      stats.add({
        'label': 'Most Damage in a Single Turn',
        'value': '${maxTurnDamage.value}',
        'detail': 'Turn ${turnLog[maxTurnDamage.key].turnNumber}',
        'urls': session.playerArtUrls[turnLog[maxTurnDamage.key].activePlayerIndex],
      });
    }

    if (mostCmdDamagePlayer != null) {
      stats.add({
        'label': 'Most Commander Damage Dealt',
        'value': '${mostCmdDamagePlayer.value}',
        'playerIndex': mostCmdDamagePlayer.key,
        'urls': session.playerArtUrls[mostCmdDamagePlayer.key],
      });
    }

    if (mostCmdDamageCommander != null) {
      final sourcePlayerIndex = commanderDamageSourcePlayer[mostCmdDamageCommander.key]!;
      final sourcePlayerCommanders = session.playerCommanderNames[sourcePlayerIndex];
      final commanderIndex = sourcePlayerCommanders.indexOf(mostCmdDamageCommander.key);
      final commanderArtUrl = commanderIndex >= 0 && commanderIndex < session.playerArtUrls[sourcePlayerIndex].length
          ? [session.playerArtUrls[sourcePlayerIndex][commanderIndex]]
          : <String>[];
      
      stats.add({
        'label': 'Most Commander Damage (Single)',
        'value': '${mostCmdDamageCommander.value}',
        'detail': mostCmdDamageCommander.key,
        'urls': commanderArtUrl,
      });
    }

    if (maxTurnCmdDamage != null) {
      stats.add({
        'label': 'Most Cmd Damage in a Turn',
        'value': '${maxTurnCmdDamage.value}',
        'detail': 'Turn ${turnLog[maxTurnCmdDamage.key].turnNumber}',
        'urls': session.playerArtUrls[turnLog[maxTurnCmdDamage.key].activePlayerIndex],
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Damage Stats',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final stat = stats[index];
            return StatCard(
              label: stat['label'],
              value: stat['value'],
              detail: stat['detail'],
              backgroundUrls: (stat['urls'] as List<dynamic>?)?.cast<String>() ?? [],
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionStatsGrid(BuildContext context, GameLogger gameLogger) {
    final turnLog = gameLogger.getTurnLog();
    if (turnLog.isEmpty) {
      return const SizedBox.shrink();
    }

    final actionMaxPerPlayer = <String, Map<int, int>>{}; // action -> {playerIndex -> max}
    final actionTotalPerPlayer = <String, Map<int, int>>{}; // action -> {playerIndex -> total}
    final actionMaxPerTurn = <String, int>{};
    final actionMaxPerTurnInfo = <String, String>{}; // action -> "X (Turn Y)"

    const actions = ['Life Paid', 'Cards Milled', 'Extra Turns', 'Cards Drawn'];

    for (final action in actions) {
      actionMaxPerPlayer[action] = {};
      actionTotalPerPlayer[action] = {};
      int maxValue = 0;
      int maxTurnNum = -1;

      for (int i = 0; i < turnLog.length; i++) {
        final turn = turnLog[i];
        int turnValue = 0;

        for (final playerState in turn.playerStates) {
          final key = _actionKeyMap(action);
          final currentValue = playerState.actionTrackers[key] ?? 0;
          
          // Calculate incremental action value from previous turn
          int actionIncrement = 0;
          if (i == 0) {
            // First turn: all actions are new
            actionIncrement = currentValue;
          } else {
            // Subsequent turns: calculate difference from previous turn
            final previousState = turnLog[i - 1].playerStates.firstWhere(
              (p) => p.playerIndex == playerState.playerIndex,
            );
            final previousValue = previousState.actionTrackers[key] ?? 0;
            actionIncrement = currentValue - previousValue;
          }

          if (actionIncrement > 0) {
            // Update max for this player for this action
            actionMaxPerPlayer[action]!.update(
              playerState.playerIndex,
              (v) => v > actionIncrement ? v : actionIncrement,
              ifAbsent: () => actionIncrement,
            );
            // Update total for this player for this action
            actionTotalPerPlayer[action]!.update(
              playerState.playerIndex,
              (v) => v + actionIncrement,
              ifAbsent: () => actionIncrement,
            );
            turnValue += actionIncrement;
          }
        }

        if (turnValue > maxValue) {
          maxValue = turnValue;
          maxTurnNum = turn.turnNumber;
        }
      }

      if (maxValue > 0) {
        actionMaxPerTurn[action] = maxValue;
        actionMaxPerTurnInfo[action] = '$maxValue (Turn $maxTurnNum)';
      }
    }

    final session = gameLogger.getSession();
    final stats = <Map<String, dynamic>>[];

    for (final action in actions) {
      if (actionMaxPerPlayer[action]!.isNotEmpty) {
        final maxEntry = actionMaxPerPlayer[action]!.entries
            .reduce((a, b) => a.value > b.value ? a : b);
        stats.add({
          'label': action,
          'value': '${maxEntry.value}',
          'playerIndex': maxEntry.key,
          'urls': session.playerArtUrls[maxEntry.key],
        });
      }
    }

    if (stats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Action Stats',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final stat = stats[index];
            return StatCard(
              label: stat['label'],
              value: stat['value'],
              backgroundUrls: (stat['urls'] as List<dynamic>?)?.cast<String>() ?? [],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCounterStatsGrid(BuildContext context, GameLogger gameLogger) {
    final turnLog = gameLogger.getTurnLog();
    if (turnLog.isEmpty) {
      return const SizedBox.shrink();
    }

    final counterMaxPerPlayer = <String, Map<int, int>>{}; // counter -> {playerIndex -> max}
    final counterMaxOverall = <String, int>{};
    final counterMaxPlayerInfo = <String, int>{}; // counter -> playerIndex with max

    for (final counterName in UIConstants.playerCounterTypes) {
      counterMaxPerPlayer[counterName] = {};
      int maxValue = 0;
      int maxPlayerIndex = -1;

      for (final turn in turnLog) {
        for (final playerState in turn.playerStates) {
          final value = playerState.counters[counterName] ?? 0;
          if (value > 0) {
            counterMaxPerPlayer[counterName]!.update(
              playerState.playerIndex,
              (v) => v > value ? v : value,
              ifAbsent: () => value,
            );
            if (value > maxValue) {
              maxValue = value;
              maxPlayerIndex = playerState.playerIndex;
            }
          }
        }
      }

      if (maxValue > 0) {
        counterMaxOverall[counterName] = maxValue;
        counterMaxPlayerInfo[counterName] = maxPlayerIndex;
      }
    }

    if (counterMaxOverall.isEmpty) {
      return const SizedBox.shrink();
    }

    final session = gameLogger.getSession();
    final stats = <Map<String, dynamic>>[];

    for (final entry in counterMaxOverall.entries) {
      stats.add({
        'label': entry.key,
        'value': '${entry.value}',
        'playerIndex': counterMaxPlayerInfo[entry.key]!,
        'urls': session.playerArtUrls[counterMaxPlayerInfo[entry.key]!],
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Counter Stats',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final stat = stats[index];
            return StatCard(
              label: stat['label'],
              value: stat['value'],
              backgroundUrls: (stat['urls'] as List<dynamic>?)?.cast<String>() ?? [],
            );
          },
        ),
      ],
    );
  }

  Widget _buildNewGameButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              final session = widget.gameLogger.getSession();
              final initialPlayerNames = <String>[];
              final initialPartnerNames = <String>[];
              final initialHasPartner = <bool>[];

              for (int i = 0; i < session.playerCommanderNames.length; i++) {
                final commanders = session.playerCommanderNames[i];
                if (commanders.length > 1) {
                  initialPlayerNames.add(commanders[0]);
                  initialPartnerNames.add(commanders[1]);
                  initialHasPartner.add(true);
                } else {
                  final name = commanders[0];
                  if (name.startsWith('Player ')) {
                    initialPlayerNames.add('');
                  } else {
                    initialPlayerNames.add(name);
                  }
                  initialPartnerNames.add('');
                  initialHasPartner.add(false);
                }
              }

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => GameSetupPage(
                    initialPlayerNames: initialPlayerNames,
                    initialPartnerNames: initialPartnerNames,
                    initialHasPartner: initialHasPartner,
                    initialUnconventionalCommanders:
                        session.unconventionalCommanders,
                  ),
                ),
                (route) => false,
              );
            },
            child: const Text('Same Players'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const GameSetupPage(),
                ),
                (route) => false,
              );
            },
            child: const Text('New Game'),
          ),
        ),
      ],
    );
  }

  String _actionKeyMap(String action) {
    return action.toLowerCase().replaceAll(' ', '_');
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${seconds}s';
    }
  }
}class StatCard extends StatelessWidget {
  /// Label for the stat (e.g., "Most Damage Dealt Overall")
  final String label;

  /// The main stat value to display
  final String value;

  /// Optional detail text to display below the value
  final String? detail;

  /// URLs to background images (commander art)
  final List<String> backgroundUrls;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.detail,
    this.backgroundUrls = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(UIConstants.cardMarginAll),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(
          Radius.circular(UIConstants.cardBorderRadius),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background: Commander art images
          if (backgroundUrls.isNotEmpty)
            Positioned.fill(
              child: Opacity(
                opacity: UIConstants.backgroundImageOpacity,
                child: Row(
                  children: backgroundUrls.map((url) {
                    return Expanded(
                      child: Image.network(url, fit: BoxFit.cover),
                    );
                  }).toList(),
                ),
              ),
            ),
          // Main content column
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: UIConstants.lifeCounterTextColor,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: UIConstants.lifeCounterShadowBlurRadius,
                        color: UIConstants.lifeCounterShadowColor,
                        offset: const Offset(
                          UIConstants.lifeCounterShadowOffsetX,
                          UIConstants.lifeCounterShadowOffsetY,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: UIConstants.lifeCounterTextColor,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: UIConstants.lifeCounterShadowBlurRadius,
                      color: UIConstants.lifeCounterShadowColor,
                      offset: const Offset(
                        UIConstants.lifeCounterShadowOffsetX,
                        UIConstants.lifeCounterShadowOffsetY,
                      ),
                    ),
                  ],
                ),
              ),
              if (detail != null) ...[
                const SizedBox(height: 4),
                Text(
                  detail!,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: UIConstants.lifeCounterTextColor,
                    fontStyle: FontStyle.italic,
                    shadows: [
                      Shadow(
                        blurRadius: UIConstants.lifeCounterShadowBlurRadius,
                        color: UIConstants.lifeCounterShadowColor,
                        offset: const Offset(
                          UIConstants.lifeCounterShadowOffsetX,
                          UIConstants.lifeCounterShadowOffsetY,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}