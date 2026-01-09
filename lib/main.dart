import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const LifeTrackerPage(),
    );
  }
}

class LifeTrackerPage extends StatefulWidget {
  const LifeTrackerPage({super.key});

  @override
  State<LifeTrackerPage> createState() => _LifeTrackerPageState();
}

class _LifeTrackerPageState extends State<LifeTrackerPage> {
  final List<GlobalKey<_PlayerCardState>> _playerCardKeys =
      List.generate(4, (_) => GlobalKey<_PlayerCardState>());
  int _currentPlayerIndex = 0;
  int _turnCount = 1;

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Game?'),
          content: const Text(
              'Are you sure you want to reset all life totals, counters, and turns?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                _resetGame();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _resetGame() {
    for (var key in _playerCardKeys) {
      key.currentState?.reset();
    }
    setState(() {
      _currentPlayerIndex = 0;
      _turnCount = 1;
    });
  }

  void _nextTurn() {
    setState(() {
      _currentPlayerIndex = (_currentPlayerIndex + 1) % 4;
      if (_currentPlayerIndex == 0) {
        _turnCount++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
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
                          isCurrentTurn: _currentPlayerIndex == 0,
                          onTurnEnd: _nextTurn,
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
                          isCurrentTurn: _currentPlayerIndex == 1,
                          onTurnEnd: _nextTurn,
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
                        isCurrentTurn: _currentPlayerIndex == 3,
                        onTurnEnd: _nextTurn,
                        turnCount: _turnCount,
                      ),
                    ),
                    Expanded(
                      child: PlayerCard(
                        key: _playerCardKeys[2],
                        playerIndex: 2,
                        isCurrentTurn: _currentPlayerIndex == 2,
                        onTurnEnd: _nextTurn,
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
      ),
    );
  }
}

class PlayerCard extends StatefulWidget {
  final int playerIndex;
  final bool isCurrentTurn;
  final VoidCallback onTurnEnd;
  final int turnCount;

  const PlayerCard({
    super.key,
    required this.playerIndex,
    required this.isCurrentTurn,
    required this.onTurnEnd,
    required this.turnCount,
  });

  @override
  State<PlayerCard> createState() => _PlayerCardState();
}

class _PlayerCardState extends State<PlayerCard> {
  int _life = 40;
  final Map<int, int> _commanderDamage = {};
  final Map<String, int> _playerCounters = {};
  bool _showCommanderDamage = false;
  bool _showPlayerCounters = false;

  void reset() {
    setState(() {
      _life = 40;
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

  void _incrementCommanderDamage(int fromPlayerIndex) {
    setState(() {
      _commanderDamage.update(fromPlayerIndex, (value) => value + 1,
          ifAbsent: () => 1);
      _life--;
    });
  }

  void _decrementCommanderDamage(int fromPlayerIndex) {
    setState(() {
      if (_commanderDamage.containsKey(fromPlayerIndex) &&
          _commanderDamage[fromPlayerIndex]! > 0) {
        _commanderDamage.update(fromPlayerIndex, (value) => value - 1,
            ifAbsent: () => 0);
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
      if (_playerCounters.containsKey(counter) && _playerCounters[counter]! > 0) {
        _playerCounters.update(counter, (value) => value - 1, ifAbsent: () => 0);
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
      child: Card(
        margin: const EdgeInsets.all(4.0),
        shape: widget.isCurrentTurn
            ? RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 3),
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
                  child: Text(
                    'Player ${widget.playerIndex + 1}',
                    style: Theme.of(context).textTheme.titleLarge,
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _toggleCommanderDamage,
                        child: const Text('Commander Dmg'),
                      ),
                      ElevatedButton(
                        onPressed: _togglePlayerCounters,
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
                                            _decrementCommanderDamage(fromPlayerIndex),
                                      ),
                                      Text('${_commanderDamage[fromPlayerIndex] ?? 0}'),
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        iconSize: 20,
                                        onPressed: () =>
                                            _incrementCommanderDamage(fromPlayerIndex),
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
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _toggleCommanderDamage,
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
                                            _decrementPlayerCounter(counterName),
                                      ),
                                      Text('${_playerCounters[counterName] ?? 0}'),
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        iconSize: 20,
                                        onPressed: () =>
                                            _incrementPlayerCounter(counterName),
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
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _togglePlayerCounters,
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.isCurrentTurn)
              Positioned(
                top: 8,
                right: (widget.playerIndex == 0 || widget.playerIndex == 2) ? 8.0 : null,
                left: (widget.playerIndex == 1 || widget.playerIndex == 3) ? 8.0 : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
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
