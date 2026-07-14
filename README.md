# ResultMaster

Offline School Result Management App.

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
