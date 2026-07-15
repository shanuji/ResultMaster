/// Shared calculation engine for every result workbook surface.
///
/// Keep this file free of Flutter, database, and spreadsheet dependencies so it
/// can be reused by Marks Entry, Workbook Engine, Summary Sheet, Final Sheet,
/// and Excel Export without duplicating business rules.
class CalculationEngine {
  const CalculationEngine();

  CalculationResult calculate(CalculationInput input) {
    final rows = <StudentCalculation>[];
    for (final student in input.students) {
      rows.add(_calculateStudent(input, student));
    }

    final ranked = _applyRanks(rows);
    return CalculationResult(
      students: ranked,
      summary: _calculateSummary(input.settings, ranked),
    );
  }

  StudentCalculation _calculateStudent(CalculationInput input, StudentMarks student) {
    final subjectResults = <String, SubjectCalculation>{};
    var grandTotal = 0.0;
    var maximumMarks = 0.0;
    var failed = false;

    for (final subject in input.subjects) {
      final componentMarks = student.subjectMarks[subject.id] ?? const <String, double>{};
      final total = calculateSubjectTotal(componentMarks);
      subjectResults[subject.id] = SubjectCalculation(
        subject: subject,
        componentMarks: Map<String, double>.unmodifiable(componentMarks),
        total: total,
      );

      if (subject.includeInPercentage) {
        grandTotal += total;
        maximumMarks += subject.maximumMarks;
      }

      if (subject.includeInPassFail && total < subject.passingMarks) {
        failed = true;
      }
    }

    final percentage = calculatePercentage(grandTotal, maximumMarks);
    final passed = !failed;
    final distinction = passed && percentage >= input.settings.distinctionThreshold;
    final remark = _remarkFor(input.settings.remarkRules, percentage, passed);

    return StudentCalculation(
      studentId: student.studentId,
      rollNumber: student.rollNumber,
      studentName: student.studentName,
      subjects: Map<String, SubjectCalculation>.unmodifiable(subjectResults),
      grandTotal: grandTotal,
      maximumMarks: maximumMarks,
      percentage: percentage,
      passed: passed,
      rank: null,
      distinction: distinction,
      qualityIndex: _qualityIndex(input.settings.qualityIndexMode, percentage, passed),
      remark: remark,
    );
  }

  double calculateSubjectTotal(Map<String, double> componentMarks) =>
      componentMarks.values.fold<double>(0, (sum, mark) => sum + mark);

  double calculatePercentage(double total, double maximumMarks) =>
      maximumMarks <= 0 ? 0 : (total / maximumMarks) * 100;

  List<StudentCalculation> _applyRanks(List<StudentCalculation> students) {
    final ordered = [...students]
      ..sort((a, b) {
        final percentageOrder = b.percentage.compareTo(a.percentage);
        if (percentageOrder != 0) return percentageOrder;
        return b.grandTotal.compareTo(a.grandTotal);
      });

    final ranksById = <String, int>{};
    var nextRank = 1;
    for (var index = 0; index < ordered.length; index++) {
      if (index > 0 && !_isTie(ordered[index - 1], ordered[index])) {
        nextRank = index + 1;
      }
      ranksById[ordered[index].studentId] = nextRank;
    }

    return students
        .map((student) => student.copyWith(rank: ranksById[student.studentId]))
        .toList(growable: false);
  }

  bool _isTie(StudentCalculation a, StudentCalculation b) =>
      a.percentage == b.percentage && a.grandTotal == b.grandTotal;

  double _qualityIndex(QualityIndexMode mode, double percentage, bool passed) {
    switch (mode) {
      case QualityIndexMode.percentage:
        return percentage;
      case QualityIndexMode.passAdjustedPercentage:
        return passed ? percentage : 0;
      case QualityIndexMode.gradePoint:
        if (!passed) return 0;
        if (percentage >= 90) return 10;
        if (percentage >= 80) return 9;
        if (percentage >= 70) return 8;
        if (percentage >= 60) return 7;
        if (percentage >= 50) return 6;
        if (percentage >= 40) return 5;
        return 4;
    }
  }

  String _remarkFor(List<RemarkRule> rules, double percentage, bool passed) {
    final sortedRules = [...rules]..sort((a, b) => b.minimumPercentage.compareTo(a.minimumPercentage));
    for (final rule in sortedRules) {
      if ((!rule.passOnly || passed) && percentage >= rule.minimumPercentage) {
        return rule.remark;
      }
    }
    return passed ? 'Pass' : 'Fail';
  }

  SummaryStatistics _calculateSummary(
    CalculationSettings settings,
    List<StudentCalculation> students,
  ) {
    final appeared = students.length;
    final pass = students.where((student) => student.passed).length;
    final distinction = students.where((student) => student.distinction).length;
    final totalQi = students.fold<double>(0, (sum, student) => sum + student.qualityIndex);
    final bands = <String, int>{for (final band in settings.scoreBands) band.label: 0};

    for (final student in students) {
      for (final band in settings.scoreBands) {
        if (band.contains(student.percentage)) {
          bands[band.label] = (bands[band.label] ?? 0) + 1;
          break;
        }
      }
    }

    return SummaryStatistics(
      appeared: appeared,
      pass: pass,
      passPercentage: appeared == 0 ? 0 : (pass / appeared) * 100,
      distinction: distinction,
      qualityIndex: appeared == 0 ? 0 : totalQi / appeared,
      scoreBands: Map<String, int>.unmodifiable(bands),
    );
  }
}

