import 'dart:async'; // Import for Timer
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game_logger.dart'; // Import the new game logger
import 'game_setup_page.dart';
import 'help_life_tracker.dart';
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
  // Timer visibility state moved to PlayerCard, but this controls if timer *ticks* and is *passed down*
  late bool _isTimerEnabled; 
  late GameLogger _gameLogger; // Declare GameLogger instance

  // Turn tracking for timer
  late DateTime _currentTurnStartTime;
  Duration _currentTurnDuration = Duration.zero;
  Timer? _turnTimer;

  static const double _menuOffset = 100.0; // Fixed offset from center

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _currentPlayerIndex = widget.startingPlayerIndex;
    _currentTurnStartTime = DateTime.now(); // Initialize turn start time
    _isTimerEnabled = true; // Timer is enabled by default

    _gameLogger = GameLogger(
      playerNames: widget.playerNames,
      playerCommanderNames: widget.playerCommanderNames,
      playerArtUrls: widget.playerArtUrls,
      startingLife: widget.startingLife,
      startingPlayerIndex: widget.startingPlayerIndex,
      unconventionalCommanders: widget.unconventionalCommanders,
    );

    // Increment cardsDrawn for the starting player and then trigger a state update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playerCardKeys[_currentPlayerIndex].currentState?.incrementCardsDrawn();
      _startTurnTimer(); // Start the timer for the first turn
    });
  }

  @override
  void dispose() {
    _turnTimer?.cancel();
    super.dispose();
  }

  void _startTurnTimer() {
    _turnTimer?.cancel(); // Cancel any existing timer
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTurnDuration = DateTime.now().difference(_currentTurnStartTime);
        });
      }
    });
  }

  void _toggleTimerDisplay() {
    setState(() => _isTimerEnabled = !_isTimerEnabled);
    // PlayerCard will now use the passed `_isTimerEnabled` to decide whether to show the timer.
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
                _turnTimer?.cancel(); // Cancel timer on new game
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
                _turnTimer?.cancel(); // Cancel timer on new game
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
      // Record the state *before* advancing the turn
      _gameLogger.recordTurn(_currentPlayerIndex, _turnCount, _playerCardKeys);
      _gameLogger.logLastTurn();

      _currentPlayerIndex = (_currentPlayerIndex + 1) % 4;
      if (_currentPlayerIndex == widget.startingPlayerIndex) {
        _turnCount++;
      }
      // Increment cardsDrawn for the next player
      _playerCardKeys[_currentPlayerIndex].currentState?.incrementCardsDrawn();

      _currentTurnStartTime = DateTime.now(); // Reset turn start time for the new turn
      _currentTurnDuration = Duration.zero; // Reset duration
      _startTurnTimer(); // Restart the timer for the new turn
    });
  }

  void _previousTurn() {
    setState(() {
      if (_turnCount == 1 &&
          _currentPlayerIndex == widget.startingPlayerIndex) {
        // Cannot go back before the very first turn
        return;
      }

      // Decrement cardsDrawn for the current player before restoring previous state
      _playerCardKeys[_currentPlayerIndex].currentState?.decrementCardsDrawn();

      final previousTurnEntry = _gameLogger.goToPreviousTurn();
      if (previousTurnEntry != null) {
        _currentPlayerIndex = previousTurnEntry.activePlayerIndex;
        _turnCount = previousTurnEntry.turnNumber;
        _currentTurnStartTime = previousTurnEntry.turnStartTime;
        // The duration shown for a previous turn should be its recorded duration, not elapsed time since now.
        // However, if we go back to a turn, it becomes the *current* turn again,
        // so we track its duration from its original start time to "now" until the turn is advanced again.
        _currentTurnDuration = DateTime.now().difference(_currentTurnStartTime);
        _startTurnTimer(); // Restart the timer to track the "reverted" turn's duration
      } else {
        // Should only happen if _turnLog becomes empty after removing the last entry,
        // which means we are at the very beginning of the game.
        _currentPlayerIndex = widget.startingPlayerIndex;
        _turnCount = 1;
        _currentTurnStartTime = _gameLogger.getSession().startTime;
        _currentTurnDuration = Duration.zero;
        _startTurnTimer(); // Restart timer for the very first turn
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
                          currentTurnDuration: _currentPlayerIndex == 0 ? _currentTurnDuration : Duration.zero,
                          showTimerDisplay: _isTimerEnabled, // Pass timer enabled state
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
                          currentTurnDuration: _currentPlayerIndex == 1 ? _currentTurnDuration : Duration.zero,
                          showTimerDisplay: _isTimerEnabled, // Pass timer enabled state
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
                        currentTurnDuration: _currentPlayerIndex == 3 ? _currentTurnDuration : Duration.zero,
                        showTimerDisplay: _isTimerEnabled, // Pass timer enabled state
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
                        currentTurnDuration: _currentPlayerIndex == 2 ? _currentTurnDuration : Duration.zero,
                        showTimerDisplay: _isTimerEnabled, // Pass timer enabled state
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
                                  builder: (context) => const HelpLifeTracker(),
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
                              setState(() => _menuOpen = false);
                              _turnTimer?.cancel(); // Cancel timer on game end
                              _gameLogger.endGame(); // Call endGame method
                              _gameLogger.logData();
                            },
                            child: const Icon(Icons.check_circle_outline),
                          ),
                        ),
                      ),
                    // Timer toggle button (left)
                    if (_menuOpen)
                      Positioned(
                        left: centerX - _menuOffset,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: FloatingActionButton(
                            heroTag: 'timer_button',
                            mini: true,
                            onPressed: _toggleTimerDisplay, // Use new method
                            child: _isTimerEnabled ? const Icon(Icons.timer_outlined) : const Icon(Icons.timer_off_outlined), // Update icon based on state
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
