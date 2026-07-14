from result_master.application import BasicDetails, ResultWorkbookWizard, WizardDraft
from result_master.domain import ClassRegister, PassCriterionType, Student, StudentSourceType
from result_master.infrastructure import SQLiteWorkbookRepository


def test_wizard_creates_workbook_with_tabs_and_total_columns(tmp_path):
    repository = SQLiteWorkbookRepository(tmp_path / "result_master.sqlite3")
    register = repository.save_class_register(
        ClassRegister(
            id=None,
            academic_year="2026-2027",
            class_name="6",
            section="A",
            students=(Student("Asha", "1"), Student("Bimal", "2")),
        )
    )
    wizard = ResultWorkbookWizard(repository)
    draft = WizardDraft()

    draft = wizard.set_basic_details(draft, BasicDetails("2026-2027", "6", "A", "Half Yearly"))
    draft = wizard.import_class_register(draft, register.id or 0)
    draft = wizard.add_subject(draft, "English", ["Written Test"])
    draft = wizard.add_subject(draft, "Science", ["FA", "Notebook", "Project", "Half Yearly"])
    draft = wizard.rename_subject(draft, "English", "English Language")
    draft = wizard.reorder_subject(draft, "Science", 0)
    draft = wizard.set_pass_criteria(draft, ["Science", "English Language"], PassCriterionType.MARKS, 33)

    workbook = wizard.create_workbook(draft)
    saved = repository.get_workbook(workbook.id or 0)

    assert saved.student_source_type == StudentSourceType.CLASS_REGISTER
    assert saved.source_register_id == register.id
    assert saved.students == register.students
    assert saved.subjects[0].name == "Science"
    assert saved.subjects[0].columns == ("FA", "Notebook", "Project", "Half Yearly", "TOTAL")
    assert saved.subjects[1].columns == ("Written Test", "TOTAL")
    assert saved.sheets == ("Science", "English Language", "Summary", "Final")
    assert saved.pass_criteria.subject_names == ("Science", "English Language")


def test_imported_students_are_copied_not_linked(tmp_path):
    repository = SQLiteWorkbookRepository(tmp_path / "result_master.sqlite3")
    register = repository.save_class_register(
        ClassRegister(None, "2026-2027", "7", "B", (Student("Original", "1"),))
    )
    wizard = ResultWorkbookWizard(repository)
    draft = wizard.import_class_register(WizardDraft(), register.id or 0)

    assert draft.students == (Student("Original", "1"),)
    assert draft.students is not register.students


def test_basic_details_are_mandatory(tmp_path):
    wizard = ResultWorkbookWizard(SQLiteWorkbookRepository(tmp_path / "result_master.sqlite3"))

    try:
        wizard.set_basic_details(WizardDraft(), BasicDetails("", "6", "A", "Half Yearly"))
    except ValueError as error:
        assert "Academic Year" in str(error)
    else:
        raise AssertionError("Expected mandatory field validation")
