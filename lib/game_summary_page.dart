import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'constants.dart';
import 'game_logger.dart';
import 'game_setup_page.dart';
import 'game_stats_utility.dart';
import 'post_game_review_page.dart';

class GameSummaryPage extends StatefulWidget {
  final GameLogger gameLogger;

  const GameSummaryPage({super.key, required this.gameLogger});

  @override
  State<GameSummaryPage> createState() => _GameSummaryPageState();
}

class _GameSummaryPageState extends State<GameSummaryPage> {
  int? _selectedPlayerIndex; // null for overall stats, otherwise player index
  late GameStatsUtility _statsUtility;

  @override
  void initState() {
    super.initState();
    _statsUtility = GameStatsUtility(widget.gameLogger);
    // Lock to portrait orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  Future<void> _downloadGameLog() async {
    final String? downloadType = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Download Options'),
          content: const Text('What data would you like to download?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'full'),
              child: const Text('Full Game Log'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'stats'),
              child: const Text('Player Stats Summary'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, null),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (downloadType == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download cancelled.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      String jsonData;
      String filenamePrefix;

      if (downloadType == 'full') {
        jsonData = widget.gameLogger.toJsonString();
        filenamePrefix = 'full_game_log';
      } else {
        // Assume 'stats'
        jsonData = _statsUtility.toJsonString();
        filenamePrefix = 'player_stats_summary';
      }

      final timestamp = DateTime.now().toString().replaceAll(
        RegExp(r'[^\w\-]'),
        '_',
      );
      final filename = '${filenamePrefix}_$timestamp.json';

      if (!mounted) return;

      String? result = await FilePicker.platform.saveFile(
        dialogTitle: 'Please select an output file:',
        fileName: filename,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: utf8.encode(jsonData),
      );

      if (result == null && !kIsWeb) {
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
            _buildStatsTypeDropdown(context, session),
            const SizedBox(height: 24),
            if (_selectedPlayerIndex == null)
              _buildOverallStatsView(context, session)
            else
              _buildPlayerStatsView(context, session, _selectedPlayerIndex!),
            const SizedBox(height: 32),
            _buildSummaryActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsTypeDropdown(BuildContext context, GameSession session) {
    final playerNames = session.playerNames;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: DropdownButton<int?>(
        value: _selectedPlayerIndex,
        isExpanded: true,
        underline: const SizedBox(),
        onChanged: (int? newValue) {
          setState(() {
            _selectedPlayerIndex = newValue;
          });
        },
        items: [
          const DropdownMenuItem<int?>(
            value: null,
            child: Text('Overall Game Stats'),
          ),
          ...List.generate(
            playerNames.length,
            (index) => DropdownMenuItem<int?>(
              value: index,
              child: Text('${playerNames[index]} Stats'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStatsView(BuildContext context, GameSession session) {
    return Column(
      children: [
        _buildGameSessionInfoGrid(context, session),
        const SizedBox(height: 24),
        _buildDamageStatsGrid(context, session),
        const SizedBox(height: 24),
        _buildActionStatsGrid(context, session),
        const SizedBox(height: 24),
        _buildCounterStatsGrid(context, session),
      ],
    );
  }

  Widget _buildPlayerStatsView(
    BuildContext context,
    GameSession session,
    int playerIndex,
  ) {
    return Column(
      children: [
        _buildPlayerTimeStats(context, session, playerIndex),
        const SizedBox(height: 24),
        _buildPlayerDamageStats(context, session, playerIndex),
        const SizedBox(height: 24),
        _buildPlayerActionStats(context, session, playerIndex),
        const SizedBox(height: 24),
        _buildPlayerCounterStats(context, session, playerIndex),
      ],
    );
  }

  Widget _buildGameSessionInfoGrid(BuildContext context, GameSession session) {
    final longestTurn = _statsUtility.longestTurn;
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
      'value': '${_statsUtility.turnLog.length}',
      'urls': const <String>[],
    });

    if (longestTurn != null) {
      stats.add({
        'label': 'Longest Turn',
        'value': _formatDuration(longestTurn.duration),
        'detail': 'Turn ${longestTurn.turnNumber}',
        'urls': session.playerArtUrls[longestTurn.playerIndex],
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Game Session', style: Theme.of(context).textTheme.titleLarge),
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
              backgroundUrls:
                  (stat['urls'] as List<dynamic>?)?.cast<String>() ?? [],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDamageStatsGrid(BuildContext context, GameSession session) {
    final damageStats = _statsUtility.overallDamageStats;
    if (damageStats == null) return const SizedBox.shrink();

    final stats = <Map<String, dynamic>>[];

    if (damageStats.mostDamagePlayer != null) {
      final entry = damageStats.mostDamagePlayer!;
      stats.add({
        'label': 'Most Damage Dealt Overall',
        'value': '${entry.value}',
        'urls': session.playerArtUrls[entry.key],
      });
    }

    if (damageStats.maxTurnDamage != null) {
      final data = damageStats.maxTurnDamage!;
      stats.add({
        'label': 'Most Damage in a Single Turn',
        'value': '${data.value}',
        'detail': 'Turn ${data.turnNumber}',
        'urls': session.playerArtUrls[data.playerIndex],
      });
    }

    if (damageStats.mostCmdDamagePlayer != null) {
      final entry = damageStats.mostCmdDamagePlayer!;
      stats.add({
        'label': 'Most Commander Damage Dealt',
        'value': '${entry.value}',
        'urls': session.playerArtUrls[entry.key],
      });
    }

    if (damageStats.mostCmdDamageCommander != null) {
      final data = damageStats.mostCmdDamageCommander!;
      final sourcePlayerIndex = data.sourcePlayerIndex;
      final sourcePlayerCommanders =
          session.playerCommanderNames[sourcePlayerIndex];
      final commanderIndex = sourcePlayerCommanders.indexOf(data.name);
      final commanderArtUrl =
          commanderIndex >= 0 &&
              commanderIndex < session.playerArtUrls[sourcePlayerIndex].length
          ? [session.playerArtUrls[sourcePlayerIndex][commanderIndex]]
          : <String>[];

      stats.add({
        'label': 'Most Commander Damage (Single)',
        'value': '${data.value}',
        'detail': data.name,
        'urls': commanderArtUrl,
      });
    }

    if (damageStats.maxTurnCmdDamage != null) {
      final data = damageStats.maxTurnCmdDamage!;
      stats.add({
        'label': 'Most Cmd Damage in a Turn',
        'value': '${data.value}',
        'detail': 'Turn ${data.turnNumber}',
        'urls': session.playerArtUrls[data.playerIndex],
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Damage Stats', style: Theme.of(context).textTheme.titleLarge),
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
              backgroundUrls:
                  (stat['urls'] as List<dynamic>?)?.cast<String>() ?? [],
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionStatsGrid(BuildContext context, GameSession session) {
    final actionStats = _statsUtility.overallActionStats;

    final stats = <Map<String, dynamic>>[];

    actionStats.forEach((action, playerMap) {
      if (playerMap.isNotEmpty) {
        final maxEntry = playerMap.entries.reduce(
          (a, b) => a.value > b.value ? a : b,
        );
        stats.add({
          'label': action,
          'value': '${maxEntry.value}',
          'urls': session.playerArtUrls[maxEntry.key],
        });
      }
    });

    if (stats.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Action Stats', style: Theme.of(context).textTheme.titleLarge),
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
              backgroundUrls:
                  (stat['urls'] as List<dynamic>?)?.cast<String>() ?? [],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCounterStatsGrid(BuildContext context, GameSession session) {
    final counterStats = _statsUtility.overallCounterStats;
    if (counterStats.isEmpty) {
      return const SizedBox.shrink();
    }

    final stats = <Map<String, dynamic>>[];
    counterStats.forEach((counterName, data) {
      stats.add({
        'label': counterName,
        'value': '${data['value']}',
        'urls': session.playerArtUrls[data['playerIndex'] as int],
      });
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Counter Stats', style: Theme.of(context).textTheme.titleLarge),
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
              backgroundUrls:
                  (stat['urls'] as List<dynamic>?)?.cast<String>() ?? [],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPlayerTimeStats(
    BuildContext context,
    GameSession session,
    int playerIndex,
  ) {
    final playerStats = _statsUtility.allPlayerStats[playerIndex];
    final timeStats = playerStats.timeStats;

    if (timeStats.turnCount == 0) return const SizedBox.shrink();

    final stats = [
      {
        'label': 'Average Turn Time',
        'value': _formatDuration(timeStats.averageDuration),
      },
      {
        'label': 'Longest Turn',
        'value': _formatDuration(timeStats.longestDuration),
      },
      {
        'label': 'Total Turn Time',
        'value': _formatDuration(timeStats.totalDuration),
      },
      {'label': 'Total Turns', 'value': '${timeStats.turnCount}'},
    ];

    return _buildPlayerStatsSection(
      context,
      session,
      playerIndex,
      'Turn Time Stats',
      stats,
    );
  }

  Widget _buildPlayerDamageStats(
    BuildContext context,
    GameSession session,
    int playerIndex,
  ) {
    final playerStats = _statsUtility.allPlayerStats[playerIndex];
    final damageStats = playerStats.damageStats;

    final stats = [
      {'label': 'Average Damage/Turn', 'value': '${damageStats.averageDamage}'},
      {
        'label': 'Most Damage in Turn',
        'value': '${damageStats.maxDamageInTurn}',
      },
      {'label': 'Total Damage Dealt', 'value': '${damageStats.totalDamage}'},
      {
        'label': 'Avg Cmd Damage/Turn',
        'value': '${damageStats.averageCommanderDamage}',
      },
      {
        'label': 'Most Cmd Damage/Turn',
        'value': '${damageStats.maxCommanderDamageInTurn}',
      },
      {
        'label': 'Total Cmd Damage',
        'value': '${damageStats.totalCommanderDamage}',
      },
    ];

    return _buildPlayerStatsSection(
      context,
      session,
      playerIndex,
      'Damage Stats',
      stats,
    );
  }

  Widget _buildPlayerActionStats(
    BuildContext context,
    GameSession session,
    int playerIndex,
  ) {
    final playerStats = _statsUtility.allPlayerStats[playerIndex];
    final actionStats = playerStats.actionStats;
    if (actionStats.isEmpty) return const SizedBox.shrink();

    final stats = <Map<String, String>>[];
    actionStats.forEach((action, data) {
      stats.add({
        'label': '$action (Avg)',
        'value': '${data['average']}',
        'detail': 'Total: ${data['total']}',
      });
      stats.add({
        'label': '$action (Max)',
        'value': '${data['max']}',
        'detail': 'Total: ${data['total']}',
      });
    });

    return _buildPlayerStatsSection(
      context,
      session,
      playerIndex,
      'Action Stats (During Their Turns)',
      stats,
    );
  }

  Widget _buildPlayerCounterStats(
    BuildContext context,
    GameSession session,
    int playerIndex,
  ) {
    final playerStats = _statsUtility.allPlayerStats[playerIndex];
    final counterStats = playerStats.counterStats;
    final stats = <Map<String, String>>[];

    final ownTurns = counterStats['ownTurns'] as Map<String, Map<String, int>>;
    final opponentTurns =
        counterStats['opponentTurns'] as Map<String, Map<String, int>>;
    final ownCount = counterStats['ownTurnsCount'] as int;
    final oppCount = counterStats['opponentTurnsCount'] as int;

    ownTurns.forEach((counterName, data) {
      if (data['total']! > 0) {
        stats.add({
          'label': '$counterName (Own - Avg)',
          'value': '${ownCount > 0 ? data['total']! ~/ ownCount : 0}',
          'detail': 'Total: ${data['total']}',
        });
        stats.add({
          'label': '$counterName (Own - Max)',
          'value': '${data['max']}',
          'detail': 'Total: ${data['total']}',
        });
      }
    });

    opponentTurns.forEach((counterName, data) {
      if (data['total']! > 0) {
        stats.add({
          'label': '$counterName (Opp - Avg)',
          'value': '${oppCount > 0 ? data['total']! ~/ oppCount : 0}',
          'detail': 'Total: ${data['total']}',
        });
        stats.add({
          'label': '$counterName (Opp - Max)',
          'value': '${data['max']}',
          'detail': 'Total: ${data['total']}',
        });
      }
    });

    if (stats.isEmpty) return const SizedBox.shrink();
    return _buildPlayerStatsSection(
      context,
      session,
      playerIndex,
      'Counter Stats',
      stats,
    );
  }

  Widget _buildPlayerStatsSection(
    BuildContext context,
    GameSession session,
    int playerIndex,
    String title,
    List<Map<String, String>> stats,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
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
              label: stat['label']!,
              value: stat['value']!,
              detail: stat['detail'],
              backgroundUrls: session.playerArtUrls[playerIndex],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSummaryActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostGameReviewPage(
                    gameStatsUtility: _statsUtility, // Pass _statsUtility here
                  ),
                ),
              );
            },
            icon: const Icon(Icons.rate_review),
            label: const Text('Post Game Review'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _showNewGameDialog,
            child: const Text('New Game'),
          ),
        ),
      ],
    );
  }

  void _showNewGameDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('New Game?'),
          content: const Text(
            'Return to the setup screen to start a new game.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('New Game with Same Players'),
              onPressed: () {
                final session = widget.gameLogger.getSession();
                final List<String> initialPlayerNames = [];
                final List<String> initialPartnerNames = [];
                final List<bool> initialHasPartner = [];

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
            ),
            TextButton(
              child: const Text('New Game (Clear Players)'),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const GameSetupPage(),
                  ),
                  (route) => false,
                );
              },
            ),
          ],
        );
      },
    );
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
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? detail;
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
