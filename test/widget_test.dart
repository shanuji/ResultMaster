import 'package:flutter_test/flutter_test.dart';
import 'package:resultmaster/app.dart';

void main() {
  testWidgets('ResultMaster dashboard renders workbook shell', (tester) async {
    await tester.pumpWidget(const ResultMasterApp());
    await tester.pump();

    expect(find.text('ResultMaster'), findsOneWidget);
    expect(find.text('Result workbook'), findsOneWidget);
    expect(find.text('Summary'), findsWidgets);
  });
}
