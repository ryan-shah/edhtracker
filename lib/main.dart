import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const LifeTrackerPage(),
    );
  }
}

class LifeTrackerPage extends StatelessWidget {
  const LifeTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: RotatedBox(
                    quarterTurns: 2,
                    child: PlayerCard(playerIndex: 0),
                  ),
                ),
                Expanded(
                  child: RotatedBox(
                    quarterTurns: 2,
                    child: PlayerCard(playerIndex: 1),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: PlayerCard(playerIndex: 2),
                ),
                Expanded(
                  child: PlayerCard(playerIndex: 3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PlayerCard extends StatefulWidget {
  final int playerIndex;

  const PlayerCard({super.key, required this.playerIndex});

  @override
  State<PlayerCard> createState() => _PlayerCardState();
}

class _PlayerCardState extends State<PlayerCard> {
  int _life = 40;
  final Map<int, int> _commanderDamage = {};
  bool _showCommanderDamage = false;

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
      _commanderDamage.update(fromPlayerIndex, (value) => value + 1, ifAbsent: () => 1);
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

  @override
  Widget build(BuildContext context) {
    final allPlayers = List.generate(4, (i) => i);

    return Card(
      margin: const EdgeInsets.all(4.0),
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
                child: ElevatedButton(
                  onPressed: _toggleCommanderDamage,
                  child: const Text('Commander Damage'),
                ),
              ),
            ],
          ),
          // Overlay: Commander Damage
          if (_showCommanderDamage)
            Container(
              color: Theme.of(context).cardColor, // Opaque background
              child: Column(
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
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: _toggleCommanderDamage,
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
