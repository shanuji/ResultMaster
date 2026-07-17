import 'package:flutter/material.dart';
import 'data_models.dart';
import 'tabs/master_list_tab.dart';
import 'tabs/subject_marks_tab.dart';
import 'tabs/final_sheet_tab.dart';
import 'tabs/summary_sheet_tab.dart';

// ==========================================
// WORKBOOK DASHBOARD 
// ==========================================
class WorkbookDashboardWidget extends StatefulWidget {
  final List<SubjectSetup> subjects;
  final List<StudentRow> students;
  final VoidCallback onStudentsUpdated;

  const WorkbookDashboardWidget({super.key, required this.subjects, required this.students, required this.onStudentsUpdated});

  @override
  State<WorkbookDashboardWidget> createState() => _WorkbookDashboardWidgetState();
}

class _WorkbookDashboardWidgetState extends State<WorkbookDashboardWidget> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final filteredStudents = widget.students.where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase()) || s.rollNo.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return DefaultTabController(
      length: 4, 
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by Roll No or Name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          const Material(
            color: Colors.blue,
            child: TabBar(
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: [
                Tab(icon: Icon(Icons.people), text: "Master List"),
                Tab(icon: Icon(Icons.subject), text: "Subject Sheets"),
                Tab(icon: Icon(Icons.assignment_turned_in), text: "Final Calculation"),
                Tab(icon: Icon(Icons.analytics), text: "Statistical Summary"), 
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                MasterListTab(students: filteredStudents, allStudents: widget.students, onUpdate: () { widget.onStudentsUpdated(); setState(() {}); }),
                SubjectMarksTab(subjects: widget.subjects, students: filteredStudents, allStudents: widget.students),
                FinalSheetTab(subjects: widget.subjects, students: filteredStudents),
                SummarySheetTab(subjects: widget.subjects, students: filteredStudents), 
              ],
            ),
          )
        ],
      ),
    );
  }
}
