enum StudentSourceType { newList, classRegister }

class Student {
  const Student({this.id, required this.rollNumber, required this.name});

  final int? id;
  final int rollNumber;
  final String name;
}

class AssessmentComponent {
  const AssessmentComponent({required this.name});

  final String name;
}

class SubjectConfig {
  const SubjectConfig({required this.name, required this.components});

  final String name;
  final List<AssessmentComponent> components;
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

class WorkbookSummary {
  const WorkbookSummary({
    required this.id,
    required this.academicYear,
    required this.className,
    required this.section,
    required this.examinationName,
    required this.studentCount,
    required this.subjectCount,
  });

  final int id;
  final String academicYear;
  final String className;
  final String section;
  final String examinationName;
  final int studentCount;
  final int subjectCount;

  String get title => '$className-$section • $examinationName • $academicYear';
}

class WorkbookComponent {
  const WorkbookComponent({
    required this.id,
    required this.name,
    required this.displayOrder,
    required this.isTotal,
    required this.isEditable,
  });

  final int id;
  final String name;
  final int displayOrder;
  final bool isTotal;
  final bool isEditable;
}

class WorkbookSubject {
  const WorkbookSubject({
    required this.id,
    required this.name,
    required this.displayOrder,
    required this.components,
  });

  final int id;
  final String name;
  final int displayOrder;
  final List<WorkbookComponent> components;
}

class WorkbookMark {
  const WorkbookMark({
    required this.studentId,
    required this.componentId,
    this.marks,
  });

  final int studentId;
  final int componentId;
  final double? marks;
}

class OpenedWorkbook {
  const OpenedWorkbook({
    required this.summary,
    required this.students,
    required this.subjects,
    required this.passCriteria,
    required this.marks,
  });

  final WorkbookSummary summary;
  final List<Student> students;
  final List<WorkbookSubject> subjects;
  final List<PassCriterion> passCriteria;
  final List<WorkbookMark> marks;

  double subjectTotal(int studentId, WorkbookSubject subject) => subject.components
      .where((component) => !component.isTotal)
      .map((component) => markFor(studentId, component.id) ?? 0)
      .fold(0, (total, mark) => total + mark);

  double? markFor(int studentId, int componentId) {
    for (final mark in marks) {
      if (mark.studentId == studentId && mark.componentId == componentId) return mark.marks;
    }
    return null;
  }
}
