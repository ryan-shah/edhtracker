import 'package:edhtracker/life_tracker_page.dart';
import 'package:edhtracker/player_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

PlayerCard activeCard(WidgetTester tester) {
  return tester
      .widgetList<PlayerCard>(find.byType(PlayerCard))
      .firstWhere((c) => c.isCurrentTurn);
}

void main() {
  // Capture orientation requests at the platform-channel level.
  final orientationCalls = <List<String>>[];
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemChrome.setPreferredOrientations') {
          orientationCalls.add(List<String>.from(call.arguments as List));
        }
        return null;
      },
    );
  });

  setUp(() => orientationCalls.clear());

  tearDownAll(() {
    binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('2-player setup requests portrait, stacks two cards, top is rotated 180°',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(414, 896));
    await tester.pumpWidget(MaterialApp(
      home: LifeTrackerPage(
        playerNames: const ['Alice', 'Bob'],
        playerCommanderNames: const [
          ['Atraxa, Praetors\' Voice'],
          ['Krenko, Mob Boss'],
        ],
        playerArtUrls: const [[], []],
        startingLife: 40,
        startingPlayerIndex: 0,
        playerCount: 2,
      ),
    ));
    await tester.pump();

    // Two PlayerCard widgets in the tree.
    expect(find.byType(PlayerCard), findsNWidgets(2));

    // 2-player layout requests portrait orientation in initState.
    expect(
      orientationCalls.any((call) =>
          call.length == 2 &&
          call[0] == 'DeviceOrientation.portraitUp' &&
          call[1] == 'DeviceOrientation.portraitDown'),
      isTrue,
    );

    // Top card (player 1) is wrapped in a RotatedBox with quarterTurns: 2.
    final topCard = tester
        .widgetList<PlayerCard>(find.byType(PlayerCard))
        .firstWhere((c) => c.playerIndex == 1);
    final topRotatedBox = find.ancestor(
      of: find.byWidget(topCard),
      matching: find.byType(RotatedBox),
    );
    expect(topRotatedBox, findsAtLeastNWidgets(1));
    final rotated = tester.widget<RotatedBox>(topRotatedBox.first);
    expect(rotated.quarterTurns, 2);
  });

  testWidgets('2-player tap-to-advance flips current turn between cards',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(414, 896));
    await tester.pumpWidget(MaterialApp(
      home: LifeTrackerPage(
        playerNames: const ['Alice', 'Bob'],
        playerCommanderNames: const [
          ['Atraxa, Praetors\' Voice'],
          ['Krenko, Mob Boss'],
        ],
        playerArtUrls: const [[], []],
        startingLife: 40,
        startingPlayerIndex: 0,
        playerCount: 2,
      ),
    ));
    await tester.pump(const Duration(milliseconds: 50));

    expect(activeCard(tester).playerIndex, 0);
    activeCard(tester).onTurnEnd();
    await tester.pump(const Duration(milliseconds: 50));
    expect(activeCard(tester).playerIndex, 1);
    activeCard(tester).onTurnEnd();
    await tester.pump(const Duration(milliseconds: 50));
    expect(activeCard(tester).playerIndex, 0);
  });
}
