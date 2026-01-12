# EDH Tracker

A simple and effective life tracker for four-player games of Magic: The Gathering's Commander (EDH) format.

## Features

*   **Game Setup:** Configure commander names, starting life total, and the first player before the game begins.
*   **Commander Autocomplete:** Search for commanders by name with autocomplete suggestions powered by Scryfall API.
*   **Partner Commanders:** Support for partner commanders - select up to two commanders per player.
*   **Unconventional Commanders:** Optional toggle to remove "is:commander" and "is:partner" filters for searching non-traditional commanders.
*   **Commander Art Display:** Each player's commander art is automatically fetched from Scryfall and displayed on their card with caching for offline access.
*   **Life Tracking:** Tracks life totals for four players with easy increment/decrement controls.
*   **Commander Damage:** Tracks commander damage from each player with an interactive overlay.
*   **Player Counters:** Tracks common player counters like Energy, Experience, Poison, and Rad via an overlay interface.
*   **Action Tracking:** Tracks actions such as life paid, cards milled, and extra turns taken.
*   **Turn Counter:** A clear turn counter is displayed on the current player's card with turn progression controls.
*   **High-Contrast UI:** Important elements like turn indicators and action buttons use a high-contrast white and deep purple theme for excellent visibility.
*   **Simple Interface:** A clean and intuitive interface, locked in landscape mode for easy viewing on a table.
*   **Easy Reset:** A central reset button takes you back to the setup screen for a new game, with a confirmation dialog.
*   **Customizable UI:** All colors, spacing, and dimensions are easily customizable through the centralized constants file.
*   **Improved UX:** Overlays for commander damage, player counters, and actions have clear close buttons and support scrolling for many items.

## Getting Started

This project is a Flutter application. To run it, you'll need to have the Flutter SDK installed.

1.  Clone this repository.
2.  Run `flutter pub get` to install dependencies.
3.  Run `flutter run` to start the application on a connected device or emulator.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Dependencies

*   **flutter_typeahead:** Provides autocomplete suggestions for commander search.
*   **http:** Handles API requests to the Scryfall database.
*   **shared_preferences:** Caches commander art images for offline access.

## Project Structure

### Core Files

*   **main.dart:** Application entry point and main app configuration.
*   **constants.dart:** Centralized UI constants for colors, spacing, and dimensions - modify here for global UI changes.
*   **utils.dart:** Utility functions including name truncation and shared helpers.

### Pages

*   **game_setup_page.dart:** Initial setup screen for configuring commanders, starting life, and first player.

### Game Mechanics

*   **player_card.dart:** Main player card widget displaying life total, commander art, and buttons for accessing counters and actions.
*   **counter_overlay.dart:** Reusable overlay widget for displaying and managing various counters (commander damage, player counters, actions).
*   **scryfall_service.dart:** Service for fetching commander data and images from Scryfall API.

### UI Components

*   **commander_autocomplete.dart:** Autocomplete input field for searching and selecting commanders.

## Customization

### Modifying UI Constants

All colors, spacing, padding, and dimensions are defined in `constants.dart`. To customize the appearance:

1. Open `lib/constants.dart`
2. Modify the relevant constant in the `UIConstants` class
3. Changes will automatically apply throughout the application

### Adding New Counters

To add new player counters:

1. Add the counter name to `UIConstants.playerCounterTypes` in `constants.dart`
2. The counter will automatically appear in the "Counters" overlay

### Adding New Actions

To add new action trackers:

1. Add instance variables in `PlayerCardState` (e.g., `int _newAction = 0`)
2. Add methods for increment/decrement
3. Add `OverlayItem` entries in the `_showActions` overlay

## Architecture Notes

*   **State Management:** The app uses Flutter's built-in `StatefulWidget` for local state management.
*   **API Integration:** Commander search and images are fetched from the Scryfall API with offline caching.
*   **Responsive UI:** The overlay grid adapts to different screen widths with 1 or 2 columns.
*   **Overlay System:** All counter displays (commander damage, player counters, actions) use the same `CounterOverlay` widget for consistency.
