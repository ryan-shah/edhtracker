import 'package:flutter/material.dart';

/// Centralized UI constants for the EDH Tracker application.
/// 
/// This class contains all colors, spacing, padding, and dimension values
/// used throughout the application. Modifying values here will automatically
/// update the appearance of the entire app.
/// 
/// Constants are organized into logical groups:
/// - Counter Overlay Constants: Dimensions and styling for overlay widgets
/// - Player Card Constants: Layout and styling for player cards
/// - Player Counter Types: Available counter types for players
/// - Colors: Color scheme for the entire application
class UIConstants {
  // ============================================================================
  // Counter Overlay Constants
  // ============================================================================
  
  /// Opacity of the overlay container background
  static const double overlayContainerOpacity = 0.95;
  
  /// Minimum width threshold for showing 2-column layout (otherwise 1 column)
  static const double overlayMinCrossAxisCount = 350;

  /// Default height for items in overlays
  static const double defaultOverlayItemHeight = 100.0;
  
  /// Bottom padding to reserve space for the close button
  static const double overlayPaddingBottom = 60.0;
  
  /// Bottom offset for the close button
  static const double overlayButtonBottom = 8.0;
  
  /// Top padding for overlay items (above label text)
  static const double overlayItemPaddingTop = 8.0;
  
  /// Space between label and increment/decrement buttons
  static const double overlayItemPaddingBetweenLabelAndButtons = 4.0;
  
  /// Bottom padding for overlay items (below buttons)
  static const double overlayItemPaddingBottom = 8.0;
  
  /// Offset subtracted from item width for text truncation calculation
  static const double overlayItemTextAvailableWidthOffset = 16.0;
  
  /// Large icon size for wide layouts (width > largeIconSizeThreshold)
  static const double largeIconSize = 24.0;
  
  /// Small icon size for narrow layouts (width <= largeIconSizeThreshold)
  static const double smallIconSize = 18.0;
  
  /// Minimum width threshold for using large icons
  static const double largeIconSizeThreshold = 300;

  // ============================================================================
  // Player Card Constants
  // ============================================================================
  
  /// Margin around the card widget
  static const double cardMarginAll = 4.0;
  
  /// Border width when player is the current turn
  static const double cardBorderWidth = 3.0;
  
  /// Border radius for card corners
  static const double cardBorderRadius = 12.0;
  
  /// Padding around player name text
  static const double playerNamePadding = 8.0;
  
  /// Opacity of the background image (commander art)
  static const double backgroundImageOpacity = 0.4;
  
  /// Top padding when background image is visible (to prevent overlap with name)
  static const double backgroundPaddingIfNotEmpty = 20.0;
  
  /// Horizontal padding around the life counter number
  static const double lifeCounterPaddingHorizontal = 16.0;
  
  /// Icon size for life counter increment/decrement buttons
  static const double lifeCounterIconSize = 28.0;
  
  /// Blur radius for the life counter text shadow
  static const double lifeCounterShadowBlurRadius = 10.0;
  
  /// X offset for the life counter text shadow
  static const double lifeCounterShadowOffsetX = 2.0;
  
  /// Y offset for the life counter text shadow
  static const double lifeCounterShadowOffsetY = 2.0;
  
  /// Padding around the button group
  static const double buttonPaddingAll = 8.0;
  
  /// Horizontal spacing between buttons
  static const double wrapSpacing = 8.0;
  
  /// Vertical spacing between button rows
  static const double wrapRunSpacing = 4.0;
  
  /// Opacity for action buttons
  static const double buttonOpacity = 0.9;
  
  /// Horizontal padding for the turn counter
  static const double turnCounterPadding = 12.0;
  
  /// Vertical padding for the turn counter
  static const double turnCounterVerticalPadding = 6.0;
  
  /// Position offset for the turn counter from the card edge
  static const double turnCounterPositionOffset = 8.0;
  
  /// Border radius for the turn counter container
  static const double turnCounterBorderRadius = 12.0;

  /// Vertical padding for the turn timer
  static const double turnTimerVerticalPadding = 4.0;

  // ============================================================================
  // Player Counter Types
  // ============================================================================
  
  /// Available player counter types that players can track.
  /// These appear in the "Counters" overlay.
  static const List<String> playerCounterTypes = ['Energy', 'Experience', 'Poison', 'Rad'];

  // ============================================================================
  // Colors
  // ============================================================================
  
  /// Color for the close button on overlays
  static const Color closeButtonColor = Colors.red;
  
  /// Background color for action buttons
  static const Color buttonBackgroundColor = Colors.white;
  
  /// Text color for action buttons
  static const Color buttonForegroundColor = Colors.deepPurple;
  
  /// Color for the life counter text
  static const Color lifeCounterTextColor = Colors.white;
  
  /// Color for the life counter text shadow
  static const Color lifeCounterShadowColor = Colors.black;
  
  /// Background color for the turn counter
  static const Color turnCounterBackgroundColor = Colors.white;
  
  /// Text color for the turn counter
  static const Color turnCounterTextColor = Colors.deepPurple;
  
  /// Dark background color for icon buttons
  static const Color buttonBackgroundDarkColor = Colors.black26;
}
