from __future__ import annotations

import json
import sqlite3
from pathlib import Path

from result_master.domain import (
    AssessmentComponent,
    ClassRegister,
    PassCriteria,
    PassCriterionType,
    Student,
    StudentSourceType,
    Subject,
    Workbook,
)


class SQLiteWorkbookRepository:
    def __init__(self, database_path: str | Path = "result_master.sqlite3"):
        self.database_path = Path(database_path)
        self._initialize()

    def list_class_registers(self) -> list[ClassRegister]:
        with self._connect() as connection:
            rows = connection.execute(
                "SELECT id, academic_year, class_name, section, students_json FROM class_registers ORDER BY academic_year, class_name, section"
            ).fetchall()
        return [self._class_register_from_row(row) for row in rows]

    def get_class_register(self, register_id: int) -> ClassRegister:
        with self._connect() as connection:
            row = connection.execute(
                "SELECT id, academic_year, class_name, section, students_json FROM class_registers WHERE id = ?",
                (register_id,),
            ).fetchone()
        if row is None:
            raise ValueError("Class register not found.")
        return self._class_register_from_row(row)

    def save_class_register(self, register: ClassRegister) -> ClassRegister:
        students_json = json.dumps([student.__dict__ for student in register.students])
        with self._connect() as connection:
            cursor = connection.execute(
                "INSERT INTO class_registers (academic_year, class_name, section, students_json) VALUES (?, ?, ?, ?)",
                (register.academic_year, register.class_name, register.section, students_json),
            )
            register_id = int(cursor.lastrowid)
        return ClassRegister(register_id, register.academic_year, register.class_name, register.section, register.students)

    def save_workbook(self, workbook: Workbook) -> Workbook:
        payload = self._workbook_payload(workbook)
        with self._connect() as connection:
            cursor = connection.execute(
                """
                INSERT INTO workbooks (
                    academic_year, class_name, section, examination_name, student_source_type,
                    source_register_id, students_json, subjects_json, pass_criteria_json, sheets_json
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    workbook.academic_year,
                    workbook.class_name,
                    workbook.section,
                    workbook.examination_name,
                    workbook.student_source_type.value,
                    workbook.source_register_id,
                    payload["students_json"],
                    payload["subjects_json"],
                    payload["pass_criteria_json"],
                    payload["sheets_json"],
                ),
            )
            workbook_id = int(cursor.lastrowid)
        return Workbook(**{**workbook.__dict__, "id": workbook_id})

    def get_workbook(self, workbook_id: int) -> Workbook:
        with self._connect() as connection:
            row = connection.execute("SELECT * FROM workbooks WHERE id = ?", (workbook_id,)).fetchone()
        if row is None:
            raise ValueError("Workbook not found.")
        return self._workbook_from_row(row)

    def _initialize(self) -> None:
        with self._connect() as connection:
            connection.execute(
                """
                CREATE TABLE IF NOT EXISTS class_registers (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    academic_year TEXT NOT NULL,
                    class_name TEXT NOT NULL,
                    section TEXT NOT NULL,
                    students_json TEXT NOT NULL
                )
                """
            )
            connection.execute(
                """
                CREATE TABLE IF NOT EXISTS workbooks (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    academic_year TEXT NOT NULL,
                    class_name TEXT NOT NULL,
                    section TEXT NOT NULL,
                    examination_name TEXT NOT NULL,
                    student_source_type TEXT NOT NULL,
                    source_register_id INTEGER,
                    students_json TEXT NOT NULL,
                    subjects_json TEXT NOT NULL,
                    pass_criteria_json TEXT NOT NULL,
                    sheets_json TEXT NOT NULL
                )
                """
            )

    def _connect(self) -> sqlite3.Connection:
        connection = sqlite3.connect(self.database_path)
        connection.row_factory = sqlite3.Row
        return connection

    def _class_register_from_row(self, row: sqlite3.Row) -> ClassRegister:
        students = tuple(Student(**student) for student in json.loads(row["students_json"]))
        return ClassRegister(row["id"], row["academic_year"], row["class_name"], row["section"], students)

    def _workbook_payload(self, workbook: Workbook) -> dict[str, str]:
        return {
            "students_json": json.dumps([student.__dict__ for student in workbook.students]),
            "subjects_json": json.dumps([
                {"name": subject.name, "components": [component.name for component in subject.components], "columns": subject.columns}
                for subject in workbook.subjects
            ]),
            "pass_criteria_json": json.dumps(
                {
                    "subject_names": workbook.pass_criteria.subject_names,
                    "criterion_type": workbook.pass_criteria.criterion_type.value,
                    "value": workbook.pass_criteria.value,
                }
            ),
            "sheets_json": json.dumps(workbook.sheets),
        }

    def _workbook_from_row(self, row: sqlite3.Row) -> Workbook:
        subjects = tuple(
            Subject(item["name"], tuple(AssessmentComponent(name) for name in item["components"]))
            for item in json.loads(row["subjects_json"])
        )
        criteria = json.loads(row["pass_criteria_json"])
        return Workbook(
            id=row["id"],
            academic_year=row["academic_year"],
            class_name=row["class_name"],
            section=row["section"],
            examination_name=row["examination_name"],
            student_source_type=StudentSourceType(row["student_source_type"]),
            source_register_id=row["source_register_id"],
            students=tuple(Student(**student) for student in json.loads(row["students_json"])),
            subjects=subjects,
            pass_criteria=PassCriteria(
                tuple(criteria["subject_names"]), PassCriterionType(criteria["criterion_type"]), criteria["value"]
            ),
            sheets=tuple(json.loads(row["sheets_json"])),
        )
