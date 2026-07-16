import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:result_master/app.dart';
import 'package:result_master/features/results/presentation/screens/result_workspace_screen.dart';

void main() {
  testWidgets('ResultMaster dashboard renders workbook shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ResultMasterApp()));
    await tester.pump();

    expect(find.text('ResultMaster'), findsOneWidget);
    expect(find.text('Offline result workbooks for every class'), findsOneWidget);
    expect(find.text('Start New Result'), findsOneWidget);
  });

  testWidgets('marks entry validates, handles AB, totals, and auto-save status', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MarksEntrySheet(
            subjectId: 'math',
            subjectName: 'Mathematics',
            studentCount: 1,
            componentMaxMarks: {'CA': 20, 'Exam': 80},
          ),
        ),
      ),
    );

    await tester.enterText(find.byKey(const ValueKey('mark-0-0')), '18');
    await tester.pump();
    await tester.enterText(find.byKey(const ValueKey('mark-0-1')), '75');
    await tester.pump();

    expect(find.text('93'), findsOneWidget);
    expect(find.text('All edits auto-saved'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('mark-0-1')), 'AB');
    await tester.pump();

    expect(find.text('AB'), findsWidgets);
    expect(find.text('Fix invalid marks before finalizing'), findsNothing);

    await tester.enterText(find.byKey(const ValueKey('mark-0-0')), '21');
    await tester.pump();

    expect(find.text('Enter 0-20 or AB'), findsOneWidget);
    expect(find.text('Fix invalid marks before finalizing'), findsOneWidget);
  });
}
