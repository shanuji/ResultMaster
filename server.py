#!/usr/bin/env python3
"""ResultMaster local server with SQLite autosave and Summary export."""
from __future__ import annotations

import json
import sqlite3
import zipfile
from datetime import datetime
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from io import BytesIO
from pathlib import Path
from urllib.parse import urlparse
from xml.sax.saxutils import escape

ROOT = Path(__file__).resolve().parent
DB = ROOT / "resultmaster.sqlite3"

DEFAULT_REMARK_RULES = [
    {"min": 90, "remark": "Excellent"},
    {"min": 75, "remark": "Very Good"},
    {"min": 60, "remark": "Good"},
    {"min": 40, "remark": "Average"},
    {"min": 0, "remark": "Needs Improvement"},
]
DEFAULT_SUBJECTS = ["English", "Hindi", "Mathematics", "Science", "SST"]


def db() -> sqlite3.Connection:
    con = sqlite3.connect(DB)
    con.row_factory = sqlite3.Row
    return con


def init_db() -> None:
    with db() as con:
        con.executescript(
            """
            CREATE TABLE IF NOT EXISTS workbook (
                id INTEGER PRIMARY KEY CHECK (id = 1),
                pass_marks REAL NOT NULL DEFAULT 33,
                max_marks REAL NOT NULL DEFAULT 100,
                remark_rules TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS subjects (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL UNIQUE,
                sort_order INTEGER NOT NULL,
                maximum_marks REAL NOT NULL DEFAULT 100,
                passing_marks REAL NOT NULL DEFAULT 33,
                include_in_pass_fail INTEGER NOT NULL DEFAULT 1,
                include_in_percentage INTEGER NOT NULL DEFAULT 1
            );
            CREATE TABLE IF NOT EXISTS students (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                roll_no TEXT NOT NULL UNIQUE,
                name TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS marks (
                student_id INTEGER NOT NULL,
                subject_id INTEGER NOT NULL,
                marks REAL NOT NULL DEFAULT 0,
                PRIMARY KEY (student_id, subject_id),
                FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
                FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE
            );
            """
        )
        con.execute(
            "INSERT OR IGNORE INTO workbook (id, pass_marks, max_marks, remark_rules) VALUES (1, 33, 100, ?)",
            (json.dumps(DEFAULT_REMARK_RULES),),
        )
        for column, definition in {
            "maximum_marks": "REAL NOT NULL DEFAULT 100",
            "passing_marks": "REAL NOT NULL DEFAULT 33",
            "include_in_pass_fail": "INTEGER NOT NULL DEFAULT 1",
            "include_in_percentage": "INTEGER NOT NULL DEFAULT 1",
        }.items():
            if column not in [row[1] for row in con.execute("PRAGMA table_info(subjects)")]:
                con.execute(f"ALTER TABLE subjects ADD COLUMN {column} {definition}")
        if con.execute("SELECT COUNT(*) FROM subjects").fetchone()[0] == 0:
            con.executemany(
                "INSERT INTO subjects (name, sort_order, maximum_marks, passing_marks, include_in_pass_fail, include_in_percentage) VALUES (?, ?, 100, 33, 1, 1)",
                [(name, i) for i, name in enumerate(DEFAULT_SUBJECTS)],
            )
        if con.execute("SELECT COUNT(*) FROM students").fetchone()[0] == 0:
            con.executemany(
                "INSERT INTO students (roll_no, name) VALUES (?, ?)",
                [("101", "Aarav Sharma"), ("102", "Isha Verma"), ("103", "Kabir Singh")],
            )
        ensure_mark_rows(con)


def ensure_mark_rows(con: sqlite3.Connection) -> None:
    con.execute(
        """
        INSERT OR IGNORE INTO marks (student_id, subject_id, marks)
        SELECT students.id, subjects.id, 0 FROM students CROSS JOIN subjects
        """
    )


def workbook_payload() -> dict:
    with db() as con:
        ensure_mark_rows(con)
        settings = dict(con.execute("SELECT * FROM workbook WHERE id = 1").fetchone())
        settings["remark_rules"] = json.loads(settings["remark_rules"])
        subjects = [dict(r) for r in con.execute("SELECT id, name, maximum_marks, passing_marks, include_in_pass_fail, include_in_percentage FROM subjects ORDER BY sort_order, id")]
        students = [dict(r) for r in con.execute("SELECT id, roll_no, name FROM students ORDER BY CAST(roll_no AS INTEGER), roll_no")]
        marks = [dict(r) for r in con.execute("SELECT student_id, subject_id, marks FROM marks")]
    return {"settings": settings, "subjects": subjects, "students": students, "marks": marks}


def calculate_summary(payload: dict) -> list[dict]:
    subjects = payload["subjects"]
    settings = payload["settings"]
    max_total = sum(float(s.get("maximum_marks") or settings["max_marks"] or 0) for s in subjects if int(s.get("include_in_percentage", 1)))
    mark_map = {(m["student_id"], m["subject_id"]): float(m["marks"] or 0) for m in payload["marks"]}
    rows = []
    for idx, student in enumerate(payload["students"], start=1):
        subject_totals = {s["name"]: mark_map.get((student["id"], s["id"]), 0) for s in subjects}
        grand_total = sum(subject_totals[s["name"]] for s in subjects if int(s.get("include_in_percentage", 1)))
        percentage = round((grand_total / max_total * 100) if max_total else 0, 2)
        passed = all(subject_totals[s["name"]] >= float(s.get("passing_marks") or settings["pass_marks"] or 0) for s in subjects if int(s.get("include_in_pass_fail", 1)))
        rows.append({"student_id": student["id"], "sno": idx, "roll_no": student["roll_no"], "student_name": student["name"], "subjects": subject_totals, "grand_total": grand_total, "maximum_marks": max_total, "percentage": percentage, "result": "PASS" if passed else "FAIL", "rank": 0, "remarks": remark_for(percentage, settings["remark_rules"])})
    ranked = sorted(rows, key=lambda r: (-r["grand_total"], r["student_name"]))
    previous_total = None
    previous_rank = 0
    for pos, row in enumerate(ranked, start=1):
        if previous_total is None or row["grand_total"] != previous_total:
            previous_rank = pos
            previous_total = row["grand_total"]
        row["rank"] = previous_rank
    return rows


