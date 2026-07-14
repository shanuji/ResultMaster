-- ResultMaster SQLite schema foundation for Sprint 2.
-- This file defines relationships only; business calculation logic is intentionally not implemented here.

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS class_registers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  class_name TEXT NOT NULL,
  section TEXT,
  academic_year TEXT NOT NULL,
  term_label TEXT,
  teacher_name TEXT,
  school_name TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  archived_at TEXT
);

CREATE TABLE IF NOT EXISTS students (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  class_register_id INTEGER NOT NULL,
  roll_no TEXT NOT NULL,
  admission_no TEXT,
  student_name TEXT NOT NULL,
  guardian_name TEXT,
  display_order INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (class_register_id) REFERENCES class_registers(id) ON DELETE CASCADE,
  UNIQUE (class_register_id, roll_no)
);

CREATE TABLE IF NOT EXISTS result_workbooks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  class_register_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  exam_label TEXT,
  status TEXT NOT NULL DEFAULT 'draft',
  autosave_enabled INTEGER NOT NULL DEFAULT 1,
  last_saved_at TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (class_register_id) REFERENCES class_registers(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS subjects (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  result_workbook_id INTEGER NOT NULL,
  subject_name TEXT NOT NULL,
  subject_code TEXT,
  display_order INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (result_workbook_id) REFERENCES result_workbooks(id) ON DELETE CASCADE,
  UNIQUE (result_workbook_id, subject_name)
);

CREATE TABLE IF NOT EXISTS subject_components (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  subject_id INTEGER NOT NULL,
  component_name TEXT NOT NULL,
  max_marks REAL NOT NULL DEFAULT 0,
  pass_marks REAL,
  display_order INTEGER NOT NULL DEFAULT 0,
  include_in_total INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE,
  UNIQUE (subject_id, component_name)
);

CREATE TABLE IF NOT EXISTS marks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  result_workbook_id INTEGER NOT NULL,
  student_id INTEGER NOT NULL,
  subject_id INTEGER NOT NULL,
  subject_component_id INTEGER NOT NULL,
  mark_value REAL,
  is_absent INTEGER NOT NULL DEFAULT 0,
  entered_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (result_workbook_id) REFERENCES result_workbooks(id) ON DELETE CASCADE,
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
  FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE,
  FOREIGN KEY (subject_component_id) REFERENCES subject_components(id) ON DELETE CASCADE,
  UNIQUE (result_workbook_id, student_id, subject_component_id),
  CHECK ((is_absent = 1 AND mark_value IS NULL) OR is_absent = 0)
);

CREATE TABLE IF NOT EXISTS teacher_notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  class_register_id INTEGER,
  result_workbook_id INTEGER,
  student_id INTEGER,
  subject_id INTEGER,
  mark_id INTEGER,
  note_text TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (class_register_id) REFERENCES class_registers(id) ON DELETE CASCADE,
  FOREIGN KEY (result_workbook_id) REFERENCES result_workbooks(id) ON DELETE CASCADE,
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
  FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE,
  FOREIGN KEY (mark_id) REFERENCES marks(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS templates (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  template_name TEXT NOT NULL UNIQUE,
  description TEXT,
  template_type TEXT NOT NULL DEFAULT 'workbook',
  template_json TEXT NOT NULL DEFAULT '{}',
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_students_class_register ON students(class_register_id);
CREATE INDEX IF NOT EXISTS idx_workbooks_class_register ON result_workbooks(class_register_id);
CREATE INDEX IF NOT EXISTS idx_subjects_workbook ON subjects(result_workbook_id);
CREATE INDEX IF NOT EXISTS idx_components_subject ON subject_components(subject_id);
CREATE INDEX IF NOT EXISTS idx_marks_lookup ON marks(result_workbook_id, student_id, subject_id, subject_component_id);
CREATE INDEX IF NOT EXISTS idx_teacher_notes_context ON teacher_notes(class_register_id, result_workbook_id, student_id, subject_id);
