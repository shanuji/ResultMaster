import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/result_workbook.dart';
import '../../domain/repositories/result_workbook_repository.dart';

class SqliteResultWorkbookRepository implements ResultWorkbookRepository {
  SqliteResultWorkbookRepository({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  @override
  Future<List<Student>> getClassRegisterStudents(int classRegisterId) async {
    final db = await _database.database;
    final rows = await db.query(
      'students',
      where: 'register_id = ?',
      whereArgs: <Object?>[classRegisterId],
      orderBy: 'roll_number ASC',
    );
    return rows
        .map((row) => Student(
              rollNumber: int.tryParse(row['roll_number'].toString()) ?? 0,
              name: row['name'] as String,
            ))
        .toList();
  }

  @override
  Future<CreatedWorkbook> createWorkbook(ResultWorkbookDraft draft) async {
    final db = await _database.database;
    final workbookId = await db.transaction<int>((txn) async {
      final id = await txn.insert('workbooks', <String, Object?>{
        'academic_year': draft.academicYear,
        'class_name': draft.className,
        'section': draft.section,
        'examination_name': draft.examinationName,
        'student_source_type': draft.studentSourceType.name,
        'class_register_id': draft.classRegisterId,
      });

      final students = draft.studentSourceType == StudentSourceType.classRegister &&
              draft.classRegisterId != null
          ? await _registerStudents(txn, draft.classRegisterId!)
          : draft.newStudents;
      for (final student in students) {
        await txn.insert('workbook_students', <String, Object?>{
          'workbook_id': id,
          'roll_number': student.rollNumber,
          'student_name': student.name,
        });
      }

      var tabOrder = 0;
      for (var subjectIndex = 0; subjectIndex < draft.subjects.length; subjectIndex++) {
        final subject = draft.subjects[subjectIndex];
        final subjectId = await txn.insert('workbook_subjects', <String, Object?>{
          'workbook_id': id,
          'subject_name': subject.name,
          'display_order': subjectIndex,
        });
        for (var componentIndex = 0; componentIndex < subject.components.length; componentIndex++) {
          await txn.insert('subject_components', <String, Object?>{
            'subject_id': subjectId,
            'component_name': subject.components[componentIndex].name,
            'display_order': componentIndex,
            'is_total': 0,
            'is_editable': 1,
          });
        }
        await txn.insert('subject_components', <String, Object?>{
          'subject_id': subjectId,
          'component_name': 'TOTAL',
          'display_order': subject.components.length,
          'is_total': 1,
          'is_editable': 0,
        });
        await _insertPlaceholderTab(txn, id, subject.name, 'subject', tabOrder++);
      }

      await _insertPlaceholderTab(txn, id, 'Summary', 'summary', tabOrder++);
      await _insertPlaceholderTab(txn, id, 'Final', 'final', tabOrder++);

      for (final criterion in draft.passCriteria) {
        await txn.insert('pass_criteria', <String, Object?>{
          'workbook_id': id,
          'subject_name': criterion.subjectName,
          'pass_marks': criterion.passMarks,
          'pass_percentage': criterion.passPercentage,
        });
      }
      return id;
    });
    return CreatedWorkbook(id: workbookId, draft: draft);
  }

  Future<List<Student>> _registerStudents(Transaction txn, int registerId) async {
    final rows = await txn.query(
      'students',
      where: 'register_id = ?',
      whereArgs: <Object?>[registerId],
      orderBy: 'roll_number ASC',
    );
    return rows
        .map((row) => Student(
              rollNumber: int.tryParse(row['roll_number'].toString()) ?? 0,
              name: row['name'] as String,
            ))
        .toList();
  }

  Future<void> _insertPlaceholderTab(
    Transaction txn,
    int workbookId,
    String name,
    String type,
    int order,
  ) {
    return txn.insert('workbook_tabs', <String, Object?>{
      'workbook_id': workbookId,
      'tab_name': name,
      'tab_type': type,
      'display_order': order,
      'placeholder_json': '{"columns":["Roll No","Name"],"rows":[]}',
    });
  }
}
