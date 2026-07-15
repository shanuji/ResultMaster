import '../entities/result_workbook.dart';

class StudentMarks {
  const StudentMarks({required this.student, this.componentMarks = const {}});

  final Student student;
  final Map<String, Map<String, double>> componentMarks;
}

class SubjectResult {
  const SubjectResult({required this.subjectName, required this.componentMarks, required this.total, required this.maximumMarks, required this.passed});

  final String subjectName;
  final Map<String, double> componentMarks;
  final double total;
  final double maximumMarks;
  final bool passed;
}

class CalculatedResultRow {
  const CalculatedResultRow({required this.student, required this.subjects, required this.totalMarks, required this.maximumMarks, required this.percentage, required this.passed, required this.remarks});

  final Student student;
  final Map<String, SubjectResult> subjects;
  final double totalMarks;
  final double maximumMarks;
  final double percentage;
  final bool passed;
  final String remarks;
}

class RemarkRule {
  const RemarkRule({required this.minimumPercentage, required this.remark});

  final double minimumPercentage;
  final String remark;
}

class ResultCalculationEngine {
  const ResultCalculationEngine({this.remarkRules = defaultRemarkRules});

  static const defaultRemarkRules = <RemarkRule>[
    RemarkRule(minimumPercentage: 90, remark: 'Excellent'),
    RemarkRule(minimumPercentage: 75, remark: 'Very Good'),
    RemarkRule(minimumPercentage: 60, remark: 'Good'),
    RemarkRule(minimumPercentage: 40, remark: 'Satisfactory'),
    RemarkRule(minimumPercentage: 0, remark: 'Needs Improvement'),
  ];

  final List<RemarkRule> remarkRules;

  List<CalculatedResultRow> calculate(ResultWorkbookDraft workbook, List<StudentMarks> marks) {
    return marks.map((studentMarks) => _calculateStudent(workbook, studentMarks)).toList(growable: false);
  }

  CalculatedResultRow _calculateStudent(ResultWorkbookDraft workbook, StudentMarks marks) {
    final subjectResults = <String, SubjectResult>{};
    var totalMarks = 0.0;
    var maximumMarks = 0.0;
    var passed = true;

    final criteria = {for (final criterion in workbook.passCriteria) criterion.subjectName: criterion};

    for (final subject in workbook.subjects) {
      final componentMarks = <String, double>{};
      var subjectTotal = 0.0;
      for (final component in subject.components) {
        final value = marks.componentMarks[subject.name]?[component.name] ?? 0;
        componentMarks[component.name] = value;
        subjectTotal += value;
      }
      final criterion = criteria[subject.name];
      final passMark = criterion?.passMarks ??
          (criterion?.passPercentage == null
              ? subject.passingMarks
              : subject.maximumMarks * (criterion!.passPercentage! / 100));
      final subjectPassed = !subject.includeInPassFail || subjectTotal >= passMark;
      if (subject.includeInPassFail && !subjectPassed) passed = false;
      if (subject.includeInPercentage) {
        totalMarks += subjectTotal;
        maximumMarks += subject.maximumMarks;
      }
      subjectResults[subject.name] = SubjectResult(
        subjectName: subject.name,
        componentMarks: componentMarks,
        total: subjectTotal,
        maximumMarks: subject.maximumMarks,
        passed: subjectPassed,
      );
    }

    final percentage = maximumMarks == 0 ? 0.0 : (totalMarks / maximumMarks) * 100;
    return CalculatedResultRow(
      student: marks.student,
      subjects: subjectResults,
      totalMarks: totalMarks,
      maximumMarks: maximumMarks,
      percentage: percentage,
      passed: passed,
      remarks: _remarkFor(percentage),
    );
  }

  String _remarkFor(double percentage) {
    final sorted = [...remarkRules]..sort((a, b) => b.minimumPercentage.compareTo(a.minimumPercentage));
    return sorted.firstWhere((rule) => percentage >= rule.minimumPercentage, orElse: () => const RemarkRule(minimumPercentage: 0, remark: '')).remark;
  }
}
