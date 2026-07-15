from server import calculate_summary


def test_calculate_summary_respects_subject_include_flags():
    payload = {
        "settings": {"max_marks": 100, "pass_marks": 33, "remark_rules": [{"min": 50, "remark": "Good"}, {"min": 0, "remark": "Needs Work"}]},
        "subjects": [
            {"id": 1, "name": "English", "max_marks": 100, "pass_marks": 33, "include_in_pass_fail": 1, "include_in_percentage": 1},
            {"id": 2, "name": "Drawing", "max_marks": 50, "pass_marks": 20, "include_in_pass_fail": 0, "include_in_percentage": 0},
            {"id": 3, "name": "Science", "max_marks": 100, "pass_marks": 33, "include_in_pass_fail": 1, "include_in_percentage": 1},
        ],
        "students": [{"id": 1, "roll_no": "1", "name": "Asha"}],
        "marks": [
            {"student_id": 1, "subject_id": 1, "marks": 40},
            {"student_id": 1, "subject_id": 2, "marks": 50},
            {"student_id": 1, "subject_id": 3, "marks": 20},
        ],
    }

    row = calculate_summary(payload)[0]

    assert row["subjects"] == {"English": 40.0, "Drawing": 50.0, "Science": 20.0}
    assert row["grand_total"] == 60.0
    assert row["maximum_marks"] == 200.0
    assert row["percentage"] == 30.0
    assert row["result"] == "FAIL"
    assert row["remarks"] == "Needs Work"
