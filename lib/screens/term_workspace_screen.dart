import 'package:flutter/material.dart';
import '../models/data_models.dart';
import '../widgets/wavy_header.dart';
import '../widgets/subject_marks_tab.dart';
import '../widgets/final_sheet_tab.dart';
import '../widgets/summary_sheet_tab.dart';
import '../widgets/premium_ui.dart';

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
              leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Chip(
                    avatar: const Icon(Icons.groups_rounded, size: 16, color: Colors.white),
                    label: Text('${widget.allStudents.length} students'),
                    labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    backgroundColor: Colors.white24,
                    side: BorderSide.none,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: PremiumPanel(
                padding: const EdgeInsets.all(6),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(colors: [Color(0xFF21D4B7), Color(0xFF0A8D82)]),
                    boxShadow: [BoxShadow(color: Color(0x330A8D82), blurRadius: 14, offset: Offset(0, 6))],
                  ),
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  tabs: [
                    const Tab(icon: Icon(Icons.edit_note_rounded), text: "Subject Marks"),
                    Tab(icon: const Icon(Icons.assignment_turned_in_rounded), text: "${widget.term.name} Final"),
                    Tab(icon: const Icon(Icons.analytics_rounded), text: "${widget.term.name} Summary")
                  ],
                ),
              ),
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
