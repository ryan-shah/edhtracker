import 'package:flutter/material.dart';

import 'constants.dart';
import 'counter_overlay.dart';
import 'utils.dart';
import 'game_logger.dart'; // Import the new game logger

/// Stateless widget that represents the configuration for a player card.
///
/// Contains all the data needed to display and manage a player's game state,
/// including commander information, starting life total, and callbacks for
/// turn management.
class PlayerCard extends StatefulWidget {
  /// Index of this player (0-3)
  final int playerIndex;

  /// Display name for this player
  final String playerName;

  /// 2D list of commander names: [playerIndex][commanderIndex]
  /// Used for tracking commander damage from each player's commander(s)
  final List<List<String>> allCommanderNames;

  /// URLs to background images (commander art) for this player.
  /// Can be empty if no commanders are set.
  final List<String> backgroundUrls;

  /// Starting life total for this player (usually 40 in EDH)
  final int startingLife;

  /// Whether it's currently this player's turn
  final bool isCurrentTurn;

  /// Callback to advance to the next player's turn
  final VoidCallback onTurnEnd;

  /// Callback to go back to the previous player's turn
  final VoidCallback onTurnBack;

  /// Current turn number
  final int turnCount;

  /// Duration of the current turn
  final Duration currentTurnDuration;

  const PlayerCard({
    super.key,
    required this.playerIndex,
    required this.playerName,
    required this.allCommanderNames,
    this.backgroundUrls = const [],
    required this.startingLife,
    required this.isCurrentTurn,
    required this.onTurnEnd,
    required this.onTurnBack,
    required this.turnCount,
    required this.currentTurnDuration,
  });

  @override
  State<PlayerCard> createState() => PlayerCardState();
}

/// State for PlayerCard widget.
///
/// Manages all the game state for a single player, including:
/// - Life total tracking
/// - Commander damage from each opponent
/// - Player counters (Energy, Experience, Poison, Rad)
/// - Action tracking (Life Paid, Cards Milled, Extra Turns)
/// - Visibility state of various overlays
class PlayerCardState extends State<PlayerCard> {
  /// Current life total for this player
  late int _life;

  /// Commander damage tracking: key = '${fromPlayerIndex}_${commanderIndex}', value = damage amount
  final Map<String, int> _commanderDamage = {};

  /// Player counter tracking: key = counter name, value = counter amount
  final Map<String, int> _playerCounters = {};

  /// Whether the commander damage overlay is currently visible
  bool _showCommanderDamage = false;

  /// Whether the player counters overlay is currently visible
  bool _showPlayerCounters = false;

  /// Whether the actions overlay is currently visible
  bool _showActions = false;

  /// Whether the player is currently shown as eliminated
  bool _isEliminated = false;

  /// Whether the player has dismissed the elimination overlay at least once
  bool _hasDismissedElimination = false;

  // ============================================================================
  // Action Trackers
  // ============================================================================

  /// Amount of life this player has paid (for effects like Necropotence)
  int _lifePaid = 0;

  /// Number of cards this player has milled
  int _cardsMilled = 0;

  /// Number of extra turns this player has taken
  int _extraTurns = 0;

  /// Number of cards this player has drawn
  int _cardsDrawn = 0;

  @override
  void initState() {
    super.initState();
    _life = widget.startingLife;
  }

  /// Resets all game state for this player back to initial values.
  /// Called when starting a new game.
  void reset() {
    setState(() {
      _life = widget.startingLife;
      _commanderDamage.clear();
      _playerCounters.clear();
      _showCommanderDamage = false;
      _showPlayerCounters = false;
      _showActions = false;
      _isEliminated = false;
      _hasDismissedElimination = false;
      _lifePaid = 0;
      _cardsMilled = 0;
      _extraTurns = 0;
      _cardsDrawn = 0;
    });
  }

  // ============================================================================
  // Life Total Management
  // ============================================================================

  /// Increments life total by 1
  void _incrementLife() {
    setState(() {
      _life++;
    });
  }

  /// Decrements life total by 1
  void _decrementLife() {
    setState(() {
      _life--;
      if (_life == 0) {
        _isEliminated = true;
      }
    });
  }

  // ============================================================================
  // Life Paid Tracking
  // ============================================================================

  /// Increments life paid and decrements life total
  void _incrementLifePaid() {
    setState(() {
      _lifePaid++;
      _life--;
      if (_life == 0) {
        _isEliminated = true;
      }
    });
  }

  /// Decrements life paid and increments life total (if life paid > 0)
  void _decrementLifePaid() {
    setState(() {
      if (_lifePaid > 0) {
        _lifePaid--;
        _life++;
      }
    });
  }

