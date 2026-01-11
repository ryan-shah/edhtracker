import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;

String _truncateName(String name, {int maxLength = 40, double? availableWidth}) {
  if (availableWidth != null) {
    // For PlayerCard: Estimate max characters based on available width.
    // Assuming an average character width of ~10.0 pixels for titleLarge text style.
    const double estimatedCharWidth = 10.0;
    final dynamicMaxLength = (availableWidth / estimatedCharWidth).floor();
    
    if (name.length <= dynamicMaxLength) {
      return name;
    }
    
    // Set maxLength to the calculated dynamic limit, ensuring it's at least 5 
    // to allow for "..." and a couple of characters.
    maxLength = max(5, dynamicMaxLength); 
  }

  if (name.length <= maxLength) {
    return name;
  }
  return '${name.substring(0, maxLength - 3)}...';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EDH Life Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const GameSetupPage(),
    );
  }
}

class CommanderAutocomplete extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final bool isPartner;

  const CommanderAutocomplete({
    super.key,
    required this.controller,
    required this.labelText,
    this.isPartner = false,
  });

  Future<List<String>> _getSuggestions(String pattern) async {
    if (pattern.length < 3) {
      return Future.value([]);
    }
    String query = 'name:"$pattern" is:commander';
    if (isPartner) {
      query += ' is:partner';
    }

    final uri = Uri.https('api.scryfall.com', '/cards/search', {
      'q': query,
      'order': 'edhrec',
    });

    final response = await http.get(
      uri,
      headers: {
        'User-Agent': 'EDHTracker/1.0',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['object'] == 'list' && data['data'] != null) {
        final cards = data['data'] as List;
        return cards.map((card) => card['name'] as String).toList();
      }
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return TypeAheadField<String>(
      suggestionsCallback: _getSuggestions,
      builder: (context, controller, primaryFocus) {
        return TextField(
          controller: controller,
          focusNode: primaryFocus,
          decoration: InputDecoration(
            labelText: labelText,
            border: const OutlineInputBorder(),
          ),
        );
      },
      controller: controller,
      itemBuilder: (context, suggestion) {
        return ListTile(
          title: Text(suggestion),
        );
      },
      onSelected: (suggestion) {
        controller.text = suggestion;
      },
    );
  }
}

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
    return _truncateName(name);
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

class LifeTrackerPage extends StatefulWidget {
  final List<String> playerNames;
  final int startingLife;
  final int startingPlayerIndex;

  const LifeTrackerPage({
    super.key,
    required this.playerNames,
    required this.startingLife,
    required this.startingPlayerIndex,
  });

  @override
  State<LifeTrackerPage> createState() => _LifeTrackerPageState();
}

class _LifeTrackerPageState extends State<LifeTrackerPage> {
  final List<GlobalKey<_PlayerCardState>> _playerCardKeys = List.generate(
    4,
    (_) => GlobalKey<_PlayerCardState>(),
  );
  late int _currentPlayerIndex;
  int _turnCount = 1;

