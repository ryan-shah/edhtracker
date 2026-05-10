import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps [child] inside a minimal MaterialApp at a known size so layouts
/// behave deterministically. Default size is a generic landscape phone
/// (matches the in-game orientation for 3/4-player layouts).
Future<void> pumpInApp(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(896, 414),
}) async {
  await tester.binding.setSurfaceSize(size);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: child),
    ),
  );
  await tester.pump();
}

/// Wrap [child] in a MaterialApp + Scaffold without overriding surface size.
/// Useful when the page already manages its own scaffold.
Future<void> pumpPage(WidgetTester tester, Widget page) async {
  await tester.pumpWidget(MaterialApp(home: page));
  await tester.pump();
}
