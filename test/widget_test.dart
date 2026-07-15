import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:result_master/app.dart';

void main() {
  testWidgets('ResultMaster dashboard renders workbook shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ResultMasterApp()));
    await tester.pump();

    expect(find.text('ResultMaster'), findsOneWidget);
    expect(find.text('Result workbook'), findsOneWidget);
    expect(find.text('Summary'), findsWidgets);
  });
}
