import 'package:flutter/material.dart';
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
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Column(
          children: [
            WavyHeader(
              title: '${widget.term.name} Workspace',
              leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
              actions: [IconButton(icon: const Icon(Icons.more_vert), onPressed: (){})],
            ),
            TabBar(
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).colorScheme.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                const Tab(icon: Icon(Icons.edit_note), text: "Subject Marks"), 
                Tab(icon: const Icon(Icons.assignment_turned_in), text: "${widget.term.name} Final"), 
                Tab(icon: const Icon(Icons.analytics), text: "${widget.term.name} Summary")
              ],
            ),
            Expanded(
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  SubjectMarksTabWidget(termId: widget.term.id, subjects: widget.subjects, students: widget.allStudents),
                  FinalSheetTabWidget(termId: widget.term.id, subjects: widget.subjects, students: widget.allStudents),
                  SummarySheetTabWidget(termId: widget.term.id, subjects: widget.subjects, students: widget.allStudents),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
