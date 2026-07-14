# ResultMaster Project Specification

ResultMaster is an offline-first school result management application.

## Product Principles
- Keep all core workflows available without internet access.
- Store durable app data locally in SQLite.
- Keep business rules out of widgets and screens.
- Prefer simple, fast interactions over decorative motion.

## Architecture
Use Clean Architecture boundaries:
- `domain`: entities, value objects, repository contracts, and validation rules.
- `application`: use cases and orchestration.
- `data`: SQLite-backed implementations, DTO mapping, and import/export adapters.
- `presentation`: screens, controllers, widgets, and routing.

## UI Theme
The app uses an Excel-inspired theme:
- White and pale green surfaces.
- Dark green primary headers.
- Thin grey grid lines.
- Spreadsheet-like tables with frozen headers.
- Alternating row colours.
- Minimal animations.

## Current Sprint
Sprint 2 delivers the Class Register module for creating registers, maintaining students, and importing/exporting Excel files.
