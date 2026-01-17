import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for Clipboard

import 'commander_autocomplete.dart';
import 'game_stats_utility.dart';

class PostGameReviewPage extends StatefulWidget {
  final GameStatsUtility gameStatsUtility;

  const PostGameReviewPage({super.key, required this.gameStatsUtility});

  @override
  State<PostGameReviewPage> createState() => _PostGameReviewPageState();
}

class _PostGameReviewPageState extends State<PostGameReviewPage> {
  bool _isDraw = false;
  int? _winnerIndex;
  String? _winCondition;
  int? _userSeat; // Added state variable for user seat
  final List<TextEditingController> _keyCardControllers = List.generate(
    3,
    (_) => TextEditingController(),
  );
  late List<bool> _fastMana;

  final List<String> _winConditions = [
    'combat damage',
    'infinite combo',
    'mill',
    'poison',
    'alt-wincon',
    'hard lock',
    'commander damage',
    'non-combat damage',
    'concession',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _fastMana = List.generate(
      widget.gameStatsUtility.session.playerNames.length,
      (_) => false,
    );
    // Initialize userSeat to the first player if players exist
    if (widget.gameStatsUtility.session.playerNames.isNotEmpty) {
      _winnerIndex = 0;
      _userSeat = 0; // Initialize userSeat
    }
  }

  @override
  void dispose() {
    for (var controller in _keyCardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleSubmitReview() async {
    // Ensure _userSeat is passed to setReviewDetails
    widget.gameStatsUtility.setReviewDetails(
      _isDraw,
      _winnerIndex,
      _winCondition,
      _keyCardControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList(),
      _fastMana,
      _userSeat, // Pass the user seat
    );

    final String reviewJson = widget.gameStatsUtility.toJsonString();

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Review Details JSON'),
          content: SingleChildScrollView(child: Text(reviewJson)),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: reviewJson));
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('JSON copied to clipboard!')),
                );
              },
              child: const Text('Copy to Clipboard'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    Navigator.pop(context); // Return to the summary screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Game Review'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: SwitchListTile(
                title: const Text('Was the game a draw?'),
                subtitle: const Text('Toggle on if no winner was determined'),
                value: _isDraw,
                onChanged: (val) => setState(() => _isDraw = val),
              ),
            ),
            const SizedBox(height: 16),
            if (!_isDraw) ...[
              DropdownButtonFormField<int>(
                initialValue: _winnerIndex,
                decoration: const InputDecoration(
                  labelText: 'Game Winner',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.emoji_events),
                ),
                items: List.generate(
                  widget.gameStatsUtility.session.playerNames.length,
                  (index) {
                    return DropdownMenuItem(
                      value: index,
                      child: Text(
                        widget.gameStatsUtility.session.playerNames[index],
                      ),
                    );
                  },
                ),
                onChanged: (val) => setState(() => _winnerIndex = val),
              ),
              const SizedBox(height: 16),
              // Added dropdown for user seat selection
              DropdownButtonFormField<int>(
                initialValue: _userSeat,
                decoration: const InputDecoration(
                  labelText: 'Your Seat',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                items: List.generate(
                  widget.gameStatsUtility.session.playerNames.length,
                  (index) {
                    return DropdownMenuItem(
                      value: index,
                      child: Text(
                        widget.gameStatsUtility.session.playerNames[index],
                      ),
                    );
                  },
                ),
                onChanged: (val) => setState(() => _userSeat = val),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _winCondition,
                decoration: const InputDecoration(
                  labelText: 'Win Condition',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.star),
                ),
                items: _winConditions.map((condition) {
                  return DropdownMenuItem(
                    value: condition,
                    child: Text(condition),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _winCondition = val),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              'Key Cards (Up to 3)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Text(
              'Cards that had a major impact on the game',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
            const SizedBox(height: 12),
            ...List.generate(3, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: CommanderAutocomplete(
                  controller: _keyCardControllers[index],
                  labelText: 'Key Card ${index + 1}',
                  unconventionalCommanders: true,
                ),
              );
            }),
            const SizedBox(height: 24),
            Text(
              'Turn 1 Fast Mana',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Text(
              'Which players had turn 1 fast mana (e.g., Sol Ring)?',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: List.generate(
                  widget.gameStatsUtility.session.playerNames.length,
                  (index) {
                    return CheckboxListTile(
                      title: Text(
                        widget.gameStatsUtility.session.playerNames[index],
                      ),
                      value: _fastMana[index],
                      onChanged: (val) =>
                          setState(() => _fastMana[index] = val ?? false),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _handleSubmitReview,
                child: const Text('Submit Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
