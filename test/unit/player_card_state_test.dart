import 'package:edhtracker/player_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

PlayerCard buildCard(GlobalKey<PlayerCardState> key, {int startingLife = 40}) {
  return PlayerCard(
    key: key,
    playerIndex: 0,
    playerName: 'Alice',
    allCommanderNames: const [
      ['Tymna the Weaver', 'Thrasios, Triton Hero'],
      ['Krenko, Mob Boss'],
      ['Kaalia of the Vast'],
      ['Sliver Overlord'],
    ],
    startingLife: startingLife,
    isCurrentTurn: false,
    onTurnEnd: () {},
    onTurnBack: () {},
    turnCount: 1,
    currentTurnDuration: Duration.zero,
    onOpenCommanderDamage: (_) {},
    onOpenActions: (_) {},
    onOpenCounters: (_) {},
  );
}

void main() {
  group('PlayerCardState mutators', () {
    testWidgets('incrementLife / decrementLife adjust by 1', (tester) async {
      final key = GlobalKey<PlayerCardState>();
      await pumpInApp(tester, buildCard(key));
      final state = key.currentState!;

      expect(state.life, 40);
      state.incrementLife();
      expect(state.life, 41);
      state.decrementLife();
      state.decrementLife();
      expect(state.life, 39);
    });

    testWidgets('decrementLife to 0 triggers elimination', (tester) async {
      final key = GlobalKey<PlayerCardState>();
      await pumpInApp(tester, buildCard(key, startingLife: 2));
      final state = key.currentState!;

      state.decrementLife();
      expect(state.isEliminated, isFalse);
      state.decrementLife();
      expect(state.life, 0);
      expect(state.isEliminated, isTrue);
    });

    testWidgets('incrementLifePaid couples lifePaid and life', (tester) async {
      final key = GlobalKey<PlayerCardState>();
      await pumpInApp(tester, buildCard(key));
      final state = key.currentState!;

      state.incrementLifePaid();
      state.incrementLifePaid();
      expect(state.lifePaid, 2);
      expect(state.life, 38);

      state.decrementLifePaid();
      expect(state.lifePaid, 1);
      expect(state.life, 39);
    });

    testWidgets('decrementLifePaid is no-op at zero', (tester) async {
      final key = GlobalKey<PlayerCardState>();
      await pumpInApp(tester, buildCard(key));
      final state = key.currentState!;

      state.decrementLifePaid();
      expect(state.lifePaid, 0);
      expect(state.life, 40);
    });

    testWidgets('incrementLifePaid to 0 life eliminates', (tester) async {
      final key = GlobalKey<PlayerCardState>();
      await pumpInApp(tester, buildCard(key, startingLife: 1));
      final state = key.currentState!;
      state.incrementLifePaid();
      expect(state.life, 0);
      expect(state.isEliminated, isTrue);
    });

    testWidgets('cardsMilled / extraTurns / cardsDrawn are pure counters', (tester) async {
      final key = GlobalKey<PlayerCardState>();
      await pumpInApp(tester, buildCard(key));
      final state = key.currentState!;

      state.incrementCardsMilled();
      state.incrementCardsMilled();
      state.incrementExtraTurns();
      state.incrementCardsDrawn();
      state.incrementCardsDrawn();
      state.incrementCardsDrawn();
      expect(state.cardsMilled, 2);
      expect(state.extraTurns, 1);
      expect(state.cardsDrawn, 3);
      // No life side effects.
      expect(state.life, 40);

      state.decrementCardsMilled();
      state.decrementExtraTurns();
      expect(state.cardsMilled, 1);
      expect(state.extraTurns, 0);
      // Decrement guarded against going negative.
      state.decrementExtraTurns();
      expect(state.extraTurns, 0);
    });

    testWidgets('commander damage updates map and life, eliminates at 21', (tester) async {
      final key = GlobalKey<PlayerCardState>();
      await pumpInApp(tester, buildCard(key));
      final state = key.currentState!;

      // Take 21 damage from player 1's commander 0 (Krenko).
      for (int i = 0; i < 21; i++) {
        state.incrementCommanderDamage(1, 0);
      }
      expect(state.commanderDamage['1_0'], 21);
      expect(state.life, 19);
      expect(state.isEliminated, isTrue);
    });

    testWidgets('decrement commander damage guarded at 0 and adjusts life', (tester) async {
      final key = GlobalKey<PlayerCardState>();
      await pumpInApp(tester, buildCard(key));
      final state = key.currentState!;

      state.incrementCommanderDamage(2, 0);
      state.incrementCommanderDamage(2, 0);
      expect(state.commanderDamage['2_0'], 2);
      expect(state.life, 38);

      state.decrementCommanderDamage(2, 0);
      expect(state.commanderDamage['2_0'], 1);
      expect(state.life, 39);

      // Decrement past zero is a no-op (key not yet present).
      state.decrementCommanderDamage(3, 0);
      expect(state.commanderDamage['3_0'], isNull);
      expect(state.life, 39);
    });

    testWidgets('player counters increment for Energy/Experience/Poison/Rad', (tester) async {
      final key = GlobalKey<PlayerCardState>();
      await pumpInApp(tester, buildCard(key));
      final state = key.currentState!;

      for (final c in ['Energy', 'Experience', 'Poison', 'Rad']) {
        state.incrementPlayerCounter(c);
      }
      expect(state.playerCounters, {
        'Energy': 1,
        'Experience': 1,
        'Poison': 1,
        'Rad': 1,
      });

      state.decrementPlayerCounter('Energy');
      expect(state.playerCounters['Energy'], 0);
      // Decrement at zero is a no-op.
      state.decrementPlayerCounter('Energy');
      expect(state.playerCounters['Energy'], 0);
    });

    testWidgets('getCurrentState assembles snapshot with snake_case action keys', (tester) async {
      final key = GlobalKey<PlayerCardState>();
      await pumpInApp(tester, buildCard(key));
      final state = key.currentState!;

      state.incrementLifePaid();
      state.incrementCardsMilled();
      state.incrementCardsDrawn();
      state.incrementCommanderDamage(0, 1); // Thrasios from player 0
      state.incrementCommanderDamage(2, 0); // Kaalia from player 2

      final snap = state.getCurrentState();
      expect(snap.playerIndex, 0);
      expect(snap.life, 40 - 1 - 2); // -1 from lifePaid, -2 from cmd damage
      expect(snap.actionTrackers, {
        'life_paid': 1,
        'cards_milled': 1,
        'extra_turns': 0,
        'cards_drawn': 1,
      });
      // CommanderDamageTaken built from "fromIdx_cmdIdx" keys + name lookup.
      final names = snap.commanderDamageTaken
          .map((c) => c.commanderName)
          .toSet();
      expect(names, contains('Thrasios, Triton Hero'));
      expect(names, contains('Kaalia of the Vast'));
    });

    testWidgets('reset returns all fields to initial values', (tester) async {
      final key = GlobalKey<PlayerCardState>();
      await pumpInApp(tester, buildCard(key));
      final state = key.currentState!;

      state.incrementLifePaid();
      state.incrementCommanderDamage(1, 0);
      state.incrementPlayerCounter('Energy');
      state.reset();

      expect(state.life, 40);
      expect(state.lifePaid, 0);
      expect(state.commanderDamage, isEmpty);
      expect(state.playerCounters, isEmpty);
      expect(state.isEliminated, isFalse);
    });
  });
}