  @override
  void initState() {
    super.initState();
    _currentPlayerIndex = widget.startingPlayerIndex;
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('New Game?'),
          content: const Text(
            'This will end the current game and return to the setup screen.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('New Game'),
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

  void _nextTurn() {
    setState(() {
      _currentPlayerIndex = (_currentPlayerIndex + 1) % 4;
      if (_currentPlayerIndex == widget.startingPlayerIndex) {
        _turnCount++;
      }
    });
  }

  void _previousTurn() {
    setState(() {
      if (_turnCount == 1 && _currentPlayerIndex == widget.startingPlayerIndex) {
        return;
      }
      final bool isNewTurn = _currentPlayerIndex == widget.startingPlayerIndex;
      _currentPlayerIndex = (_currentPlayerIndex - 1 + 4) % 4;
      if (isNewTurn) {
        _turnCount--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isPortrait = constraints.maxHeight > constraints.maxWidth;
          final lifeTrackerWidget = Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: RotatedBox(
                            quarterTurns: 2,
                            child: PlayerCard(
                              key: _playerCardKeys[0],
                              playerIndex: 0,
                              playerName: widget.playerNames[0],
                              startingLife: widget.startingLife,
                              isCurrentTurn: _currentPlayerIndex == 0,
                              onTurnEnd: _nextTurn,
                              onTurnBack: _previousTurn,
                              turnCount: _turnCount,
                            ),
                          ),
                        ),
                        Expanded(
                          child: RotatedBox(
                            quarterTurns: 2,
                            child: PlayerCard(
                              key: _playerCardKeys[1],
                              playerIndex: 1,
                              playerName: widget.playerNames[1],
                              startingLife: widget.startingLife,
                              isCurrentTurn: _currentPlayerIndex == 1,
                              onTurnEnd: _nextTurn,
                              onTurnBack: _previousTurn,
                              turnCount: _turnCount,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: PlayerCard(
                            key: _playerCardKeys[3],
                            playerIndex: 3,
                            playerName: widget.playerNames[3],
                            startingLife: widget.startingLife,
                            isCurrentTurn: _currentPlayerIndex == 3,
                            onTurnEnd: _nextTurn,
                            onTurnBack: _previousTurn,
                            turnCount: _turnCount,
                          ),
                        ),
                        Expanded(
                          child: PlayerCard(
                            key: _playerCardKeys[2],
                            playerIndex: 2,
                            playerName: widget.playerNames[2],
                            startingLife: widget.startingLife,
                            isCurrentTurn: _currentPlayerIndex == 2,
                            onTurnEnd: _nextTurn,
                            onTurnBack: _previousTurn,
                            turnCount: _turnCount,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Center(
                child: FloatingActionButton(
                  onPressed: _showResetDialog,
                  child: const Icon(Icons.refresh),
                ),
              ),
            ],
          );

          if (isPortrait) {
            return RotatedBox(quarterTurns: 1, child: lifeTrackerWidget);
          } else {
            return lifeTrackerWidget;
          }
        },
      ),
    );
  }
}

class PlayerCard extends StatefulWidget {
  final int playerIndex;
  final String playerName;
  final int startingLife;
  final bool isCurrentTurn;
  final VoidCallback onTurnEnd;
  final VoidCallback onTurnBack;
  final int turnCount;

  const PlayerCard({
    super.key,
    required this.playerIndex,
    required this.playerName,
    required this.startingLife,
    required this.isCurrentTurn,
    required this.onTurnEnd,
    required this.onTurnBack,
    required this.turnCount,
  });

  @override
  State<PlayerCard> createState() => _PlayerCardState();
}

class _PlayerCardState extends State<PlayerCard> {
  late int _life;
  final Map<int, int> _commanderDamage = {};
  final Map<String, int> _playerCounters = {};
  bool _showCommanderDamage = false;
  bool _showPlayerCounters = false;

  @override
  void initState() {
    super.initState();
    _life = widget.startingLife;
  }

  void reset() {
    setState(() {
      _life = widget.startingLife;
      _commanderDamage.clear();
      _playerCounters.clear();
      _showCommanderDamage = false;
      _showPlayerCounters = false;
    });
  }

  void _incrementLife() {
    setState(() {
      _life++;
    });
  }

  void _decrementLife() {
    setState(() {
      _life--;
    });
  }

  void _payLife() {
    setState(() {
      _life--;
    });
  }

  void _incrementCommanderDamage(int fromPlayerIndex) {
    setState(() {
      _commanderDamage.update(
        fromPlayerIndex,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      _life--;
    });
  }

  void _decrementCommanderDamage(int fromPlayerIndex) {
    setState(() {
      if (_commanderDamage.containsKey(fromPlayerIndex) &&
          _commanderDamage[fromPlayerIndex]! > 0) {
        _commanderDamage.update(
          fromPlayerIndex,
          (value) => value - 1,
          ifAbsent: () => 0,
        );
        _life++;
      }
    });
  }

  void _toggleCommanderDamage() {
    setState(() {
      _showCommanderDamage = !_showCommanderDamage;
    });
  }

  void _togglePlayerCounters() {
    setState(() {
      _showPlayerCounters = !_showPlayerCounters;
    });
  }

  void _incrementPlayerCounter(String counter) {
    setState(() {
      _playerCounters.update(counter, (value) => value + 1, ifAbsent: () => 1);
    });
  }

  void _decrementPlayerCounter(String counter) {
    setState(() {
      if (_playerCounters.containsKey(counter) &&
          _playerCounters[counter]! > 0) {
        _playerCounters.update(
          counter,
          (value) => value - 1,
          ifAbsent: () => 0,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final allPlayers = List.generate(4, (i) => i);
    const playerCounterTypes = ['Energy', 'Experience', 'Poison', 'Rad'];

    return GestureDetector(
      onTap: () {
        if (widget.isCurrentTurn) {
          widget.onTurnEnd();
        }
      },
      onLongPress: () {
        if (widget.isCurrentTurn) {
          widget.onTurnBack();
        }
      },
      child: Card(
        margin: const EdgeInsets.all(4.0),
        shape: widget.isCurrentTurn
            ? RoundedRectangleBorder(
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              )
            : null,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Base layer: Life counter
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Text(
                        _truncateName(
                          widget.playerName,
                          availableWidth: constraints.maxWidth,
                        ),
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: _decrementLife,
                        iconSize: 28,
                      ),
                      Text(
                        '$_life',
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _incrementLife,
                        iconSize: 28,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Wrap(
                    alignment: WrapAlignment.spaceEvenly,
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: [
                      ElevatedButton(
                        onPressed: _toggleCommanderDamage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.deepPurple,
                        ),
                        child: const Text('Cmdr Dmg'),
                      ),
                      ElevatedButton(
                        onPressed: _payLife,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.deepPurple,
                        ),
                        child: const Text('Pay Life'),
                      ),
                      ElevatedButton(
                        onPressed: _togglePlayerCounters,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.deepPurple,
                        ),
                        child: const Text('Counters'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Overlay: Commander Damage
            if (_showCommanderDamage)
              Container(
                color: Theme.of(context).cardColor, // Opaque background
                child: Stack(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 2,
                            childAspectRatio: 2.5,
                            children: allPlayers.map((fromPlayerIndex) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('From P${fromPlayerIndex + 1}:'),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove),
                                        iconSize: 20,
                                        onPressed: () =>
                                            _decrementCommanderDamage(
                                              fromPlayerIndex,
                                            ),
                                      ),
                                      Text(
                                        '${_commanderDamage[fromPlayerIndex] ?? 0}',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        iconSize: 20,
                                        onPressed: () =>
                                            _incrementCommanderDamage(
                                              fromPlayerIndex,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: FloatingActionButton(
                          onPressed: _toggleCommanderDamage,
                          backgroundColor: Colors.red,
                          mini: true,
                          child: const Icon(Icons.close),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Overlay: Player Counters
            if (_showPlayerCounters)
              Container(
                color: Theme.of(context).cardColor, // Opaque background
                child: Stack(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 2,
                            childAspectRatio: 2.5,
                            children: playerCounterTypes.map((counterName) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(counterName),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove),
                                        iconSize: 20,
                                        onPressed: () =>
                                            _decrementPlayerCounter(
                                              counterName,
                                            ),
                                      ),
                                      Text(
                                        '${_playerCounters[counterName] ?? 0}',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        iconSize: 20,
                                        onPressed: () =>
                                            _incrementPlayerCounter(
                                              counterName,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: FloatingActionButton(
                          onPressed: _togglePlayerCounters,
                          backgroundColor: Colors.red,
                          mini: true,
                          child: const Icon(Icons.close),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.isCurrentTurn)
              Positioned(
                top: 8,
                right: (widget.playerIndex == 0 || widget.playerIndex == 2)
                    ? 8.0
                    : null,
                left: (widget.playerIndex == 1 || widget.playerIndex == 3)
                    ? 8.0
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 6.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    'Turn ${widget.turnCount}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}