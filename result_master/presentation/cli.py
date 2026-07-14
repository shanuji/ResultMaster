from __future__ import annotations

from result_master.application import BasicDetails, ResultWorkbookWizard, WizardDraft
from result_master.domain import PassCriterionType, Student
from result_master.infrastructure import SQLiteWorkbookRepository


def run_new_result_wizard(database_path: str = "result_master.sqlite3") -> None:
    repository = SQLiteWorkbookRepository(database_path)
    wizard = ResultWorkbookWizard(repository)
    draft = WizardDraft()

    print("Step 1 - Basic Details")
    draft = wizard.set_basic_details(
        draft,
        BasicDetails(
            academic_year=input("Academic Year: "),
            class_name=input("Class: "),
            section=input("Section: "),
            examination_name=input("Examination Name: "),
        ),
    )

    print("Step 2 - Student Source")
    source = input("Choose source: 1) Create a New Student List 2) Import from an Existing Class Register: ")
    if source.strip() == "2":
        registers = repository.list_class_registers()
        for register in registers:
            print(f"{register.id}: {register.academic_year} Class {register.class_name}-{register.section}")
        draft = wizard.import_class_register(draft, int(input("Register ID: ")))
    else:
        students: list[Student] = []
        print("Enter students. Leave name blank when finished.")
        while True:
            name = input("Student Name: ").strip()
            if not name:
                break
            roll_number = input("Roll Number (optional): ").strip() or None
            students.append(Student(name=name, roll_number=roll_number))
        draft = wizard.create_new_student_list(draft, students)

    print("Step 3 - Subject Setup")
    while True:
        action = input("Action: add, rename, delete, reorder, done: ").strip().lower()
        if action == "done":
            break
        if action == "add":
            name = input("Subject Name: ")
            component_count = int(input("How many assessment components? "))
            components = [input(f"Component {index + 1} Name: ") for index in range(component_count)]
            draft = wizard.add_subject(draft, name, components)
        elif action == "rename":
            draft = wizard.rename_subject(draft, input("Current Subject Name: "), input("New Subject Name: "))
        elif action == "delete":
            draft = wizard.delete_subject(draft, input("Subject Name: "))
        elif action == "reorder":
            draft = wizard.reorder_subject(draft, input("Subject Name: "), int(input("New Position (1-based): ")) - 1)

    print("Step 4 - Pass / Fail")
    subject_names = [name.strip() for name in input("Pass/fail subjects (comma-separated): ").split(",") if name.strip()]
    criterion = input("Pass Marks or Pass Percentage? (marks/percentage): ").strip().lower()
    criterion_type = PassCriterionType.PERCENTAGE if criterion.startswith("p") else PassCriterionType.MARKS
    draft = wizard.set_pass_criteria(draft, subject_names, criterion_type, float(input("Pass Value: ")))

    print("Step 5 - Confirmation")
    for key, value in wizard.summarize(draft).items():
        print(f"{key}: {value}")
    if input("Create Workbook? (yes/no): ").strip().lower() == "yes":
        workbook = wizard.create_workbook(draft)
        print(f"Workbook created with ID {workbook.id}.")


if __name__ == "__main__":
    run_new_result_wizard()
