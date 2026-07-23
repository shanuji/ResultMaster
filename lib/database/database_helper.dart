import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
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
    final path = p.join(dbPath, filePath);
    return await openDatabase(path, version: 4, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('CREATE TABLE workbooks (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, created_at TEXT NOT NULL)');
    await db.execute('CREATE TABLE terms (id INTEGER PRIMARY KEY AUTOINCREMENT, workbook_id INTEGER NOT NULL, name TEXT NOT NULL, FOREIGN KEY (workbook_id) REFERENCES workbooks (id) ON DELETE CASCADE)');
    await db.execute('''CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT, workbook_id INTEGER NOT NULL, name TEXT NOT NULL,
        max_marks REAL NOT NULL, passing_marks REAL NOT NULL, include_in_pass_fail INTEGER NOT NULL,
        theme_color INTEGER NOT NULL, components_json TEXT, require_pass_per_component INTEGER DEFAULT 0,
        FOREIGN KEY (workbook_id) REFERENCES workbooks (id) ON DELETE CASCADE)''');
    await db.execute('''CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT, workbook_id INTEGER NOT NULL, roll_no TEXT NOT NULL,
        name TEXT NOT NULL, is_promoted_overall INTEGER DEFAULT 0,
        FOREIGN KEY (workbook_id) REFERENCES workbooks (id) ON DELETE CASCADE)''');
    await db.execute('''CREATE TABLE student_marks (
        id INTEGER PRIMARY KEY AUTOINCREMENT, term_id INTEGER NOT NULL, roll_no TEXT NOT NULL,
        mark_key TEXT NOT NULL, mark_value TEXT NOT NULL, is_promoted INTEGER DEFAULT 0,
        FOREIGN KEY (term_id) REFERENCES terms (id) ON DELETE CASCADE)''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      await db.execute('DROP TABLE IF EXISTS student_marks'); await db.execute('DROP TABLE IF EXISTS students');
      await db.execute('DROP TABLE IF EXISTS subjects'); await db.execute('DROP TABLE IF EXISTS terms');
      await db.execute('DROP TABLE IF EXISTS workbooks'); await _createDB(db, newVersion);
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllWorkbooks() async {
    final db = await instance.database; return await db.query('workbooks', orderBy: 'id DESC');
  }
  Future<int> createWorkbook(String title) async {
    final db = await instance.database; return await db.insert('workbooks', {'title': title.isEmpty ? 'Untitled Workbook' : title, 'created_at': DateTime.now().toIso8601String()});
  }
  Future<void> deleteWorkbook(int id) async {
    final db = await instance.database; await db.delete('workbooks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertLiveStudent(int workbookId, String rollNo, String name) async {
    final db = await instance.database; await db.insert('students', {'workbook_id': workbookId, 'roll_no': rollNo, 'name': name, 'is_promoted_overall': 0});
  }
  Future<void> deleteLiveStudent(int workbookId, String rollNo) async {
    final db = await instance.database;
    await db.delete('students', where: 'workbook_id = ? AND roll_no = ?', whereArgs: [workbookId, rollNo]);
    await db.rawDelete('DELETE FROM student_marks WHERE roll_no = ? AND term_id IN (SELECT id FROM terms WHERE workbook_id = ?)', [rollNo, workbookId]);
  }
  Future<void> updateLiveStudentInfo(int workbookId, String oldRollNo, String newRollNo, String name) async {
    final db = await instance.database;
    await db.update('students', {'roll_no': newRollNo, 'name': name}, where: 'workbook_id = ? AND roll_no = ?', whereArgs: [workbookId, oldRollNo]);
    if (oldRollNo != newRollNo) {
      await db.rawUpdate('UPDATE student_marks SET roll_no = ? WHERE roll_no = ? AND term_id IN (SELECT id FROM terms WHERE workbook_id = ?)', [newRollNo, oldRollNo, workbookId]);
    }
  }
  Future<void> updateStudentOverallPromotion(int workbookId, String rollNo, bool isPromoted) async {
    final db = await instance.database; await db.update('students', {'is_promoted_overall': isPromoted ? 1 : 0}, where: 'workbook_id = ? AND roll_no = ?', whereArgs: [workbookId, rollNo]);
  }

  Future<int> createTerm(int workbookId, String termName) async {
    final db = await instance.database; return await db.insert('terms', {'workbook_id': workbookId, 'name': termName});
  }
  Future<void> deleteTerm(int termId) async {
    final db = await instance.database; await db.delete('terms', where: 'id = ?', whereArgs: [termId]);
  }

  Future<void> updateWorkbookSubjects(int workbookId, List<SubjectSetup> subjects) async {
    final db = await instance.database;
    await db.delete('subjects', where: 'workbook_id = ?', whereArgs: [workbookId]);
    for (var sub in subjects) {
      List<Map<String, dynamic>> comps = sub.components.map((c) => {'name': c.name, 'maxMarks': c.maxMarks, 'passingMarks': c.passingMarks}).toList();
      await db.insert('subjects', {
        'workbook_id': workbookId, 'name': sub.name, 'max_marks': sub.maxMarks, 'passing_marks': sub.passingMarks,
        'include_in_pass_fail': sub.includeInPassFail ? 1 : 0, 'require_pass_per_component': 0,
        'theme_color': sub.themeColor.value, 'components_json': jsonEncode(comps),
      });
    }
  }

  Future<Map<String, dynamic>> loadFullWorkbookData(int workbookId) async {
    final db = await instance.database;
    
    final subMaps = await db.query('subjects', where: 'workbook_id = ?', whereArgs: [workbookId]);
    List<SubjectSetup> subjects = subMaps.map((map) {
      var sub = SubjectSetup(
        id: map['id'] as int, workbookId: workbookId, name: map['name'] as String, maxMarks: map['max_marks'] as double,
        passingMarks: map['passing_marks'] as double, includeInPassFail: (map['include_in_pass_fail'] as int) == 1,
        themeColor: Color(map['theme_color'] as int),
      );
      if (map['components_json'] != null) {
        List dynamicList = jsonDecode(map['components_json'] as String);
        sub.components = dynamicList.map((c) => SubjectComponent(name: c['name'], maxMarks: (c['maxMarks'] as num).toDouble(), passingMarks: (c['passingMarks'] as num?)?.toDouble() ?? 0.0)).toList();
      }
      return sub;
    }).toList();

    final termMaps = await db.query('terms', where: 'workbook_id = ?', whereArgs: [workbookId]);
    List<TermSetup> terms = termMaps.map((t) => TermSetup(id: t['id'] as int, workbookId: workbookId, name: t['name'] as String)).toList();

    final studMaps = await db.query('students', where: 'workbook_id = ?', whereArgs: [workbookId], orderBy: 'CAST(roll_no AS INTEGER) ASC, roll_no ASC');
    List<StudentRow> students = studMaps.map((map) => StudentRow(rollNo: map['roll_no'] as String, name: map['name'] as String, isPromotedOverall: (map['is_promoted_overall'] as int) == 1)).toList();

    for (var term in terms) {
      final markMaps = await db.query('student_marks', where: 'term_id = ?', whereArgs: [term.id]);
      for (var m in markMaps) {
        String roll = m['roll_no'] as String; String key = m['mark_key'] as String;
        var student = students.firstWhere((s) => s.rollNo == roll, orElse: () => StudentRow(rollNo: '', name: ''));
        if (student.rollNo.isNotEmpty) {
          if (!student.termMarks.containsKey(term.id)) { student.termMarks[term.id] = {}; student.termPromotions[term.id] = {}; }
          student.termMarks[term.id]![key] = m['mark_value'] as String;
          student.termPromotions[term.id]![key] = (m['is_promoted'] as int) == 1;
        }
      }
    }
    return {'terms': terms, 'students': students, 'subjects': subjects};
  }

  Future<void> saveLiveMark({required int termId, required String rollNo, required String markKey, required String value}) async {
    final db = await instance.database;
    await db.rawUpdate('UPDATE student_marks SET mark_value = ? WHERE term_id = ? AND roll_no = ? AND mark_key = ?', [value, termId, rollNo, markKey]);
    var changes = await db.rawQuery('SELECT changes() AS c');
    if (changes.first['c'] == 0 && value.isNotEmpty) {
      await db.insert('student_marks', {'term_id': termId, 'roll_no': rollNo, 'mark_key': markKey, 'mark_value': value, 'is_promoted': 0});
    }
  }

  Future<void> toggleSubjectPromotion(int termId, String rollNo, String markKey, bool isPromoted) async {
    final db = await instance.database;
    await db.rawUpdate('UPDATE student_marks SET is_promoted = ? WHERE term_id = ? AND roll_no = ? AND mark_key = ?', [isPromoted ? 1 : 0, termId, rollNo, markKey]);
    var changes = await db.rawQuery('SELECT changes() AS c');
    if (changes.first['c'] == 0) {
      await db.insert('student_marks', {'term_id': termId, 'roll_no': rollNo, 'mark_key': markKey, 'mark_value': '', 'is_promoted': isPromoted ? 1 : 0});
    }
  }
}
