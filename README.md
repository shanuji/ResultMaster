# ResultMaster

Offline School Result Management App.

## Sprint 2 Progress – Class Register Module

Implemented the Class Register module using the project's Clean Architecture split:

- Dashboard tile for opening **Class Registers**.
- Register management: create, open/select, rename, and delete with confirmation.
- Student management with roll number and student name while keeping the `Student.metadata` model future-proof for additional fields.
- Excel-inspired student table with frozen header row, alternating row colours, and thin grid lines.
- Add, edit, delete, and live search by roll number or student name.
- SQLite persistence for registers and students, including a per-register unique roll-number constraint.
- Excel `.xlsx` import/export codec with required `Roll Number` and `Student Name` headers and exported `S.No.`, `Roll Number`, `Student Name` layout.
- Unit tests for practical validation rules.

## Development

Install Flutter dependencies and run tests:

```bash
flutter pub get
flutter test
```
