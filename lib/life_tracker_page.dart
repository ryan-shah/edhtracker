import 'package:flutter/material.dart';

import 'game_setup_page.dart';
import 'help_page.dart';
import 'player_card.dart';

class LifeTrackerPage extends StatefulWidget {
  final List<String> playerNames;
  final List<List<String>> playerCommanderNames;
  final List<List<String>> playerArtUrls;
  final int startingLife;
  final int startingPlayerIndex;
  final bool unconventionalCommanders;

  const LifeTrackerPage({
    super.key,
    required this.playerNames,
    required this.playerCommanderNames,
    required this.playerArtUrls,
    required this.startingLife,
    required this.startingPlayerIndex,
    this.unconventionalCommanders = false,
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
  bool _menuOpen = false;

  static const double _menuOffset = 100.0; // Fixed offset from center

  @override
  void initState() {
    super.initState();
    _currentPlayerIndex = widget.startingPlayerIndex;
    // Increment cardsDrawn for the starting player and then trigger a state update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playerCardKeys[_currentPlayerIndex].currentState?.incrementCardsDrawn();
    });
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
              child: const Text('New Game with Same Players'),
              onPressed: () {
                final List<String> initialPlayerNames = [];
                final List<String> initialPartnerNames = [];
                final List<bool> initialHasPartner = [];

                for (int i = 0; i < widget.playerCommanderNames.length; i++) {
                  final commanders = widget.playerCommanderNames[i];
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
                          widget.unconventionalCommanders,
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

  void _toggleMenu() {
    setState(() {
      _menuOpen = !_menuOpen;
    });
  }

  void _nextTurn() {
    setState(() {
      _currentPlayerIndex = (_currentPlayerIndex + 1) % 4;
      if (_currentPlayerIndex == widget.startingPlayerIndex) {
        _turnCount++;
      }
      // Increment cardsDrawn for the next player
      _playerCardKeys[_currentPlayerIndex].currentState?.incrementCardsDrawn();
    });
  }

  void _previousTurn() {
    setState(() {
      if (_turnCount == 1 &&
          _currentPlayerIndex == widget.startingPlayerIndex) {
        return;
      }
      final bool isNewTurn = _currentPlayerIndex == widget.startingPlayerIndex;
      // Decrement cardsDrawn for the previous player *before* changing _currentPlayerIndex
      _playerCardKeys[_currentPlayerIndex].currentState?.decrementCardsDrawn();

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

          final playerCardsWidget = Column(
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
                          allCommanderNames: widget.playerCommanderNames,
                          backgroundUrls: widget.playerArtUrls[0],
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
                          allCommanderNames: widget.playerCommanderNames,
                          backgroundUrls: widget.playerArtUrls[1],
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
                        allCommanderNames: widget.playerCommanderNames,
                        backgroundUrls: widget.playerArtUrls[3],
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
                        allCommanderNames: widget.playerCommanderNames,
                        backgroundUrls: widget.playerArtUrls[2],
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
          );

          final lifeTrackerWidget = isPortrait
              ? RotatedBox(quarterTurns: 1, child: playerCardsWidget)
              : playerCardsWidget;

          // Calculate center of screen and offset by fixed amount
          final centerX = constraints.maxWidth / 2;
          final centerY = constraints.maxHeight / 2;

          return Stack(
            children: [
              lifeTrackerWidget,
              Center(
                child: Stack(
                  children: [
                    // Help button (top)
                    if (_menuOpen)
                      Positioned(
                        top: centerY - _menuOffset,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: FloatingActionButton(
                            heroTag: 'help_button',
                            mini: true,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HelpPage(),
                                ),
                              );
                            },
                            child: const Icon(Icons.help_outline),
                          ),
                        ),
                      ),
                    // Start new game button (right)
                    if (_menuOpen)
                      Positioned(
                        right: centerX - _menuOffset,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: FloatingActionButton(
                            heroTag: 'new_game_button',
                            mini: true,
                            onPressed: () {
                              setState(() => _menuOpen = false);
                              _showResetDialog();
                            },
                            child: const Icon(Icons.restart_alt),
                          ),
                        ),
                      ),
                    // Complete current game button (bottom)
                    if (_menuOpen)
                      Positioned(
                        bottom: centerY - _menuOffset,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: FloatingActionButton(
                            heroTag: 'complete_game_button',
                            mini: true,
                            onPressed: () {
                              // TODO: Implement complete game functionality
                              setState(() => _menuOpen = false);
                            },
                            child: const Icon(Icons.check_circle_outline),
                          ),
                        ),
                      ),
                    // Left button (close)
                    if (_menuOpen)
                      Positioned(
                        left: centerX - _menuOffset,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: FloatingActionButton(
                            heroTag: 'close_menu_button',
                            mini: true,
                            onPressed: () {
                              setState(() => _menuOpen = false);
                            },
                            child: const Icon(Icons.close),
                          ),
                        ),
                      ),
                    // Main menu button (center)
                    Center(
                      child: FloatingActionButton(
                        heroTag: 'main_menu_button',
                        onPressed: _toggleMenu,
                        child: AnimatedRotation(
                          turns: _menuOpen ? 0.125 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(Icons.menu),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
