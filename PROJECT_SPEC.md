# Project Spec

ResultMaster is an offline-first school result management app. Data must be stored locally and workflows should follow Clean Architecture boundaries between presentation, domain, data, and infrastructure.
# PROJECT SPEC

## Result Workbook Configuration

Each subject must have these configurable properties:

1. Subject Name
2. Maximum Marks
3. Passing Marks
4. Include in Pass/Fail (Yes/No)
5. Include in Percentage (Yes/No)
6. Assessment Components
7. Maximum Marks for each Assessment Component
8. TOTAL (Automatically calculated from assessment components)

## Final Sheet

The Final sheet must NEVER contain hardcoded subject names.

It must dynamically create one column for every subject configured while creating the workbook.

After the subject columns, generate:

- Total Marks
- Maximum Marks
- Percentage
- Pass / Fail
- Remarks

## Pass / Fail

Only subjects where Include in Pass/Fail = Yes must be considered.

## Total Marks

Only subjects where Include in Percentage = Yes must be included.

## Maximum Marks

Calculate only from subjects included in Percentage.

## Percentage

Percentage = Total Marks ÷ Maximum Marks × 100

## Remarks

Remarks should be generated using configurable remark rules.