  // ============================================================================
  // Cards Milled Tracking
  // ============================================================================

  /// Increments cards milled counter
  void _incrementCardsMilled() {
    setState(() {
      _cardsMilled++;
    });
  }

  /// Decrements cards milled counter (if > 0)
  void _decrementCardsMilled() {
    setState(() {
      if (_cardsMilled > 0) {
        _cardsMilled--;
      }
    });
  }

  // ============================================================================
  // Extra Turns Tracking
  // ============================================================================

  /// Increments extra turns counter
  void _incrementExtraTurns() {
    setState(() {
      _extraTurns++;
    });
  }

  /// Decrements extra turns counter (if > 0)
  void _decrementExtraTurns() {
    setState(() {
      if (_extraTurns > 0) {
        _extraTurns--;
      }
    });
  }

  // ============================================================================
  // Cards Drawn Tracking
  // ============================================================================

  /// Increments cards drawn counter
  void incrementCardsDrawn() {
    setState(() {
      _cardsDrawn++;
    });
  }

  /// Decrements cards drawn counter (if > 0)
  void decrementCardsDrawn() {
    setState(() {
      if (_cardsDrawn > 0) {
        _cardsDrawn--;
      }
    });
  }

  // ============================================================================
  // Commander Damage Management
  // ============================================================================

  /// Increments commander damage from a specific player's commander.
  /// Also decrements this player's life total.
  ///
  /// [fromPlayerIndex] - Index of the player dealing damage
  /// [commanderIndex] - Index of the commander dealing damage
  void _incrementCommanderDamage(int fromPlayerIndex, int commanderIndex) {
    final key = '${fromPlayerIndex}_$commanderIndex';
    setState(() {
      _commanderDamage.update(key, (value) => value + 1, ifAbsent: () => 1);
      _life--;
      if (_life == 0 || _commanderDamage[key]! == 21) {
        _isEliminated = true;
      }
    });
  }

  /// Decrements commander damage from a specific player's commander.
  /// Also increments this player's life total if damage is > 0.
  ///
  /// [fromPlayerIndex] - Index of the player dealing damage
  /// [commanderIndex] - Index of the commander dealing damage
  void _decrementCommanderDamage(int fromPlayerIndex, int commanderIndex) {
    final key = '${fromPlayerIndex}_$commanderIndex';
    setState(() {
      if (_commanderDamage.containsKey(key) && _commanderDamage[key]! > 0) {
        _commanderDamage.update(key, (value) => value - 1, ifAbsent: () => 0);
        _life++;
      }
    });
  }

  // ============================================================================
  // Overlay Visibility Management
  // ============================================================================

  /// Toggles the visibility of the commander damage overlay.
  /// Hides other overlays when this one is shown.
  void _toggleCommanderDamage() {
    setState(() {
      _showCommanderDamage = !_showCommanderDamage;
      _showPlayerCounters = false;
      _showActions = false;
    });
  }

  /// Toggles the visibility of the player counters overlay.
  /// Hides other overlays when this one is shown.
  void _togglePlayerCounters() {
    setState(() {
      _showPlayerCounters = !_showPlayerCounters;
      _showCommanderDamage = false;
      _showActions = false;
    });
  }

  /// Toggles the visibility of the actions overlay.
  /// Hides other overlays when this one is shown.
  void _toggleActions() {
    setState(() {
      _showActions = !_showActions;
      _showCommanderDamage = false;
      _showPlayerCounters = false;
    });
  }

  // ============================================================================
  // Player Counter Management
  // ============================================================================

  /// Increments a player counter (Energy, Experience, Poison, or Rad)
  void _incrementPlayerCounter(String counter) {
    setState(() {
      _playerCounters.update(counter, (value) => value + 1, ifAbsent: () => 1);
    });
  }

  /// Decrements a player counter (if > 0)
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

  /// Returns a snapshot of the current player's state.
  PlayerStateSnapshot getCurrentState() {
    final List<CommanderDamageTaken> commanderDamageList = [];
    _commanderDamage.forEach((key, value) {
      final parts = key.split('_');
      commanderDamageList.add(
        CommanderDamageTaken(
          sourcePlayerIndex: int.parse(parts[0]),
          commanderName: widget.allCommanderNames[int.parse(parts[0])][int.parse(parts[1])],
          damage: value,
        ),
      );
    });

    return PlayerStateSnapshot(
      playerIndex: widget.playerIndex,
      life: _life,
      counters: Map.from(_playerCounters), // Create a copy
      actionTrackers: {
        'life_paid': _lifePaid,
        'cards_milled': _cardsMilled,
        'extra_turns': _extraTurns,
        'cards_drawn': _cardsDrawn,
      },
      commanderDamageTaken: commanderDamageList,
      isEliminated: _isEliminated,
    );
  }

