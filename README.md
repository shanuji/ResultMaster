# ResultMaster

ResultMaster is an offline-first school result management app for preparing class results in a familiar Excel-inspired workspace.

## Project Purpose

ResultMaster helps teachers and school administrators create, manage, validate, export, and back up result workbooks without depending on a continuous internet connection. The product direction is defined in [`PROJECT_SPEC.md`](PROJECT_SPEC.md), which is the single source of truth for future development.

## Architecture

Current Sprint 1 foundation:

- **Static dashboard foundation:** `src/index.html` contains the initial productivity dashboard with six primary actions.
- **Theme foundation:** `src/styles/theme.css` defines the Excel-inspired visual system: yellow headers, white sheet background, light grey alternate rows, thin grid lines, and minimal shadows.
- **SQLite schema foundation:** `database/schema.sql` defines core entities and relationships for future Sprint 2 data work.
- **Project specification:** `PROJECT_SPEC.md` documents product behavior, modules, data expectations, UI philosophy, and future constraints.

No business calculation logic is implemented yet.

## Folder Structure

```text
ResultMaster/
├── PROJECT_SPEC.md          # Product specification and source of truth
├── README.md                # Project overview and development notes
├── database/
│   └── schema.sql           # SQLite schema foundation
└── src/
    ├── index.html           # Dashboard foundation
    └── styles/
        └── theme.css        # Excel-inspired theme foundation
```

## How to Run

This repository currently contains a static Sprint 1 foundation. Open the dashboard directly in a browser:

```bash
python3 -m http.server 8000 -d src
```

Then visit:

```text
http://localhost:8000
```

To validate the SQLite schema manually:

```bash
sqlite3 /tmp/resultmaster.db < database/schema.sql
```

## Current Sprint Status

### Sprint 1: Foundation Review and Cleanup

Completed:

- Added `PROJECT_SPEC.md` as the single source of truth.
- Replaced promotional dashboard direction with a clean six-card productivity dashboard.
- Added Excel-inspired theme tokens and sheet table styles.
- Added SQLite schema foundation for class registers, students, result workbooks, subjects, subject components, marks, teacher notes, and templates.
- Updated documentation with project purpose, architecture, folder structure, run instructions, sprint status, and roadmap.

Not implemented yet:

- Business calculations.
- Mark entry logic.
- Summary and final sheet calculations.
- Excel export generation.
- Backup execution workflow.
- Search implementation.
- Autosave implementation.

## Future Sprint Roadmap

### Sprint 2: Data and Workbook Foundations

- Wire SQLite schema into the application runtime.
- Add CRUD flows for class registers and student registers.
- Add workbook creation/opening foundation.
- Add dynamic subject and assessment component setup screens.
- Prepare autosave plumbing without final calculations.

### Sprint 3: Mark Entry Workbook

- Implement Excel-like mark entry grid.
- Freeze header row and identity columns: `S.No.`, `Roll No.`, and `Name`.
- Support absent display as `A` while storing calculation-safe state.
- Add workbook search and teacher notes surfaces.

### Sprint 4: Validation and Criteria

- Add configurable validation rules.
- Add dynamic pass/fail criteria support.
- Add workbook completeness checks.

### Sprint 5: Summary, Final Sheet, and Export

- Implement summary sheet calculations.
- Implement final sheet review layout.
- Add Excel-compatible export preserving workbook layout and frozen panes.

### Sprint 6: Templates, Backup, and Settings

- Add reusable workbook templates.
- Add local backup workflow.
- Add application settings and defaults.
