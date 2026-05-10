import 'package:edhtracker/counter_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

OverlayItem item({
  required String label,
  required int value,
  VoidCallback? inc,
  VoidCallback? dec,
}) {
  return OverlayItem(
    label: label,
    value: value,
    onIncrement: inc ?? () {},
    onDecrement: dec ?? () {},
  );
}

void main() {
  group('CounterOverlay', () {
    testWidgets('renders 4 items in 2x2 with values and labels', (tester) async {
      await pumpInApp(
        tester,
        CounterOverlay(
          onClose: () {},
          items: [
            item(label: 'Energy', value: 1),
            item(label: 'Experience', value: 2),
            item(label: 'Poison', value: 3),
            item(label: 'Rad', value: 4),
          ],
        ),
      );

      for (final label in ['Energy', 'Experience', 'Poison', 'Rad']) {
        expect(find.text(label), findsOneWidget);
      }
      for (final v in ['1', '2', '3', '4']) {
        expect(find.text(v), findsOneWidget);
      }
    });

    testWidgets('+/- buttons fire their callbacks', (tester) async {
      int incCount = 0;
      int decCount = 0;
      await pumpInApp(
        tester,
        CounterOverlay(
          onClose: () {},
          items: [
            item(label: 'A', value: 0, inc: () => incCount++, dec: () => decCount++),
            item(label: 'B', value: 0),
            item(label: 'C', value: 0),
            item(label: 'D', value: 0),
          ],
        ),
      );

      // Tap the first add button (Item A is top-left).
      final addButtons = find.byIcon(Icons.add);
      final removeButtons = find.byIcon(Icons.remove);
      await tester.tap(addButtons.first);
      await tester.tap(removeButtons.first);
      await tester.pump();
      expect(incCount, 1);
      expect(decCount, 1);
    });

    testWidgets('close button fires onClose', (tester) async {
      bool closed = false;
      await pumpInApp(
        tester,
        CounterOverlay(
          onClose: () => closed = true,
          items: List.generate(4, (i) => item(label: 'L$i', value: 0)),
        ),
      );
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(closed, isTrue);
    });

    testWidgets('falls back to grid layout for non-4 item counts', (tester) async {
      await pumpInApp(
        tester,
        CounterOverlay(
          onClose: () {},
          items: [
            item(label: 'Only', value: 7),
          ],
        ),
      );
      expect(find.text('Only'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('items show updated value when re-pumped', (tester) async {
      await pumpInApp(
        tester,
        CounterOverlay(
          onClose: () {},
          items: [
            item(label: 'A', value: 0),
            item(label: 'B', value: 0),
            item(label: 'C', value: 0),
            item(label: 'D', value: 0),
          ],
        ),
      );
      expect(find.text('0'), findsNWidgets(4));

      await pumpInApp(
        tester,
        CounterOverlay(
          onClose: () {},
          items: [
            item(label: 'A', value: 5),
            item(label: 'B', value: 0),
            item(label: 'C', value: 0),
            item(label: 'D', value: 0),
          ],
        ),
      );
      expect(find.text('5'), findsOneWidget);
    });
  });
}
