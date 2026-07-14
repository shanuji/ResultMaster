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

## Sprint 3 – Result Workbook Wizard

Sprint 3 adds the complete **New Result** workflow:

- A **New Result** action launches a five-step workbook wizard.
- Step 1 captures basic details: Academic Year, Class, Section, and Examination Name.
- Step 2 supports creating a new student list or using an existing Class Register; register imports preserve roll numbers in the persistence layer.
- Step 3 supports adding, renaming, deleting, and reordering subjects, plus multiple assessment components per subject.
- Every subject automatically receives a read-only **TOTAL** component persisted with `is_total = 1` and `is_editable = 0`.
- Step 4 stores pass criteria for selected subjects as pass marks or pass percentage metadata without calculating pass/fail.
- Step 5 displays a confirmation summary and supports Back or Create Workbook.
- Workbook creation automatically persists subject tabs, a Summary tab, and a Final tab with placeholder table JSON.
- SQLite persistence follows Clean Architecture with domain entities/use cases, repository contracts, and a SQLite data implementation.

## Development

```bash
flutter pub get
flutter test
```
## Sprint 3 - Result Workbook Wizard

ResultMaster now includes a complete New Result Wizard implemented with Clean Architecture layers:

- `result_master/domain`: workbook, subject, student, pass-criteria, and register entities.
- `result_master/application`: wizard use case and validation rules.
- `result_master/infrastructure`: SQLite persistence for class registers and generated result workbooks.
- `result_master/presentation`: command-line wizard entry point.

### Wizard Flow

1. **Basic Details** - collects mandatory Academic Year, Class, Section, and Examination Name.
2. **Student Source** - creates a new student list or imports a saved class register. Imported students are copied into the workbook so later workbook edits do not modify the original register.
3. **Subject Setup** - supports adding, renaming, deleting, and reordering subjects. Each subject stores one or more assessment components and automatically includes a non-editable `TOTAL` column.
4. **Pass / Fail** - stores the selected pass/fail subjects and either pass marks or pass percentage. No pass/fail calculations are performed yet.
5. **Confirmation** - shows the configured details, student source, student count, subjects, components, and pass criteria before creating the workbook.

Creating a workbook automatically stores placeholder sheet names for every subject plus `Summary` and `Final` tabs in SQLite.

## Run the Wizard

```bash
python -m result_master.presentation.cli
```

By default, data is saved to `result_master.sqlite3` in the current directory.

## Run Tests

```bash
python -m pytest
```
## Sprint 4: Excel-like Marks Entry Workbook

ResultMaster now includes a local workbook-style marks entry screen that keeps the existing Excel-inspired layout and saves every edit immediately to SQLite.

### Workbook tabs

When the workbook opens, the sheet tabs appear in this order:

1. English
2. Hindi
3. Mathematics
4. Science
5. SST
6. Summary
7. Final

The Summary and Final sheets are placeholders only. Their calculations are intentionally not implemented yet.

### Subject sheets

Each subject tab displays a spreadsheet with:

- Frozen header row.
- Frozen first three columns: `S.No.`, `Roll No.`, and `Student Name`.
- Assessment columns: `FA1`, `Notebook`, `Project`, and `Half Yearly`.
- Automatic read-only `TOTAL` column.
- Alternating row colours and thin Excel-like borders.
- Smooth horizontal and vertical scrolling for larger datasets.

### Marks entry and validation

- Tap or click any editable mark cell to enter marks directly.
- Accepted mark values are `0` through `100` or `AB` for absent.
- Invalid marks, negative marks, and marks above the maximum are rejected.
- `TOTAL` recalculates immediately after a mark changes and cannot be edited directly.
- `AB` is stored as an absent mark.

### Student editing

The workbook supports immediate autosaved edits for:

- Insert Student.
- Delete Student.
- Edit Student Name.
- Edit Roll Number.

Serial numbers are maintained automatically after inserts and deletes. Duplicate roll numbers are not allowed.

### Search

Use the search box for instant filtering by:

- Roll Number.
- Student Name.

### Autosave and persistence

Every student and mark edit is immediately saved to `resultmaster.sqlite3` using SQLite. Reopening the workbook restores saved students and marks.

## Run locally

Requires Python 3. No third-party packages are needed.

```bash
python3 app.py
```

Open <http://127.0.0.1:8000> in a browser.

To store the SQLite database somewhere else:

```bash
RESULTMASTER_DB=/path/to/resultmaster.sqlite3 python3 app.py
```
Offline School Result Management App with an Excel-like marks entry interface, SQLite autosave, and a calculated Summary sheet.

## Running locally

```bash
python3 server.py
```

Open <http://127.0.0.1:8000> in a browser. The app creates `resultmaster.sqlite3` automatically on first run.

## Sprint 5 features

- **Summary sheet:** one row per student with S.No., Roll No., Student Name, subject TOTAL columns, Grand Total, Percentage, Result, Rank, and Remarks.
- **Automatic calculation:** changing any subject mark immediately recalculates subject totals, Grand Total, Percentage, Result, Rank, and Remarks without a Save button.
- **SQLite autosave:** every mark and settings change is posted to the local server and saved in SQLite immediately; reopening the workbook restores the saved data.
- **Pass/fail criteria:** the Result column uses the workbook pass marks setting. A student passes only when every subject satisfies the pass rule.
- **Percentage:** calculated from total marks and rounded to two decimal places.
- **Rank:** calculated by Grand Total with competition ranking (`1, 2, 2, 4`) for ties.
- **Configurable remarks:** percentage thresholds are editable in Settings and autosaved.
- **Search:** Summary can be searched by Roll Number or Student Name.
- **Sorting:** Summary supports Roll Number, Student Name, Grand Total, Rank, and Percentage sorting.
- **Export:** Summary exports to an `.xlsx` file with a frozen header row and workbook-like table formatting.
- **Final sheet:** intentionally left as a placeholder for a later sprint.

## Project notes

`PROJECT_SPEC.md` was requested for Sprint 5 implementation but is not present in this repository snapshot. The implementation follows the Sprint 5 requirements from the task prompt.
