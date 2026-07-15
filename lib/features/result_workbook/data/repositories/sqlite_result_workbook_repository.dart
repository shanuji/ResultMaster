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
  Future<List<WorkbookSummary>> listWorkbooks() async {
    final db = await _database.database;
    await _ensureWorkbookMarksTable(db);
    final rows = await db.rawQuery('''
      SELECT w.id, w.academic_year, w.class_name, w.section, w.examination_name,
        COUNT(DISTINCT ws.id) AS student_count,
        COUNT(DISTINCT sub.id) AS subject_count
      FROM workbooks w
      LEFT JOIN workbook_students ws ON ws.workbook_id = w.id
      LEFT JOIN workbook_subjects sub ON sub.workbook_id = w.id
      GROUP BY w.id
      ORDER BY w.id DESC
    ''');
    return rows.map(_summaryFromRow).toList(growable: false);
  }

  @override
  Future<OpenedWorkbook> openWorkbook(int workbookId) async {
    final db = await _database.database;
    await _ensureWorkbookMarksTable(db);
    final workbookRows = await db.rawQuery('''
      SELECT w.id, w.academic_year, w.class_name, w.section, w.examination_name,
        COUNT(DISTINCT ws.id) AS student_count,
        COUNT(DISTINCT sub.id) AS subject_count
      FROM workbooks w
      LEFT JOIN workbook_students ws ON ws.workbook_id = w.id
      LEFT JOIN workbook_subjects sub ON sub.workbook_id = w.id
      WHERE w.id = ?
      GROUP BY w.id
    ''', <Object?>[workbookId]);
    if (workbookRows.isEmpty) throw StateError('Workbook not found.');

    final studentRows = await db.query('workbook_students', where: 'workbook_id = ?', whereArgs: <Object?>[workbookId], orderBy: 'roll_number ASC');
    final subjectRows = await db.query('workbook_subjects', where: 'workbook_id = ?', whereArgs: <Object?>[workbookId], orderBy: 'display_order ASC');
    final subjects = <WorkbookSubject>[];
    for (final subjectRow in subjectRows) {
      final componentRows = await db.query('subject_components', where: 'subject_id = ?', whereArgs: <Object?>[subjectRow['id']], orderBy: 'display_order ASC');
      subjects.add(WorkbookSubject(
        id: subjectRow['id'] as int,
        name: subjectRow['subject_name'] as String,
        displayOrder: subjectRow['display_order'] as int,
        components: componentRows.map((row) => WorkbookComponent(
          id: row['id'] as int,
          name: row['component_name'] as String,
          displayOrder: row['display_order'] as int,
          isTotal: row['is_total'] == 1,
          isEditable: row['is_editable'] == 1,
        )).toList(growable: false),
      ));
    }
    final criteriaRows = await db.query('pass_criteria', where: 'workbook_id = ?', whereArgs: <Object?>[workbookId]);
    final markRows = await db.query('workbook_marks', where: 'workbook_id = ?', whereArgs: <Object?>[workbookId]);
    return OpenedWorkbook(
      summary: _summaryFromRow(workbookRows.single),
      students: studentRows.map((row) => Student(id: row['id'] as int?, rollNumber: row['roll_number'] as int, name: row['student_name'] as String)).toList(growable: false),
      subjects: subjects,
      passCriteria: criteriaRows.map((row) => PassCriterion(subjectName: row['subject_name'] as String, passMarks: (row['pass_marks'] as num?)?.toDouble(), passPercentage: (row['pass_percentage'] as num?)?.toDouble())).toList(growable: false),
      marks: markRows.map((row) => WorkbookMark(studentId: row['student_id'] as int, componentId: row['component_id'] as int, marks: (row['marks'] as num?)?.toDouble())).toList(growable: false),
    );
  }

  @override
  Future<CreatedWorkbook> createWorkbook(ResultWorkbookDraft draft) async {
    final db = await _database.database;
    await _ensureWorkbookMarksTable(db);
    final workbookId = await db.transaction<int>((txn) async {
      final id = await txn.insert('workbooks', <String, Object?>{
        'academic_year': draft.academicYear,
        'class_name': draft.className,
        'section': draft.section,
        'examination_name': draft.examinationName,
        'student_source_type': draft.studentSourceType.name,
        'class_register_id': draft.classRegisterId,
      });

      final students = draft.studentSourceType == StudentSourceType.classRegister && draft.classRegisterId != null
          ? await _registerStudents(txn, draft.classRegisterId!)
          : draft.newStudents;
      for (final student in students) {
        await txn.insert('workbook_students', <String, Object?>{'workbook_id': id, 'roll_number': student.rollNumber, 'student_name': student.name});
      }

      var tabOrder = 0;
      for (var subjectIndex = 0; subjectIndex < draft.subjects.length; subjectIndex++) {
        final subject = draft.subjects[subjectIndex];
        final subjectId = await txn.insert('workbook_subjects', <String, Object?>{
          'workbook_id': id,
          'subject_name': subject.name,
          'display_order': subjectIndex,
          'maximum_marks': subject.maximumMarks,
          'passing_marks': subject.passingMarks,
          'include_in_percentage': subject.includeInPercentage ? 1 : 0,
          'include_in_pass_fail': subject.includeInPassFail ? 1 : 0,
        });
        for (var componentIndex = 0; componentIndex < subject.components.length; componentIndex++) {
          await txn.insert('subject_components', <String, Object?>{'subject_id': subjectId, 'component_name': subject.components[componentIndex].name, 'display_order': componentIndex, 'is_total': 0, 'is_editable': 1});
        }
        await txn.insert('subject_components', <String, Object?>{'subject_id': subjectId, 'component_name': 'TOTAL', 'display_order': subject.components.length, 'is_total': 1, 'is_editable': 0});
        await _insertPlaceholderTab(txn, id, subject.name, 'subject', tabOrder++);
      }

      await _insertPlaceholderTab(txn, id, 'Summary', 'summary', tabOrder++);
      await _insertPlaceholderTab(txn, id, 'Final', 'final', tabOrder++);

      for (final criterion in draft.passCriteria) {
        await txn.insert('pass_criteria', <String, Object?>{'workbook_id': id, 'subject_name': criterion.subjectName, 'pass_marks': criterion.passMarks, 'pass_percentage': criterion.passPercentage});
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
  @override
  Future<void> renameWorkbook(int workbookId, String examinationName) async {
    final db = await _database.database;
    await db.update('workbooks', <String, Object?>{'examination_name': examinationName.trim()}, where: 'id = ?', whereArgs: <Object?>[workbookId]);
  }

  @override
  Future<void> deleteWorkbook(int workbookId) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      final subjectRows = await txn.query('workbook_subjects', columns: <String>['id'], where: 'workbook_id = ?', whereArgs: <Object?>[workbookId]);
      for (final subject in subjectRows) {
        await txn.delete('subject_components', where: 'subject_id = ?', whereArgs: <Object?>[subject['id']]);
      }
      await txn.delete('workbook_marks', where: 'workbook_id = ?', whereArgs: <Object?>[workbookId]);
      await txn.delete('workbook_students', where: 'workbook_id = ?', whereArgs: <Object?>[workbookId]);
      await txn.delete('workbook_subjects', where: 'workbook_id = ?', whereArgs: <Object?>[workbookId]);
      await txn.delete('pass_criteria', where: 'workbook_id = ?', whereArgs: <Object?>[workbookId]);
      await txn.delete('workbook_tabs', where: 'workbook_id = ?', whereArgs: <Object?>[workbookId]);
      await txn.delete('workbooks', where: 'id = ?', whereArgs: <Object?>[workbookId]);
    });
  }

  @override
  Future<void> saveMark({required int workbookId, required int studentId, required int componentId, double? marks}) async {
    final db = await _database.database;
    await _ensureWorkbookMarksTable(db);
    if (marks == null) {
      await db.delete('workbook_marks', where: 'workbook_id = ? AND student_id = ? AND component_id = ?', whereArgs: <Object?>[workbookId, studentId, componentId]);
      return;
    }
    await db.insert('workbook_marks', <String, Object?>{'workbook_id': workbookId, 'student_id': studentId, 'component_id': componentId, 'marks': marks}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _ensureWorkbookMarksTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS workbook_marks (
        workbook_id INTEGER NOT NULL,
        student_id INTEGER NOT NULL,
        component_id INTEGER NOT NULL,
        marks REAL NOT NULL,
        PRIMARY KEY(workbook_id, student_id, component_id)
      )
    ''');
  }

  WorkbookSummary _summaryFromRow(Map<String, Object?> row) => WorkbookSummary(
    id: row['id'] as int,
    academicYear: row['academic_year'] as String,
    className: row['class_name'] as String,
    section: row['section'] as String,
    examinationName: row['examination_name'] as String,
    studentCount: row['student_count'] as int? ?? 0,
    subjectCount: row['subject_count'] as int? ?? 0,
  );

  Future<List<Student>> _registerStudents(Transaction txn, int registerId) async {
    final rows = await txn.query('class_register_students', where: 'register_id = ?', whereArgs: <Object?>[registerId], orderBy: 'roll_number ASC');
    return rows.map((row) => Student(id: row['id'] as int?, rollNumber: row['roll_number'] as int, name: row['student_name'] as String)).toList();
  }

  Future<void> _insertPlaceholderTab(Transaction txn, int workbookId, String name, String type, int order) => txn.insert('workbook_tabs', <String, Object?>{'workbook_id': workbookId, 'tab_name': name, 'tab_type': type, 'display_order': order, 'placeholder_json': '{"columns":["Roll No","Name"],"rows":[]}'});
}
