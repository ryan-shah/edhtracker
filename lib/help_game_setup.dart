import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants.dart';

/// Help page for the Game Setup screen.
///
/// Provides detailed information about:
/// - Commander selection and autocomplete
/// - Partner commanders
/// - Unconventional commanders option
/// - Starting life total selection
/// - Starting player selection
/// - Scryfall integration
/// - Loading a game from a file
class HelpGameSetup extends StatefulWidget {
  const HelpGameSetup({super.key});

  @override
  State<HelpGameSetup> createState() => _HelpGameSetupState();
}

class _HelpGameSetupState extends State<HelpGameSetup> {
  @override
  void initState() {
    super.initState();
    // Lock to portrait mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Setup Help'), centerTitle: true),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'Loading a Game'),
                  _buildSection(context, [
                    _buildSectionContent(
                      'How to Load',
                      'Tap the "Load Game" icon (upload file icon) in the top app bar to open a file picker. Select a previously saved game log (.json file) to load its data.',
                    ),
                    _buildSectionContent(
                      'What It Does',
                      'Loading a game log will take you directly to the Game Summary page for that game, allowing you to review all statistics from the completed session.',
                    ),
                    _buildSectionContent(
                      'Art Fetching',
                      'After loading the file, the app will automatically fetch the commander art for all players, ensuring the summary page is visually complete.',
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Unconventional Commanders'),
                  _buildSection(context, [
                    _buildSectionContent(
                      'What It Does',
                      'Enable this toggle to remove the "is:commander" and "is:partner" filters from the search. This allows you to search for any card.',
                    ),
                    _buildSectionContent(
                      'Use Cases',
                      'Use this option for alternate formats, house rules, or custom commander variants where standard commander restrictions don\'t apply.',
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Commander Selection'),
                  _buildSection(context, [
                    _buildSectionContent(
                      'How to Search',
                      'Type the name of a commander in the "Player X Commander" field. The autocomplete feature will suggest matching commanders from the Scryfall database as you type.',
                    ),
                    _buildSectionContent(
                      'Commander Requirements',
                      'By default, the search only shows cards with the "is:commander" or "is:partner" keywords. This ensures you\'re selecting valid EDH commanders.',
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Partner Commanders'),
                  _buildSection(context, [
                    _buildSectionContent(
                      'Adding a Partner',
                      'Check the "Partner?" checkbox next to a commander to add a second commander to that player. A partner field will appear below.',
                    ),
                    _buildSectionContent(
                      'Partner Display',
                      'In the Starting Player dropdown, partners are displayed as "Commander1 // Commander2" so you can easily identify multi-commander strategies.',
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Game Configuration'),
                  _buildSection(context, [
                    _buildSectionContent(
                      'Starting Life Total',
                      'Select the starting life total for the game. Standard EDH uses 40 life, but options range from 10 to 100 for flexible gameplay.',
                    ),
                    _buildSectionContent(
                      'Starting Player',
                      'Choose which player goes first. Select "Random" to automatically randomize the starting player, or pick a specific player.',
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Scryfall Integration'),
                  _buildSection(context, [
                    _buildSectionContent(
                      'Real-Time Search',
                      'The app uses the Scryfall API to provide real-time search suggestions for commanders. Make sure you have internet connectivity for the best experience.',
                    ),
                    _buildSectionContent(
                      'Card Art',
                      'Once you select a commander, the app automatically fetches and displays their card art on the Life Tracker page. This adds visual flair to your game.',
                    ),
                    _buildSectionContent(
                      'Card Art Caching',
                      'Commander card art is cached locally on your device for offline access. Previously loaded images will still be available even without an internet connection.',
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Tips'),
                  _buildSection(context, [
                    _buildTipContent(
                      'Quick Start',
                      'You can leave commander fields blank to use generic "Player X" names. These will be displayed on the Life Tracker page.',
                    ),
                    _buildTipContent(
                      'Partial Search',
                      'You don\'t need to type the full commander name. For example, typing "Zur" will find "Zur the Enchanter".',
                    ),
                    _buildTipContent(
                      'Save Time',
                      'After a game, you can start a new game with the same players/commanders. This saves you from re-entering all the information.',
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
        border: Border.all(
          color: UIConstants.buttonForegroundColor.withValues(alpha: 0.3),
        ),
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4.0),
        Text(description, style: const TextStyle(fontSize: 13)),
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
            color: UIConstants.buttonForegroundColor.withValues(alpha: 0.7),
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
              Text(description, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
