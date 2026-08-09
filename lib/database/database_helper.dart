import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/data_models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('result_master.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Workbooks
    await db.execute('''
      CREATE TABLE workbooks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 2. Terms
    await db.execute('''
      CREATE TABLE terms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workbook_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        FOREIGN KEY (workbook_id) REFERENCES workbooks (id) ON DELETE CASCADE
      )
    ''');

    // 3. Students
    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workbook_id INTEGER NOT NULL,
        roll_no TEXT NOT NULL,
        name TEXT NOT NULL,
        FOREIGN KEY (workbook_id) REFERENCES workbooks (id) ON DELETE CASCADE
      )
    ''');

    // 4. Subjects
    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workbook_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        max_marks REAL NOT NULL,
        passing_marks REAL NOT NULL,
        include_in_pass_fail INTEGER NOT NULL,
        theme_color INTEGER NOT NULL,
        FOREIGN KEY (workbook_id) REFERENCES workbooks (id) ON DELETE CASCADE
      )
    ''');

    // 5. Subject Components
    await db.execute('''
      CREATE TABLE subject_components (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        max_marks REAL NOT NULL,
        passing_marks REAL NOT NULL,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
      )
    ''');

    // 6. Unified Term-Aware Workbook Marks (UPSERT target)
    await db.execute('''
      CREATE TABLE workbook_marks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workbook_id INTEGER NOT NULL,
        term_id INTEGER NOT NULL,
        student_id TEXT NOT NULL,
        component_id TEXT NOT NULL,
        marks TEXT NOT NULL,
        UNIQUE(workbook_id, term_id, student_id, component_id)
      )
    ''');

    // 7. Term Promotions
    await db.execute('''
      CREATE TABLE term_promotions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        term_id INTEGER NOT NULL,
        roll_no TEXT NOT NULL,
        subject_name TEXT NOT NULL,
        is_promoted INTEGER NOT NULL,
        FOREIGN KEY (term_id) REFERENCES terms (id) ON DELETE CASCADE
      )
    ''');
    
    // 8. Overall Promotions
    await db.execute('''
      CREATE TABLE overall_promotions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workbook_id INTEGER NOT NULL,
        roll_no TEXT NOT NULL,
        is_promoted INTEGER NOT NULL,
        FOREIGN KEY (workbook_id) REFERENCES workbooks (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Transactional safe upgrade path
    if (oldVersion < 3) {
      // Ensure backup or schema evolution rules apply here
      await db.execute('CREATE TABLE IF NOT EXISTS workbook_marks (id INTEGER PRIMARY KEY AUTOINCREMENT, workbook_id INTEGER NOT NULL, term_id INTEGER NOT NULL, student_id TEXT NOT NULL, component_id TEXT NOT NULL, marks TEXT NOT NULL, UNIQUE(workbook_id, term_id, student_id, component_id))');
    }
  }

  // Workbook Operations
  Future<int> createWorkbook(String title) async {
    final db = await database;
    return await db.insert('workbooks', {'title': title, 'created_at': DateTime.now().toIso8601String()});
  }

  Future<List<Map<String, dynamic>>> getWorkbooks() async {
    final db = await database;
    return await db.query('workbooks', orderBy: 'id DESC');
  }

  Future<void> updateWorkbookTitle(int workbookId, String newTitle) async {
    final db = await database;
    await db.update('workbooks', {'title': newTitle}, where: 'id = ?', whereArgs: [workbookId]);
  }

  Future<void> deleteWorkbook(int workbookId) async {
    final db = await database;
    await db.delete('workbooks', where: 'id = ?', whereArgs: [workbookId]);
  }

  // Full Data Loader for Workbook Dashboard
  Future<Map<String, dynamic>> loadFullWorkbookData(int workbookId) async {
    final db = await database;

    // Load Terms
    var termMaps = await db.query('terms', where: 'workbook_id = ?', whereArgs: [workbookId]);
    List<TermSetup> terms = termMaps.map((t) => TermSetup(id: t['id'] as int, name: t['name'] as String)).toList();

    // Load Subjects & Components
    var subMaps = await db.query('subjects', where: 'workbook_id = ?', whereArgs: [workbookId]);
    List<SubjectSetup> subjects = [];
    for (var s in subMaps) {
      int subId = s['id'] as int;
      var compMaps = await db.query('subject_components', where: 'subject_id = ?', whereArgs: [subId]);
      List<SubjectComponent> comps = compMaps.map((c) => SubjectComponent(
        name: c['name'] as String,
        maxMarks: c['max_marks'] as double,
        passingMarks: c['passing_marks'] as double,
      )).toList();

      subjects.add(SubjectSetup(
        name: s['name'] as String,
        maxMarks: s['max_marks'] as double,
        passingMarks: s['passing_marks'] as double,
        includeInPassFail: (s['include_in_pass_fail'] as int) == 1,
        themeColor: Color(s['theme_color'] as int),
        components: comps,
      ));
    }

    // Load Students & Marks
    var studMaps = await db.query('students', where: 'workbook_id = ?', whereArgs: [workbookId]);
    List<StudentRow> students = [];

    for (var st in studMaps) {
      String rollNo = st['roll_no'] as String;
      String name = st['name'] as String;

      Map<int, Map<String, String>> termMarks = {};
      Map<int, Map<String, bool>> termPromotions = {};
      bool isPromotedOverall = false;

      // Overall promotions check
      var opMaps = await db.query('overall_promotions', where: 'workbook_id = ? AND roll_no = ?', whereArgs: [workbookId, rollNo]);
      if (opMaps.isNotEmpty) {
        isPromotedOverall = (opMaps.first['is_promoted'] as int) == 1;
      }

      for (var term in terms) {
        termMarks[term.id] = {};
        termPromotions[term.id] = {};

        // Fetch marks from unified term-aware workbook_marks table
        var markMaps = await db.query('workbook_marks', 
          where: 'workbook_id = ? AND term_id = ? AND student_id = ?', 
          whereArgs: [workbookId, term.id, rollNo]
        );
        for (var m in markMaps) {
          termMarks[term.id]![m['component_id'] as String] = m['marks'] as String;
        }

        // Fetch term promotions
        var promoMaps = await db.query('term_promotions', where: 'term_id = ? AND roll_no = ?', whereArgs: [term.id, rollNo]);
        for (var p in promoMaps) {
          termPromotions[term.id]![p['subject_name'] as String] = (p['is_promoted'] as int) == 1;
        }
      }

      students.add(StudentRow(
        rollNo: rollNo,
        name: name,
        termMarks: termMarks,
        termPromotions: termPromotions,
        isPromotedOverall: isPromotedOverall,
      ));
    }

    return {
      'terms': terms,
      'subjects': subjects,
      'students': students,
    };
  }

  // Unified Term-Aware Mark Upsert (The Data-Entry backbone)
  Future<void> saveTermMark({
    required int workbookId,
    required int termId,
    required String rollNo,
    required String componentId,
    required String marks,
  }) async {
    final db = await database;
    await db.rawInsert('''
      INSERT INTO workbook_marks (workbook_id, term_id, student_id, component_id, marks)
      VALUES (?, ?, ?, ?, ?)
      ON CONFLICT(workbook_id, term_id, student_id, component_id) 
      DO UPDATE SET marks = excluded.marks
    ''', [workbookId, termId, rollNo, componentId, marks]);
  }

  // Term management
  Future<int> createTerm(int workbookId, String name) async {
    final db = await database;
    return await db.insert('terms', {'workbook_id': workbookId, 'name': name});
  }

  Future<void> updateTermName(int termId, String newName) async {
    final db = await database;
    await db.update('terms', {'name': newName}, where: 'id = ?', whereArgs: [termId]);
  }

  Future<void> deleteTerm(int termId) async {
    final db = await database;
    await db.delete('terms', where: 'id = ?', whereArgs: [termId]);
  }

  // Student CRUD
  Future<void> insertLiveStudent(int workbookId, String rollNo, String name) async {
    final db = await database;
    await db.insert('students', {'workbook_id': workbookId, 'roll_no': rollNo, 'name': name}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateLiveStudentInfo(int workbookId, String oldRollNo, String newRollNo, String name) async {
    final db = await database;
    await db.update('students', {'roll_no': newRollNo, 'name': name}, where: 'workbook_id = ? AND roll_no = ?', whereArgs: [workbookId, oldRollNo]);
  }

  Future<void> deleteLiveStudent(int workbookId, String rollNo) async {
    final db = await database;
    await db.delete('students', where: 'workbook_id = ? AND roll_no = ?', whereArgs: [workbookId, rollNo]);
  }

  // Subject Setup Configuration
  Future<void> updateWorkbookSubjects(int workbookId, List<SubjectSetup> subjects) async {
    final db = await database;
    await db.transaction((txn) async {
      // Clear old subjects and components for this workbook
      var oldSubs = await txn.query('subjects', where: 'workbook_id = ?', whereArgs: [workbookId]);
      for (var sub in oldSubs) {
        await txn.delete('subject_components', where: 'subject_id = ?', whereArgs: [sub['id']]);
      }
      await txn.delete('subjects', where: 'workbook_id = ?', whereArgs: [workbookId]);

      // Insert new subjects & components
      for (var sub in subjects) {
        int subId = await txn.insert('subjects', {
          'workbook_id': workbookId,
          'name': sub.name,
          'max_marks': sub.maxMarks,
          'passing_marks': sub.passingMarks,
          'include_in_pass_fail': sub.includeInPassFail ? 1 : 0,
          'theme_color': sub.themeColor.value,
        });

        for (var comp in sub.components) {
          await txn.insert('subject_components', {
            'subject_id': subId,
            'name': comp.name,
            'max_marks': comp.maxMarks,
            'passing_marks': comp.passingMarks,
          });
        }
      }
    });
  }

  // Promotion toggles
  Future<void> toggleSubjectPromotion(int termId, String rollNo, String subjectName, bool isPromoted) async {
    final db = await database;
    var existing = await db.query('term_promotions', where: 'term_id = ? AND roll_no = ? AND subject_name = ?', whereArgs: [termId, rollNo, subjectName]);
    if (existing.isNotEmpty) {
      await db.update('term_promotions', {'is_promoted': isPromoted ? 1 : 0}, where: 'id = ?', whereArgs: [existing.first['id']]);
    } else {
      await db.insert('term_promotions', {'term_id': termId, 'roll_no': rollNo, 'subject_name': subjectName, 'is_promoted': isPromoted ? 1 : 0});
    }
  }

  Future<void> updateStudentOverallPromotion(int workbookId, String rollNo, bool isPromoted) async {
    final db = await database;
    var existing = await db.query('overall_promotions', where: 'workbook_id = ? AND roll_no = ?', whereArgs: [workbookId, rollNo]);
    if (existing.isNotEmpty) {
      await db.update('overall_promotions', {'is_promoted': isPromoted ? 1 : 0}, where: 'id = ?', whereArgs: [existing.first['id']]);
    } else {
      await db.insert('overall_promotions', {'workbook_id': workbookId, 'roll_no': rollNo, 'is_promoted': isPromoted ? 1 : 0});
    }
  }
}
