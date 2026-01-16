import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants.dart';

/// Help page for the Life Tracker screen.
///
/// Provides detailed information about:
/// - Life counter and tracking
/// - Turn management
/// - Turn timer
/// - Menu controls
/// - Tracking tools (Commander Damage, Counters, Actions)
/// - Game Summary and logging
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
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    // Reset orientation preferences when leaving the page
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
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
                  _buildSectionTitle(context, 'Game Summary & Logging'),
                  _buildSection(context, [
                    _buildSectionContent(
                      'Ending a Game',
                      'When the game is finished, use the "Complete Game" button (check mark icon) in the central menu. This will end the game and take you to the Game Summary page.',
                    ),
                    _buildSectionContent(
                      'Game Summary Page',
                      'This page provides a detailed breakdown of the completed game, including overall stats and individual player performance.',
                    ),
                    _buildSectionContent(
                      'Switching Views',
                      'Use the dropdown at the top of the summary page to switch between "Overall Game Stats" and detailed statistics for each player.',
                    ),
                    _buildSectionContent(
                      'Downloading Game Logs',
                      'On the summary page, tap the download icon in the app bar to save the entire game log as a JSON file. You can load this file later to review the game.',
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Tracking Tools & Overlays'),
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
                      'Track important game actions and events. The actions overlay is now scrollable to accommodate more trackers.\n' 
                      '• Life Paid: Tracks life points paid for effects.\n'
                      '• Cards Milled: Counts the number of cards milled.\n'
                      '• Extra Turns: Tracks extra turns taken by the player.\n'
                      '• Cards Drawn: Tracks cards drawn.',
                      Icons.track_changes,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Turn Management'),
                  _buildSection(context, [
                    _buildSectionContent(
                      'Current Turn Indicator',
                      'The active player\'s card has a bright border and displays the current turn number and a running timer.',
                    ),
                    _buildSectionContent(
                      'Advancing Turns',
                      'Tap the main area of any player card to advance to the next player\'s turn. This logs the previous turn\'s data and starts the next turn.',
                    ),
                    _buildSectionContent(
                      'Undoing Turns',
                      'Long-press any player card to undo the last turn progression. This reverts the game state to the beginning of the previous turn, including all tracked values.',
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
                      'Marks the current game as complete and logs the final game data, taking you to the summary page.',
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
                  _buildSectionTitle(context, 'Tips & Best Practices'),
                  _buildSection(context, [
                    _buildTipContent(
                      'Data Logging',
                      'All life changes, counter values, and actions are logged at the end of each turn when you tap to advance to the next player. This ensures the game summary is accurate.',
                    ),
                    _buildTipContent(
                      'Undo for Mistakes',
                      'The undo feature reverts all game state changes from the current turn. Use it to correct mistakes quickly.',
                    ),
                    _buildTipContent(
                      'Overlay Management',
                      'Only one overlay can be visible at a time. Opening a new overlay will close any previously open one. Close overlays with the red X button.',
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
