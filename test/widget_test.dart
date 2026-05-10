import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:edhtracker/main.dart';

void main() {
  testWidgets('GameSetupPage shows player-count dropdown with 2/3/4 options',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('Number of Players'), findsOneWidget);
    expect(find.text('4 Players'), findsOneWidget);

    final playerCountDropdown = find.ancestor(
      of: find.text('Number of Players'),
      matching: find.byType(DropdownButtonFormField<int>),
    );
    expect(playerCountDropdown, findsOneWidget);

    await tester.tap(playerCountDropdown);
    await tester.pumpAndSettle();

    // Open menu shows all three options. The currently-selected "4 Players"
    // also still renders in the field, so it appears twice.
    expect(find.text('2 Players'), findsOneWidget);
    expect(find.text('3 Players'), findsOneWidget);
    expect(find.text('4 Players'), findsNWidgets(2));

    await tester.tap(find.text('2 Players').last);
    await tester.pumpAndSettle();

    expect(find.text('2 Players'), findsOneWidget);
    expect(find.text('4 Players'), findsNothing);
  });
}
