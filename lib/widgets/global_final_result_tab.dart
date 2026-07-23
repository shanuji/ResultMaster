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
  @override
  Widget build(BuildContext context) {
    if (widget.terms.isEmpty || widget.subjects.isEmpty) {
      return const Center(child: Text('Create Terms and Global Subjects first.'));
    }

    List<DataColumn> columns = [const DataColumn(label: Text('Roll No')), const DataColumn(label: Text('Name'))];
    for (var sub in widget.subjects) {
      if (sub.components.isEmpty) {
        for (var term in widget.terms) { columns.add(DataColumn(label: Text('${sub.name}\n${term.name}'))); }
        columns.add(DataColumn(label: Text('${sub.name}\nTotal', style: const TextStyle(fontWeight: FontWeight.bold))));
      } else {
        for (var comp in sub.components) {
          for (var term in widget.terms) { columns.add(DataColumn(label: Text('${sub.name}\n${comp.name} ${term.name}'))); }
          columns.add(DataColumn(label: Text('${sub.name}\n${comp.name} Total', style: const TextStyle(fontWeight: FontWeight.bold))));
        }
      }
    }
    columns.add(const DataColumn(label: Text('GRAND\nTOTAL', style: TextStyle(fontWeight: FontWeight.bold))));
    columns.add(const DataColumn(label: Text('OVERALL\n%')));
    columns.add(const DataColumn(label: Text('RESULT')));
    columns.add(const DataColumn(label: Text('PROMOTE\nOVERALL', style: TextStyle(color: Colors.blue))));

    double globalMaxMarks = 0.0;
    for (var sub in widget.subjects) { globalMaxMarks += (sub.maxMarks * widget.terms.length); }

    List<DataRow> rows = widget.students.asMap().entries.map((entry) {
      int sIdx = entry.key; var student = entry.value;
      List<DataCell> cells = [DataCell(Text(student.rollNo)), DataCell(Text(student.name.isEmpty ? 'Student ${student.rollNo}' : student.name))];
      
      double studentGrandTotal = 0.0;
      bool studentFailed = false;

      for (var sub in widget.subjects) {
        if (sub.components.isEmpty) {
          double subjectTotal = 0.0;
          for (var term in widget.terms) {
            double s = student.getSubjectScore(term.id, sub);
            subjectTotal += s;
            cells.add(DataCell(Text(student.termMarks[term.id]?[sub.name] ?? "-")));
            if (sub.includeInPassFail && student.isSubjectAttempted(term.id, sub) && !student.isSubjectPassed(term.id, sub)) studentFailed = true;
          }
          studentGrandTotal += subjectTotal;
          cells.add(DataCell(Text(subjectTotal.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold))));
        } else {
          for (var comp in sub.components) {
            double compTotal = 0.0;
            for (var term in widget.terms) {
              String markKey = '${sub.name}_${comp.name}';
              double s = double.tryParse(student.termMarks[term.id]?[markKey] ?? "") ?? 0.0;
              compTotal += s;
              cells.add(DataCell(Text(student.termMarks[term.id]?[markKey] ?? "-")));
            }
            studentGrandTotal += compTotal;
            cells.add(DataCell(Text(compTotal.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold))));
          }
          for (var term in widget.terms) { if (sub.includeInPassFail && student.isSubjectAttempted(term.id, sub) && !student.isSubjectPassed(term.id, sub)) studentFailed = true; }
        }
      }

      double pct = globalMaxMarks > 0 ? (studentGrandTotal / globalMaxMarks) * 100 : 0.0;
      
      cells.add(DataCell(Text(studentGrandTotal.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold))));
      cells.add(DataCell(Text('${pct.toStringAsFixed(2)}%')));
      
      bool finalPassStatus = student.isPromotedOverall ? true : !studentFailed;
      cells.add(DataCell(Text(student.isPromotedOverall ? 'PROMOTED' : (finalPassStatus ? 'PASS' : 'FAIL'), style: TextStyle(color: finalPassStatus ? Colors.green : Colors.red, fontWeight: FontWeight.bold))));
      cells.add(DataCell(Switch(value: student.isPromotedOverall, activeColor: Colors.blue, onChanged: (val) async { await DatabaseHelper.instance.updateStudentOverallPromotion(widget.workbookId, student.rollNo, val); setState(() { student.isPromotedOverall = val; }); })));

      return DataRow(color: MaterialStateProperty.all(sIdx.isEven ? Colors.grey[50] : Colors.white), cells: cells);
    }).toList();

    return SingleChildScrollView(scrollDirection: Axis.vertical, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(columnSpacing: 20, headingRowColor: MaterialStateProperty.all(Colors.blue[100]), columns: columns, rows: rows)));
  }
}