def remark_for(percentage: float, rules: list[dict]) -> str:
    for rule in sorted(rules, key=lambda r: float(r.get("min", 0)), reverse=True):
        if percentage >= float(rule.get("min", 0)):
            return str(rule.get("remark", ""))
    return ""


def xlsx_bytes() -> bytes:
    payload = workbook_payload()
    rows = calculate_summary(payload)
    headers = ["S.No.", "Roll No.", "Student Name", *[s["name"] for s in payload["subjects"]], "Total Marks", "Maximum Marks", "Percentage", "Pass / Fail", "Rank", "Remarks"]
    table = [headers]
    for r in rows:
        table.append([r["sno"], r["roll_no"], r["student_name"], *[r["subjects"][s["name"]] for s in payload["subjects"]], r["grand_total"], r["maximum_marks"], r["percentage"], r["result"], r["rank"], r["remarks"]])
    sheet_rows = []
    for ridx, row in enumerate(table, 1):
        cells = []
        for cidx, value in enumerate(row, 1):
            ref = f"{col_name(cidx)}{ridx}"
            if isinstance(value, (int, float)):
                cells.append(f'<c r="{ref}" s="{1 if ridx == 1 else 0}"><v>{value}</v></c>')
            else:
                cells.append(f'<c r="{ref}" t="inlineStr" s="{1 if ridx == 1 else 0}"><is><t>{escape(str(value))}</t></is></c>')
        sheet_rows.append(f'<row r="{ridx}">{"".join(cells)}</row>')
    sheet = '<?xml version="1.0" encoding="UTF-8"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews><sheetData>' + ''.join(sheet_rows) + '</sheetData></worksheet>'
    buf = BytesIO()
    with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("[Content_Types].xml", '<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/><Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/></Types>')
        z.writestr("_rels/.rels", '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>')
        z.writestr("xl/workbook.xml", '<?xml version="1.0" encoding="UTF-8"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="Summary" sheetId="1" r:id="rId1"/></sheets></workbook>')
        z.writestr("xl/_rels/workbook.xml.rels", '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>')
        z.writestr("xl/styles.xml", '<?xml version="1.0" encoding="UTF-8"?><styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><fonts count="2"><font/><font><b/></font></fonts><fills count="2"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill></fills><borders count="1"><border/></borders><cellStyleXfs count="1"><xf/></cellStyleXfs><cellXfs count="2"><xf fontId="0"/><xf fontId="1" applyFont="1"/></cellXfs></styleSheet>')
        z.writestr("xl/worksheets/sheet1.xml", sheet)
    return buf.getvalue()


def col_name(n: int) -> str:
    out = ""
    while n:
        n, rem = divmod(n - 1, 26)
        out = chr(65 + rem) + out
    return out


class Handler(SimpleHTTPRequestHandler):
    def do_GET(self):
        path = urlparse(self.path).path
        if path == "/api/workbook":
            self.json(workbook_payload())
        elif path == "/api/summary":
            self.json({"rows": calculate_summary(workbook_payload())})
        elif path == "/api/export/summary.xlsx":
            data = xlsx_bytes()
            self.send_response(200)
            self.send_header("Content-Type", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
            self.send_header("Content-Disposition", f'attachment; filename="summary-{datetime.now():%Y%m%d-%H%M%S}.xlsx"')
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
        else:
            super().do_GET()

    def do_POST(self):
        path = urlparse(self.path).path
        data = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))) or b"{}")
        with db() as con:
            if path == "/api/marks":
                subject = con.execute("SELECT maximum_marks FROM subjects WHERE id = ?", (data["subject_id"],)).fetchone()
                if subject is None:
                    self.error_json(400, "Invalid subject")
                    return
                marks = float(data["marks"] or 0)
                if marks < 0 or marks > float(subject["maximum_marks"]):
                    self.error_json(400, "Marks must be between 0 and the subject maximum")
                    return
                con.execute("INSERT INTO marks (student_id, subject_id, marks) VALUES (?, ?, ?) ON CONFLICT(student_id, subject_id) DO UPDATE SET marks = excluded.marks", (data["student_id"], data["subject_id"], marks))
            elif path == "/api/settings":
                con.execute("UPDATE workbook SET pass_marks = ?, max_marks = ?, remark_rules = ? WHERE id = 1", (data["pass_marks"], data["max_marks"], json.dumps(data["remark_rules"])))
            else:
                self.send_error(404)
                return
        self.json(workbook_payload())

    def error_json(self, status: int, message: str) -> None:
        data = json.dumps({"error": message}).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def json(self, obj: dict) -> None:
        data = json.dumps(obj).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


if __name__ == "__main__":
    init_db()
    print("ResultMaster running at http://127.0.0.1:8000")
    ThreadingHTTPServer(("127.0.0.1", 8000), Handler).serve_forever()
