import 'package:flutter/material.dart';
import '../models/data_models.dart';
import '../database/database_helper.dart';

class GlobalFinalResultTabWidget extends StatefulWidget {
  final int workbookId;
  final List<TermSetup> terms;
  final List<SubjectSetup> subjects;
  final List<StudentRow> students;
  const GlobalFinalResultTabWidget({super.key, required this.workbookId, required this.terms, required this.subjects, required this.students});
  @override
  State<GlobalFinalResultTabWidget> createState() => _GlobalFinalResultTabWidgetState();
}

class _GlobalFinalResultTabWidgetState extends State<GlobalFinalResultTabWidget> {
  bool _freezeRollNo = true; 
  bool _freezeName = true; 

  @override
  Widget build(BuildContext context) {
    if (widget.terms.isEmpty || widget.subjects.isEmpty) { return const Center(child: Text('Create Terms and Global Subjects first.', style: TextStyle(color: Colors.grey))); }

    List<DataColumn> fixedCols = []; List<DataColumn> scrollCols = [];
    var colRoll = const DataColumn(label: Text('Roll No', style: TextStyle(fontWeight: FontWeight.bold)));
    var colName = const DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold)));

    if (_freezeRollNo) fixedCols.add(colRoll); else scrollCols.add(colRoll);
    if (_freezeName) fixedCols.add(colName); else scrollCols.add(colName);
    
    for (var sub in widget.subjects) {
      if (sub.components.isEmpty) {
        for (var term in widget.terms) { scrollCols.add(DataColumn(label: Text('${sub.name}\n${term.name}', textAlign: TextAlign.center))); }
        scrollCols.add(DataColumn(label: Text('${sub.name}\nTotal', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))));
      } else {
        for (var comp in sub.components) {
          for (var term in widget.terms) { scrollCols.add(DataColumn(label: Text('${sub.name}\n${comp.name} ${term.name}', textAlign: TextAlign.center))); }
          scrollCols.add(DataColumn(label: Text('${sub.name}\n${comp.name} Total', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))));
        }
      }
    }
    scrollCols.add(const DataColumn(label: Text('GRAND\nTOTAL', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))));
    scrollCols.add(const DataColumn(label: Text('OVERALL\n%', textAlign: TextAlign.center)));
    scrollCols.add(const DataColumn(label: Text('RESULT', textAlign: TextAlign.center)));
    scrollCols.add(const DataColumn(label: Text('PROMOTE\nOVERALL', textAlign: TextAlign.center, style: TextStyle(color: Colors.blue))));

    double globalMaxMarks = 0.0;
    for (var sub in widget.subjects) { globalMaxMarks += (sub.maxMarks * widget.terms.length); }

    List<DataRow> fixedRows = []; List<DataRow> scrollRows = [];

    for (int i = 0; i < widget.students.length; i++) {
      var student = widget.students[i];
      
      var cellRoll = DataCell(Text(student.rollNo)); 
      var cellName = DataCell(Text(student.name.isEmpty ? 'Student ${student.rollNo}' : student.name));
      List<DataCell> fCells = []; List<DataCell> sCells = [];

      if (_freezeRollNo) fCells.add(cellRoll); else sCells.add(cellRoll);
      if (_freezeName) fCells.add(cellName); else sCells.add(cellName);
      
      double studentGrandTotal = 0.0;
      bool naturallyFailed = false;

      for (var sub in widget.subjects) {
        if (sub.components.isEmpty) {
          double subjectTotal = 0.0;
          for (var term in widget.terms) {
            double s = student.getSubjectScore(term.id, sub);
            subjectTotal += s;
            sCells.add(DataCell(Center(child: Text(student.termMarks[term.id]?[sub.name] ?? "-"))));
            if (sub.includeInPassFail) {
              bool passedNormally = s >= sub.passingMarks;
              if (!passedNormally && student.isSubjectAttempted(term.id, sub)) naturallyFailed = true;
            }
          }
          studentGrandTotal += subjectTotal;
          sCells.add(DataCell(Container(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), color: Colors.grey.shade300, alignment: Alignment.center, child: Text(subjectTotal.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)))));
        } else {
          for (var comp in sub.components) {
            double compTotal = 0.0;
            for (var term in widget.terms) {
              String markKey = '${sub.name}_${comp.name}';
              double s = double.tryParse(student.termMarks[term.id]?[markKey] ?? "") ?? 0.0;
              compTotal += s;
              sCells.add(DataCell(Center(child: Text(student.termMarks[term.id]?[markKey] ?? "-"))));
            }
            studentGrandTotal += compTotal;
            sCells.add(DataCell(Container(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), color: Colors.grey.shade300, alignment: Alignment.center, child: Text(compTotal.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)))));
          }
          for (var term in widget.terms) {
            if (sub.includeInPassFail && student.isSubjectAttempted(term.id, sub)) {
              for (var c in sub.components) { if (c.passingMarks > 0 && (double.tryParse(student.termMarks[term.id]?['${sub.name}_${c.name}'] ?? "") ?? 0.0) < c.passingMarks) naturallyFailed = true; }
            }
          }
        }
      }

      double pct = globalMaxMarks > 0 ? (studentGrandTotal / globalMaxMarks) * 100 : 0.0;
      sCells.add(DataCell(Center(child: Text(studentGrandTotal.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)))));
      sCells.add(DataCell(Center(child: Text('${pct.toStringAsFixed(2)}%'))));
      
      bool hasAnySubjectPromotion = false;
      for (var t in widget.terms) { if (student.termPromotions[t.id]?.values.contains(true) == true) hasAnySubjectPromotion = true; }
      
      bool isPromoted = student.isPromotedOverall || hasAnySubjectPromotion;
      String statusText = isPromoted ? 'PROMOTED' : (naturallyFailed ? 'FAIL' : 'PASS');
      Color statusColor = isPromoted ? Colors.orange : (naturallyFailed ? Colors.red : Colors.green);

      sCells.add(DataCell(Center(child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)))));
      // FIX APPLIED HERE: Corrected the closing brackets for the Switch widget
      sCells.add(DataCell(Center(child: Switch(value: student.isPromotedOverall, activeColor: Colors.blue, onChanged: (val) async { await DatabaseHelper.instance.updateStudentOverallPromotion(widget.workbookId, student.rollNo, val); setState(() { student.isPromotedOverall = val; }); }))));

      Color rowColor = i.isEven ? Colors.grey[50]! : Colors.white;
      if (fixedCols.isNotEmpty) fixedRows.add(DataRow(color: MaterialStateProperty.all(rowColor), cells: fCells));
      scrollRows.add(DataRow(color: MaterialStateProperty.all(rowColor), cells: sCells));
    }

    return Column(
      children: [
        Container(
          color: Colors.blue.shade50, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.push_pin, size: 16, color: Colors.blue), const SizedBox(width: 6), const Text("Freeze Columns:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
              const Spacer(), const Text("Roll No", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Switch(value: _freezeRollNo, activeColor: Colors.blue, onChanged: (val) => setState(() => _freezeRollNo = val)),
              const SizedBox(width: 16), const Text("Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Switch(value: _freezeName, activeColor: Colors.blue, onChanged: (val) => setState(() => _freezeName = val)),
            ],
          ),
        ),
        Expanded(
          child: fixedCols.isEmpty ? 
            SingleChildScrollView(scrollDirection: Axis.vertical, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(columnSpacing: 16, headingRowColor: MaterialStateProperty.all(Colors.blue.shade50), border: TableBorder.all(color: Colors.grey.shade300, width: 1), columns: scrollCols, rows: scrollRows)))
            : 
            SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DataTable(columnSpacing: 16, headingRowColor: MaterialStateProperty.all(Colors.blue.shade50), dataRowMinHeight: 48, dataRowMaxHeight: 48, border: TableBorder.all(color: Colors.grey.shade300, width: 1), columns: fixedCols, rows: fixedRows),
                  Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(columnSpacing: 16, headingRowColor: MaterialStateProperty.all(Colors.blue.shade50), dataRowMinHeight: 48, dataRowMaxHeight: 48, border: TableBorder.all(color: Colors.grey.shade300, width: 1), columns: scrollCols, rows: scrollRows))),
                ],
              ),
            ),
        ),
      ],
    );
  }
}
