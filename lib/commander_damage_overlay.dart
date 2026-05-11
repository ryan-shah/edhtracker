import 'package:flutter/material.dart';

import 'constants.dart';
import 'utils.dart';

/// Full-screen commander damage editor that mirrors the life-tracker layout.
///
/// Each opposing player slot shows the damage *that player's commander(s)*
/// have dealt to [receiverIndex]. For partner commanders, the slot splits
/// horizontally so each half is one commander. The receiver's own slot is
/// rendered but disabled, so the layout stays symmetric with the life tracker.
class CommanderDamageOverlay extends StatelessWidget {
  /// Index of the player who opened the overlay (the damage receiver).
  final int receiverIndex;

  /// Number of active players (2, 3, or 4).
  final int playerCount;

  /// 2D list of commander names: [playerIndex][commanderIndex].
  final List<List<String>> allCommanderNames;

  /// 2D list of commander art URLs: [playerIndex][commanderIndex].
  final List<List<String>> allArtUrls;

  /// Current damage map for the receiver, keyed by '${fromPlayerIndex}_$commanderIndex'.
  final Map<String, int> currentDamage;

  /// Called when the receiver takes one more damage from a commander.
  final void Function(int fromPlayerIndex, int commanderIndex) onIncrement;

  /// Called when the receiver removes one damage from a commander.
  final void Function(int fromPlayerIndex, int commanderIndex) onDecrement;

  /// Close-button callback.
  final VoidCallback onClose;

  const CommanderDamageOverlay({
    super.key,
    required this.receiverIndex,
    required this.playerCount,
    required this.allCommanderNames,
    required this.allArtUrls,
    required this.currentDamage,
    required this.onIncrement,
    required this.onDecrement,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(
        context,
      ).cardColor.withValues(alpha: UIConstants.overlayContainerOpacity),
      child: Stack(
        children: [
          switch (playerCount) {
            2 => _buildTwoSlotGrid(),
            3 => _buildThreeSlotGrid(),
            _ => _buildFourSlotGrid(),
          },
          Positioned(
            bottom: UIConstants.fullScreenOverlayCloseButtonBottom,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: onClose,
                backgroundColor: UIConstants.closeButtonColor,
                child: const Icon(Icons.close),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTwoSlotGrid() {
    return Column(
      children: [
        Expanded(
          child: RotatedBox(quarterTurns: 2, child: _buildSlot(1)),
        ),
        Expanded(child: _buildSlot(0)),
      ],
    );
  }

  Widget _buildFourSlotGrid() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: RotatedBox(quarterTurns: 2, child: _buildSlot(0)),
              ),
              Expanded(
                child: RotatedBox(quarterTurns: 2, child: _buildSlot(1)),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildSlot(3)),
              Expanded(child: _buildSlot(2)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThreeSlotGrid() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: RotatedBox(quarterTurns: 2, child: _buildSlot(0)),
              ),
              Expanded(
                child: RotatedBox(quarterTurns: 2, child: _buildSlot(1)),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildSlot(2)),
              Expanded(child: _buildPlaceholderSlot()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlot(int fromPlayerIndex) {
    return _CommanderDamageSlot(
      fromPlayerIndex: fromPlayerIndex,
      commanderNames: allCommanderNames[fromPlayerIndex],
      artUrls: allArtUrls[fromPlayerIndex],
      damage: currentDamage,
      isReceiver: fromPlayerIndex == receiverIndex,
      onIncrement: (c) => onIncrement(fromPlayerIndex, c),
      onDecrement: (c) => onDecrement(fromPlayerIndex, c),
    );
  }

  Widget _buildPlaceholderSlot() {
    return Container(
      color: Colors.black87,
      child: const Center(
        child: Text(
          'Player 4 Slot\n(Not Active)',
          style: TextStyle(color: Colors.white54, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// One player slot in the commander damage overlay.
///
/// Renders one or two [_CommanderTile]s side-by-side, mirroring the
/// PlayerCard's commander art split. When [isReceiver] is true, the slot is
/// still fully interactive (so stolen-commander damage can be recorded), with
/// a small "(you)" badge in the corner as a visual cue.
class _CommanderDamageSlot extends StatelessWidget {
  final int fromPlayerIndex;
  final List<String> commanderNames;
  final List<String> artUrls;
  final Map<String, int> damage;
  final bool isReceiver;
  final void Function(int commanderIndex) onIncrement;
  final void Function(int commanderIndex) onDecrement;

  const _CommanderDamageSlot({
    required this.fromPlayerIndex,
    required this.commanderNames,
    required this.artUrls,
    required this.damage,
    required this.isReceiver,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final tiles = Row(
      children: List.generate(commanderNames.length, (c) {
        return Expanded(
          child: _CommanderTile(
            commanderName: commanderNames[c],
            artUrl: c < artUrls.length ? artUrls[c] : '',
            damage: damage['${fromPlayerIndex}_$c'] ?? 0,
            onIncrement: () => onIncrement(c),
            onDecrement: () => onDecrement(c),
          ),
        );
      }),
    );

    if (!isReceiver) return tiles;

    return Stack(
      fit: StackFit.expand,
      children: [
        tiles,
        Positioned(
          top: 4,
          left: 4,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '(you)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A single commander tile inside a slot.
///
/// Background = commander art. Foreground = name (top), large damage number
/// (center), and two large transparent tap halves (left = decrement, right =
/// increment).
class _CommanderTile extends StatelessWidget {
  final String commanderName;
  final String artUrl;
  final int damage;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _CommanderTile({
    required this.commanderName,
    required this.artUrl,
    required this.damage,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (artUrl.isNotEmpty)
            Opacity(
              opacity: UIConstants.backgroundImageOpacity,
              child: Image.network(artUrl, fit: BoxFit.cover),
            ),
          // Tap targets: left half decrements, right half increments
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onDecrement,
                  child: Center(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: UIConstants.overlayButtonBackgroundColor,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(
                        UIConstants.overlayIconButtonPadding,
                      ),
                      child: Icon(
                        Icons.remove,
                        size: UIConstants.largeIconSize,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onIncrement,
                  child: Center(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: UIConstants.overlayButtonBackgroundColor,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(
                        UIConstants.overlayIconButtonPadding,
                      ),
                      child: Icon(
                        Icons.add,
                        size: UIConstants.largeIconSize,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Foreground content (name + damage number) — non-interactive so the
          // tap-half GestureDetectors below it still get the taps.
          IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.all(
                UIConstants.commanderDamageSlotPadding,
              ),
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Text(
                        truncateName(
                          commanderName,
                          availableWidth: constraints.maxWidth,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(blurRadius: 4, color: Colors.black),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '$damage',
                        style: TextStyle(
                          color: damage >= 21
                              ? Colors.redAccent
                              : Colors.white,
                          fontSize:
                              UIConstants.commanderDamageNumberFontSize,
                          fontWeight: FontWeight.bold,
                          shadows: const [
                            Shadow(blurRadius: 6, color: Colors.black),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
