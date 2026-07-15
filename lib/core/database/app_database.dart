import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final dbPath = await getDatabasesPath();
    _database = await openDatabase(
      p.join(dbPath, 'result_master.db'),
      version: 1,
      onCreate: _create,
    );
    return _database!;
  }

  Future<void> _create(Database db, int version) async {
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
    await db.execute('''
      CREATE TABLE workbooks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        academic_year TEXT NOT NULL,
        class_name TEXT NOT NULL,
        section TEXT NOT NULL,
        examination_name TEXT NOT NULL,
        student_source_type TEXT NOT NULL,
        class_register_id INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE workbook_students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workbook_id INTEGER NOT NULL,
        roll_number INTEGER NOT NULL,
        student_name TEXT NOT NULL,
        FOREIGN KEY(workbook_id) REFERENCES workbooks(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE workbook_subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workbook_id INTEGER NOT NULL,
        subject_name TEXT NOT NULL,
        display_order INTEGER NOT NULL,
        FOREIGN KEY(workbook_id) REFERENCES workbooks(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE subject_components (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        component_name TEXT NOT NULL,
        display_order INTEGER NOT NULL,
        is_total INTEGER NOT NULL DEFAULT 0,
        is_editable INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY(subject_id) REFERENCES workbook_subjects(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE pass_criteria (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workbook_id INTEGER NOT NULL,
        subject_name TEXT NOT NULL,
        pass_marks REAL,
        pass_percentage REAL,
        FOREIGN KEY(workbook_id) REFERENCES workbooks(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE workbook_tabs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workbook_id INTEGER NOT NULL,
        tab_name TEXT NOT NULL,
        tab_type TEXT NOT NULL,
        display_order INTEGER NOT NULL,
        placeholder_json TEXT NOT NULL,
        FOREIGN KEY(workbook_id) REFERENCES workbooks(id)
      )
    ''');
  }
}
