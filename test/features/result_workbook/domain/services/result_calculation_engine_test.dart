import 'package:flutter_test/flutter_test.dart';
import 'package:result_master/features/result_workbook/domain/entities/result_workbook.dart';
import 'package:result_master/features/result_workbook/domain/services/result_calculation_engine.dart';

void main() {
  test('calculates totals using only percentage subjects and pass/fail subjects', () {
    const engine = ResultCalculationEngine();
    final draft = ResultWorkbookDraft(
      academicYear: '2026-27',
      className: 'III',
      section: 'A',
      examinationName: 'Annual',
      studentSourceType: StudentSourceType.newList,
      subjects: const <SubjectConfig>[
        SubjectConfig(
          name: 'English',
          maximumMarks: 100,
          passingMarks: 33,
          components: <AssessmentComponent>[AssessmentComponent(name: 'FA'), AssessmentComponent(name: 'Exam')],
        ),
        SubjectConfig(
          name: 'Art',
          maximumMarks: 50,
          passingMarks: 20,
          includeInPassFail: false,
          includeInPercentage: false,
          components: <AssessmentComponent>[AssessmentComponent(name: 'Practical')],
        ),
      ],
      passCriteria: const <PassCriterion>[PassCriterion(subjectName: 'English', passMarks: 33)],
    );

    final rows = engine.calculate(draft, const <StudentMarks>[
      StudentMarks(
        student: Student(rollNumber: 1, name: 'Asha'),
        componentMarks: <String, Map<String, double>>{
          'English': <String, double>{'FA': 20, 'Exam': 50},
          'Art': <String, double>{'Practical': 10},
        },
      ),
    ]);

    expect(rows.single.subjects['English']!.total, 70);
    expect(rows.single.subjects['Art']!.total, 10);
    expect(rows.single.totalMarks, 70);
    expect(rows.single.maximumMarks, 100);
    expect(rows.single.percentage, 70);
    expect(rows.single.passed, isTrue);
  });
}
