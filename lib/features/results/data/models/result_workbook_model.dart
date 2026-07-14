import '../../domain/entities/result_workbook.dart';

class ResultWorkbookModel extends ResultWorkbook {
  const ResultWorkbookModel({
    required super.id,
    required super.title,
    required super.className,
    required super.academicYear,
    required super.subjects,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ResultWorkbookModel.fromMap(Map<String, Object?> map, {List<SubjectTab> subjects = const []}) {
    return ResultWorkbookModel(
      id: map['id']! as String,
      title: map['title']! as String,
      className: map['class_name']! as String,
      academicYear: map['academic_year']! as String,
      subjects: subjects,
      createdAt: DateTime.parse(map['created_at']! as String),
      updatedAt: DateTime.parse(map['updated_at']! as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'class_name': className,
      'academic_year': academicYear,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
