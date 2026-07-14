# ResultMaster

Offline School Result Management App.

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
