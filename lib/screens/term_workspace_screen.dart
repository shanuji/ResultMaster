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
      var excel = ex.Excel.createExcel();
      String defaultSheetName = excel.getDefaultSheet() ?? 'Sheet1';
      excel.rename(defaultSheetName, '${widget.term.name} Final');
      
      var termSheet = excel['${widget.term.name} Final'];
      List<dynamic> tHeaders = ['Roll No', 'Name'];
      for (var sub in widget.subjects) { tHeaders.add(sub.name); }
      tHeaders.addAll(['Total', '%']);
      termSheet.appendRow(tHeaders);

      double termMax = widget.subjects.fold(0.0, (sum, sub) => sum + sub.maxMarks);
      for (var s in widget.allStudents) {
        List<dynamic> row = [s.rollNo, s.name];
        double termTotal = 0;
        for (var sub in widget.subjects) { double score = s.getSubjectScore(widget.term.id, sub); termTotal += score; row.add(s.termMarks[widget.term.id]?[sub.name] ?? "-"); }
        row.addAll([termTotal, '${termMax > 0 ? (termTotal / termMax * 100).toStringAsFixed(2) : 0}%']);
        termSheet.appendRow(row);
      }

      for (var sub in widget.subjects) {
        var subSheet = excel['${widget.term.name} - ${sub.name}'];
        List<dynamic> subHeaders = ['Roll No', 'Name'];
        if (sub.components.isEmpty) { subHeaders.add('Marks'); } else { for(var c in sub.components) subHeaders.add(c.name); }
        subHeaders.add('Promoted');
        subSheet.appendRow(subHeaders);
        for (var s in widget.allStudents) {
          List<dynamic> sRow = [s.rollNo, s.name];
          if (sub.components.isEmpty) { sRow.add(s.termMarks[widget.term.id]?[sub.name] ?? "-"); } else { for(var c in sub.components) sRow.add(s.termMarks[widget.term.id]?['${sub.name}_${c.name}'] ?? "-"); }
          sRow.add(s.termPromotions[widget.term.id]?[sub.name] == true ? "YES" : "NO");
          subSheet.appendRow(sRow);
        }
      }
      
      var bytes = excel.encode();
      if (bytes != null) {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/ResultMaster_${widget.term.name}.xlsx');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(file.path)], text: '${widget.term.name} Excel Export');
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Term Exported Successfully!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red));
    }
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
              WavyHeader(
                title: widget.term.name,
                leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
                actions: [
                  TextButton.icon(onPressed: _exportTermToExcel, icon: const Icon(Icons.download, color: Colors.white, size: 18), label: const Text("Download Result", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))
                ],
              ),
              TabBar(
                labelColor: Theme.of(context).colorScheme.primary, unselectedLabelColor: Colors.grey, indicatorColor: Theme.of(context).colorScheme.primary, indicatorWeight: 3, labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  const Tab(icon: Icon(Icons.edit_note), text: "Subject Marks"), 
                  Tab(icon: const Icon(Icons.assignment_turned_in), text: "${widget.term.name} Final"), 
                  Tab(icon: const Icon(Icons.analytics), text: "${widget.term.name} Summary")
                ],
              ),
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      SubjectMarksTabWidget(termId: widget.term.id, subjects: widget.subjects, students: widget.allStudents),
                      FinalSheetTabWidget(termId: widget.term.id, subjects: widget.subjects, students: widget.allStudents),
                      SummarySheetTabWidget(termId: widget.term.id, subjects: widget.subjects, students: widget.allStudents),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
