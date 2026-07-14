# ResultMaster Project Specification

ResultMaster is an offline-first school result management application for teachers and school administrators who need an Excel-like workspace for preparing, validating, reviewing, exporting, and backing up class results.

Future development **must always follow this document**. If implementation requirements conflict with this specification, update this document deliberately before changing product behavior.

## Purpose

ResultMaster helps schools create and manage result workbooks without requiring a constant internet connection. It should feel familiar to teachers who currently prepare results in spreadsheets, while adding structured registers, validation, reusable templates, notes, backup, and export support.

## Product Principles

- **Offline-first:** Core workflows must work locally using SQLite-backed storage. Network access must not be required for creating, editing, saving, searching, exporting, or backing up results.
- **Excel-inspired UI:** Result sheets should look and behave like a clean workbook: visible grid lines, row/column alignment, frozen headers, frozen identity columns, fast keyboard-friendly entry, and predictable spreadsheet-style navigation.
- **Foundation before business logic:** Sprint 1 and Sprint 2 foundations define data structures and UI surfaces only. Calculation rules and promotion/result business logic should be implemented in later sprints.
- **Dynamic configuration:** Subjects, assessment components, pass/fail rules, templates, and settings must be configurable instead of hard-coded.

## Core Modules

### Dashboard

The dashboard is a productivity landing page, not a promotional page. It must open quickly and show exactly six large action cards:

1. New Result
2. Open Result
3. Class Registers
4. Templates
5. Backup
6. Settings

The dashboard must not contain a decorative hero section, gradients, marketing copy, or heavy visual effects.

### Class Register

The Class Register stores class-level metadata such as class name, section, academic year, term/exam label, teacher, and school/session context. It is the parent record for student registers and result workbooks.

### Student Register

The Student Register stores students attached to a class register. It must support roll number, admission number, name, optional demographic metadata, active/inactive state, and display order.

### Result Workbooks

A Result Workbook belongs to a class register and represents a result preparation workspace for an exam, term, or reporting period. Workbooks contain subjects, components, marks, teacher notes, summary sheet data, final sheet data, and export metadata.

### Dynamic Subjects

Subjects must be dynamic per workbook. Users must be able to define, order, enable, disable, and rename subjects without code changes.

### Dynamic Assessment Components

Each subject may contain multiple assessment components such as theory, practical, internal, oral, project, unit test, or custom components. Components must be dynamic and ordered. The system must support automatic subject `TOTAL` values from the configured components.

### Marks

Marks are recorded per workbook, student, subject, and assessment component. A mark can be numeric or absent. When a student is absent, the UI must display `A`, while calculations must treat the value as `0`.

### Summary Sheet

The Summary Sheet provides workbook-level and class-level summaries such as totals, percentages, grades, pass/fail counts, absentees, subject summaries, and validation status. Initial foundation work should reserve the module without implementing final business calculations.

### Final Sheet

The Final Sheet is the polished output sheet intended for final review and export. It must use the same source workbook data and should be compatible with Excel export requirements.

### Teacher Notes

Teachers can add notes at class, workbook, subject, student, or mark context. Notes are local-first records and should be searchable in future sprints.

### Templates

Templates store reusable class structures, subject sets, components, validation defaults, pass/fail criteria, and display preferences.

### Backup

The app must provide a backup module for exporting local data safely. Backup should support copying the SQLite database and future structured backup packages.

### Settings

Settings include application preferences, default academic year/session, grading preferences, export options, autosave interval, visual density, and validation defaults.

## Workbook UI Requirements

- Yellow header row matching the reference Excel workbook.
- White sheet background.
- Light grey alternate rows.
- Thin Excel-style grid lines.
- Minimal shadows.
- No gradients.
- No green workbook styling except success indicators.
- Frozen header row.
- Frozen `S.No.`, `Roll No.`, and `Name` columns.
- Multiple assessment components per subject.
- Automatic `TOTAL` column per subject when components exist.
- Fast search for students, roll numbers, subjects, notes, and workbook content.
- Auto save with visible save status.

## Validation Rules

Validation must be configurable and prepared for later implementation. Rules should support:

- Required student identity fields.
- Duplicate roll number checks within a class.
- Mark range checks against component maximum marks.
- Absent marker validation.
- Required subject/component definitions before mark entry.
- Workbook completeness checks before final export.
- Dynamic pass/fail criteria by class, subject, component, or template.

## Dynamic Pass/Fail Criteria

Pass/fail criteria must not be hard-coded. They should support future rules based on:

- Subject total minimum.
- Component-level minimum.
- Overall percentage.
- Required subjects.
- Optional/grace rules.
- Template-defined criteria.

## Excel Export Requirement

ResultMaster must export workbook data to Excel-compatible files. Exported workbooks must preserve the Excel-inspired layout, yellow headers, frozen panes, visible grid lines, summary sheet, final sheet, absent display values, and totals when business logic is implemented.

## Data Ownership

Local data belongs to the school/teacher using the application. The application should avoid remote dependencies for core operations and provide user-controlled backup/export mechanisms.
