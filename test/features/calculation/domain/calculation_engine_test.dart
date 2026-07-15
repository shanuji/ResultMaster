import 'package:result_master/features/calculation/domain/calculation_engine.dart';
import 'package:test/test.dart';

void main() {
  const engine = CalculationEngine();

  test('calculates totals, filtered percentage, pass fail, ranks, QI, bands, and remarks', () {
    final result = engine.calculate(
      const CalculationInput(
        subjects: <CalculationSubject>[
          CalculationSubject(id: 'english', name: 'English', maximumMarks: 100, passingMarks: 33),
          CalculationSubject(id: 'art', name: 'Art', maximumMarks: 50, passingMarks: 0, includeInPercentage: false, includeInPassFail: false),
          CalculationSubject(id: 'math', name: 'Math', maximumMarks: 100, passingMarks: 40),
        ],
        students: <StudentMarks>[
          StudentMarks(
            studentId: '1',
            rollNumber: '1',
            studentName: 'Asha',
            subjectMarks: <String, Map<String, double>>{
              'english': <String, double>{'CA': 40, 'Exam': 45},
              'art': <String, double>{'Practical': 5},
              'math': <String, double>{'CA': 45, 'Exam': 40},
            },
          ),
          StudentMarks(
            studentId: '2',
            rollNumber: '2',
            studentName: 'Bala',
            subjectMarks: <String, Map<String, double>>{
              'english': <String, double>{'CA': 50, 'Exam': 40},
              'art': <String, double>{'Practical': 0},
              'math': <String, double>{'CA': 30, 'Exam': 10},
            },
          ),
          StudentMarks(
            studentId: '3',
            rollNumber: '3',
            studentName: 'Chetan',
            subjectMarks: <String, Map<String, double>>{
              'english': <String, double>{'CA': 40, 'Exam': 45},
              'math': <String, double>{'CA': 45, 'Exam': 40},
            },
          ),
        ],
        settings: CalculationSettings(
          distinctionThreshold: 80,
          qualityIndexMode: QualityIndexMode.passAdjustedPercentage,
          scoreBands: <ScoreBand>[
            ScoreBand(label: '80+', minimumInclusive: 80, maximumExclusive: 100.000001),
            ScoreBand(label: 'Below 80', minimumInclusive: 0, maximumExclusive: 80),
          ],
          remarkRules: <RemarkRule>[
            RemarkRule(minimumPercentage: 80, remark: 'Excellent', passOnly: true),
            RemarkRule(minimumPercentage: 0, remark: 'Improve'),
          ],
        ),
      ),
    );

    expect(result.students[0].subjects['english']!.total, 85);
    expect(result.students[0].grandTotal, 170);
    expect(result.students[0].maximumMarks, 200);
    expect(result.students[0].percentage, 85);
    expect(result.students[0].passed, isTrue);
    expect(result.students[0].rank, 1);
    expect(result.students[0].distinction, isTrue);
    expect(result.students[0].qualityIndex, 85);
    expect(result.students[0].remark, 'Excellent');

    expect(result.students[1].grandTotal, 130);
    expect(result.students[1].passed, isTrue);
    expect(result.students[1].rank, 3);
    expect(result.students[1].remark, 'Improve');

    expect(result.students[2].rank, 1);
    expect(result.summary.appeared, 3);
    expect(result.summary.pass, 3);
    expect(result.summary.passPercentage, 100);
    expect(result.summary.distinction, 2);
    expect(result.summary.qualityIndex, closeTo(78.333, 0.001));
    expect(result.summary.scoreBands, <String, int>{'80+': 2, 'Below 80': 1});
  });

  test('uses only pass/fail subjects for failing decisions', () {
    final result = engine.calculate(
      const CalculationInput(
        subjects: <CalculationSubject>[
          CalculationSubject(id: 'included', name: 'Included', maximumMarks: 100, passingMarks: 35),
          CalculationSubject(id: 'excluded', name: 'Excluded', maximumMarks: 100, passingMarks: 90, includeInPassFail: false),
        ],
        students: <StudentMarks>[
          StudentMarks(
            studentId: '1',
            rollNumber: '1',
            studentName: 'Asha',
            subjectMarks: <String, Map<String, double>>{
              'included': <String, double>{'Exam': 35},
              'excluded': <String, double>{'Exam': 10},
            },
          ),
        ],
      ),
    );

    expect(result.students.single.passed, isTrue);
  });
}
