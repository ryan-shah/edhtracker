import 'dart:math';
import 'package:flutter/material.dart';
import 'commander_autocomplete.dart';
import 'life_tracker_page.dart';
import 'utils.dart';
import 'scryfall_service.dart';

class GameSetupPage extends StatefulWidget {
  final List<String>? initialPlayerNames;
  final List<String>? initialPartnerNames;
  final List<bool>? initialHasPartner;
  final bool? initialUnconventionalCommanders;

  const GameSetupPage({
    super.key,
    this.initialPlayerNames,
    this.initialPartnerNames,
    this.initialHasPartner,
    this.initialUnconventionalCommanders,
  });

  @override
  State<GameSetupPage> createState() => _GameSetupPageState();
}

class _GameSetupPageState extends State<GameSetupPage> {
  final _playerNames = List.generate(4, (i) => TextEditingController());
  final _partnerNames = List.generate(4, (i) => TextEditingController());
  final _hasPartner = List.generate(4, (i) => false);
  int _startingLife = 40;
  int _startingPlayerIndex = -1;
  bool _isLoading = false;
  bool _unconventionalCommanders = false;

  @override
  void initState() {
    super.initState();
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
      _unconventionalCommanders = widget.initialUnconventionalCommanders ?? false;
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
    final playerArtUrls = <List<String>>[];

    for (int i = 0; i < 4; i++) {
      final primary = _playerNames[i].text;
      final partner = _partnerNames[i].text;
      final currentArtUrls = <String>[];

      if (_hasPartner[i] && primary.isNotEmpty && partner.isNotEmpty) {
        playerNames.add('$primary // $partner');
        final primaryArt = await ScryfallService.getCardArtUrl(primary);
        final partnerArt = await ScryfallService.getCardArtUrl(partner);
        if (primaryArt != null) currentArtUrls.add(primaryArt);
        if (partnerArt != null) currentArtUrls.add(partnerArt);
      } else if (primary.isNotEmpty) {
        playerNames.add(primary);
        final primaryArt = await ScryfallService.getCardArtUrl(primary);
        if (primaryArt != null) currentArtUrls.add(primaryArt);
      } else {
        playerNames.add('Player ${i + 1}');
      }
      playerArtUrls.add(currentArtUrls);
    }

    final startingLife = _startingLife;
    var startingPlayerIndex = _startingPlayerIndex;
    if (startingPlayerIndex == -1) {
      startingPlayerIndex = Random().nextInt(4);
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
          playerArtUrls: playerArtUrls,
          startingLife: startingLife,
          startingPlayerIndex: startingPlayerIndex,
          unconventionalCommanders: _unconventionalCommanders,
        ),
      ),
    );
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
      appBar: AppBar(title: const Text('Game Setup'), centerTitle: true),
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
                    Row(
                      children: [
                        Tooltip(
                          message: 'Removes "is:commander" and "is:partner" filters from search',
                          child: IconButton(
                            icon: const Icon(Icons.help_outline),
                            onPressed: () {},
                          ),
                        ),
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
                    ...List.generate(4, (i) {
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
                                    unconventionalCommanders: _unconventionalCommanders,
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
                                unconventionalCommanders: _unconventionalCommanders,
                              ),
                            ]
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _startingLife,
                      decoration: const InputDecoration(
                        labelText: 'Starting Life Total',
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(10, (i) => (i + 1) * 10).map((life) {
                        return DropdownMenuItem(value: life, child: Text('$life'));
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
                        ...List.generate(4, (i) {
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
                    Text('Fetching Commander Art...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
