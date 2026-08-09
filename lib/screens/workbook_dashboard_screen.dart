import 'package:flutter/material.dart';
import '../models/data_models.dart';
import '../features/result_workbook/data/repositories/sqlite_result_workbook_repository.dart';
import '../widgets/subject_marks_tab.dart';

class WorkbookDashboardScreen extends StatefulWidget {
  final int workbookId;

  const WorkbookDashboardScreen({Key? key, required this.workbookId}) : super(key: key);

  @override
  _WorkbookDashboardScreenState createState() => _WorkbookDashboardScreenState();
}

class _WorkbookDashboardScreenState extends State<WorkbookDashboardScreen> {
  final SqliteResultWorkbookRepository _repository = SqliteResultWorkbookRepository();
  
  bool _isLoading = true;
  List<TermSetup> _terms = [];
  List<SubjectSetup> _subjects = [];
  List<StudentRow> _students = [];
  
  int? _activeTermId;

  @override
  void initState() {
    super.initState();
    _loadWorkbookData();
  }

  Future<void> _loadWorkbookData() async {
    setState(() => _isLoading = true);

    _terms = await _repository.getWorkbookTerms(widget.workbookId);
    _subjects = await _repository.getWorkbookSubjects(widget.workbookId);
    _students = await _repository.getStudentsWithFullData(widget.workbookId);

    if (_terms.isNotEmpty && (_activeTermId == null || !_terms.any((t) => t.id == _activeTermId))) {
      _activeTermId = _terms.first.id;
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_terms.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Result Dashboard')),
        body: const Center(child: Text("No terms configured for this workbook.")),
      );
    }

    return DefaultTabController(
      length: _subjects.length + 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Result Dashboard'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: DropdownButton<int>(
                value: _activeTermId,
                dropdownColor: Theme.of(context).primaryColor,
                style: const TextStyle(color: Colors.white),
                iconEnabledColor: Colors.white,
                items: _terms.map((term) {
                  return DropdownMenuItem(
                    value: term.id,
                    child: Text(term.name),
                  );
                }).toList(),
                onChanged: (newTermId) {
                  if (newTermId != null) {
                    setState(() => _activeTermId = newTermId);
                  }
                },
              ),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              ..._subjects.map((s) => Tab(text: s.name)),
              const Tab(text: "Term Summary"),
              const Tab(text: "Final Result"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ..._subjects.map((subject) => SubjectMarksTab(
                  workbookId: widget.workbookId,
                  termId: _activeTermId!,
                  subject: subject,
                  students: _students,
                  repository: _repository,
                  onMarksSaved: _loadWorkbookData,
                )),
            const Center(child: Text("Summary Sheet Tab")),
            const Center(child: Text("Final Sheet Tab")),
          ],
        ),
      ),
    );
  }
}
