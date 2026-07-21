
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as ex;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

import '../models/data_models.dart';
import '../database/database_helper.dart';
import '../utils/ux_helpers.dart';
import '../widgets/setup_wizard_widget.dart';
import '../widgets/subject_marks_tab.dart';
import '../widgets/final_sheet_tab.dart';
import '../widgets/summary_sheet_tab.dart';

class WorkbookWorkspaceScreen extends StatefulWidget {
  final int workbookId;
  final String workbookTitle;
  final List<SubjectSetup> initialSubjects;
  final List<StudentRow> initialStudents;
  const WorkbookWorkspaceScreen({super.key, required this.workbookId, required this.workbookTitle, required this.initialSubjects, required this.initialStudents});
  @override
  State<WorkbookWorkspaceScreen> createState() => _WorkbookWorkspaceScreenState();
}

class _WorkbookWorkspaceScreenState extends State<WorkbookWorkspaceScreen> {
  late String _currentTitle;
  late List<SubjectSetup> _subjects;
  late List<StudentRow> _students;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.workbookTitle; _subjects = widget.initialSubjects; _students = widget.initialStudents;
  }

  void _openEditSetup() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SetupWizardWidget(
        palette: const [Colors.blue, Colors.purple, Colors.teal, Colors.indigo, Colors.pink, Colors.orange, Colors.cyan, Colors.green],
        initialTitle: _currentTitle, initialSubjects: _subjects,
        onSetupComplete: (title, subjects) async {
          await DatabaseHelper.instance.updateWorkbookSetup(widget.workbookId, title, subjects);
          setState(() { _currentTitle = title; _subjects = subjects; });
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Workbook setup updated successfully!'), backgroundColor: Colors.green));
        },
      ),
    );
  }

  void _openFileBrowserWizard() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx'], withData: true);
      if (result != null && result.files.single.bytes != null) {
        var bytes = result.files.single.bytes!; var excel = ex.Excel.decodeBytes(bytes);
        List<StudentRow> newParsedList = [];
        for (var table in excel.tables.keys) {
          var sheet = excel.tables[table]!;
          for (var row in sheet.rows) {
            if (row.length >= 2) {
              String roll = row[0]?.value?.toString().trim() ?? ''; String name = row[1]?.value?.toString().trim() ?? '';
              if (roll.isNotEmpty && roll.toLowerCase() != 'roll no' && roll.toLowerCase() != 'rollno') {
                if (name.isEmpty) name = "";
                newParsedList.add(StudentRow(rollNo: roll, name: name, marks: {}));
              }
            }
          }
          break; 
        }
        if (newParsedList.isNotEmpty) {
          await DatabaseHelper.instance.clearAllStudents(widget.workbookId);
          for (var student in newParsedList) await DatabaseHelper.instance.insertLiveStudent(widget.workbookId, student.rollNo, student.name);
          setState(() { _students = newParsedList; });
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully imported ${newParsedList.length} students!'), backgroundColor: Colors.green));
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No valid student data found.'), backgroundColor: Colors.orange));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error reading file: $e'), backgroundColor: Colors.red));
    }
  }

  void _exportAsExcel() async {
    var excel = ex.Excel.createExcel(); 
    
    ex.Sheet finalSheet = excel['Final Result'];
    finalSheet.appendRow([ex.TextCellValue("Roll No"), ex.TextCellValue("Name"), ..._subjects.map((s) => ex.TextCellValue(s.name)), ex.TextCellValue("Total"), ex.TextCellValue("Percentage"), ex.TextCellValue("Result")]);
    for (var s in _students) {
      double totalObtained = 0.0; double totalMax = 0.0; bool failed = false; List<ex.CellValue> subValues = [];
      for (var sub in _subjects) {
        totalMax += sub.maxMarks;
        if (s.isSubjectAttempted(sub)) {
          double score = s.getSubjectScore(sub); totalObtained += score;
          if (sub.includeInPassFail && !s.isSubjectPassed(sub)) failed = true;
          subValues.add(ex.DoubleCellValue(score));
        } else {
          subValues.add(ex.TextCellValue("-"));
        }
      }
      double pct = totalMax > 0 ? (totalObtained / totalMax) * 100 : 0.0;
      finalSheet.appendRow([ex.TextCellValue(s.rollNo), ex.TextCellValue(s.name.isEmpty ? '-' : s.name), ...subValues, ex.DoubleCellValue(totalObtained), ex.TextCellValue('${pct.toStringAsFixed(2)}%'), ex.TextCellValue(failed ? "FAIL" : "PASS")]);
    }

    for (var sub in _subjects) {
      String sheetName = sub.name.isEmpty ? 'Subject' : sub.name;
      ex.Sheet subSheet = excel[sheetName];
      
      List<ex.CellValue> subHeaders = [ex.TextCellValue("Roll No"), ex.TextCellValue("Name")];
      if (sub.components.isEmpty) { subHeaders.add(ex.TextCellValue("Marks")); } 
      else { subHeaders.addAll(sub.components.map((c) => ex.TextCellValue(c.name))); }
      subSheet.appendRow(subHeaders);

      for (var s in _students) {
        List<ex.CellValue> row = [ex.TextCellValue(s.rollNo), ex.TextCellValue(s.name.isEmpty ? '-' : s.name)];
        if (sub.components.isEmpty) {
          row.add(ex.TextCellValue(s.marks[sub.name] ?? "-"));
        } else {
          for (var c in sub.components) {
            row.add(ex.TextCellValue(s.marks['${sub.name}_${c.name}'] ?? "-"));
          }
        }
        subSheet.appendRow(row);
      }
    }

    if (excel.tables.containsKey('Sheet1')) { excel.delete('Sheet1'); }

    String fileName = _currentTitle.trim();
    if (!fileName.toLowerCase().endsWith('result')) fileName += ' Result';

    var bytes = excel.encode();
    if (bytes != null) {
      File tempFile = File('${Directory.systemTemp.path}/$fileName.xlsx');
      await tempFile.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(tempFile.path)], text: 'Excel Report Card Grid');
    }
  }

  void _exportAsPDF() async {
    final pdfDoc = pw.Document();

    pdfDoc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) => [
          pw.Header(level: 0, child: pw.Text('$_currentTitle - Final Result', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: ['Roll No', 'Name', ..._subjects.map((s) => s.name), 'Total', '%', 'Result'],
            data: _students.map((s) {
              double totalObtained = 0.0; double totalMax = 0.0; bool failed = false; List<String> rowCells = [s.rollNo, s.name.isEmpty ? '-' : s.name];
              for (var sub in _subjects) {
                totalMax += sub.maxMarks;
                if (s.isSubjectAttempted(sub)) {
                  double score = s.getSubjectScore(sub); totalObtained += score;
                  if (sub.includeInPassFail && !s.isSubjectPassed(sub)) failed = true;
                  rowCells.add(score.toStringAsFixed(1));
                } else {
                  rowCells.add("-");
                }
              }
              double pct = totalMax > 0 ? (totalObtained / totalMax) * 100 : 0.0;
              rowCells.addAll([totalObtained.toStringAsFixed(1), '${pct.toStringAsFixed(2)}%', failed ? "FAIL" : "PASS"]);
              return rowCells;
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold), cellAlignment: pw.Alignment.center,
          )
        ]
      )
    );

    for (var sub in _subjects) {
      pdfDoc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.portrait,
          build: (pw.Context context) {
            List<String> subHeaders = ['Roll No', 'Name'];
            if (sub.components.isEmpty) { subHeaders.add("Marks"); } 
            else { subHeaders.addAll(sub.components.map((c) => c.name)); }

            List<List<String>> data = _students.map((s) {
              List<String> row = [s.rollNo, s.name.isEmpty ? '-' : s.name];
              if (sub.components.isEmpty) {
                row.add(s.marks[sub.name] ?? "-");
              } else {
                row.addAll(sub.components.map((c) => s.marks['${sub.name}_${c.name}'] ?? "-"));
              }
              return row;
            }).toList();

            return [
              pw.Header(level: 0, child: pw.Text('$_currentTitle - ${sub.name}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 12),
              pw.TableHelper.fromTextArray(
                headers: subHeaders,
                data: data,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold), cellAlignment: pw.Alignment.center,
              )
            ];
          }
        )
      );
    }

    String fileName = _currentTitle.trim();
    if (!fileName.toLowerCase().endsWith('result')) fileName += ' Result';

    final bytes = await pdfDoc.save();
    File tempFile = File('${Directory.systemTemp.path}/$fileName.pdf');
    await tempFile.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(tempFile.path)], text: 'PDF Grade Sheet Report');
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24), height: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Choose Download Format', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center), const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.green[50], padding: const EdgeInsets.symmetric(vertical: 14)), icon: const Icon(Icons.table_view, color: Colors.green), label: const Text('Excel (.xlsx)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)), onPressed: () { Navigator.pop(context); _exportAsExcel(); })),
                const SizedBox(width: 16),
                Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50], padding: const EdgeInsets.symmetric(vertical: 14)), icon: const Icon(Icons.picture_as_pdf, color: Colors.red), label: const Text('PDF (.pdf)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), onPressed: () { Navigator.pop(context); _exportAsPDF(); })),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredStudents = _students.where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase()) || s.rollNo.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentTitle), backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          actions: [IconButton(icon: const Icon(Icons.edit), tooltip: 'Edit Setup', onPressed: _openEditSetup), IconButton(icon: const Icon(Icons.download), tooltip: 'Download', onPressed: _showExportOptions)],
          bottom: const TabBar(isScrollable: true, tabs: [Tab(icon: Icon(Icons.people), text: "Master List"), Tab(icon: Icon(Icons.subject), text: "Subject Sheets"), Tab(icon: Icon(Icons.assignment_turned_in), text: "Final Calculation"), Tab(icon: Icon(Icons.analytics), text: "Statistical Summary")]),
        ),
        body: Column(
          children: [
            Padding(padding: const EdgeInsets.all(8.0), child: TextField(decoration: InputDecoration(hintText: 'Search Roll No or Name...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)), onChanged: (val) => setState(() => _searchQuery = val))),
            Expanded(
              child: TabBarView(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 8.0, runSpacing: 8.0,
                          children: [
                            ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[50]), onPressed: _openFileBrowserWizard, icon: const Icon(Icons.file_upload, size: 18), label: const Text('Upload Excel')),
                            ElevatedButton.icon(
                              onPressed: () async {
                                int nextRoll = 1; while (_students.any((s) => s.rollNo.trim() == nextRoll.toString())) nextRoll++;
                                String newRoll = nextRoll.toString(); String newName = "";
                                await DatabaseHelper.instance.insertLiveStudent(widget.workbookId, newRoll, newName);
                                setState(() { _students.add(StudentRow(rollNo: newRoll, name: newName, marks: {})); });
                              },
                              icon: const Icon(Icons.person_add, size: 18), label: const Text('Add Student'),
                            )
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [DataColumn(label: Text('Roll No')), DataColumn(label: Text('Name')), DataColumn(label: Text('Actions'))],
                              rows: filteredStudents.asMap().entries.map((entry) {
                                int index = entry.key; var student = entry.value;
                                return DataRow(
                                  color: MaterialStateProperty.all(index.isEven ? Colors.grey[100] : Colors.white),
                                  cells: [
                                    DataCell(SizedBox(width: 50, child: AutoSelectTextField(initialValue: student.rollNo, decoration: const InputDecoration(border: InputBorder.none, hintText: 'Roll'), onChanged: (val) { String oldRoll = student.rollNo; student.rollNo = val; DatabaseHelper.instance.updateLiveStudentInfo(widget.workbookId, oldRoll, val, student.name); }))),
                                    DataCell(AutoSelectTextField(initialValue: student.name, decoration: InputDecoration(border: InputBorder.none, hintText: 'Student ${student.rollNo}'), onChanged: (val) { student.name = val; DatabaseHelper.instance.updateLiveStudentInfo(widget.workbookId, student.rollNo, student.rollNo, val); })),
                                    DataCell(IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async { await DatabaseHelper.instance.deleteLiveStudent(widget.workbookId, student.rollNo); setState(() { _students.remove(student); }); })),
                                  ]
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SubjectMarksTabWidget(workbookId: widget.workbookId, subjects: _subjects, students: filteredStudents, allStudents: _students),
                  FinalSheetTabWidget(subjects: _subjects, students: filteredStudents),
                  SummarySheetTabWidget(subjects: _subjects, students: filteredStudents),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
