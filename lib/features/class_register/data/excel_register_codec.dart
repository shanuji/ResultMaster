import 'dart:io';

import 'package:excel/excel.dart';

import '../domain/class_register_failure.dart';
import '../domain/student.dart';

class ExcelRegisterCodec {
  static const headers = ['S.No.', 'Roll Number', 'Student Name'];

  Future<ExcelRegisterWorkbook> inspectFile(File file) async {
    final bytes = await file.readAsBytes();
    final workbook = Excel.decodeBytes(bytes);
    return ExcelRegisterWorkbook(workbook);
  }

  Future<List<Student>> importFile(
    File file,
    int registerId, {
    String? worksheet,
    required String rollNumberColumn,
    required String studentNameColumn,
  }) async {
    final workbook = await inspectFile(file);
    return workbook.students(
      registerId,
      worksheet: worksheet ?? workbook.sheetNames.first,
      rollNumberColumn: rollNumberColumn,
      studentNameColumn: studentNameColumn,
    );
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

class ExcelRegisterWorkbook {
  const ExcelRegisterWorkbook(this._workbook);

  final Excel _workbook;

  List<String> get sheetNames => _workbook.tables.keys.toList(growable: false);

  List<String> columns(String worksheet) {
    final sheet = _sheet(worksheet);
    if (sheet.rows.isEmpty) return const <String>[];
    return sheet.rows.first
        .map((cell) => cell?.value.toString().trim() ?? '')
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  List<Student> students(
    int registerId, {
    required String worksheet,
    required String rollNumberColumn,
    required String studentNameColumn,
  }) {
    final sheet = _sheet(worksheet);
    if (sheet.rows.isEmpty) return const <Student>[];
    final header = sheet.rows.first.map((cell) => cell?.value.toString().trim() ?? '').toList();
    final rollIndex = header.indexOf(rollNumberColumn);
    final nameIndex = header.indexOf(studentNameColumn);
    if (rollIndex == -1 || nameIndex == -1) {
      throw const ClassRegisterFailure('Selected worksheet does not include the mapped Roll Number and Student Name columns.');
    }
    final imported = <Student>[];
    final seenRolls = <String>{};
    for (final row in sheet.rows.skip(1)) {
      String valueAt(int index) => index < row.length ? row[index]?.value.toString().trim() ?? '' : '';
      final rollNumber = valueAt(rollIndex);
      final name = valueAt(nameIndex);
      if (rollNumber.isEmpty && name.isEmpty) continue;
      if (rollNumber.isEmpty || name.isEmpty) {
        throw const ClassRegisterFailure('Import contains a row with a blank Roll Number or Student Name.');
      }
      if (!seenRolls.add(rollNumber.toLowerCase())) {
        throw ClassRegisterFailure('Import contains duplicate Roll Number: $rollNumber.');
      }
      imported.add(Student(registerId: registerId, rollNumber: rollNumber, name: name));
    }
    return imported;
  }

  Sheet _sheet(String worksheet) {
    final sheet = _workbook.tables[worksheet];
    if (sheet == null) throw ClassRegisterFailure('Worksheet "$worksheet" was not found.');
    return sheet;
  }
}
