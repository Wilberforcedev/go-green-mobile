import 'package:flutter_test/flutter_test.dart';
import 'package:grinmates_mobile/main.dart';

void main() {
  testWidgets('shows Go Green Mates home and navigation', (tester) async {
    await tester.pumpWidget(const GoGreenApp());
    expect(find.text('GO GREEN MATES'), findsOneWidget);
    expect(find.text('Campaigns'), findsOneWidget);
    expect(find.text('Impact Hub'), findsOneWidget);
  });
}
