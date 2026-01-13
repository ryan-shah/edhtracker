import 'package:flutter/material.dart';
import 'constants.dart';

/// Help page that explains the functionality of the EDH Tracker application.
/// 
/// Provides detailed information about:
/// - Game Setup page features and options
/// - Life Tracker page controls and interactions
/// - Various tracking tools (Commander Damage, Counters, Actions)
/// - Tips and best practices
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'Game Setup'),
                  _buildSection(context, [
                    _buildSectionContent(
                      'Commander Selection',
                      'Search for and select a commander for each player. The autocomplete feature will suggest commanders as you type, powered by the Scryfall database.',
                    ),
                    _buildSectionContent(
                      'Partner Commanders',
                      'Check the "Partner?" checkbox next to a commander to add a second commander to that player. Use this for partner commanders or other multi-commander strategies.',
                    ),
                    _buildSectionContent(
                      'Unconventional Commanders',
                      'Enable this option to remove the "is:commander" and "is:partner" filters from the search. This allows you to search for any card, useful for alternate formats or house rules.',
                    ),
                    _buildSectionContent(
                      'Starting Life Total',
                      'Select the starting life total for the game. Standard EDH uses 40 life, but you can customize this value.',
                    ),
                    _buildSectionContent(
                      'Starting Player',
                      'Choose which player goes first, or select "Random" to randomly determine the starting player.',
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Life Tracker'),
                  _buildSection(context, [
                    _buildSectionContent(
                      'Life Counter',
                      'Each player\'s life total is displayed prominently in the center of their card. Tap the + button to increase life or the - button to decrease life.',
                    ),
                    _buildSectionContent(
                      'Turn Indicator',
                      'The current player\'s card will have a blue border and display "Turn X" in the corner, where X is the current turn number.',
                    ),
                    _buildSectionContent(
                      'Advancing Turns',
                      'Tap any player card to advance to the next player\'s turn. Long-press a card to go back to the previous player\'s turn.',
                    ),
                    _buildSectionContent(
                      'Commander Art Display',
                      'If commanders were selected during setup, their card art will be displayed in the background of each player\'s card.',
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Main Menu'),
                  _buildSection(context, [
                    _buildToolSection(
                      context,
                      'Help (Top)',
                      'Opens this help page to guide you through the application\'s features.',
                      Icons.help_outline,
                    ),
                    _buildToolSection(
                      context,
                      'New Game (Right)',
                      'Resets the match. You can choose to start a new game with the same players/commanders or clear everything to start fresh.',
                      Icons.restart_alt,
                    ),
                    _buildToolSection(
                      context,
                      'Complete Game (Bottom)',
                      'Finalizes the current match. (Functionality coming soon).',
                      Icons.check_circle_outline,
                    ),
                    _buildToolSection(
                      context,
                      'Close Menu (Left)',
                      'Hides the expanded menu options.',
                      Icons.close,
                    ),
                    _buildToolSection(
                      context,
                      'Menu Toggle (Center)',
                      'Taps to expand or collapse the central control menu.',
                      Icons.menu,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Tracking Tools'),
                  _buildSection(context, [
                    _buildToolSection(
                      context,
                      'Cmdr Dmg (Commander Damage)',
                      'Track damage dealt by each opponent\'s commander. '
                      'Tap the "Cmdr Dmg" button to open an overlay showing damage from each player\'s commander(s). '
                      'Use the + and - buttons to adjust damage. '
                      'Note: In regular EDH, 21 commander damage from a single commander causes that player to lose.',
                      Icons.shield,
                    ),
                    _buildToolSection(
                      context,
                      'Counters',
                      'Track player counters such as Energy, Experience, Poison, and Rad. '
                      'Tap the "Counters" button to open an overlay where you can increment or decrement each counter type. '
                      'These counters are useful for tracking various card mechanics and effects.',
                      Icons.assessment,
                    ),
                    _buildToolSection(
                      context,
                      'Actions',
                      'Track important game actions and events:\n'
                      '• Life Paid: Tracks life points paid for effects (e.g., Necropotence, Phyrexian mana).\n'
                      '• Cards Milled: Counts the number of cards milled from libraries.\n'
                      '• Extra Turns: Tracks extra turns taken by the player.\n'
                      '• Cards Drawn: Tracks the number of cards drawn by the player. Auto increments on turn start.\n'
                      'Tap the "Actions" button to open an overlay and manage these counters.',
                      Icons.track_changes,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Tips & Best Practices'),
                  _buildSection(context, [
                    _buildTipContent(
                      'Quick Navigation',
                      'Use tap to advance turns and long-press to go back. This is faster than using an app menu.',
                    ),
                    _buildTipContent(
                      'Overlay Management',
                      'Only one overlay can be visible at a time. Opening a new overlay will close any previously open one. Close overlays with the red X button.',
                    ),
                    _buildTipContent(
                      'Life Paid vs Life Total',
                      'When you tap the + button in the "Life Paid" overlay, it both increments the life paid counter and decrements your actual life total.',
                    ),
                    _buildTipContent(
                      'Commander Damage Tracking',
                      'Each commander is tracked separately. If a player has a partner commander, both will appear in the commander damage list.',
                    ),
                    _buildTipContent(
                      'Screen Orientation',
                      'The app is locked in landscape mode for easy viewing when placed on a table during gameplay.',
                    ),
                    _buildTipContent(
                      'Starting New Game',
                      'From the Life Tracker page, use the reset button to return to the setup screen and configure a new game.',
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Scryfall Integration'),
                  _buildSection(context, [
                    _buildSectionContent(
                      'Commander Search',
                      'The app uses the Scryfall API to provide real-time search suggestions for commanders. Make sure you have internet connectivity for the best experience.',
                    ),
                    _buildSectionContent(
                      'Card Art Caching',
                      'Commander card art is cached locally on your device for offline access. Previously loaded images will still be available even without an internet connection.',
                    ),
                  ]),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a section title
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: UIConstants.buttonForegroundColor,
      ),
    );
  }

  /// Builds a section container with consistent styling
  Widget _buildSection(BuildContext context, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border.all(color: UIConstants.buttonForegroundColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children.expand((widget) {
          final index = children.indexOf(widget);
          if (index == children.length - 1) {
            return [widget];
          }
          return [widget, const SizedBox(height: 12.0)];
        }).toList(),
      ),
    );
  }

  /// Builds a standard section content item with title and description
  Widget _buildSectionContent(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          description,
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  /// Builds a tool section with an icon
  Widget _buildToolSection(
    BuildContext context,
    String title,
    String description,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: UIConstants.buttonForegroundColor,
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4.0),
        Text(
          description,
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  /// Builds a tip item with a lightbulb icon
  Widget _buildTipContent(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2.0, right: 8.0),
          child: Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: UIConstants.buttonForegroundColor.withOpacity(0.7),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                description,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
