import 'dart:math';
import 'package:flutter/material.dart';
import 'commander_autocomplete.dart';
import 'life_tracker_page.dart';
import 'utils.dart';

class GameSetupPage extends StatefulWidget {
  const GameSetupPage({super.key});

  @override
  State<GameSetupPage> createState() => _GameSetupPageState();
}

class _GameSetupPageState extends State<GameSetupPage> {
  final _playerNames = List.generate(4, (i) => TextEditingController());
  final _partnerNames = List.generate(4, (i) => TextEditingController());
  final _hasPartner = List.generate(4, (i) => false);
  int _startingLife = 40;
  int _startingPlayerIndex = -1;

  @override
  void initState() {
    super.initState();
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

  void _startGame() {
    final playerNames = List.generate(4, (i) {
      final primary = _playerNames[i].text;
      final partner = _partnerNames[i].text;
      if (_hasPartner[i] && primary.isNotEmpty && partner.isNotEmpty) {
        return '$primary // $partner';
      } else if (primary.isNotEmpty) {
        return primary;
      }
      return 'Player ${i + 1}';
    });

    final startingLife = _startingLife;
    var startingPlayerIndex = _startingPlayerIndex;
    if (startingPlayerIndex == -1) {
      startingPlayerIndex = Random().nextInt(4);
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LifeTrackerPage(
          playerNames: playerNames,
          startingLife: startingLife,
          startingPlayerIndex: startingPlayerIndex,
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
    // Use a static, generous max length for the dropdown display
    return truncateName(name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Setup'), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                          ),
                        ]
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
                  onPressed: _startGame,
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
    );
  }
}
