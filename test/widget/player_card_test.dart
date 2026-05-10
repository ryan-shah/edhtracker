import 'package:edhtracker/player_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

PlayerCard buildCard({
  required GlobalKey<PlayerCardState> key,
  bool isCurrentTurn = false,
  int startingLife = 40,
  ValueChanged<int>? onOpenCommanderDamage,
  ValueChanged<int>? onOpenActions,
  ValueChanged<int>? onOpenCounters,
  VoidCallback? onTurnEnd,
  VoidCallback? onTurnBack,
}) {
  return PlayerCard(
    key: key,
    playerIndex: 0,
    playerName: 'Alice',
    allCommanderNames: const [
      ['Atraxa, Praetors\' Voice'],
      ['Krenko, Mob Boss'],
      ['Kaalia of the Vast'],
      ['Sliver Overlord'],
    ],
    startingLife: startingLife,
    isCurrentTurn: isCurrentTurn,
    onTurnEnd: onTurnEnd ?? () {},
    onTurnBack: onTurnBack ?? () {},
    turnCount: 1,
    currentTurnDuration: Duration.zero,
    onOpenCommanderDamage: onOpenCommanderDamage ?? (_) {},
    onOpenActions: onOpenActions ?? (_) {},
    onOpenCounters: onOpenCounters ?? (_) {},
  );
}

void main() {
  group('PlayerCard UI', () {
    testWidgets('+/- buttons change the displayed life by 1', (tester) async {
      final key = GlobalKey<PlayerCardState>();
      await pumpInApp(tester, buildCard(key: key));

      expect(find.text('40'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(find.text('41'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.remove));
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();
      expect(find.text('39'), findsOneWidget);
    });

    testWidgets('long-pressing the life total shows confirmation dialog and eliminates on confirm',
        (tester) async {
      final key = GlobalKey<PlayerCardState>();
      await pumpInApp(tester, buildCard(key: key));

      await tester.longPress(find.text('40'));
      await tester.pumpAndSettle();
      expect(find.text('Eliminate Alice?'), findsOneWidget);
      await tester.tap(find.text('Eliminate'));
      await tester.pumpAndSettle();

      expect(key.currentState!.isEliminated, isTrue);
      expect(find.text('ELIMINATED'), findsOneWidget);
    });

    testWidgets('cancel on elimination dialog leaves player alive', (tester) async {
      final key = GlobalKey<PlayerCardState>();
      await pumpInApp(tester, buildCard(key: key));

      await tester.longPress(find.text('40'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(key.currentState!.isEliminated, isFalse);
      expect(find.text('ELIMINATED'), findsNothing);
    });

    testWidgets('tapping ELIMINATED overlay un-eliminates the player', (tester) async {
      final key = GlobalKey<PlayerCardState>();
      await pumpInApp(tester, buildCard(key: key, startingLife: 1));

      // Drive life to 0 → automatic elimination.
      key.currentState!.decrementLife();
      await tester.pump();
      expect(find.text('ELIMINATED'), findsOneWidget);

      await tester.tap(find.text('ELIMINATED'));
      await tester.pump();
      expect(key.currentState!.isEliminated, isFalse);
      expect(find.text('ELIMINATED'), findsNothing);
    });

    testWidgets('overlay buttons fire their callbacks with player index', (tester) async {
      int? cmdDmgIdx;
      int? actionsIdx;
      int? countersIdx;
      final key = GlobalKey<PlayerCardState>();
      await pumpInApp(
        tester,
        buildCard(
          key: key,
          onOpenCommanderDamage: (i) => cmdDmgIdx = i,
          onOpenActions: (i) => actionsIdx = i,
          onOpenCounters: (i) => countersIdx = i,
        ),
      );

      await tester.tap(find.text('Cmdr Dmg'));
      await tester.pump();
      await tester.tap(find.text('Actions'));
      await tester.pump();
      await tester.tap(find.text('Counters'));
      await tester.pump();

      expect(cmdDmgIdx, 0);
      expect(actionsIdx, 0);
      expect(countersIdx, 0);
    });

    testWidgets('current-turn card shows the turn counter; non-current does not', (tester) async {
      final key = GlobalKey<PlayerCardState>();
      await pumpInApp(tester, buildCard(key: key, isCurrentTurn: true));
      expect(find.text('Turn 1'), findsOneWidget);

      // Re-pump as not current.
      await pumpInApp(tester, buildCard(key: GlobalKey(), isCurrentTurn: false));
      expect(find.text('Turn 1'), findsNothing);
    });
  });
}
