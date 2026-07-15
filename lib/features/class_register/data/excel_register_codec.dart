import 'dart:io';

import 'package:collection/collection.dart';
import 'package:excel/excel.dart';

import '../domain/class_register_failure.dart';
import '../domain/student.dart';

class ExcelRegisterCodec {
  static const headers = ['S.No.', 'Roll Number', 'Student Name'];

  Future<List<Student>> importFile(File file, int registerId) async {
    final bytes = await file.readAsBytes();
    final workbook = Excel.decodeBytes(bytes);
    final sheet = workbook.tables.values.firstOrNull;
    if (sheet == null || sheet.rows.isEmpty) return const <Student>[];
    final header = sheet.rows.first.map((cell) => cell?.value.toString().trim()).toList();
    final rollIndex = header.indexOf('Roll Number');
    final nameIndex = header.indexOf('Student Name');
    if (rollIndex == -1 || nameIndex == -1) {
      throw const ClassRegisterFailure('Excel file must include Roll Number and Student Name headers.');
    }
    return sheet.rows.skip(1).where((row) => row.any((cell) => cell?.value != null)).map((row) {
      String valueAt(int index) => index < row.length ? row[index]?.value.toString().trim() ?? '' : '';
      return Student(registerId: registerId, rollNumber: valueAt(rollIndex), name: valueAt(nameIndex));
    }).toList(growable: false);
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
}
