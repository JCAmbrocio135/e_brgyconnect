import 'package:flutter_test/flutter_test.dart';
import 'package:e_brgy_connect/main.dart';

void main() {
  testWidgets('E-BrgyConnect app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const EBrgyConnectApp());

    expect(find.text('E-BrgyConnect'), findsOneWidget);
    expect(find.text('Resident Portal'), findsOneWidget);
  });
}