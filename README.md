# ResultMaster 1.0

ResultMaster is an offline-first school result management app with an Excel-like marks workbook, SQLite autosave, analytics, printable report cards, and local backup/restore. Version 1.0 is the first stable production release.

## Highlights

- Excel-style marks entry with frozen headers and student columns.
- Dynamic Summary and Final sheets with configured subject columns, total marks, maximum marks, percentage, pass/fail status, rank, and configurable remarks.
- Per-subject maximum marks, passing marks, pass/fail inclusion, and percentage inclusion rules that follow `PROJECT_SPEC.md`.
- A4 class and individual student report-card print preview.
- Exports for Students CSV, Marks CSV, Settings JSON, Excel `.xlsx`, PDF report cards, and complete SQLite backups.
- Application settings for light/dark/system theme, default export format, print metadata, school details, and autosave preference.
- Local-only data storage in `resultmaster.sqlite3` with SQLite foreign-key enforcement and restore integrity checks.
- Responsive UI, keyboard-accessible controls, loading indicators, success messages, and error dialogs.

## Requirements

### Python web app

- Python 3.10 or newer.
- No third-party Python dependencies are required for the local web app.

### Flutter modules and tests

The repository also contains Flutter/Dart modules used by earlier sprints. Install the stable Flutter SDK before running Flutter tests.

## Installation

```bash
git clone <repository-url>
cd ResultMaster
```

No package installation is required for the Python server. If you plan to run Flutter tests, install Flutter dependencies:

```bash
flutter pub get
```

## Running ResultMaster

Start the local server:

```bash
python3 server.py
```

Open <http://127.0.0.1:8000> in a browser. ResultMaster creates `resultmaster.sqlite3` on first launch and seeds sample subjects and students if the database is empty.

## Usage

1. Open the **Workbook** tab to enter marks. Each edit validates the configured subject maximum and autosaves to SQLite.
2. Use search (`Ctrl+/`) to find students by roll number or name.
3. Use **Analytics** for grade distribution, subject averages, highest/lowest marks, pass percentage, and class performance.
4. Use **Reports** for class/section reports, topper lists, merit lists, pass/fail analysis, and subject summaries.
5. Use **A4 Class Print** or **A4 Student Print** for printable report cards.
6. Open **Application, print & export setup** to configure:
   - Theme: System, Light, or Dark.
   - Default export: Excel or PDF.
   - Subject inclusion rules for pass/fail and percentage calculations.
   - School name, address, logo URL, header/footer text, page size, margins, class teacher, and principal.

## Backup and restore

### Create a backup

Use the **Backup DB** toolbar button or the **Download Backup** action in **Data Management**. This downloads a timestamped SQLite database file.

### Restore a backup

1. Base64-encode a previously downloaded `.sqlite3` backup.
2. Open **Data Management**.
3. Paste the base64 content into **Restore base64 SQLite backup**.
4. Click **Restore Database** and confirm.

Restore validates that the file is a SQLite database, runs an integrity check, applies current schema migrations, and then reloads the workbook.

## Import and export

The **Data Management** tab supports:

- Export Students CSV.
- Export Marks CSV.
- Export Settings JSON.
- Export Excel `.xlsx` summary/report workbook.
- Export PDF report-card file.
- Download complete SQLite backup.
- Import/bulk edit students with `roll_no,name` CSV.
- Import/bulk edit marks with `roll_no,name,subject,marks` CSV.

## Android release APK

The Android application is configured for the production package `com.resultmaster.app` and release signing through Gradle properties or environment variables. Create or provide a private keystore, then build the signed APK without committing secrets:

```bash
export RESULTMASTER_KEYSTORE=/absolute/path/resultmaster-release.jks
export RESULTMASTER_KEYSTORE_PASSWORD='<keystore-password>'
export RESULTMASTER_KEY_ALIAS='<key-alias>'
export RESULTMASTER_KEY_PASSWORD='<key-password>'
flutter pub get
flutter build apk --release
```

The generated release APK is written to `build/app/outputs/flutter-apk/app-release.apk`. Keep the keystore and passwords outside the repository; they are required for future Version 1.0 patch releases.

## Running tests and checks

```bash
python -m py_compile server.py
python -m pytest
flutter test
flutter build apk --release
```

`flutter test` and `flutter build apk --release` require Flutter and the Android build toolchain to be installed and available on `PATH`.

## Version 1.0 changelog

- Prepared RC-1 Android release signing configuration and documented the signed APK build flow.
- Renamed the generated Excel workbook sheet to the dynamic Final sheet required by `PROJECT_SPEC.md`.
- Tightened import validation so bulk mark imports use each configured subject maximum instead of a fixed cap.
- Hardened backup restore by requiring SQLite integrity checks to return `ok` before replacing local data.
- Removed an obsolete duplicate Android activity package and aligned the application id with the release package.

## Version 1.0 release notes

- Finalized production polish for Sprint 8 and the Version 1.0 release candidate.
- Aligned seeded workbook data, migration behavior, and settings persistence with the project specification subject configuration fields.
- Added application-level preferences for theme, autosave, and default export format.
- Improved responsive layout, dark mode support, focus styles, keyboard search, loading indicators, success toasts, and modal error handling.
- Hardened local data operations with JSON validation, numeric bounds checks, text sanitization, SQLite foreign keys, restore file validation, and restore integrity checks.
- Verified export endpoints for Excel, PDF, CSV, JSON settings, print preview, and database backups.
- Updated documentation for installation, usage, backup/restore, tests, and release readiness.

## Data privacy and security

ResultMaster is designed for local/offline use. Student records and marks remain in the local SQLite database unless a user explicitly exports or backs up data. Keep downloaded backups secure because they contain the complete local database.
