enum StudentSourceType { newList, classRegister }

class Student {
  const Student({required this.rollNumber, required this.name});

  final int rollNumber;
  final String name;
}

class AssessmentComponent {
  const AssessmentComponent({required this.name});

  final String name;
}

class SubjectConfig {
  const SubjectConfig({
    required this.name,
    required this.components,
    this.maximumMarks = 100,
    this.passingMarks = 33,
    this.includeInPercentage = true,
    this.includeInPassFail = true,
  });

  final String name;
  final List<AssessmentComponent> components;
  final double maximumMarks;
  final double passingMarks;
  final bool includeInPercentage;
  final bool includeInPassFail;
}

class PassCriterion {
  const PassCriterion({
    required this.subjectName,
    this.passMarks,
    this.passPercentage,
  }) : assert(passMarks != null || passPercentage != null);

  final String subjectName;
  final double? passMarks;
  final double? passPercentage;
}

class ResultWorkbookDraft {
  const ResultWorkbookDraft({
    required this.academicYear,
    required this.className,
    required this.section,
    required this.examinationName,
    required this.studentSourceType,
    this.classRegisterId,
    this.newStudents = const <Student>[],
    required this.subjects,
    required this.passCriteria,
  });

  final String academicYear;
  final String className;
  final String section;
  final String examinationName;
  final StudentSourceType studentSourceType;
  final int? classRegisterId;
  final List<Student> newStudents;
  final List<SubjectConfig> subjects;
  final List<PassCriterion> passCriteria;
}

class CreatedWorkbook {
  const CreatedWorkbook({required this.id, required this.draft});

  final int id;
  final ResultWorkbookDraft draft;
}
