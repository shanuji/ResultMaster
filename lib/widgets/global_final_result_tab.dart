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
      return const Center(child: Text('Create Terms and Global Subjects first.', style: TextStyle(color: Colors.grey)));
    }

    List<DataColumn> columns = [
      const DataColumn(label: Text('Roll No', style: TextStyle(fontWeight: FontWeight.bold))), 
      const DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold)))
    ];
    
    for (var sub in widget.subjects) {
      if (sub.components.isEmpty) {
        for (var term in widget.terms) { 
          columns.add(DataColumn(label: Text('${sub.name}\n${term.name}', textAlign: TextAlign.center))); 
        }
        columns.add(DataColumn(label: Text('${sub.name}\nTotal', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))));
      } else {
        for (var comp in sub.components) {
          for (var term in widget.terms) { 
            columns.add(DataColumn(label: Text('${sub.name}\n${comp.name} ${term.name}', textAlign: TextAlign.center))); 
          }
          columns.add(DataColumn(label: Text('${sub.name}\n${comp.name} Total', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))));
        }
      }
    }
    columns.add(const DataColumn(label: Text('GRAND\nTOTAL', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))));
    columns.add(const DataColumn(label: Text('OVERALL\n%', textAlign: TextAlign.center)));
    columns.add(const DataColumn(label: Text('RESULT', textAlign: TextAlign.center)));
    columns.add(const DataColumn(label: Text('PROMOTE\nOVERALL', textAlign: TextAlign.center, style: TextStyle(color: Colors.blue))));

    double globalMaxMarks = 0.0;
    for (var sub in widget.subjects) { globalMaxMarks += (sub.maxMarks * widget.terms.length); }

    List<DataRow> rows = widget.students.asMap().entries.map((entry) {
      int sIdx = entry.key; var student = entry.value;
      List<DataCell> cells = [
        DataCell(Text(student.rollNo)), 
        DataCell(Text(student.name.isEmpty ? 'Student ${student.rollNo}' : student.name))
      ];
      
      double studentGrandTotal = 0.0;
      bool studentFailed = false;

      for (var sub in widget.subjects) {
        if (sub.components.isEmpty) {
          double subjectTotal = 0.0;
          for (var term in widget.terms) {
            double s = student.getSubjectScore(term.id, sub);
            subjectTotal += s;
            cells.add(DataCell(Center(child: Text(student.termMarks[term.id]?[sub.name] ?? "-"))));
            if (sub.includeInPassFail && student.isSubjectAttempted(term.id, sub) && !student.isSubjectPassed(term.id, sub)) studentFailed = true;
          }
          studentGrandTotal += subjectTotal;
          // Shaded background for Total to create a visual break between subjects
          cells.add(DataCell(Container(color: Colors.grey.shade100, alignment: Alignment.center, child: Text(subjectTotal.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)))));
        } else {
          for (var comp in sub.components) {
            double compTotal = 0.0;
            for (var term in widget.terms) {
              String markKey = '${sub.name}_${comp.name}';
              double s = double.tryParse(student.termMarks[term.id]?[markKey] ?? "") ?? 0.0;
              compTotal += s;
              cells.add(DataCell(Center(child: Text(student.termMarks[term.id]?[markKey] ?? "-"))));
            }
            studentGrandTotal += compTotal;
            cells.add(DataCell(Container(color: Colors.grey.shade100, alignment: Alignment.center, child: Text(compTotal.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)))));
          }
          for (var term in widget.terms) { if (sub.includeInPassFail && student.isSubjectAttempted(term.id, sub) && !student.isSubjectPassed(term.id, sub)) studentFailed = true; }
        }
      }

      double pct = globalMaxMarks > 0 ? (studentGrandTotal / globalMaxMarks) * 100 : 0.0;
      
      cells.add(DataCell(Center(child: Text(studentGrandTotal.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)))));
      cells.add(DataCell(Center(child: Text('${pct.toStringAsFixed(2)}%'))));
      
      bool finalPassStatus = student.isPromotedOverall ? true : !studentFailed;
      cells.add(DataCell(Center(child: Text(student.isPromotedOverall ? 'PROMOTED' : (finalPassStatus ? 'PASS' : 'FAIL'), style: TextStyle(color: finalPassStatus ? Colors.green : Colors.red, fontWeight: FontWeight.bold)))));
      cells.add(DataCell(Center(child: Switch(value: student.isPromotedOverall, activeColor: Colors.blue, onChanged: (val) async { await DatabaseHelper.instance.updateStudentOverallPromotion(widget.workbookId, student.rollNo, val); setState(() { student.isPromotedOverall = val; }); })))));

      return DataRow(color: MaterialStateProperty.all(sIdx.isEven ? Colors.grey[50] : Colors.white), cells: cells);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical, 
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal, 
            child: DataTable(
              columnSpacing: 25, 
              headingRowColor: MaterialStateProperty.all(Colors.blue.shade50), 
              // THIS ADDS THE GRID LINES:
              border: TableBorder.all(color: Colors.grey.shade300, width: 1),
              columns: columns, 
              rows: rows
            )
          )
        ),
      ),
    );
  }
}
