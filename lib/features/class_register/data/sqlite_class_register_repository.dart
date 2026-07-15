import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../domain/class_register.dart';
import '../domain/class_register_repository.dart';
import '../domain/student.dart';

class SqliteClassRegisterRepository implements ClassRegisterRepository {
  SqliteClassRegisterRepository._(this._db);
  final Database _db;

  static Future<SqliteClassRegisterRepository> open() async {
    final path = p.join(await getDatabasesPath(), 'result_master.db');
    final db = await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE class_registers(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE students(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          register_id INTEGER NOT NULL,
          roll_number TEXT NOT NULL,
          name TEXT NOT NULL,
          metadata TEXT NOT NULL DEFAULT '{}',
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY(register_id) REFERENCES class_registers(id) ON DELETE CASCADE,
          UNIQUE(register_id, roll_number COLLATE NOCASE)
        )
      ''');
      await db.execute('CREATE INDEX students_register_search_idx ON students(register_id, roll_number, name)');
    });
    return SqliteClassRegisterRepository._(db);
  }

  @override
  Future<List<ClassRegister>> watchRegisters() async {
    final rows = await _db.query('class_registers', orderBy: 'updated_at DESC');
    return rows.map(_registerFromRow).toList(growable: false);
  }

  @override
  Future<ClassRegister> createRegister(String name) async {
    final now = DateTime.now().toIso8601String();
    final id = await _db.insert('class_registers', {'name': name, 'created_at': now, 'updated_at': now});
    return ClassRegister(id: id, name: name, createdAt: DateTime.parse(now), updatedAt: DateTime.parse(now));
  }

  @override
  Future<void> renameRegister(int registerId, String name) => _db.update('class_registers', {
        'name': name,
        'updated_at': DateTime.now().toIso8601String(),
      }, where: 'id = ?', whereArgs: [registerId]);

  @override
  Future<void> deleteRegister(int registerId) => _db.delete('class_registers', where: 'id = ?', whereArgs: [registerId]);

  @override
  Future<List<Student>> students(int registerId, {String? rollQuery, String? nameQuery}) async {
    final where = StringBuffer('register_id = ?');
    final args = <Object?>[registerId];
    if (rollQuery != null && rollQuery.trim().isNotEmpty) {
      where.write(' AND roll_number LIKE ?');
      args.add('%${rollQuery.trim()}%');
    }
    if (nameQuery != null && nameQuery.trim().isNotEmpty) {
      where.write(' AND name LIKE ?');
      args.add('%${nameQuery.trim()}%');
    }
    final rows = await _db.query('students', where: where.toString(), whereArgs: args, orderBy: 'CAST(roll_number AS INTEGER), roll_number');
    return rows.map(_studentFromRow).toList(growable: false);
  }

  @override
  Future<Student> addStudent(Student student) async {
    final now = DateTime.now().toIso8601String();
    final id = await _db.insert('students', _studentToRow(student)..addAll({'created_at': now, 'updated_at': now}), conflictAlgorithm: ConflictAlgorithm.abort);
    return student.copyWith(id: id);
  }

  @override
  Future<void> updateStudent(Student student) => _db.update('students', _studentToRow(student)..['updated_at'] = DateTime.now().toIso8601String(), where: 'id = ?', whereArgs: [student.id]);

  @override
  Future<void> deleteStudent(int studentId) => _db.delete('students', where: 'id = ?', whereArgs: [studentId]);

  @override
  Future<void> appendStudents(int registerId, List<Student> students) async {
    await _db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      for (final student in students) {
        await txn.insert('students', _studentToRow(student.copyWith(registerId: registerId))..addAll({'created_at': now, 'updated_at': now}));
      }
      await txn.update('class_registers', {'updated_at': now}, where: 'id = ?', whereArgs: [registerId]);
    });
  }

  @override
  Future<void> replaceStudents(int registerId, List<Student> students) async {
    await _db.transaction((txn) async {
      await txn.delete('students', where: 'register_id = ?', whereArgs: [registerId]);
      final now = DateTime.now().toIso8601String();
      for (final student in students) {
        await txn.insert('students', _studentToRow(student.copyWith(registerId: registerId))..addAll({'created_at': now, 'updated_at': now}));
      }
      await txn.update('class_registers', {'updated_at': now}, where: 'id = ?', whereArgs: [registerId]);
    });
  }

  @override
  Future<void> appendStudents(int registerId, List<Student> students) async {
    await _db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      for (final student in students) {
        await txn.insert('students', _studentToRow(student.copyWith(registerId: registerId))..addAll({'created_at': now, 'updated_at': now}), conflictAlgorithm: ConflictAlgorithm.abort);
      }
    });
  }

  ClassRegister _registerFromRow(Map<String, Object?> row) => ClassRegister(id: row['id'] as int, name: row['name'] as String, createdAt: DateTime.parse(row['created_at'] as String), updatedAt: DateTime.parse(row['updated_at'] as String));
  Student _studentFromRow(Map<String, Object?> row) => Student(id: row['id'] as int, registerId: row['register_id'] as int, rollNumber: row['roll_number'] as String, name: row['name'] as String, metadata: Map<String, Object?>.from(jsonDecode(row['metadata'] as String) as Map));
  Map<String, Object?> _studentToRow(Student student) => {'register_id': student.registerId, 'roll_number': student.rollNumber, 'name': student.name, 'metadata': jsonEncode(student.metadata)};
}
