import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'commander_autocomplete.dart';
import 'game_logger.dart';
import 'game_summary_page.dart';
import 'help_game_setup.dart';
import 'life_tracker_page.dart';
import 'scryfall_service.dart';
import 'utils.dart';

class GameSetupPage extends StatefulWidget {
  final List<String>? initialPlayerNames;
  final List<String>? initialPartnerNames;
  final List<bool>? initialHasPartner;
  final bool? initialUnconventionalCommanders;
  final int? initialPlayerCount;

  const GameSetupPage({
    super.key,
    this.initialPlayerNames,
    this.initialPartnerNames,
    this.initialHasPartner,
    this.initialUnconventionalCommanders,
    this.initialPlayerCount,
  });

  @override
  State<GameSetupPage> createState() => _GameSetupPageState();
}

class _GameSetupPageState extends State<GameSetupPage>
    with SingleTickerProviderStateMixin {
  // Corrected mixin

  final _playerNames = List.generate(4, (i) => TextEditingController());
  final _partnerNames = List.generate(4, (i) => TextEditingController());
  final _hasPartner = List.generate(4, (i) => false);
  int _startingLife = 40;
  int _startingPlayerIndex = -1;
  int _playerCount = 4;
  bool _isLoading = false;
  bool _unconventionalCommanders = false;

  @override
  void initState() {
    super.initState();
    // Lock to portrait mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Initialize with provided data if available
    if (widget.initialPlayerNames != null &&
        widget.initialPartnerNames != null &&
        widget.initialHasPartner != null &&
        widget.initialPlayerNames!.length == 4) {
      for (int i = 0; i < 4; i++) {
        _playerNames[i].text = widget.initialPlayerNames![i];
        _partnerNames[i].text = widget.initialPartnerNames![i];
        _hasPartner[i] = widget.initialHasPartner![i];
      }
      _unconventionalCommanders =
          widget.initialUnconventionalCommanders ?? false;
      _playerCount = widget.initialPlayerCount ?? 4;
    }

    for (var controller in _playerNames) {
      controller.addListener(() => setState(() {}));
    }
    for (var controller in _partnerNames) {
      controller.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (var controller in _playerNames) {
      controller.dispose();
    }
    for (var controller in _partnerNames) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _startGame() async {
    setState(() {
      _isLoading = true;
    });

    final playerNames = <String>[];
    final playerCommanderNames = <List<String>>[];
    final playerArtUrls = <List<String>>[];

    for (int i = 0; i < _playerCount; i++) {
      final primary = _playerNames[i].text;
      final partner = _partnerNames[i].text;
      final currentArtUrls = <String>[];
      final currentCommanderNames = <String>[];

      if (_hasPartner[i] && primary.isNotEmpty && partner.isNotEmpty) {
        playerNames.add('$primary || $partner');
        currentCommanderNames.addAll([primary, partner]);
        final primaryArt = await ScryfallService.getCardArtUrl(primary);
        final partnerArt = await ScryfallService.getCardArtUrl(partner);
        if (primaryArt != null) currentArtUrls.add(primaryArt);
        if (partnerArt != null) currentArtUrls.add(partnerArt);
      } else if (primary.isNotEmpty) {
        playerNames.add(primary);
        currentCommanderNames.add(primary);
        final primaryArt = await ScryfallService.getCardArtUrl(primary);
        if (primaryArt != null) currentArtUrls.add(primaryArt);
      } else {
        playerNames.add('Player ${i + 1}');
        currentCommanderNames.add('Player ${i + 1}');
      }
      playerArtUrls.add(currentArtUrls);
      playerCommanderNames.add(currentCommanderNames);
    }

    final startingLife = _startingLife;
    var startingPlayerIndex = _startingPlayerIndex;
    if (startingPlayerIndex == -1 || startingPlayerIndex >= _playerCount) {
      startingPlayerIndex = Random().nextInt(_playerCount);
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LifeTrackerPage(
          playerNames: playerNames,
          playerCommanderNames: playerCommanderNames,
          playerArtUrls: playerArtUrls,
          startingLife: startingLife,
          startingPlayerIndex: startingPlayerIndex,
          playerCount: _playerCount,
          unconventionalCommanders: _unconventionalCommanders,
        ),
      ),
    );
  }

  Future<void> _loadGameFromJson() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        final PlatformFile file = result.files.single;

        // Read file content - handle both bytes and path
        String jsonString;
        if (file.bytes != null) {
          // If bytes are available (usually on web/some mobile), use them
          jsonString = utf8.decode(file.bytes!);
        } else if (file.path != null) {
          // If path is available (usually on Android/iOS), read from file system
          final fileContent = await File(file.path!).readAsString();
          jsonString = fileContent;
        } else {
          throw Exception(
            'Unable to read file: neither bytes nor path available',
          );
        }

        final gameLogger = GameLogger.fromJson(jsonString);

        // Fetch card art URLs for all commanders
        final session = gameLogger.getSession();
        final playerArtUrls = <List<String>>[];

        for (int i = 0; i < session.playerCommanderNames.length; i++) {
          final commanders = session.playerCommanderNames[i];
          final currentArtUrls = <String>[];

          for (final commander in commanders) {
            // Skip placeholder names like 'Player X'
            if (!commander.startsWith('Player ')) {
              final artUrl = await ScryfallService.getCardArtUrl(commander);
              if (artUrl != null) {
                currentArtUrls.add(artUrl);
              }
            }
          }

          playerArtUrls.add(currentArtUrls);
        }

        // Update the session's playerArtUrls
        session.playerArtUrls.clear();
        session.playerArtUrls.addAll(playerArtUrls);

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GameSummaryPage(gameLogger: gameLogger),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading game: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // User canceled the picker
    }
  }

  String _getPlayerDisplayName(int i) {
    final primary = _playerNames[i].text;
    final partner = _partnerNames[i].text;
    String name;
    if (_hasPartner[i] && primary.isNotEmpty && partner.isNotEmpty) {
      name = '$primary // $partner';
    } else if (primary.isNotEmpty) {
      name = primary;
    } else {
      name = 'Player ${i + 1}';
    }
    return truncateName(name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Setup'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Load Game',
            onPressed: () {
              _loadGameFromJson();
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpGameSetup()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _playerCount,
                      decoration: const InputDecoration(
                        labelText: 'Number of Players',
                        border: OutlineInputBorder(),
                      ),
                      items: [3, 4].map((count) {
                        return DropdownMenuItem(
                          value: count,
                          child: Text('$count Players'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _playerCount = value;
                            // Reset starting player index if it's out of range
                            if (_startingPlayerIndex >= _playerCount) {
                              _startingPlayerIndex = -1;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Unconventional Commanders'),
                            value: _unconventionalCommanders,
                            onChanged: (value) {
                              setState(() {
                                _unconventionalCommanders = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    ...List.generate(_playerCount, (i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: CommanderAutocomplete(
                                    controller: _playerNames[i],
                                    labelText: 'Player ${i + 1} Commander',
                                    unconventionalCommanders:
                                        _unconventionalCommanders,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('Partner?'),
                                    Checkbox(
                                      value: _hasPartner[i],
                                      onChanged: (value) {
                                        setState(() {
                                          _hasPartner[i] = value!;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (_hasPartner[i]) ...[
                              const SizedBox(height: 8),
                              CommanderAutocomplete(
                                controller: _partnerNames[i],
                                labelText: 'Partner Commander',
                                isPartner: true,
                                unconventionalCommanders:
                                    _unconventionalCommanders,
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: _startingLife,
                      decoration: const InputDecoration(
                        labelText: 'Starting Life Total',
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(10, (i) => (i + 1) * 10).map((life) {
                        return DropdownMenuItem(
                          value: life,
                          child: Text('$life'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _startingLife = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _startingPlayerIndex,
                      decoration: const InputDecoration(
                        labelText: 'Starting Player',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: -1,
                          child: Text('Random'),
                        ),
                        ...List.generate(_playerCount, (i) {
                          return DropdownMenuItem(
                            value: i,
                            child: Text(_getPlayerDisplayName(i)),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _startingPlayerIndex = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _startGame,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Start Game'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Loading game data...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
