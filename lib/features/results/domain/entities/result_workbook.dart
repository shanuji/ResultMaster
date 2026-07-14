class ResultWorkbook {
  const ResultWorkbook({
    required this.id,
    required this.title,
    required this.className,
    required this.academicYear,
    required this.subjects,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String className;
  final String academicYear;
  final List<SubjectTab> subjects;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class SubjectTab {
  const SubjectTab({required this.id, required this.name, required this.position});

  final String id;
  final String name;
  final int position;
}
