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

  testWidgets('shows setup guidance when Supabase is not configured', (
    tester,
  ) async {
    await tester.pumpWidget(const GoGreenApp());
    await tester.pump();

    await tester.tap(find.text('Impact Hub'));
    await tester.pump();

    expect(find.text('Impact Hub setup needed'), findsOneWidget);
    expect(find.text('Add Supabase configuration'), findsOneWidget);
  });

  testWidgets('shows configuration guidance when startup fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      const GoGreenApp(
        startupError: 'SUPABASE_URL must be a valid https project URL.',
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Impact Hub'));
    await tester.pump();

    expect(find.text('Impact Hub unavailable'), findsOneWidget);
    expect(
      find.text('SUPABASE_URL must be a valid https project URL.'),
      findsOneWidget,
    );
  });

  testWidgets('campaign tab shows published campaign information', (
    tester,
  ) async {
    await tester.pumpWidget(const GoGreenApp());
    await tester.pump();

    await tester.tap(find.text('Campaigns'));
    await tester.pump();

    expect(find.text('Campaigns & partnerships'), findsOneWidget);
    expect(find.text('One Million Trees'), findsOneWidget);
  });

  testWidgets('about tab shows organisation information', (tester) async {
    await tester.pumpWidget(const GoGreenApp());
    await tester.pump();

    await tester.tap(find.text('About'));
    await tester.pump();

    expect(find.text('About Go Green Mates'), findsOneWidget);
    expect(find.text('For enquiries: googreenmates@gmail.com'), findsOneWidget);
  });

  testWidgets('home call to action opens the Impact Hub', (tester) async {
    await tester.pumpWidget(const GoGreenApp());
    await tester.pump();

    final action = find.text('Get started in the Impact Hub');
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pump();

    expect(find.text('Impact Hub setup needed'), findsOneWidget);
  });

  testWidgets('every tab renders without errors', (tester) async {
    await tester.pumpWidget(const GoGreenApp());
    await tester.pump();

    for (final label in ['Campaigns', 'Impact Hub', 'About', 'Home']) {
      await tester.tap(find.text(label));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });
}
