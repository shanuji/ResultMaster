import 'dart:io';

import 'package:excel/excel.dart';

import '../domain/class_register_failure.dart';
import '../domain/student.dart';

class ExcelRegisterCodec {
  static const headers = ['S.No.', 'Roll Number', 'Student Name'];

  Future<ExcelRegisterWorkbook> inspectFile(File file) async {
    final bytes = await file.readAsBytes();
    final workbook = Excel.decodeBytes(bytes);
    final sheets = workbook.tables.entries
        .map((entry) => ExcelRegisterSheet(
              name: entry.key,
              columns: _columnsFor(entry.value),
            ))
        .where((sheet) => sheet.columns.isNotEmpty)
        .toList(growable: false);
    if (sheets.isEmpty) {
      throw const ClassRegisterFailure('Excel file does not contain any worksheets with columns.');
    }
    return ExcelRegisterWorkbook(file: file, sheets: sheets);
  }

  Future<ExcelRegisterImportPreview> previewImport({
    required File file,
    required String sheetName,
    required int rollNumberColumn,
    required int studentNameColumn,
    required int registerId,
  }) async {
    if (rollNumberColumn == studentNameColumn) {
      throw const ClassRegisterFailure('Roll Number and Student Name must use different columns.');
    }
    final bytes = await file.readAsBytes();
    final workbook = Excel.decodeBytes(bytes);
    final sheet = workbook.tables[sheetName];
    if (sheet == null) {
      throw ClassRegisterFailure('Worksheet "$sheetName" was not found.');
    }

    final students = <Student>[];
    final duplicateRollNumbers = <String>{};
    final seenRollNumbers = <String>{};
    var skipped = 0;

    for (final row in sheet.rows.skip(1)) {
      if (_isBlankRow(row)) {
        skipped++;
        continue;
      }
      final rollNumber = _valueAt(row, rollNumberColumn);
      final name = _valueAt(row, studentNameColumn);
      if (rollNumber.isEmpty && name.isEmpty) {
        skipped++;
        continue;
      }
      if (rollNumber.isEmpty || name.isEmpty) {
        skipped++;
        continue;
      }
      final normalizedRollNumber = rollNumber.toLowerCase();
      if (!seenRollNumbers.add(normalizedRollNumber)) {
        duplicateRollNumbers.add(rollNumber);
        skipped++;
        continue;
      }
      students.add(Student(registerId: registerId, rollNumber: rollNumber, name: name));
    }

    return ExcelRegisterImportPreview(
      students: students,
      skipped: skipped,
      duplicateRollNumbers: duplicateRollNumbers.toList(growable: false)..sort(),
    );
  }

  Future<List<Student>> importFile(File file, int registerId) async {
    final workbook = await inspectFile(file);
    final sheet = workbook.sheets.first;
    final rollIndex = sheet.columns.indexWhere((column) => column.header == 'Roll Number');
    final nameIndex = sheet.columns.indexWhere((column) => column.header == 'Student Name');
    if (rollIndex == -1 || nameIndex == -1) {
      throw const ClassRegisterFailure('Excel file must include Roll Number and Student Name headers.');
    }
    final preview = await previewImport(
      file: file,
      sheetName: sheet.name,
      rollNumberColumn: rollIndex,
      studentNameColumn: nameIndex,
      registerId: registerId,
    );
    if (preview.duplicateRollNumbers.isNotEmpty) {
      throw const ClassRegisterFailure('Import contains duplicate Roll Numbers.');
    }
    return preview.students;
  }

  Future<File> exportFile(File file, List<Student> students) async {
    final workbook = Excel.createExcel();
    final sheet = workbook['Register'];
    sheet.appendRow(headers.map(TextCellValue.new).toList());
    for (var i = 0; i < students.length; i++) {
      final student = students[i];
      sheet.appendRow([IntCellValue(i + 1), TextCellValue(student.rollNumber), TextCellValue(student.name)]);
    }
    await file.writeAsBytes(workbook.encode()!, flush: true);
    return file;
  }

  List<ExcelRegisterColumn> _columnsFor(Sheet sheet) {
    if (sheet.rows.isEmpty) return const <ExcelRegisterColumn>[];
    final headerRow = sheet.rows.first;
    final width = sheet.maxColumns > headerRow.length ? sheet.maxColumns : headerRow.length;
    return List.generate(width, (index) {
      final header = _valueAt(headerRow, index);
      return ExcelRegisterColumn(index: index, header: header.isEmpty ? 'Column ${index + 1}' : header);
    }, growable: false);
  }

  bool _isBlankRow(List<Data?> row) => row.every((cell) => (cell?.value.toString().trim() ?? '').isEmpty);

  String _valueAt(List<Data?> row, int index) => index < row.length ? row[index]?.value.toString().trim() ?? '' : '';
}

class ExcelRegisterWorkbook {
  const ExcelRegisterWorkbook({required this.file, required this.sheets});

  final File file;
  final List<ExcelRegisterSheet> sheets;
}

class ExcelRegisterSheet {
  const ExcelRegisterSheet({required this.name, required this.columns});

  final String name;
  final List<ExcelRegisterColumn> columns;
}

class ExcelRegisterColumn {
  const ExcelRegisterColumn({required this.index, required this.header});

  final int index;
  final String header;

  String get label => '${index + 1}. $header';
}

class ExcelRegisterImportPreview {
  const ExcelRegisterImportPreview({
    required this.students,
    required this.skipped,
    required this.duplicateRollNumbers,
  });

  final List<Student> students;
  final int skipped;
  final List<String> duplicateRollNumbers;

  int get imported => students.length;
  int get duplicates => duplicateRollNumbers.length;
}
