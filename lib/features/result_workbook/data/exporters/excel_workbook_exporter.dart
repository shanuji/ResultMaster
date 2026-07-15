import 'dart:io';

import 'package:excel/excel.dart';

import '../../domain/entities/result_workbook.dart';
import '../../domain/services/result_calculation_engine.dart';

class ExcelWorkbookExporter {
  const ExcelWorkbookExporter({this.calculationEngine = const ResultCalculationEngine()});

  final ResultCalculationEngine calculationEngine;

  Future<File> exportFile(File file, ResultWorkbookDraft workbook, List<StudentMarks> marks) async {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Class Register');
    final calculated = calculationEngine.calculate(workbook, marks);

    _writeClassRegister(excel['Class Register'], workbook, marks.map((entry) => entry.student).toList());
    for (final subject in workbook.subjects) {
      _writeSubjectSheet(excel[subject.name], subject, marks, calculated);
    }
    _writeSummarySheet(excel['Summary'], workbook, calculated);
    _writeFinalSheet(excel['Final'], workbook, calculated);

    await file.writeAsBytes(excel.encode()!, flush: true);
    return file;
  }

  void _writeClassRegister(Sheet sheet, ResultWorkbookDraft workbook, List<Student> students) {
    _title(sheet, 'A1', 'C1', 'Class Register');
    _meta(sheet, 2, workbook);
    _header(sheet, 5, ['S.No.', 'Roll Number', 'Student Name']);
    for (var i = 0; i < students.length; i++) {
      final row = 6 + i;
      _row(sheet, row, [i + 1, students[i].rollNumber, students[i].name]);
    }
    _widths(sheet, [10, 16, 32]);
  }

  void _writeSubjectSheet(Sheet sheet, SubjectConfig subject, List<StudentMarks> marks, List<CalculatedResultRow> calculated) {
    final headers = ['S.No.', 'Roll Number', 'Student Name', ...subject.components.map((c) => c.name), 'TOTAL'];
    _title(sheet, 'A1', _cell(headers.length - 1, 1), subject.name);
    _header(sheet, 3, headers);
    for (var i = 0; i < marks.length; i++) {
      final result = calculated[i].subjects[subject.name]!;
      _row(sheet, 4 + i, [
        i + 1,
        marks[i].student.rollNumber,
        marks[i].student.name,
        ...subject.components.map((component) => result.componentMarks[component.name] ?? 0),
        result.total,
      ]);
    }
    _widths(sheet, [10, 16, 32, ...List.filled(subject.components.length + 1, 14)]);
  }

  void _writeSummarySheet(Sheet sheet, ResultWorkbookDraft workbook, List<CalculatedResultRow> calculated) {
    final headers = ['S.No.', 'Roll Number', 'Student Name', ...workbook.subjects.map((s) => s.name), 'Grand Total', 'Percentage', 'Result', 'Remarks'];
    _title(sheet, 'A1', _cell(headers.length - 1, 1), 'Summary');
    _header(sheet, 3, headers);
    for (var i = 0; i < calculated.length; i++) {
      final row = calculated[i];
      _row(sheet, 4 + i, [i + 1, row.student.rollNumber, row.student.name, ...workbook.subjects.map((subject) => row.subjects[subject.name]!.total), row.totalMarks, row.percentage, row.passed ? 'PASS' : 'FAIL', row.remarks]);
    }
    _widths(sheet, [10, 16, 32, ...List.filled(workbook.subjects.length, 14), 14, 14, 12, 24]);
  }

  void _writeFinalSheet(Sheet sheet, ResultWorkbookDraft workbook, List<CalculatedResultRow> calculated) {
    final headers = ['S.No.', 'Roll Number', 'Student Name', ...workbook.subjects.map((s) => s.name), 'Total Marks', 'Maximum Marks', 'Percentage', 'Pass / Fail', 'Remarks'];
    _title(sheet, 'A1', _cell(headers.length - 1, 1), 'Final');
    _header(sheet, 3, headers);
    for (var i = 0; i < calculated.length; i++) {
      final row = calculated[i];
      _row(sheet, 4 + i, [i + 1, row.student.rollNumber, row.student.name, ...workbook.subjects.map((subject) => row.subjects[subject.name]!.total), row.totalMarks, row.maximumMarks, row.percentage, row.passed ? 'PASS' : 'FAIL', row.remarks]);
    }
    _widths(sheet, [10, 16, 32, ...List.filled(workbook.subjects.length, 14), 14, 16, 14, 14, 24]);
  }

  void _meta(Sheet sheet, int row, ResultWorkbookDraft workbook) {
    _row(sheet, row, ['Academic Year', workbook.academicYear, 'Examination', workbook.examinationName]);
    _row(sheet, row + 1, ['Class', workbook.className, 'Section', workbook.section]);
  }

  void _title(Sheet sheet, String start, String end, String text) {
    sheet.merge(CellIndex.indexByString(start), CellIndex.indexByString(end));
    final cell = sheet.cell(CellIndex.indexByString(start));
    cell.value = TextCellValue(text);
    cell.cellStyle = CellStyle(bold: true, fontSize: 16, horizontalAlign: HorizontalAlign.Center, backgroundColorHex: ExcelColor.fromHexString('#D9EAD3'));
  }

  void _header(Sheet sheet, int row, List<String> headers) {
    _row(sheet, row, headers, style: CellStyle(bold: true, horizontalAlign: HorizontalAlign.Center, backgroundColorHex: ExcelColor.fromHexString('#217346'), fontColorHex: ExcelColor.fromHexString('#FFFFFF')));
  }

  void _row(Sheet sheet, int rowNumber, List<Object?> values, {CellStyle? style}) {
    for (var column = 0; column < values.length; column++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: column, rowIndex: rowNumber - 1));
      final value = values[column];
      cell.value = switch (value) { int v => IntCellValue(v), double v => DoubleCellValue(v), num v => DoubleCellValue(v.toDouble()), _ => TextCellValue(value?.toString() ?? '') };
      cell.cellStyle = style ?? CellStyle(horizontalAlign: value is num ? HorizontalAlign.Right : HorizontalAlign.Left);
    }
  }

  void _widths(Sheet sheet, List<double> widths) {
    for (var i = 0; i < widths.length; i++) {
      sheet.setColumnWidth(i, widths[i]);
    }
  }

  String _cell(int columnIndex, int rowNumber) => '${_columnName(columnIndex)}$rowNumber';

  String _columnName(int index) {
    var dividend = index + 1;
    var name = '';
    while (dividend > 0) {
      final modulo = (dividend - 1) % 26;
      name = String.fromCharCode(65 + modulo) + name;
      dividend = (dividend - modulo) ~/ 26;
    }
    return name;
  }
}
