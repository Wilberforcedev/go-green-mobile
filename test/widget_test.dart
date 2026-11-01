import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinmates_mobile/main.dart';

void main() {
  testWidgets('shows the home screen and primary navigation', (tester) async {
    await tester.pumpWidget(const GoGreenApp());
    await tester.pump();

    expect(find.text('GO GREEN MATES'), findsOneWidget);
    expect(find.text('Campaigns'), findsOneWidget);
    expect(find.text('Impact Hub'), findsOneWidget);
  });

  testWidgets('shows setup guidance when Supabase is not configured', (tester) async {
    await tester.pumpWidget(const GoGreenApp());
    await tester.pump();

    await tester.tap(find.text('Impact Hub'));
    await tester.pump();

    expect(find.text('Impact Hub setup needed'), findsOneWidget);
    expect(find.text('Add Supabase configuration'), findsOneWidget);
  });

  testWidgets('campaign tab shows published campaign information', (tester) async {
    await tester.pumpWidget(const GoGreenApp());
    await tester.pump();

    await tester.tap(find.text('Campaigns'));
    await tester.pump();

    expect(find.text('Campaigns & partnerships'), findsOneWidget);
    expect(find.text('One Million Trees'), findsOneWidget);
  });
}
