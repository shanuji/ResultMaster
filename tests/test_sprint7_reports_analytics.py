import server


def payload():
    return {
        "settings": {"max_marks": 100, "pass_marks": 33, "distinction_percentage": 75, "remark_rules": [{"min": 0, "remark": "OK"}], "score_bands": [{"min": 80, "label": "A"}, {"min": 0, "label": "B"}]},
        "subjects": [
            {"id": 1, "name": "English", "max_marks": 100, "pass_marks": 33, "include_in_pass_fail": 1, "include_in_percentage": 1},
            {"id": 2, "name": "Math", "max_marks": 100, "pass_marks": 33, "include_in_pass_fail": 1, "include_in_percentage": 1},
        ],
        "students": [{"id": 1, "roll_no": "1", "name": "Asha"}, {"id": 2, "roll_no": "2", "name": "Bala"}],
        "marks": [
            {"student_id": 1, "subject_id": 1, "marks": 90}, {"student_id": 1, "subject_id": 2, "marks": 80},
            {"student_id": 2, "subject_id": 1, "marks": 30}, {"student_id": 2, "subject_id": 2, "marks": 40},
        ],
    }


def test_analytics_payload_contains_sprint7_metrics():
    analytics = server.analytics_payload(payload())

    assert analytics["grade_distribution"] == {"A": 1, "B": 1}
    assert analytics["pass_percentage"] == 50
    assert analytics["overall_class_performance"] == 60
    assert analytics["highest_marks"] == 170
    assert analytics["lowest_marks"] == 70
    assert analytics["subject_averages"][0]["average"] == 60


def test_reports_payload_builds_topper_pass_fail_and_merit_lists(monkeypatch):
    monkeypatch.setattr(server, "workbook_payload", payload)

    reports = server.reports_payload(q="asha", sort_by="percentage", direction="desc")

    assert reports["pass_fail_analysis"] == {"pass": 1, "fail": 0}
    assert reports["topper_list"][0]["student_name"] == "Asha"
    assert reports["merit_list"][0]["percentage"] == 85
    assert reports["subject_report"][0]["subject"] == "English"