class CalculationInput {
  const CalculationInput({
    required this.subjects,
    required this.students,
    this.settings = const CalculationSettings(),
  });

  final List<CalculationSubject> subjects;
  final List<StudentMarks> students;
  final CalculationSettings settings;
}

class CalculationSettings {
  const CalculationSettings({
    this.distinctionThreshold = 75,
    this.qualityIndexMode = QualityIndexMode.passAdjustedPercentage,
    this.scoreBands = defaultScoreBands,
    this.remarkRules = defaultRemarkRules,
  });

  static const defaultScoreBands = <ScoreBand>[
    ScoreBand(label: '90-100', minimumInclusive: 90, maximumExclusive: 100.000001),
    ScoreBand(label: '75-89.99', minimumInclusive: 75, maximumExclusive: 90),
    ScoreBand(label: '60-74.99', minimumInclusive: 60, maximumExclusive: 75),
    ScoreBand(label: 'Below 60', minimumInclusive: 0, maximumExclusive: 60),
  ];

  static const defaultRemarkRules = <RemarkRule>[
    RemarkRule(minimumPercentage: 75, remark: 'Distinction'),
    RemarkRule(minimumPercentage: 60, remark: 'First Division'),
    RemarkRule(minimumPercentage: 45, remark: 'Second Division'),
    RemarkRule(minimumPercentage: 0, remark: 'Needs Improvement'),
  ];

  final double distinctionThreshold;
  final QualityIndexMode qualityIndexMode;
  final List<ScoreBand> scoreBands;
  final List<RemarkRule> remarkRules;
}

enum QualityIndexMode { percentage, passAdjustedPercentage, gradePoint }

class ScoreBand {
  const ScoreBand({
    required this.label,
    required this.minimumInclusive,
    required this.maximumExclusive,
  });

  final String label;
  final double minimumInclusive;
  final double maximumExclusive;

  bool contains(double score) => score >= minimumInclusive && score < maximumExclusive;
}

class RemarkRule {
  const RemarkRule({
    required this.minimumPercentage,
    required this.remark,
    this.passOnly = false,
  });

  final double minimumPercentage;
  final String remark;
  final bool passOnly;
}

class CalculationSubject {
  const CalculationSubject({
    required this.id,
    required this.name,
    required this.maximumMarks,
    required this.passingMarks,
    this.includeInPercentage = true,
    this.includeInPassFail = true,
  });

  final String id;
  final String name;
  final double maximumMarks;
  final double passingMarks;
  final bool includeInPercentage;
  final bool includeInPassFail;
}

class StudentMarks {
  const StudentMarks({
    required this.studentId,
    required this.rollNumber,
    required this.studentName,
    required this.subjectMarks,
  });

  final String studentId;
  final String rollNumber;
  final String studentName;
  final Map<String, Map<String, double>> subjectMarks;
}

class SubjectCalculation {
  const SubjectCalculation({
    required this.subject,
    required this.componentMarks,
    required this.total,
  });

  final CalculationSubject subject;
  final Map<String, double> componentMarks;
  final double total;
}

class StudentCalculation {
  const StudentCalculation({
    required this.studentId,
    required this.rollNumber,
    required this.studentName,
    required this.subjects,
    required this.grandTotal,
    required this.maximumMarks,
    required this.percentage,
    required this.passed,
    required this.rank,
    required this.distinction,
    required this.qualityIndex,
    required this.remark,
  });

  final String studentId;
  final String rollNumber;
  final String studentName;
  final Map<String, SubjectCalculation> subjects;
  final double grandTotal;
  final double maximumMarks;
  final double percentage;
  final bool passed;
  final int? rank;
  final bool distinction;
  final double qualityIndex;
  final String remark;

  StudentCalculation copyWith({int? rank}) => StudentCalculation(
        studentId: studentId,
        rollNumber: rollNumber,
        studentName: studentName,
        subjects: subjects,
        grandTotal: grandTotal,
        maximumMarks: maximumMarks,
        percentage: percentage,
        passed: passed,
        rank: rank ?? this.rank,
        distinction: distinction,
        qualityIndex: qualityIndex,
        remark: remark,
      );
}

class SummaryStatistics {
  const SummaryStatistics({
    required this.appeared,
    required this.pass,
    required this.passPercentage,
    required this.distinction,
    required this.qualityIndex,
    required this.scoreBands,
  });

  final int appeared;
  final int pass;
  final double passPercentage;
  final int distinction;
  final double qualityIndex;
  final Map<String, int> scoreBands;
}

class CalculationResult {
  const CalculationResult({required this.students, required this.summary});

  final List<StudentCalculation> students;
  final SummaryStatistics summary;
}
