import 'package:flutter/material.dart';
import 'utils.dart';

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
  State<PlayerCard> createState() => PlayerCardState();
}

class PlayerCardState extends State<PlayerCard> {
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
                        truncateName(
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
