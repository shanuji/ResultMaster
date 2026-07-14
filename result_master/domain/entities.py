from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum


class StudentSourceType(str, Enum):
    NEW_LIST = "new_list"
    CLASS_REGISTER = "class_register"


class PassCriterionType(str, Enum):
    MARKS = "marks"
    PERCENTAGE = "percentage"


@dataclass(frozen=True)
class Student:
    name: str
    roll_number: str | None = None


@dataclass(frozen=True)
class ClassRegister:
    id: int | None
    academic_year: str
    class_name: str
    section: str
    students: tuple[Student, ...]


@dataclass(frozen=True)
class AssessmentComponent:
    name: str


@dataclass(frozen=True)
class Subject:
    name: str
    components: tuple[AssessmentComponent, ...]

    @property
    def columns(self) -> tuple[str, ...]:
        return tuple(component.name for component in self.components) + ("TOTAL",)


@dataclass(frozen=True)
class PassCriteria:
    subject_names: tuple[str, ...]
    criterion_type: PassCriterionType
    value: float


@dataclass(frozen=True)
class Workbook:
    id: int | None
    academic_year: str
    class_name: str
    section: str
    examination_name: str
    student_source_type: StudentSourceType
    source_register_id: int | None
    students: tuple[Student, ...]
    subjects: tuple[Subject, ...]
    pass_criteria: PassCriteria
    sheets: tuple[str, ...] = field(default_factory=tuple)
