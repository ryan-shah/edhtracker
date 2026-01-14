import 'package:flutter/material.dart';
import 'constants.dart';

/// Help page for the Life Tracker screen.
///
/// Provides detailed information about:
/// - Life counter and tracking
/// - Turn management
/// - Turn timer
/// - Menu controls
/// - Tracking tools (Commander Damage, Counters, Actions)
/// - Tips and best practices
class HelpLifeTracker extends StatefulWidget {
  const HelpLifeTracker({super.key});

  @override
  State<HelpLifeTracker> createState() => _HelpLifeTrackerState();
}

class _HelpLifeTrackerState extends State<HelpLifeTracker> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Life Tracker Help'),
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
                  _buildSectionTitle(context, 'Life Tracking'),
                  _buildSection(context, [
                    _buildSectionContent(
                      'Life Counter',
                      'Each player\'s life total is displayed prominently in the center of their card. This is the primary focus of the tracker.',
                    ),
                    _buildSectionContent(
                      'Adjusting Life',
                      'Tap the + button to increase life or the - button to decrease life. You can also enter a custom value by tapping directly on the life total.',
                    ),
                    _buildSectionContent(
                      'Commander Art Display',
                      'If commanders were selected during setup, their card art will be displayed in the background of each player\'s card for visual reference.',
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Turn Management'),
                  _buildSection(context, [
                    _buildSectionContent(
                      'Current Turn Indicator',
                      'The active player\'s card has a blue border and displays "Turn X" in the corner, where X is the current turn number.',
                    ),
                    _buildSectionContent(
                      'Advancing Turns',
                      'Tap any player card to advance to the next player\'s turn. This moves the turn indicator and resets the turn timer.',
                    ),
                    _buildSectionContent(
                      'Undoing Turns',
                      'Long-press any player card to undo the last turn progression. This reverts the game state to the beginning of the previous turn, including all tracked values.',
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Turn Timer'),
                  _buildSection(context, [
                    _buildSectionContent(
                      'Timer Display',
                      'The active player\'s card displays a timer showing how long their current turn has been running. This helps monitor game pace.',
                    ),
                    _buildSectionContent(
                      'Toggle Timer Visibility',
                      'Use the timer button in the main menu (left icon) to toggle the timer display on or off. The timer still tracks time internally when hidden.',
                    ),
                    _buildSectionContent(
                      'Timer Reset',
                      'The timer automatically resets when advancing to the next player\'s turn.',
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Main Menu'),
                  _buildSection(context, [
                    _buildToolSection(
                      context,
                      'Help Button (Top)',
                      'Opens this help page to guide you through the Life Tracker\'s features.',
                      Icons.help_outline,
                    ),
                    _buildToolSection(
                      context,
                      'New Game Button (Right)',
                      'Ends the current game and returns to the setup screen. Choose to start with the same players or clear everything for a fresh start.',
                      Icons.restart_alt,
                    ),
                    _buildToolSection(
                      context,
                      'Timer Toggle Button (Left)',
                      'Toggles the visibility of the turn timer on the active player\'s card.',
                      Icons.timer,
                    ),
                    _buildToolSection(
                      context,
                      'Complete Game Button (Bottom)',
                      'Marks the current game as complete and logs the final game data.',
                      Icons.check_circle_outline,
                    ),
                    _buildToolSection(
                      context,
                      'Menu Button (Center)',
                      'Expands or collapses the central control menu to show/hide the action buttons.',
                      Icons.menu,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Tracking Tools'),
                  _buildSection(context, [
                    _buildToolSection(
                      context,
                      'Commander Damage (Cmdr Dmg)',
                      'Track damage dealt by each opponent\'s commander. Tap the "Cmdr Dmg" button to open an overlay. Note: In standard EDH, 21 commander damage from a single commander causes that player to lose.',
                      Icons.shield,
                    ),
                    _buildToolSection(
                      context,
                      'Counters',
                      'Track player counters such as Energy, Experience, Poison, and Rad. Tap the "Counters" button to open an overlay where you can increment or decrement each counter type.',
                      Icons.assessment,
                    ),
                    _buildToolSection(
                      context,
                      'Actions',
                      'Track important game actions and events:\n' 
                      '• Life Paid: Tracks life points paid for effects (e.g., Necropotence, Phyrexian mana).\n'
                      '• Cards Milled: Counts the number of cards milled from libraries.\n'
                      '• Extra Turns: Tracks extra turns taken by the player.\n'
                      '• Cards Drawn: Automatically increments at the start of each turn, but can be manually adjusted.',
                      Icons.track_changes,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Tips & Best Practices'),
                  _buildSection(context, [
                    _buildTipContent(
                      'Quick Navigation',
                      'Use a single tap to advance turns and long-press to undo. This is faster than using the menu.',
                    ),
                    _buildTipContent(
                      'Undo for Mistakes',
                      'The undo feature reverts all game state changes from the current turn, including life totals and counter values. Use it to correct mistakes quickly.',
                    ),
                    _buildTipContent(
                      'Overlay Management',
                      'Only one overlay can be visible at a time. Opening a new overlay will close any previously open one. Close overlays with the red X button.',
                    ),
                    _buildTipContent(
                      'Life Paid Mechanics',
                      'When you increment "Life Paid", it both adds to the life paid counter AND decrements your actual life total.',
                    ),
                    _buildTipContent(
                      'Table Placement',
                      'The app is locked in landscape mode for easy viewing when placed on a table during gameplay. This keeps the orientation stable.',
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
