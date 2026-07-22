import 'package:flutter/material.dart';
import '../models/data_models.dart';
import '../database/database_helper.dart';
import '../widgets/subject_marks_tab.dart';
import '../widgets/setup_wizard_widget.dart'; // We reuse your existing Setup wizard for term subjects!

class TermWorkspaceScreen extends StatefulWidget {
  final TermSetup term;
  final List<StudentRow> allStudents;
  const TermWorkspaceScreen({super.key, required this.term, required this.allStudents});
  @override
  State<TermWorkspaceScreen> createState() => _TermWorkspaceScreenState();
}

class _TermWorkspaceScreenState extends State<TermWorkspaceScreen> {
  late List<SubjectSetup> _subjects;

  @override
  void initState() {
    super.initState();
    _subjects = widget.term.subjects;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.term.name} Workspace'), backgroundColor: Colors.blue[50],
          bottom: const TabBar(tabs: [Tab(icon: Icon(Icons.edit_note), text: "Subject Marks"), Tab(icon: Icon(Icons.settings), text: "Term Subjects Setup")]),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(), // Prevents accidental swipe between forms
          children: [
            SubjectMarksTabWidget(termId: widget.term.id, subjects: _subjects, students: widget.allStudents),
            SetupWizardWidget(
              palette: const [Colors.blue, Colors.purple, Colors.teal, Colors.indigo, Colors.pink, Colors.orange],
              initialSubjects: _subjects,
              onSetupComplete: (_, subjects) async {
                await DatabaseHelper.instance.updateTermSubjects(widget.term.id, subjects);
                setState(() => _subjects = subjects);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Term Subjects Saved!')));
              },
            )
          ],
        ),
      ),
    );
  }
}
