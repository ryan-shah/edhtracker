import 'dart:convert';

import 'package:edhtracker/game_log_file_service.dart';
import 'package:edhtracker/game_setup_page.dart';
import 'package:edhtracker/scryfall_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_file_service.dart';
import '../helpers/fake_scryfall_client.dart';

void main() {
  late MockHttpClient client;
  late FakeGameLogFileService fakeFileService;

  setUpAll(() {
    registerHttpFallbacks();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    client = MockHttpClient();
    // Default: any Scryfall lookup returns a fake art URL.
    when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
      (_) async => okJson(jsonEncode({
            'image_uris': {'art_crop': 'https://example.com/fake.jpg'},
          })),
    );
    ScryfallService.setDefaultInstance(ScryfallService(client: client));
    fakeFileService = FakeGameLogFileService();
    GameLogFileService.setDefaultInstance(fakeFileService);
  });

  tearDown(() {
    ScryfallService.resetDefaultInstance();
    GameLogFileService.resetDefaultInstance();
  });

  Future<void> pump(WidgetTester tester) async {
    // Tall surface so the entire setup form is visible without scrolling —
    // makes dropdown taps reliable.
    await tester.binding.setSurfaceSize(const Size(600, 1400));
    await tester.pumpWidget(const MaterialApp(home: GameSetupPage()));
    await tester.pump();
  }

  group('GameSetupPage', () {
    testWidgets('default render shows 4 commander fields', (tester) async {
      await pump(tester);
      for (int i = 1; i <= 4; i++) {
        expect(find.text('Player $i Commander'), findsOneWidget);
      }
    });

    testWidgets('switching to 2 players hides players 3 and 4', (tester) async {
      await pump(tester);
      final dropdown = find.ancestor(
        of: find.text('Number of Players'),
        matching: find.byType(DropdownButtonFormField<int>),
      );
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('2 Players').last);
      await tester.pumpAndSettle();

      expect(find.text('Player 1 Commander'), findsOneWidget);
      expect(find.text('Player 2 Commander'), findsOneWidget);
      expect(find.text('Player 3 Commander'), findsNothing);
      expect(find.text('Player 4 Commander'), findsNothing);
    });

    testWidgets('Partner? checkbox reveals a partner field', (tester) async {
      await pump(tester);
      // Initially no partner field is visible.
      expect(find.text('Partner Commander'), findsNothing);

      // Tap the first Partner? checkbox.
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();

      expect(find.text('Partner Commander'), findsOneWidget);
    });

    testWidgets('Unconventional Commanders toggle flips state', (tester) async {
      await pump(tester);
      final switchTile = find.byType(SwitchListTile);
      expect(switchTile, findsOneWidget);

      final initial =
          (tester.widget<SwitchListTile>(switchTile)).value;
      expect(initial, isFalse);

      await tester.tap(switchTile);
      await tester.pump();

      final after = (tester.widget<SwitchListTile>(switchTile)).value;
      expect(after, isTrue);
    });

    testWidgets('Starting Life dropdown defaults to 40 and offers 10..100', (tester) async {
      await pump(tester);
      final dropdown = find.ancestor(
        of: find.text('Starting Life Total'),
        matching: find.byType(DropdownButtonFormField<int>),
      );
      expect(dropdown, findsOneWidget);
      // Field shows 40 by default.
      expect(find.text('40'), findsOneWidget);

      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      // Menu shows all 10 increments.
      for (final v in [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]) {
        expect(find.text('$v'), findsAtLeastNWidgets(1));
      }
      await tester.tap(find.text('60').last);
      await tester.pumpAndSettle();
      expect(find.text('60'), findsOneWidget);
    });

    testWidgets('Starting Player dropdown lists Random + each player', (tester) async {
      await pump(tester);
      final dropdown = find.ancestor(
        of: find.text('Starting Player'),
        matching: find.byType(DropdownButtonFormField<int>),
      );
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      expect(find.text('Random'), findsAtLeastNWidgets(1));
      // Each player slot has a "Player N" entry by default fallback.
      for (int i = 1; i <= 4; i++) {
        expect(find.text('Player $i'), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('Load Game tap delegates to GameLogFileService', (tester) async {
      // No file selected scenario.
      fakeFileService.nextLoad = null;
      await pump(tester);

      await tester.tap(find.byTooltip('Load Game'));
      await tester.pumpAndSettle();

      // Page stays on setup since no file was loaded; nothing thrown.
      expect(find.byType(GameSetupPage), findsOneWidget);
    });
  });

  // Pumps a GameSetupPage seeded with the "New Game with Same Players"
  // restore values. Mirrors what LifeTrackerPage / GameSummaryPage pass back.
  Future<void> pumpRestored(
    WidgetTester tester, {
    List<String>? initialPlayerNames,
    List<String>? initialPartnerNames,
    List<bool>? initialHasPartner,
    bool? initialUnconventionalCommanders,
    int? initialPlayerCount,
    int? initialStartingLife,
  }) async {
    await tester.binding.setSurfaceSize(const Size(600, 1400));
    await tester.pumpWidget(MaterialApp(
      home: GameSetupPage(
        initialPlayerNames: initialPlayerNames,
        initialPartnerNames: initialPartnerNames,
        initialHasPartner: initialHasPartner,
        initialUnconventionalCommanders: initialUnconventionalCommanders,
        initialPlayerCount: initialPlayerCount,
        initialStartingLife: initialStartingLife,
      ),
    ));
    await tester.pump();
  }

  group('GameSetupPage restore (New Game with Same Players)', () {
    testWidgets('restores players and count for a 3-player game', (tester) async {
      await pumpRestored(
        tester,
        initialPlayerNames: const ['Krenko, Mob Boss', 'Atraxa', 'Yuriko'],
        initialPartnerNames: const ['', '', ''],
        initialHasPartner: const [false, false, false],
        initialPlayerCount: 3,
      );

      // Player count restored to 3: rows 1-3 present, row 4 hidden.
      expect(find.text('3 Players'), findsOneWidget);
      expect(find.text('Player 1 Commander'), findsOneWidget);
      expect(find.text('Player 3 Commander'), findsOneWidget);
      expect(find.text('Player 4 Commander'), findsNothing);

      // Commander names pre-filled into their fields.
      expect(find.text('Krenko, Mob Boss'), findsOneWidget);
      expect(find.text('Atraxa'), findsOneWidget);
      expect(find.text('Yuriko'), findsOneWidget);
    });

    testWidgets('restores players for a 2-player game', (tester) async {
      await pumpRestored(
        tester,
        initialPlayerNames: const ['Krenko, Mob Boss', 'Atraxa'],
        initialPartnerNames: const ['', ''],
        initialHasPartner: const [false, false],
        initialPlayerCount: 2,
      );

      expect(find.text('2 Players'), findsOneWidget);
      expect(find.text('Player 2 Commander'), findsOneWidget);
      expect(find.text('Player 3 Commander'), findsNothing);
      expect(find.text('Krenko, Mob Boss'), findsOneWidget);
      expect(find.text('Atraxa'), findsOneWidget);
    });

    testWidgets('restores the starting life total', (tester) async {
      await pumpRestored(
        tester,
        initialPlayerNames: const ['Atraxa', '', '', ''],
        initialPartnerNames: const ['', '', '', ''],
        initialHasPartner: const [false, false, false, false],
        initialPlayerCount: 4,
        initialStartingLife: 30,
      );

      // Restored value shown, not the default 40.
      expect(find.text('30'), findsOneWidget);
      expect(find.text('40'), findsNothing);
    });

    testWidgets('restores a partner commander pairing', (tester) async {
      await pumpRestored(
        tester,
        initialPlayerNames: const ['Tymna', 'Atraxa'],
        initialPartnerNames: const ['Thrasios', ''],
        initialHasPartner: const [true, false],
        initialPlayerCount: 2,
      );

      expect(find.text('Partner Commander'), findsOneWidget);
      expect(find.text('Tymna'), findsOneWidget);
      expect(find.text('Thrasios'), findsOneWidget);
    });

    testWidgets('restores the unconventional commanders toggle', (tester) async {
      await pumpRestored(
        tester,
        initialPlayerNames: const ['Atraxa', 'Yuriko'],
        initialPartnerNames: const ['', ''],
        initialHasPartner: const [false, false],
        initialUnconventionalCommanders: true,
        initialPlayerCount: 2,
      );

      final switchTile = find.byType(SwitchListTile);
      expect((tester.widget<SwitchListTile>(switchTile)).value, isTrue);
    });
  });
}