  @override
  Widget build(BuildContext context) {
    String formatDuration(Duration duration) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final minutes = twoDigits(duration.inMinutes.remainder(60));
      final seconds = twoDigits(duration.inSeconds.remainder(60));
      return '$minutes:$seconds';
    }

    return GestureDetector(
      // Tap to advance to next player's turn (if current turn)
      onTap: () {
        if (widget.isCurrentTurn) {
          widget.onTurnEnd();
        }
      },
      // Long press to go back to previous player's turn (if current turn)
      onLongPress: () {
        if (widget.isCurrentTurn) {
          widget.onTurnBack();
        }
      },
      child: Card(
        margin: const EdgeInsets.all(UIConstants.cardMarginAll),
        clipBehavior: Clip.antiAlias,
        // Highlight border for current player
        shape: widget.isCurrentTurn
            ? RoundedRectangleBorder(
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: UIConstants.cardBorderWidth,
                ),
                borderRadius: const BorderRadius.all(
                  Radius.circular(UIConstants.cardBorderRadius),
                ),
              )
            : null,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background: Commander art images
            if (widget.backgroundUrls.isNotEmpty)
              Positioned.fill(
                child: Opacity(
                  opacity: UIConstants.backgroundImageOpacity,
                  child: Row(
                    children: widget.backgroundUrls.map((url) {
                      return Expanded(
                        child: Image.network(url, fit: BoxFit.cover),
                      );
                    }).toList(),
                  ),
                ),
              ),
            // Main content column
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Player name (shown if no background image)
                if (widget.backgroundUrls.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(
                      UIConstants.playerNamePadding,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Text(
                          truncateName(
                            widget.playerName,
                            availableWidth: constraints.maxWidth,
                          ),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: UIConstants.lifeCounterTextColor,
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        );
                      },
                    ),
                  ),
                // Extra spacing if background image is shown
                if (widget.backgroundUrls.isNotEmpty)
                  const SizedBox(
                    height: UIConstants.backgroundPaddingIfNotEmpty,
                  ),
                // Life total display with increment/decrement buttons
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: _decrementLife,
                        iconSize: UIConstants.lifeCounterIconSize,
                        color: UIConstants.lifeCounterTextColor,
                        style: IconButton.styleFrom(
                          backgroundColor:
                              UIConstants.buttonBackgroundDarkColor,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: UIConstants.lifeCounterPaddingHorizontal,
                        ),
                        child: Text(
                          '$_life',
                          style: Theme.of(context).textTheme.displayLarge
                              ?.copyWith(
                                color: UIConstants.lifeCounterTextColor,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    blurRadius:
                                        UIConstants.lifeCounterShadowBlurRadius,
                                    color: UIConstants.lifeCounterShadowColor,
                                    offset: const Offset(
                                      UIConstants.lifeCounterShadowOffsetX,
                                      UIConstants.lifeCounterShadowOffsetY,
                                    ),
                                  ),
                                ],
                              ),
                        ),
                      ),
                      // Row to keep buttons together
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _incrementLife,
                            iconSize: UIConstants.lifeCounterIconSize,
                            color: UIConstants.lifeCounterTextColor,
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  UIConstants.buttonBackgroundDarkColor,
                            ),
                          ),
                          // Self-eliminate button shown after dismissal
                          if (_hasDismissedElimination && !_isEliminated)
                            IconButton(
                              icon: const Icon(Icons.person_off),
                              onPressed: () {
                                setState(() {
                                  _isEliminated = true;
                                });
                              },
                              iconSize: UIConstants.lifeCounterIconSize * 0.7,
                              color: Colors.redAccent,
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    UIConstants.buttonBackgroundDarkColor,
                              ),
                              tooltip: 'Eliminate Player',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Action buttons for opening overlays
                Padding(
                  padding: const EdgeInsets.all(UIConstants.buttonPaddingAll),
                  child: Wrap(
                    alignment: WrapAlignment.spaceEvenly,
                    spacing: UIConstants.wrapSpacing,
                    runSpacing: UIConstants.wrapRunSpacing,
                    children: [
                      ElevatedButton(
                        onPressed: _toggleCommanderDamage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: UIConstants.buttonBackgroundColor
                              .withOpacity(UIConstants.buttonOpacity),
                          foregroundColor: UIConstants.buttonForegroundColor,
                        ),
                        child: const Text('Cmdr Dmg'),
                      ),
                      ElevatedButton(
                        onPressed: _toggleActions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: UIConstants.buttonBackgroundColor
                              .withOpacity(UIConstants.buttonOpacity),
                          foregroundColor: UIConstants.buttonForegroundColor,
                        ),
                        child: const Text('Actions'),
                      ),
                      ElevatedButton(
                        onPressed: _togglePlayerCounters,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: UIConstants.buttonBackgroundColor
                              .withOpacity(UIConstants.buttonOpacity),
                          foregroundColor: UIConstants.buttonForegroundColor,
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
              Positioned.fill(
                child: CounterOverlay(
                  items: [
                    // Generate items for commander damage from each player
                    for (int p = 0; p < 4; p++)
                      ...List.generate(widget.allCommanderNames[p].length, (c) {
                        final commanderName = widget.allCommanderNames[p][c];
                        final key = '${p}_$c';
                        return OverlayItem(
                          label: p == widget.playerIndex
                              ? '(you) $commanderName'
                              : commanderName,
                          value: _commanderDamage[key] ?? 0,
                          onIncrement: () => _incrementCommanderDamage(p, c),
                          onDecrement: () => _decrementCommanderDamage(p, c),
                        );
                      }),
                  ],
                  onClose: _toggleCommanderDamage,
                  isScrollable: true,
                ),
              ),
            // Overlay: Player Counters
            if (_showPlayerCounters)
              Positioned.fill(
                child: CounterOverlay(
                  items: UIConstants.playerCounterTypes
                      .map(
                        (name) => OverlayItem(
                          label: name,
                          value: _playerCounters[name] ?? 0,
                          onIncrement: () => _incrementPlayerCounter(name),
                          onDecrement: () => _decrementPlayerCounter(name),
                        ),
                      )
                      .toList(),
                  onClose: _togglePlayerCounters,
                ),
              ),
            // Overlay: Actions (Life Paid, Cards Milled, Extra Turns)
            if (_showActions)
              Positioned.fill(
                child: CounterOverlay(
                  items: [
                    OverlayItem(
                      label: 'Life Paid',
                      value: _lifePaid,
                      onIncrement: _incrementLifePaid,
                      onDecrement: _decrementLifePaid,
                    ),
                    OverlayItem(
                      label: 'Cards Milled',
                      value: _cardsMilled,
                      onIncrement: _incrementCardsMilled,
                      onDecrement: _decrementCardsMilled,
                    ),
                    OverlayItem(
                      label: 'Extra Turns',
                      value: _extraTurns,
                      onIncrement: _incrementExtraTurns,
                      onDecrement: _decrementExtraTurns,
                    ),
                    OverlayItem(
                      label: 'Cards Drawn',
                      value: _cardsDrawn,
                      onIncrement: incrementCardsDrawn,
                      onDecrement: decrementCardsDrawn,
                    ),
                  ],
                  onClose: _toggleActions,
                ),
              ),
            // Elimination Overlay
            if (_isEliminated)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isEliminated = false;
                      _hasDismissedElimination = true;
                    });
                  },
                  child: Container(
                    color: Colors.black.withOpacity(0.7),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off,
                          color: Colors.white,
                          size: 64,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'ELIMINATED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap to Dismiss',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            // Turn indicator and timer (shown if current player's turn)
            if (widget.isCurrentTurn)
              Positioned(
                top: UIConstants.turnCounterPositionOffset,
                right: (widget.playerIndex == 0 || widget.playerIndex == 2)
                    ? UIConstants.turnCounterPositionOffset
                    : null,
                left: (widget.playerIndex == 1 || widget.playerIndex == 3)
                    ? UIConstants.turnCounterPositionOffset
                    : null,
                child: Column(
                  crossAxisAlignment: (widget.playerIndex == 0 || widget.playerIndex == 2)
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: UIConstants.turnCounterPadding,
                        vertical: UIConstants.turnCounterVerticalPadding,
                      ),
                      decoration: BoxDecoration(
                        color: UIConstants.turnCounterBackgroundColor,
                        borderRadius: BorderRadius.circular(
                          UIConstants.turnCounterBorderRadius,
                        ),
                      ),
                      child: Text(
                        'Turn ${widget.turnCount}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: UIConstants.turnCounterTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: UIConstants.turnCounterPadding,
                        vertical: UIConstants.turnTimerVerticalPadding,
                      ),
                      decoration: BoxDecoration(
                        color: UIConstants.turnCounterBackgroundColor,
                        borderRadius: BorderRadius.circular(
                          UIConstants.turnCounterBorderRadius,
                        ),
                      ),
                      child: Text(
                        formatDuration(widget.currentTurnDuration),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: UIConstants.turnCounterTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
