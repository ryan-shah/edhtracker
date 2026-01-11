import 'package:flutter/material.dart';
import 'player_card.dart';
import 'game_setup_page.dart';

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
  final List<GlobalKey<PlayerCardState>> _playerCardKeys = List.generate(
    4,
    (_) => GlobalKey<PlayerCardState>(),
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
