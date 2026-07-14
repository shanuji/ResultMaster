# ResultMaster

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
