import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as ex;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/data_models.dart';
import '../widgets/wavy_header.dart';
import '../widgets/subject_marks_tab.dart';
import '../widgets/final_sheet_tab.dart';
import '../widgets/summary_sheet_tab.dart';

class TermWorkspaceScreen extends StatefulWidget {
  final TermSetup term;
  final List<SubjectSetup> subjects;
  final List<StudentRow> allStudents;
  const TermWorkspaceScreen({super.key, required this.term, required this.subjects, required this.allStudents});
  @override
  State<TermWorkspaceScreen> createState() => _TermWorkspaceScreenState();
}

class _TermWorkspaceScreenState extends State<TermWorkspaceScreen> {
  Future<void> _exportTermToExcel() async {
    try {
      final excel = ex.Excel.createExcel();
      final defaultSheetName = excel.getDefaultSheet() ?? 'Sheet1';
      final finalSheetName = '${widget.term.name} Final';
      excel.rename(defaultSheetName, finalSheetName);
      final finalSheet = excel[finalSheetName];
      final finalHeaders = <String>['Roll Number', 'Student Name', ...widget.subjects.map((sub) => sub.name), 'Total Marks', 'Maximum Marks', 'Percentage'];
      _appendStyledHeader(finalSheet, finalHeaders);
      final termMax = widget.subjects.fold<double>(0, (sum, sub) => sum + sub.maxMarks);
      for (final student in widget.allStudents) {
        final row = <dynamic>[student.rollNo, student.name];
        var termTotal = 0.0;
        for (final sub in widget.subjects) {
          final score = student.getSubjectScore(widget.term.id, sub);
          termTotal += score;
          row.add(student.termMarks[widget.term.id]?[sub.name] ?? '-');
        }
        row.add(termTotal);
        row.add(termMax);
        row.add(termMax > 0 ? termTotal / termMax * 100 : 0);
        finalSheet.appendRow(row.map<ex.CellValue>(_toCellValue).toList());
      }
      _setColumnWidths(finalSheet, [16, 30, ...List<double>.filled(widget.subjects.length, 20), 16, 18, 14]);

      for (final sub in widget.subjects) {
        final sheet = excel['${widget.term.name} - ${sub.name}'];
        final headers = <String>['Roll Number', 'Student Name'];
        if (sub.components.isEmpty) {
          headers.add('Marks');
        } else {
          headers.addAll(sub.components.map((component) => '${component.name} (Max ${component.maxMarks.toStringAsFixed(0)})'));
        }
        headers.add('Promotion Status');
        _appendStyledHeader(sheet, headers);
        for (final student in widget.allStudents) {
          final row = <dynamic>[student.rollNo, student.name];
          if (sub.components.isEmpty) {
            row.add(student.termMarks[widget.term.id]?[sub.name] ?? '-');
          } else {
            for (final component in sub.components) {
              row.add(student.termMarks[widget.term.id]?['${sub.name}_${component.name}'] ?? '-');
            }
          }
          row.add(student.termPromotions[widget.term.id]?[sub.name] == true ? 'PROMOTED' : 'NOT PROMOTED');
          sheet.appendRow(row.map<ex.CellValue>(_toCellValue).toList());
        }
        _setColumnWidths(sheet, [16, 30, ...List<double>.filled(sub.components.isEmpty ? 1 : sub.components.length, 24), 22]);
      }

      final bytes = excel.encode();
      if (bytes != null) {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/ResultMaster_${widget.term.name}.xlsx');
        await file.writeAsBytes(bytes, flush: true);
        await Share.shareXFiles([XFile(file.path)], text: '${widget.term.name} Excel Export');
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Term Exported Successfully!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red));
    }
  }

  ex.CellValue _toCellValue(dynamic value) {
    return switch (value) {
      int v => ex.IntCellValue(v),
      double v => ex.DoubleCellValue(v),
      num v => ex.DoubleCellValue(v.toDouble()),
      _ => ex.TextCellValue(value?.toString() ?? ''),
    };
  }

  void _appendStyledHeader(ex.Sheet sheet, List<String> headers) {
    final style = ex.CellStyle(bold: true, horizontalAlign: ex.HorizontalAlign.Center, verticalAlign: ex.VerticalAlign.Center, backgroundColorHex: ex.ExcelColor.fromHexString('#217346'), fontColorHex: ex.ExcelColor.fromHexString('#FFFFFF'));
    sheet.appendRow(headers.map<ex.CellValue>((header) => ex.TextCellValue(header)).toList());
    final rowIndex = sheet.maxRows - 1;
    for (var column = 0; column < headers.length; column++) {
      sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: column, rowIndex: rowIndex)).cellStyle = style;
    }
  }

  void _setColumnWidths(ex.Sheet sheet, List<double> widths) {
    for (var column = 0; column < widths.length; column++) sheet.setColumnWidth(column, widths[column]);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Column(
            children: [
              WavyHeader(title: widget.term.name, leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)), actions: [TextButton.icon(onPressed: _exportTermToExcel, icon: const Icon(Icons.download, color: Colors.white, size: 18), label: const Text('Download Result', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))]),
              TabBar(labelColor: Theme.of(context).colorScheme.primary, unselectedLabelColor: Colors.grey, indicatorColor: Theme.of(context).colorScheme.primary, indicatorWeight: 3, labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), tabs: [const Tab(icon: Icon(Icons.edit_note), text: 'Subject Marks'), Tab(icon: const Icon(Icons.assignment_turned_in), text: '${widget.term.name} Final'), Tab(icon: const Icon(Icons.analytics), text: '${widget.term.name} Summary')]),
              Expanded(child: Container(color: Colors.white, child: TabBarView(physics: const NeverScrollableScrollPhysics(), children: [SubjectMarksTabWidget(termId: widget.term.id, subjects: widget.subjects, students: widget.allStudents), FinalSheetTabWidget(termId: widget.term.id, subjects: widget.subjects, students: widget.allStudents), SummarySheetTabWidget(termId: widget.term.id, subjects: widget.subjects, students: widget.allStudents)]))),
            ],
          ),
        ),
      ),
    );
  }
}
