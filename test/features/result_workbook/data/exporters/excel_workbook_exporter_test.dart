import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_master/features/result_workbook/data/exporters/excel_workbook_exporter.dart';
import 'package:result_master/features/result_workbook/domain/entities/result_workbook.dart';
import 'package:result_master/features/result_workbook/domain/services/result_calculation_engine.dart';

void main() {
  test('exports register, dynamic subjects, summary, and final sheets', () async {
    final file = File('${Directory.systemTemp.path}/result_master_export_test.xlsx');
    final draft = ResultWorkbookDraft(
      academicYear: '2026-27',
      className: 'III',
      section: 'A',
      examinationName: 'Annual',
      studentSourceType: StudentSourceType.newList,
      subjects: const <SubjectConfig>[
        SubjectConfig(name: 'English', components: <AssessmentComponent>[AssessmentComponent(name: 'FA')]),
        SubjectConfig(name: 'Maths', components: <AssessmentComponent>[AssessmentComponent(name: 'Exam')]),
      ],
      passCriteria: const <PassCriterion>[
        PassCriterion(subjectName: 'English', passMarks: 33),
        PassCriterion(subjectName: 'Maths', passMarks: 33),
      ],
    );

    await const ExcelWorkbookExporter().exportFile(file, draft, const <StudentMarks>[
      StudentMarks(
        student: Student(rollNumber: 1, name: 'Asha'),
        componentMarks: <String, Map<String, double>>{
          'English': <String, double>{'FA': 80},
          'Maths': <String, double>{'Exam': 90},
        },
      ),
    ]);

    final workbook = Excel.decodeBytes(await file.readAsBytes());
    expect(workbook.tables.keys, containsAll(<String>['Class Register', 'English', 'Maths', 'Summary', 'Final']));
    expect(workbook['Final'].rows[2][3]?.value.toString(), 'English');
    expect(workbook['Final'].rows[2][4]?.value.toString(), 'Maths');
    expect(workbook['Final'].rows[3][5]?.value.toString(), '170.0');
  });
}
