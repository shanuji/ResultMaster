from __future__ import annotations

from dataclasses import dataclass, replace
from typing import Protocol

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


class WorkbookRepository(Protocol):
    def list_class_registers(self) -> list[ClassRegister]: ...
    def get_class_register(self, register_id: int) -> ClassRegister: ...
    def save_workbook(self, workbook: Workbook) -> Workbook: ...


@dataclass(frozen=True)
class BasicDetails:
    academic_year: str
    class_name: str
    section: str
    examination_name: str


@dataclass(frozen=True)
class WizardDraft:
    basic_details: BasicDetails | None = None
    student_source_type: StudentSourceType | None = None
    source_register_id: int | None = None
    students: tuple[Student, ...] = ()
    subjects: tuple[Subject, ...] = ()
    pass_criteria: PassCriteria | None = None


class ResultWorkbookWizard:
    def __init__(self, repository: WorkbookRepository):
        self.repository = repository

    def set_basic_details(self, draft: WizardDraft, details: BasicDetails) -> WizardDraft:
        for label, value in (
            ("Academic Year", details.academic_year),
            ("Class", details.class_name),
            ("Section", details.section),
            ("Examination Name", details.examination_name),
        ):
            if not value.strip():
                raise ValueError(f"{label} is mandatory.")
        return replace(draft, basic_details=details)

    def create_new_student_list(self, draft: WizardDraft, students: list[Student]) -> WizardDraft:
        return replace(
            draft,
            student_source_type=StudentSourceType.NEW_LIST,
            source_register_id=None,
            students=tuple(students),
        )

    def import_class_register(self, draft: WizardDraft, register_id: int) -> WizardDraft:
        register = self.repository.get_class_register(register_id)
        copied_students = tuple(Student(name=s.name, roll_number=s.roll_number) for s in register.students)
        return replace(
            draft,
            student_source_type=StudentSourceType.CLASS_REGISTER,
            source_register_id=register_id,
            students=copied_students,
        )

    def add_subject(self, draft: WizardDraft, name: str, component_names: list[str]) -> WizardDraft:
        subject = self._build_subject(name, component_names)
        if any(existing.name == subject.name for existing in draft.subjects):
            raise ValueError("Subject names must be unique.")
        return replace(draft, subjects=draft.subjects + (subject,))

    def rename_subject(self, draft: WizardDraft, old_name: str, new_name: str) -> WizardDraft:
        self._require_text("Subject", new_name)
        if any(subject.name == new_name for subject in draft.subjects if subject.name != old_name):
            raise ValueError("Subject names must be unique.")
        renamed = tuple(replace(subject, name=new_name) if subject.name == old_name else subject for subject in draft.subjects)
        if renamed == draft.subjects:
            raise ValueError("Subject not found.")
        return replace(draft, subjects=renamed)

    def delete_subject(self, draft: WizardDraft, name: str) -> WizardDraft:
        remaining = tuple(subject for subject in draft.subjects if subject.name != name)
        if len(remaining) == len(draft.subjects):
            raise ValueError("Subject not found.")
        return replace(draft, subjects=remaining)

    def reorder_subject(self, draft: WizardDraft, name: str, new_index: int) -> WizardDraft:
        subjects = list(draft.subjects)
        matches = [i for i, subject in enumerate(subjects) if subject.name == name]
        if not matches:
            raise ValueError("Subject not found.")
        if new_index < 0 or new_index >= len(subjects):
            raise ValueError("Subject position is out of range.")
        subject = subjects.pop(matches[0])
        subjects.insert(new_index, subject)
        return replace(draft, subjects=tuple(subjects))

    def set_pass_criteria(
        self,
        draft: WizardDraft,
        subject_names: list[str],
        criterion_type: PassCriterionType,
        value: float,
    ) -> WizardDraft:
        if not subject_names:
            raise ValueError("Select at least one pass/fail subject.")
        available = {subject.name for subject in draft.subjects}
        missing = [name for name in subject_names if name not in available]
        if missing:
            raise ValueError(f"Unknown pass/fail subject: {', '.join(missing)}")
        if value < 0:
            raise ValueError("Pass criterion value cannot be negative.")
        return replace(draft, pass_criteria=PassCriteria(tuple(subject_names), criterion_type, value))

    def summarize(self, draft: WizardDraft) -> dict[str, object]:
        self._validate_ready_to_create(draft)
        assert draft.basic_details and draft.student_source_type and draft.pass_criteria
        return {
            "academic_year": draft.basic_details.academic_year,
            "class": draft.basic_details.class_name,
            "section": draft.basic_details.section,
            "exam": draft.basic_details.examination_name,
            "student_source": draft.student_source_type.value,
            "number_of_students": len(draft.students),
            "subjects": [(subject.name, subject.columns) for subject in draft.subjects],
            "pass_criteria": draft.pass_criteria,
        }

    def create_workbook(self, draft: WizardDraft) -> Workbook:
        self._validate_ready_to_create(draft)
        assert draft.basic_details and draft.student_source_type and draft.pass_criteria
        sheets = tuple(subject.name for subject in draft.subjects) + ("Summary", "Final")
        workbook = Workbook(
            id=None,
            academic_year=draft.basic_details.academic_year,
            class_name=draft.basic_details.class_name,
            section=draft.basic_details.section,
            examination_name=draft.basic_details.examination_name,
            student_source_type=draft.student_source_type,
            source_register_id=draft.source_register_id,
            students=draft.students,
            subjects=draft.subjects,
            pass_criteria=draft.pass_criteria,
            sheets=sheets,
        )
        return self.repository.save_workbook(workbook)

    def _validate_ready_to_create(self, draft: WizardDraft) -> None:
        if draft.basic_details is None:
            raise ValueError("Basic details are required.")
        if draft.student_source_type is None:
            raise ValueError("Student source is required.")
        if not draft.subjects:
            raise ValueError("At least one subject is required.")
        if draft.pass_criteria is None:
            raise ValueError("Pass criteria are required.")

    def _build_subject(self, name: str, component_names: list[str]) -> Subject:
        self._require_text("Subject", name)
        if not component_names:
            raise ValueError("At least one assessment component is required.")
        components = []
        for component_name in component_names:
            self._require_text("Component", component_name)
            components.append(AssessmentComponent(component_name.strip()))
        return Subject(name.strip(), tuple(components))

    def _require_text(self, label: str, value: str) -> None:
        if not value.strip():
            raise ValueError(f"{label} is mandatory.")
