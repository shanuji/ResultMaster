import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../../../../models/data_models.dart' as data_models;
import '../../domain/repositories/result_workbook_repository.dart';
import '../../domain/entities/result_workbook.dart';

class SqliteResultWorkbookRepository implements ResultWorkbookRepository {
  final AppDatabase _appDatabase;

  SqliteResultWorkbookRepository({AppDatabase? appDatabase})
      : _appDatabase = appDatabase ?? AppDatabase.instance;

  Future<Database> get _db async => await _appDatabase.database;

  // =========================================================================
  // DASHBOARD DATA FETCHING (v5 Structure)
  // =========================================================================
  
  Future<List<Map<String, dynamic>>> getAllWorkbooks() async {
    final db = await _db;
    return await db.query('workbooks', orderBy: 'created_at DESC');
  }

  Future<void> saveTermMark({
    required int workbookId,
    required int termId,
    required int studentId,
    required int componentId,
    required String marks,
  }) async {
    final db = await _db;
    await db.rawInsert('''
      INSERT INTO workbook_marks 
        (workbook_id, term_id, student_id, component_id, marks) 
      VALUES (?, ?, ?, ?, ?) 
      ON CONFLICT(workbook_id, term_id, student_id, component_id) 
      DO UPDATE SET marks = excluded.marks
    ''', [workbookId, termId, studentId, componentId, marks]);
  }

  Future<void> saveTermPromotion({
    required int workbookId,
    required int termId,
    required int studentId,
    required int subjectId,
    required bool isPromoted,
  }) async {
    final db = await _db;
    await db.rawInsert('''
      INSERT INTO workbook_term_promotions 
        (workbook_id, term_id, student_id, subject_id, is_promoted) 
      VALUES (?, ?, ?, ?, ?) 
      ON CONFLICT(workbook_id, term_id, student_id, subject_id) 
      DO UPDATE SET is_promoted = excluded.is_promoted
    ''', [workbookId, termId, studentId, subjectId, isPromoted ? 1 : 0]);
  }

  Future<List<data_models.TermSetup>> getWorkbookTerms(int workbookId) async {
    final db = await _db;
    final results = await db.query(
      'workbook_terms',
      where: 'workbook_id = ?',
      whereArgs: [workbookId],
    );
    return results.map((map) => data_models.TermSetup.fromMap(map)).toList();
  }

  Future<List<data_models.SubjectSetup>> getWorkbookSubjects(int workbookId) async {
    final db = await _db;
    final rawData = await db.rawQuery('''
      SELECT 
        s.id AS subject_id, s.subject_name, s.display_order AS subject_order, 
        s.maximum_marks AS sub_max, s.passing_marks AS sub_pass,
        s.include_in_percentage, s.include_in_pass_fail, s.theme_color,
        c.id AS component_id, c.component_name, c.display_order AS component_order, 
        c.maximum_marks AS comp_max, c.passing_marks AS comp_pass, c.is_total, c.is_editable
      FROM workbook_subjects s
      LEFT JOIN subject_components c ON s.id = c.subject_id
      WHERE s.workbook_id = ?
      ORDER BY s.display_order ASC, c.display_order ASC
    ''', [workbookId]);

    Map<int, data_models.SubjectSetup> subjectsMap = {};

    for (var row in rawData) {
      int subId = row['subject_id'] as int;
      if (!subjectsMap.containsKey(subId)) {
        subjectsMap[subId] = data_models.SubjectSetup(
          id: subId,
          workbookId: workbookId,
          name: row['subject_name'] as String,
          maxMarks: (row['sub_max'] as num).toDouble(),
          passingMarks: (row['sub_pass'] as num).toDouble(),
          includeInPercentage: (row['include_in_percentage'] as int) == 1,
          includeInPassFail: (row['include_in_pass_fail'] as int) == 1,
          themeColor: row['theme_color'] as int,
          displayOrder: row['subject_order'] as int,
          components: [],
        );
      }

      if (row['component_id'] != null) {
        subjectsMap[subId]!.components.add(data_models.SubjectComponent(
          id: row['component_id'] as int,
          subjectId: subId,
          name: row['component_name'] as String,
          maxMarks: (row['comp_max'] as num).toDouble(),
          passingMarks: (row['comp_pass'] as num).toDouble(),
          isTotal: (row['is_total'] as int) == 1,
          isEditable: (row['is_editable'] as int) == 1,
          displayOrder: row['component_order'] as int,
        ));
      }
    }
    return subjectsMap.values.toList();
  }

  Future<List<data_models.StudentRow>> getStudentsWithFullData(int workbookId) async {
    final db = await _db;
    
    final studentsRaw = await db.query(
      'workbook_students',
      where: 'workbook_id = ?',
      whereArgs: [workbookId],
      orderBy: 'roll_number ASC',
    );

    final marksRaw = await db.query(
      'workbook_marks',
      where: 'workbook_id = ?',
      whereArgs: [workbookId],
    );

    final promotionsRaw = await db.query(
      'workbook_term_promotions',
      where: 'workbook_id = ?',
      whereArgs: [workbookId],
    );

    Map<int, data_models.StudentRow> studentMap = {};

    for (var s in studentsRaw) {
      int sId = s['id'] as int;
      studentMap[sId] = data_models.StudentRow(
        id: sId,
        rollNo: s['roll_number'] as String,
        name: s['student_name'] as String,
      );
    }

    for (var m in marksRaw) {
      int sId = m['student_id'] as int;
      int tId = m['term_id'] as int;
      int cId = m['component_id'] as int;
      
      if (studentMap.containsKey(sId)) {
        studentMap[sId]!.termMarks.putIfAbsent(tId, () => {});
        studentMap[sId]!.termMarks[tId]![cId] = m['marks'] as String;
      }
    }

    for (var p in promotionsRaw) {
      int sId = p['student_id'] as int;
      int tId = p['term_id'] as int;
      int subId = p['subject_id'] as int;

      if (studentMap.containsKey(sId)) {
        studentMap[sId]!.termPromotions.putIfAbsent(tId, () => {});
        studentMap[sId]!.termPromotions[tId]![subId] = (p['is_promoted'] as int) == 1;
      }
    }

    return studentMap.values.toList();
  }

  // =========================================================================
  // CLEAN ARCHITECTURE DOMAIN INTERFACE IMPLEMENTATION
  // =========================================================================
  
  @override
  Future<List<Student>> getClassRegisterStudents(int classRegisterId) async {
    return [];
  }

  @override
  Future<List<WorkbookSummary>> listWorkbooks() async {
    return [];
  }

  @override
  Future<OpenedWorkbook> openWorkbook(int workbookId) async {
    throw UnimplementedError('Database connection pending');
  }

  @override
  Future<CreatedWorkbook> createWorkbook(ResultWorkbookDraft draft) async {
    throw UnimplementedError('SQL insert logic pending entity mapping');
  }

  @override
  Future<void> renameWorkbook(int workbookId, String examinationName) async {
    final db = await _db;
    await db.update('workbooks', {'examination_name': examinationName}, where: 'id = ?', whereArgs: [workbookId]);
  }

  @override
  Future<void> deleteWorkbook(int workbookId) async {
    final db = await _db;
    await db.delete('workbooks', where: 'id = ?', whereArgs: [workbookId]);
  }

  @override
  Future<void> saveMark({required int workbookId, required int studentId, required int componentId, double? marks}) async {
    // Standard implementation
  }
}
