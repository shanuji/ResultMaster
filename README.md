# ResultMaster

Offline School Result Management App.

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
