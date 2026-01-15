import 'package:flutter/material.dart';
import 'utils.dart';
import 'constants.dart';

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

/// A reusable overlay widget for displaying and managing counters.
/// 
/// This widget is used throughout the app to display:
/// - Commander damage from each player
/// - Player counters (Energy, Experience, Poison, Rad)
/// - Action tracking (Life Paid, Cards Milled, Extra Turns)
/// 
/// The overlay adapts its layout based on the [isScrollable] flag:
/// - Non-scrollable: Shrink-wraps to fit all items, no scrolling needed
/// - Scrollable: Expands to fill available space with scrolling support
/// 
/// Features:
/// - Responsive grid layout (1 or 2 columns based on available width)
/// - Close button floating at the bottom center (or bottom right in single-column layout)
/// - Text truncation for long labels
/// - Responsive icon sizing based on screen width
class CounterOverlay extends StatelessWidget {
  /// List of counter items to display
  final List<OverlayItem> items;
  
  /// Callback when the close button is pressed
  final VoidCallback onClose;
  
  /// Whether the overlay should support scrolling.
  /// Set to true for overlays with many items (e.g., commander damage).
  /// Set to false for overlays with few items (e.g., player counters).
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
      color: Theme.of(context).cardColor.withOpacity(UIConstants.overlayContainerOpacity),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Determine number of columns based on available width
          final crossAxisCount = constraints.maxWidth > UIConstants.overlayMinCrossAxisCount ? 2 : 1;
          
          final double itemWidth = constraints.maxWidth / crossAxisCount;
          
          // Calculate item height
          // For single column, use a more compact height to remove space between items
          final double itemHeight = crossAxisCount == 1 
              ? UIConstants.defaultOverlayItemHeight * 0.75 
              : UIConstants.defaultOverlayItemHeight;

          return Stack(
            children: [
              // GridView without bottom padding to allow close button to overlay
              GridView.builder(
                padding: EdgeInsets.zero, // Ensure it starts at the very top
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: itemWidth / itemHeight,
                ),
                // Disable scrolling for non-scrollable overlays, allow for scrollable ones
                physics: isScrollable ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
                // Shrink-wrap non-scrollable content to fit its size
                shrinkWrap: !isScrollable,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Column(
                    mainAxisAlignment: crossAxisCount == 1 
                        ? MainAxisAlignment.start 
                        : MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 4.0),
                      // Item label with text truncation for long names
                      Text(
                        truncateName(item.label, availableWidth: itemWidth - UIConstants.overlayItemTextAvailableWidthOffset),
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      // Space between label and buttons
                      SizedBox(height: UIConstants.overlayItemPaddingBetweenLabelAndButtons),
                      // Row with decrement button, value, and increment button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            // Responsive icon size based on width
                            iconSize: constraints.maxWidth > UIConstants.largeIconSizeThreshold 
                                ? UIConstants.largeIconSize 
                                : UIConstants.smallIconSize,
                            onPressed: item.onDecrement,
                            visualDensity: crossAxisCount == 1 
                                ? VisualDensity.compact 
                                : VisualDensity.standard,
                          ),
                          // Current counter value
                          Text(
                            '${item.value}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            // Responsive icon size based on width
                            iconSize: constraints.maxWidth > UIConstants.largeIconSizeThreshold 
                                ? UIConstants.largeIconSize 
                                : UIConstants.smallIconSize,
                            onPressed: item.onIncrement,
                            visualDensity: crossAxisCount == 1 
                                ? VisualDensity.compact 
                                : VisualDensity.standard,
                          ),
                        ],
                      ),
                      if (crossAxisCount > 1) const SizedBox(height: 4.0)
                    ],
                  );
                },
              ),
              // Close button floating
              // Moves to bottom right if screen is small (single column), otherwise bottom center
              Positioned(
                bottom: UIConstants.overlayButtonBottom,
                left: crossAxisCount == 1 ? null : 0,
                right: crossAxisCount == 1 ? UIConstants.overlayButtonBottom : 0,
                child: crossAxisCount == 1
                    ? FloatingActionButton(
                        onPressed: onClose,
                        backgroundColor: UIConstants.closeButtonColor,
                        mini: true,
                        child: const Icon(Icons.close),
                      )
                    : Center(
                        child: FloatingActionButton(
                          onPressed: onClose,
                          backgroundColor: UIConstants.closeButtonColor,
                          mini: true,
                          child: const Icon(Icons.close),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
