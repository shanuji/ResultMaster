import 'package:flutter/material.dart';
import '../models/data_models.dart';
import '../database/database_helper.dart';
import '../utils/ux_helpers.dart';
import 'term_workspace_screen.dart';
import 'final_result_screen.dart';

class WorkbookDashboardScreen extends StatefulWidget {
  final int workbookId;
  final String workbookTitle;
  const WorkbookDashboardScreen({super.key, required this.workbookId, required this.workbookTitle});
  @override
  State<WorkbookDashboardScreen> createState() => _WorkbookDashboardScreenState();
}

class _WorkbookDashboardScreenState extends State<WorkbookDashboardScreen> {
  List<TermSetup> _terms = [];
  List<StudentRow> _students = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    var data = await DatabaseHelper.instance.loadFullWorkbookData(widget.workbookId);
    
    // Auto-populate 2 students if the workbook is brand new
    if (data['students'].isEmpty) {
      await DatabaseHelper.instance.insertLiveStudent(widget.workbookId, "1", "Student 1");
      await DatabaseHelper.instance.insertLiveStudent(widget.workbookId, "2", "Student 2");
      data = await DatabaseHelper.instance.loadFullWorkbookData(widget.workbookId);
    }
    
    setState(() { _terms = data['terms']; _students = data['students']; _isLoading = false; });
  }

  void _showAddTermDialog() {
    String termName = ""; bool copyPrevious = _terms.isNotEmpty; TermSetup? sourceTerm = _terms.isNotEmpty ? _terms.last : null;
    showDialog(
      context: context, builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Term'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(decoration: const InputDecoration(labelText: 'Term Name (e.g. Term 2)'), autofocus: true, onChanged: (val) => termName = val),
              if (_terms.isNotEmpty) ...[
                const SizedBox(height: 16),
                SwitchListTile(title: const Text("Copy subjects & components from previous term", style: TextStyle(fontSize: 14)), value: copyPrevious, onChanged: (val) => setDialogState(() => copyPrevious = val)),
                if (copyPrevious) DropdownButton<TermSetup>(value: sourceTerm, isExpanded: true, items: _terms.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(), onChanged: (val) => setDialogState(() => sourceTerm = val))
              ]
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (termName.trim().isEmpty) return;
                // Prevent duplicate terms
                if (_terms.any((t) => t.name.trim().toLowerCase() == termName.trim().toLowerCase())) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A term with this name already exists!'), backgroundColor: Colors.red));
                  return;
                }
                
                List<SubjectSetup> subjectsToCopy = [];
                if (copyPrevious && sourceTerm != null) {
                  subjectsToCopy = sourceTerm!.subjects.map((s) => SubjectSetup(name: s.name, maxMarks: s.maxMarks, passingMarks: s.passingMarks, includeInPassFail: s.includeInPassFail, requirePassPerComponent: s.requirePassPerComponent, themeColor: s.themeColor, components: s.components.map((c) => SubjectComponent(name: c.name, maxMarks: c.maxMarks, passingMarks: c.passingMarks)).toList())).toList();
                }
                await DatabaseHelper.instance.createTerm(widget.workbookId, termName.trim(), subjectsToCopy);
                if (context.mounted) Navigator.pop(context);
                _loadData();
              }, child: const Text('Add Term')
            )
          ],
        )
      )
    );
  }

  void _deleteTermConfirm(int termId, String termName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Term?'),
        content: Text('Are you sure you want to delete "$termName"? All marks inside this term will be permanently lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () async { await DatabaseHelper.instance.deleteTerm(termId); Navigator.pop(context); _loadData(); }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: Text(widget.workbookTitle), backgroundColor: Theme.of(context).colorScheme.primaryContainer),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1, child: Container(
              color: Colors.grey[100],
              child: Column(
                children: [
                  Container(padding: const EdgeInsets.all(16), color: Colors.blue[100], width: double.infinity, child: const Text('TERMS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _terms.length, itemBuilder: (context, index) {
                        return ListTile(
                          leading: const Icon(Icons.folder), 
                          title: Text(_terms[index].name, style: const TextStyle(fontWeight: FontWeight.bold)), 
                          trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20), onPressed: () => _deleteTermConfirm(_terms[index].id, _terms[index].name)),
                          onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => TermWorkspaceScreen(term: _terms[index], allStudents: _students))); _loadData(); },
                        );
                      }
                    ),
                  ),
                  Padding(padding: const EdgeInsets.all(8.0), child: ElevatedButton.icon(onPressed: _showAddTermDialog, icon: const Icon(Icons.add), label: const Text("Add Term"), style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45)))),
                  if (_terms.isNotEmpty) Padding(padding: const EdgeInsets.all(8.0), child: ElevatedButton.icon(onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (context) => FinalResultScreen(workbookId: widget.workbookId, workbookTitle: widget.workbookTitle))); }, icon: const Icon(Icons.analytics), label: const Text("View Final Result"), style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45), backgroundColor: Colors.green, foregroundColor: Colors.white)))
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            flex: 2, child: Column(
              children: [
                Container(padding: const EdgeInsets.all(16), color: Colors.yellow[100], width: double.infinity, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('STUDENT LIST', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)), child: Text('Total Students: ${_students.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))] )),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(children: [
                    ElevatedButton.icon(onPressed: () async {
                      int nextRoll = 1; while (_students.any((s) => s.rollNo.trim() == nextRoll.toString())) nextRoll++;
                      await DatabaseHelper.instance.insertLiveStudent(widget.workbookId, nextRoll.toString(), "Student $nextRoll"); _loadData();
                    }, icon: const Icon(Icons.person_add, size: 18), label: const Text('Add Student')),
                  ]),
                ),
                Expanded(
                  child: SingleChildScrollView(scrollDirection: Axis.vertical, child: DataTable(
                    columnSpacing: 20,
                    columns: const [DataColumn(label: Text('Roll No')), DataColumn(label: Text('Name'))],
                    rows: _students.asMap().entries.map((e) => DataRow(color: MaterialStateProperty.all(e.key.isEven ? Colors.grey[50] : Colors.white), cells: [
                      DataCell(AutoSelectTextField(initialValue: e.value.rollNo, decoration: const InputDecoration(hintText: 'Roll No', border: InputBorder.none), onChanged: (val) { DatabaseHelper.instance.updateLiveStudentInfo(widget.workbookId, e.value.rollNo, val, e.value.name); e.value.rollNo = val; })),
                      DataCell(AutoSelectTextField(initialValue: e.value.name, decoration: const InputDecoration(hintText: 'Student Name', border: InputBorder.none), onChanged: (val) { DatabaseHelper.instance.updateLiveStudentInfo(widget.workbookId, e.value.rollNo, e.value.rollNo, val); e.value.name = val; })),
                    ])).toList(),
                  ))
                )
              ],
            )
          )
        ],
      ),
    );
  }
}
