class TermSetup {
  final int id;
  final String name;

  TermSetup({required this.id, required this.name});

  factory TermSetup.fromMap(Map<String, dynamic> map) {
    return TermSetup(
      id: map['id'] as int,
      name: map['term_name'] as String,
    );
  }
}

class SubjectComponent {
  final int id;
  final int subjectId;
  final String name;
  final double maxMarks;
  final double passingMarks;
  final bool isTotal;
  final bool isEditable;
  final int displayOrder;

  String get uiKey => name.replaceAll(' ', '_');

  SubjectComponent({
    required this.id,
    required this.subjectId,
    required this.name,
    required this.maxMarks,
    required this.passingMarks,
    this.isTotal = false,
    this.isEditable = true,
    this.displayOrder = 0,
  });
}

class SubjectSetup {
  final int id;
  final int workbookId;
  final String name;
  final double maxMarks;
  final double passingMarks;
  final bool includeInPercentage;
  final bool includeInPassFail;
  final int themeColor;
  final int displayOrder;
  final List<SubjectComponent> components;

  SubjectSetup({
    required this.id,
    required this.workbookId,
    required this.name,
    required this.maxMarks,
    required this.passingMarks,
    this.includeInPercentage = true,
    this.includeInPassFail = true,
    this.themeColor = 0xFF2196F3,
    this.displayOrder = 0,
    required this.components,
  });
}

class StudentRow {
  final int id;
  final String rollNo;
  final String name;

  // Map<termId, Map<componentId, marks>>
  final Map<int, Map<int, String>> termMarks;
  
  // Map<termId, Map<subjectId, isPromoted>>
  final Map<int, Map<int, bool>> termPromotions;
  
  bool? overallPromoted;

  StudentRow({
    required this.id,
    required this.rollNo,
    required this.name,
    Map<int, Map<int, String>>? termMarks,
    Map<int, Map<int, bool>>? termPromotions,
    this.overallPromoted,
  })  : termMarks = termMarks ?? {},
        termPromotions = termPromotions ?? {};

  Map<int, String> getMarksForTerm(int termId) {
    return termMarks[termId] ?? {};
  }

  Map<int, bool> getPromotionsForTerm(int termId) {
    return termPromotions[termId] ?? {};
  }
}
