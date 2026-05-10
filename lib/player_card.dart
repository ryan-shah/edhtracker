import 'package:flutter/material.dart';

import 'constants.dart';
import 'game_logger.dart'; // Import the new game logger
import 'utils.dart';

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

  /// Whether to show the turn timer display
  final bool showTimerDisplay;

  /// Called when the player taps the "Cmdr Dmg" button.
  /// The page hosts a full-screen overlay for the receiver player.
  final ValueChanged<int> onOpenCommanderDamage;

  /// Called when the player taps the "Actions" button.
  final ValueChanged<int> onOpenActions;

  /// Called when the player taps the "Counters" button.
  final ValueChanged<int> onOpenCounters;

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
    required this.onOpenCommanderDamage,
    required this.onOpenActions,
    required this.onOpenCounters,
    this.showTimerDisplay = true, // Default to true
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

  /// Whether the player is currently shown as eliminated
  bool _isEliminated = false;

  // Removed: bool _showTimer = false;

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
      _isEliminated = false;
      _lifePaid = 0;
      _cardsMilled = 0;
      _extraTurns = 0;
      _cardsDrawn = 0;
    });
  }

  // ============================================================================
  // Public read-only getters (used by page-level full-screen overlays)
  // ============================================================================

  int get life => _life;
  int get lifePaid => _lifePaid;
  int get cardsMilled => _cardsMilled;
  int get extraTurns => _extraTurns;
  int get cardsDrawn => _cardsDrawn;
  bool get isEliminated => _isEliminated;
  Map<String, int> get playerCounters => Map.unmodifiable(_playerCounters);
  Map<String, int> get commanderDamage => Map.unmodifiable(_commanderDamage);

  // ============================================================================
  // Life Total Management
  // ============================================================================

  /// Increments life total by 1
  void incrementLife() {
    setState(() {
      _life++;
    });
  }

  /// Decrements life total by 1
  void decrementLife() {
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
  void incrementLifePaid() {
    setState(() {
      _lifePaid++;
      _life--;
      if (_life == 0) {
        _isEliminated = true;
      }
    });
  }

  /// Decrements life paid and increments life total (if life paid > 0)
  void decrementLifePaid() {
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
  void incrementCardsMilled() {
    setState(() {
      _cardsMilled++;
    });
  }

  /// Decrements cards milled counter (if > 0)
  void decrementCardsMilled() {
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
  void incrementExtraTurns() {
    setState(() {
      _extraTurns++;
    });
  }

  /// Decrements extra turns counter (if > 0)
  void decrementExtraTurns() {
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
  void incrementCommanderDamage(int fromPlayerIndex, int commanderIndex) {
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
  void decrementCommanderDamage(int fromPlayerIndex, int commanderIndex) {
    final key = '${fromPlayerIndex}_$commanderIndex';
    setState(() {
      if (_commanderDamage.containsKey(key) && _commanderDamage[key]! > 0) {
        _commanderDamage.update(key, (value) => value - 1, ifAbsent: () => 0);
        _life++;
      }
    });
  }

  // ============================================================================
  // Player Counter Management
  // ============================================================================

  /// Increments a player counter (Energy, Experience, Poison, or Rad)
  void incrementPlayerCounter(String counter) {
    setState(() {
      _playerCounters.update(counter, (value) => value + 1, ifAbsent: () => 1);
    });
  }

  /// Decrements a player counter (if > 0)
  void decrementPlayerCounter(String counter) {
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
          commanderName: widget
              .allCommanderNames[int.parse(parts[0])][int.parse(parts[1])],
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

  /// Long-press handler on the life total. Confirms with the user before
  /// marking the player eliminated.
  Future<void> _confirmEliminate(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminate ${widget.playerName}?'),
        content: const Text(
          'Mark this player as eliminated? Their turn will be skipped.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminate'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() {
        _isEliminated = true;
      });
    }
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
            // Background: Commander art images. Each image fills its half
            // (or full width for single commanders) via Stack.expand — same
            // pattern as the commander damage overlay tiles.
            if (widget.backgroundUrls.isNotEmpty)
              Positioned.fill(
                child: Row(
                  children: widget.backgroundUrls.map((url) {
                    return Expanded(
                      child: ClipRect(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Opacity(
                              opacity: UIConstants.backgroundImageOpacity,
                              child: Image.network(url, fit: BoxFit.cover),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
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
                  flex: 3,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: decrementLife,
                            iconSize: UIConstants.lifeCounterIconSize,
                            color: UIConstants.lifeCounterTextColor,
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  UIConstants.buttonBackgroundDarkColor,
                            ),
                          ),
                          GestureDetector(
                            onLongPress: () => _confirmEliminate(context),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal:
                                    UIConstants.lifeCounterPaddingHorizontal,
                              ),
                              child: Text(
                                '$_life',
                                style: Theme.of(context).textTheme.displayLarge
                                    ?.copyWith(
                                      color: UIConstants.lifeCounterTextColor,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          blurRadius: UIConstants
                                              .lifeCounterShadowBlurRadius,
                                          color: UIConstants
                                              .lifeCounterShadowColor,
                                          offset: const Offset(
                                            UIConstants
                                                .lifeCounterShadowOffsetX,
                                            UIConstants
                                                .lifeCounterShadowOffsetY,
                                          ),
                                        ),
                                      ],
                                    ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: incrementLife,
                            iconSize: UIConstants.lifeCounterIconSize,
                            color: UIConstants.lifeCounterTextColor,
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  UIConstants.buttonBackgroundDarkColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Action buttons for opening overlays
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(UIConstants.buttonPaddingAll),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => widget.onOpenCommanderDamage(
                              widget.playerIndex,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: UIConstants.buttonBackgroundColor
                                  .withValues(alpha: UIConstants.buttonOpacity),
                              foregroundColor:
                                  UIConstants.buttonForegroundColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              minimumSize: Size.zero,
                            ),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Cmdr Dmg'),
                            ),
                          ),
                        ),
                        const SizedBox(width: UIConstants.wrapSpacing),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                widget.onOpenActions(widget.playerIndex),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: UIConstants.buttonBackgroundColor
                                  .withValues(alpha: UIConstants.buttonOpacity),
                              foregroundColor:
                                  UIConstants.buttonForegroundColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              minimumSize: Size.zero,
                            ),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Actions'),
                            ),
                          ),
                        ),
                        const SizedBox(width: UIConstants.wrapSpacing),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                widget.onOpenCounters(widget.playerIndex),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: UIConstants.buttonBackgroundColor
                                  .withValues(alpha: UIConstants.buttonOpacity),
                              foregroundColor:
                                  UIConstants.buttonForegroundColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              minimumSize: Size.zero,
                            ),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Counters'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Elimination Overlay
            if (_isEliminated)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isEliminated = false;
                    });
                  },
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.7),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off, color: Colors.white, size: 64),
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
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Turn counter (always shown if current player's turn)
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
                  crossAxisAlignment:
                      (widget.playerIndex == 0 || widget.playerIndex == 2)
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: UIConstants.turnCounterTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    // Timer display (shown only if showTimerDisplay is true)
                    if (widget.showTimerDisplay) ...[
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
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: UIConstants.turnCounterTextColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
