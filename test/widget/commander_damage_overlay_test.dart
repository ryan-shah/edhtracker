import 'package:edhtracker/commander_damage_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  group('CommanderDamageOverlay', () {
    testWidgets('renders 4 commander tiles with names and zero damage by default',
        (tester) async {
      await pumpInApp(
        tester,
        CommanderDamageOverlay(
          receiverIndex: 0,
          playerCount: 4,
          allCommanderNames: const [
            ['Atraxa, Praetors\' Voice'],
            ['Krenko, Mob Boss'],
            ['Kaalia of the Vast'],
            ['Sliver Overlord'],
          ],
          allArtUrls: const [[], [], [], []],
          currentDamage: const {},
          onIncrement: (_, _) {},
          onDecrement: (_, _) {},
          onClose: () {},
        ),
      );

      expect(find.textContaining('Krenko'), findsOneWidget);
      expect(find.textContaining('Kaalia'), findsOneWidget);
      expect(find.textContaining('Sliver'), findsOneWidget);
      // Damage text "0" appears on each of 4 tiles.
      expect(find.text('0'), findsNWidgets(4));
    });

    testWidgets('partner commanders appear as separate tiles within one slot',
        (tester) async {
      await pumpInApp(
        tester,
        CommanderDamageOverlay(
          receiverIndex: 1,
          playerCount: 4,
          allCommanderNames: const [
            ['Tymna the Weaver', 'Thrasios, Triton Hero'],
            ['Krenko, Mob Boss'],
            ['Kaalia of the Vast'],
            ['Sliver Overlord'],
          ],
          allArtUrls: const [[], [], [], []],
          currentDamage: const {},
          onIncrement: (_, _) {},
          onDecrement: (_, _) {},
          onClose: () {},
        ),
      );

      expect(find.textContaining('Tymna'), findsOneWidget);
      expect(find.textContaining('Thrasios'), findsOneWidget);
    });

    testWidgets('tapping right half of a tile fires onIncrement with correct args',
        (tester) async {
      int? fromIdx;
      int? cmdIdx;
      await pumpInApp(
        tester,
        CommanderDamageOverlay(
          receiverIndex: 0,
          playerCount: 4,
          allCommanderNames: const [
            ['Atraxa, Praetors\' Voice'],
            ['Krenko, Mob Boss'],
            ['Kaalia of the Vast'],
            ['Sliver Overlord'],
          ],
          allArtUrls: const [[], [], [], []],
          currentDamage: const {},
          onIncrement: (from, c) {
            fromIdx = from;
            cmdIdx = c;
          },
          onDecrement: (_, _) {},
          onClose: () {},
        ),
      );

      // Tap the rightmost half of the Krenko tile (player 1, commander 0).
      // Use the displayed commander name to locate the tile, then tap on the
      // increment icon inside it.
      final krenkoTile = find.ancestor(
        of: find.textContaining('Krenko'),
        matching: find.byType(Stack),
      );
      // Within the tile, tap the add icon.
      final addIcon = find.descendant(
        of: krenkoTile.first,
        matching: find.byIcon(Icons.add),
      );
      await tester.tap(addIcon.first);
      await tester.pump();

      expect(fromIdx, 1);
      expect(cmdIdx, 0);
    });

    testWidgets('current damage map drives displayed values per commander',
        (tester) async {
      await pumpInApp(
        tester,
        CommanderDamageOverlay(
          receiverIndex: 0,
          playerCount: 4,
          allCommanderNames: const [
            ['Atraxa, Praetors\' Voice'],
            ['Krenko, Mob Boss'],
            ['Kaalia of the Vast'],
            ['Sliver Overlord'],
          ],
          allArtUrls: const [[], [], [], []],
          currentDamage: const {'1_0': 7, '2_0': 21},
          onIncrement: (_, _) {},
          onDecrement: (_, _) {},
          onClose: () {},
        ),
      );

      expect(find.text('7'), findsOneWidget);
      expect(find.text('21'), findsOneWidget);
    });

    testWidgets('close button calls onClose', (tester) async {
      bool closed = false;
      await pumpInApp(
        tester,
        CommanderDamageOverlay(
          receiverIndex: 0,
          playerCount: 4,
          allCommanderNames: const [
            ['A'],
            ['B'],
            ['C'],
            ['D'],
          ],
          allArtUrls: const [[], [], [], []],
          currentDamage: const {},
          onIncrement: (_, _) {},
          onDecrement: (_, _) {},
          onClose: () => closed = true,
        ),
      );
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(closed, isTrue);
    });
  });
}
