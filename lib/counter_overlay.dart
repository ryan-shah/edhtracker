import 'package:flutter/material.dart';

import 'constants.dart';
import 'utils.dart';

/// Represents a single item in a counter overlay.
///
/// Each item displays a label, current value, and increment/decrement buttons.
class OverlayItem {
  /// Label text describing what is being tracked (e.g., "Life Paid", "Poison")
  final String label;

  /// Current numeric value of this counter
  final int value;

  /// Callback when the increment button is pressed
  final VoidCallback onIncrement;

  /// Callback when the decrement button is pressed
  final VoidCallback onDecrement;

  OverlayItem({
    required this.label,
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
  });
}

/// Full-screen overlay for displaying and managing a small set of counters.
///
/// Used by the page-level counter overlay (Energy/Experience/Poison/Rad) and
/// the action overlay (Life Paid/Cards Milled/Extra Turns/Cards Drawn) — both
/// of which pass exactly 4 [items]. The 2×2 layout fills the viewport so no
/// scrolling is needed.
///
/// Falls back to a responsive scrollable grid if [items.length] != 4 (no
/// current callers rely on this, but the widget stays defensive).
///
/// Visual language matches the life counter (see player_card.dart): big white
/// shadowed value text, dark circular icon buttons.
class CounterOverlay extends StatelessWidget {
  /// List of counter items to display
  final List<OverlayItem> items;

  /// Callback when the close button is pressed
  final VoidCallback onClose;

  /// Whether the fallback grid should support scrolling. Ignored by the 2×2
  /// layout (which never needs to scroll).
  final bool isScrollable;

  const CounterOverlay({
    super.key,
    required this.items,
    required this.onClose,
    this.isScrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(
        context,
      ).cardColor.withValues(alpha: UIConstants.overlayContainerOpacity),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              bottom: UIConstants.fullScreenOverlayCloseButtonBottom * 2 + 56,
            ),
            child: items.length == 4
                ? _build2x2(items)
                : _buildFallbackGrid(items),
          ),
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

  Widget _build2x2(List<OverlayItem> items) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _OverlayCell(item: items[0])),
              Expanded(child: _OverlayCell(item: items[1])),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _OverlayCell(item: items[2])),
              Expanded(child: _OverlayCell(item: items[3])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackGrid(List<OverlayItem> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount =
            constraints.maxWidth > UIConstants.overlayMinCrossAxisCount
            ? 2
            : 1;
        final double itemWidth = constraints.maxWidth / crossAxisCount;
        final double itemHeight = crossAxisCount == 1
            ? UIConstants.defaultOverlayItemHeight * 0.75
            : UIConstants.defaultOverlayItemHeight;
        return GridView.builder(
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: itemWidth / itemHeight,
          ),
          physics: isScrollable
              ? const AlwaysScrollableScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          shrinkWrap: !isScrollable,
          itemCount: items.length,
          itemBuilder: (context, index) => _OverlayCell(item: items[index]),
        );
      },
    );
  }
}

/// One cell in the 2×2 (or fallback grid) overlay.
///
/// Renders the item label, value (large white shadowed text matching the life
/// counter), and dark circular +/- icon buttons. Cell content scales down via
/// [FittedBox] when space is tight.
class _OverlayCell extends StatelessWidget {
  final OverlayItem item;

  const _OverlayCell({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(UIConstants.overlayCellPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return Text(
                truncateName(
                  item.label,
                  availableWidth: constraints.maxWidth,
                ),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: UIConstants.lifeCounterTextColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              );
            },
          ),
          const SizedBox(
            height: UIConstants.overlayItemPaddingBetweenLabelAndButtons,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: item.onDecrement,
                  iconSize: UIConstants.overlayCellIconSize,
                  color: UIConstants.lifeCounterTextColor,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: UIConstants.lifeCounterPaddingHorizontal,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${item.value}',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
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
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: item.onIncrement,
                  iconSize: UIConstants.overlayCellIconSize,
                  color: UIConstants.lifeCounterTextColor,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
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
