import 'package:flutter_test/flutter_test.dart';
import 'package:pronow_mobile/main.dart';

void main() {
  testWidgets('ProNow smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProNowApp());
    expect(find.text('Luyện Nói'), findsWidgets);
  });
}
