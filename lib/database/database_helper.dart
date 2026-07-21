
import 'dart:convert';
import 'dart:io';
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
    return await openDatabase(
      path, 
      version: 2, 
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE workbooks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workbook_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        max_marks REAL NOT NULL,
        passing_marks REAL NOT NULL,
        include_in_pass_fail INTEGER NOT NULL,
        theme_color INTEGER NOT NULL,
        components_json TEXT,
        require_pass_per_component INTEGER DEFAULT 0,
        FOREIGN KEY (workbook_id) REFERENCES workbooks (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workbook_id INTEGER NOT NULL,
        roll_no TEXT NOT NULL,
        name TEXT NOT NULL,
        remarks TEXT,
        FOREIGN KEY (workbook_id) REFERENCES workbooks (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE student_marks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workbook_id INTEGER NOT NULL,
        roll_no TEXT NOT NULL,
        mark_key TEXT NOT NULL,
        mark_value TEXT NOT NULL,
        FOREIGN KEY (workbook_id) REFERENCES workbooks (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE subjects ADD COLUMN require_pass_per_component INTEGER DEFAULT 0');
    }
  }

  Future<void> restoreDatabaseFile(File backupFile) async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'result_master.db');
    await backupFile.copy(path);
    _database = await _initDB('result_master.db');
  }

  Future<List<Map<String, dynamic>>> fetchAllWorkbooks() async {
    final db = await instance.database;
    return await db.query('workbooks', orderBy: 'id DESC');
  }

  Future<int> createWorkbook(String title, List<SubjectSetup> subjects) async {
    final db = await instance.database;
    int workbookId = await db.insert('workbooks', {
      'title': title.isEmpty ? 'Untitled Workbook' : title,
      'created_at': DateTime.now().toIso8601String(),
    });

    for (var sub in subjects) {
      List<Map<String, dynamic>> comps = sub.components.map((c) => {'name': c.name, 'maxMarks': c.maxMarks, 'passingMarks': c.passingMarks}).toList();
      await db.insert('subjects', {
        'workbook_id': workbookId,
        'name': sub.name,
        'max_marks': sub.maxMarks,
        'passing_marks': sub.passingMarks,
        'include_in_pass_fail': sub.includeInPassFail ? 1 : 0,
        'require_pass_per_component': sub.requirePassPerComponent ? 1 : 0,
        'theme_color': sub.themeColor.value,
        'components_json': jsonEncode(comps),
      });
    }

    for (int i = 0; i < 3; i++) {
      await db.insert('students', {
        'workbook_id': workbookId,
        'roll_no': (i + 1).toString(),
        'name': '', 
        'remarks': '',
      });
    }
    return workbookId;
  }

  Future<void> updateWorkbookSetup(int workbookId, String newTitle, List<SubjectSetup> newSubjects) async {
    final db = await instance.database;
    await db.update('workbooks', {'title': newTitle}, where: 'id = ?', whereArgs: [workbookId]);
    await db.delete('subjects', where: 'workbook_id = ?', whereArgs: [workbookId]);
    for (var sub in newSubjects) {
      List<Map<String, dynamic>> comps = sub.components.map((c) => {'name': c.name, 'maxMarks': c.maxMarks, 'passingMarks': c.passingMarks}).toList();
      await db.insert('subjects', {
        'workbook_id': workbookId,
        'name': sub.name,
        'max_marks': sub.maxMarks,
        'passing_marks': sub.passingMarks,
        'include_in_pass_fail': sub.includeInPassFail ? 1 : 0,
        'require_pass_per_component': sub.requirePassPerComponent ? 1 : 0,
        'theme_color': sub.themeColor.value,
        'components_json': jsonEncode(comps),
      });
    }
  }

  Future<void> deleteWorkbook(int id) async {
    final db = await instance.database;
    await db.delete('workbooks', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>> loadWorkbookData(int workbookId) async {
    final db = await instance.database;
    final subMaps = await db.query('subjects', where: 'workbook_id = ?', whereArgs: [workbookId]);
    List<SubjectSetup> subjects = subMaps.map((map) {
      var sub = SubjectSetup(
        name: map['name'] as String,
        maxMarks: map['max_marks'] as double,
        passingMarks: map['passing_marks'] as double,
        includeInPassFail: (map['include_in_pass_fail'] as int) == 1,
        requirePassPerComponent: (map['require_pass_per_component'] as int?) == 1,
        themeColor: Color(map['theme_color'] as int),
      );
      if (map['components_json'] != null) {
        List dynamicList = jsonDecode(map['components_json'] as String);
        sub.components = dynamicList.map((c) => SubjectComponent(
          name: c['name'], 
          maxMarks: (c['maxMarks'] as num).toDouble(),
          passingMarks: (c['passingMarks'] as num?)?.toDouble() ?? 0.0,
        )).toList();
      }
      return sub;
    }).toList();

    final studMaps = await db.query('students', where: 'workbook_id = ?', whereArgs: [workbookId], orderBy: 'CAST(roll_no AS INTEGER) ASC, roll_no ASC');
    final markMaps = await db.query('student_marks', where: 'workbook_id = ?', whereArgs: [workbookId]);
    
    Map<String, Map<String, String>> structuralMarks = {};
    for (var m in markMaps) {
      String roll = m['roll_no'] as String;
      String key = m['mark_key'] as String;
      String val = m['mark_value'] as String;
      if (!structuralMarks.containsKey(roll)) structuralMarks[roll] = {};
      structuralMarks[roll]![key] = val;
    }

    List<StudentRow> students = studMaps.map((map) {
      String roll = map['roll_no'] as String;
      return StudentRow(
        rollNo: roll,
        name: map['name'] as String,
        remarks: map['remarks'] as String? ?? "",
        marks: structuralMarks[roll] ?? {},
      );
    }).toList();

    return {'subjects': subjects, 'students': students};
  }

  Future<void> saveLiveMark({required int workbookId, required String rollNo, required String markKey, required String value}) async {
    final db = await instance.database;
    await db.delete('student_marks', where: 'workbook_id = ? AND roll_no = ? AND mark_key = ?', whereArgs: [workbookId, rollNo, markKey]);
    if (value.isNotEmpty) {
      await db.insert('student_marks', {'workbook_id': workbookId, 'roll_no': rollNo, 'mark_key': markKey, 'mark_value': value});
    }
  }

  Future<void> insertLiveStudent(int workbookId, String rollNo, String name) async {
    final db = await instance.database;
    await db.insert('students', {'workbook_id': workbookId, 'roll_no': rollNo, 'name': name, 'remarks': ''});
  }

  Future<void> deleteLiveStudent(int workbookId, String rollNo) async {
    final db = await instance.database;
    await db.delete('students', where: 'workbook_id = ? AND roll_no = ?', whereArgs: [workbookId, rollNo]);
    await db.delete('student_marks', where: 'workbook_id = ? AND roll_no = ?', whereArgs: [workbookId, rollNo]);
  }

  Future<void> clearAllStudents(int workbookId) async {
    final db = await instance.database;
    await db.delete('students', where: 'workbook_id = ?', whereArgs: [workbookId]);
    await db.delete('student_marks', where: 'workbook_id = ?', whereArgs: [workbookId]);
  }

  Future<void> updateLiveStudentInfo(int workbookId, String oldRollNo, String newRollNo, String name) async {
    final db = await instance.database;
    await db.update('students', {'roll_no': newRollNo, 'name': name}, where: 'workbook_id = ? AND roll_no = ?', whereArgs: [workbookId, oldRollNo]);
    if (oldRollNo != newRollNo) {
      await db.update('student_marks', {'roll_no': newRollNo}, where: 'workbook_id = ? AND roll_no = ?', whereArgs: [workbookId, oldRollNo]);
    }
  }
}
