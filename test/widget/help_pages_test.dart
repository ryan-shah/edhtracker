import 'package:edhtracker/help_game_setup.dart';
import 'package:edhtracker/help_life_tracker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pump(WidgetTester tester, Widget page) async {
  await tester.binding.setSurfaceSize(const Size(600, 1400));
  await tester.pumpWidget(MaterialApp(home: page));
  await tester.pump();
}

void main() {
  // Capture orientation calls so we can assert what each help page requests.
  final orientationCalls = <List<DeviceOrientation>>[];
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemChrome.setPreferredOrientations') {
          final args = (call.arguments as List).cast<String>();
          orientationCalls.add(args
              .map((s) => DeviceOrientation.values.firstWhere(
                    (o) => o.toString() == s,
                  ))
              .toList());
        }
        return null;
      },
    );
  });

  setUp(() {
    orientationCalls.clear();
  });

  tearDownAll(() {
    binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('HelpGameSetup', () {
    testWidgets('renders all expected section titles', (tester) async {
      await pump(tester, const HelpGameSetup());
      for (final title in [
        'Loading a Game',
        'Unconventional Commanders',
        'Commander Selection',
        'Partner Commanders',
        'Game Configuration',
        'Scryfall Integration',
        'Tips',
      ]) {
        expect(find.text(title), findsOneWidget, reason: 'Missing: $title');
      }
    });

    testWidgets('initState locks to portrait orientation', (tester) async {
      await pump(tester, const HelpGameSetup());
      expect(orientationCalls, isNotEmpty);
      expect(orientationCalls.last, [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    });
  });

  group('HelpLifeTracker', () {
    testWidgets('renders all expected section titles', (tester) async {
      await pump(tester, const HelpLifeTracker());
      for (final title in [
        'Game Summary & Logging',
        'Tracking Tools & Overlays',
        'Turn Management',
        'Player Elimination',
        'Main Menu',
        'Tips & Best Practices',
      ]) {
        expect(find.text(title), findsOneWidget, reason: 'Missing: $title');
      }
    });

    testWidgets('dispose with playerCount=2 restores portrait', (tester) async {
      await pump(tester, const HelpLifeTracker(playerCount: 2));
      orientationCalls.clear();
      // Pump empty to trigger dispose.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(orientationCalls.any((call) =>
          call.length == 2 &&
          call[0] == DeviceOrientation.portraitUp &&
          call[1] == DeviceOrientation.portraitDown), isTrue);
    });

    testWidgets('dispose with playerCount=4 restores landscape', (tester) async {
      await pump(tester, const HelpLifeTracker(playerCount: 4));
      orientationCalls.clear();
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(orientationCalls.any((call) =>
          call.length == 2 &&
          call[0] == DeviceOrientation.landscapeLeft &&
          call[1] == DeviceOrientation.landscapeRight), isTrue);
    });
  });
}
