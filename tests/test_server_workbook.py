import io
import zipfile

import server


def test_summary_uses_subject_configuration_flags():
    payload = {
        "settings": {"max_marks": 100, "pass_marks": 33, "remark_rules": [{"min": 0, "remark": "OK"}]},
        "subjects": [
            {"id": 1, "name": "English", "maximum_marks": 50, "passing_marks": 20, "include_in_pass_fail": 1, "include_in_percentage": 1},
            {"id": 2, "name": "Art", "maximum_marks": 100, "passing_marks": 80, "include_in_pass_fail": 0, "include_in_percentage": 0},
        ],
        "students": [{"id": 10, "roll_no": "1", "name": "Asha"}],
        "marks": [
            {"student_id": 10, "subject_id": 1, "marks": 25},
            {"student_id": 10, "subject_id": 2, "marks": 10},
        ],
    }

    [row] = server.calculate_summary(payload)

    assert row["grand_total"] == 25
    assert row["maximum_marks"] == 50
    assert row["percentage"] == 50
    assert row["result"] == "PASS"


def test_summary_export_is_valid_xlsx_with_dynamic_final_headers(tmp_path, monkeypatch):
    monkeypatch.setattr(server, "DB", tmp_path / "resultmaster.sqlite3")
    server.init_db()

    workbook = zipfile.ZipFile(io.BytesIO(server.xlsx_bytes()))
    sheet_xml = workbook.read("xl/worksheets/sheet1.xml").decode()

    assert "Total Marks" in sheet_xml
    assert "Maximum Marks" in sheet_xml
    assert "Pass / Fail" in sheet_xml
    assert "English" in sheet_xml
