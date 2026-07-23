import 'package:flutter/material.dart';
import '../models/data_models.dart';
import '../database/database_helper.dart';
import '../utils/ux_helpers.dart';
import 'term_workspace_screen.dart';
import '../widgets/setup_wizard_widget.dart';
import '../widgets/global_final_result_tab.dart';

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
  List<SubjectSetup> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    var data = await DatabaseHelper.instance.loadFullWorkbookData(widget.workbookId);
    if (data['students'].isEmpty) {
      await DatabaseHelper.instance.insertLiveStudent(widget.workbookId, "1", "");
      await DatabaseHelper.instance.insertLiveStudent(widget.workbookId, "2", "");
      data = await DatabaseHelper.instance.loadFullWorkbookData(widget.workbookId);
    }
    setState(() { _terms = data['terms']; _students = data['students']; _subjects = data['subjects']; _isLoading = false; });
  }

  void _showAddTermDialog() {
    String termName = "";
    showDialog(
      context: context, builder: (context) => AlertDialog(
        title: const Text('Add New Term'),
        content: TextField(decoration: const InputDecoration(labelText: 'Term Name (e.g. Term 1)'), autofocus: true, onChanged: (val) => termName = val),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (termName.trim().isEmpty) return;
              if (_terms.any((t) => t.name.trim().toLowerCase() == termName.trim().toLowerCase())) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A term with this name already exists!'), backgroundColor: Colors.red));
                return;
              }
              await DatabaseHelper.instance.createTerm(widget.workbookId, termName.trim());
              if (context.mounted) Navigator.pop(context);
              _loadData();
            }, child: const Text('Add Term')
          )
        ],
      )
    );
  }

  void _deleteConfirmation(String itemType, String itemName, VoidCallback onDelete) {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: Text('Delete $itemType?'),
      content: Text('Are you sure you want to permanently delete "$itemName"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: () { Navigator.pop(context); onDelete(); }, child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.workbookTitle, style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          bottom: const TabBar(tabs: [Tab(icon: Icon(Icons.dashboard), text: "Dashboard"), Tab(icon: Icon(Icons.settings), text: "Global Subjects"), Tab(icon: Icon(Icons.analytics), text: "Global Final Result")]),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // TAB 1: Clean, Card-based Dashboard
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1, 
                    child: Card(
                      elevation: 2, clipBehavior: Clip.antiAlias, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          Container(padding: const EdgeInsets.all(16), color: Colors.blue.shade50, width: double.infinity, child: const Text('TERMS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _terms.length, itemBuilder: (context, index) {
                                return ListTile(
                                  leading: const Icon(Icons.folder, color: Colors.blue), title: Text(_terms[index].name, style: const TextStyle(fontWeight: FontWeight.bold)), 
                                  trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20), onPressed: () => _deleteConfirmation("Term", _terms[index].name, () async { await DatabaseHelper.instance.deleteTerm(_terms[index].id); _loadData(); })),
                                  onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => TermWorkspaceScreen(term: _terms[index], subjects: _subjects, allStudents: _students))); _loadData(); },
                                );
                              }
                            ),
                          ),
                          Padding(padding: const EdgeInsets.all(8.0), child: ElevatedButton.icon(onPressed: _showAddTermDialog, icon: const Icon(Icons.add), label: const Text("Add Term"), style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45)))),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2, 
                    child: Card(
                      elevation: 2, clipBehavior: Clip.antiAlias, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          Container(padding: const EdgeInsets.all(16), color: Colors.yellow.shade50, width: double.infinity, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('STUDENT LIST', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12)), child: Text('Total Students: ${_students.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))] )),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(children: [
                              ElevatedButton.icon(onPressed: () async {
                                int nextRoll = 1; while (_students.any((s) => s.rollNo.trim() == nextRoll.toString())) nextRoll++;
                                await DatabaseHelper.instance.insertLiveStudent(widget.workbookId, nextRoll.toString(), ""); _loadData();
                              }, icon: const Icon(Icons.person_add, size: 18), label: const Text('Add Student')),
                            ]),
                          ),
                          Expanded(
                            child: SingleChildScrollView(scrollDirection: Axis.vertical, child: DataTable(
                              columnSpacing: 20,
                              columns: const [DataColumn(label: Text('Roll No')), DataColumn(label: Text('Name')), DataColumn(label: Text('Action'))],
                              rows: _students.asMap().entries.map((e) => DataRow(color: MaterialStateProperty.all(e.key.isEven ? Colors.grey[50] : Colors.white), cells: [
                                DataCell(AutoSelectTextField(initialValue: e.value.rollNo, decoration: const InputDecoration(hintText: 'Roll No', border: InputBorder.none), onChanged: (val) { DatabaseHelper.instance.updateLiveStudentInfo(widget.workbookId, e.value.rollNo, val, e.value.name); e.value.rollNo = val; })),
                                DataCell(AutoSelectTextField(initialValue: e.value.name, decoration: InputDecoration(hintText: 'Student ${e.value.rollNo}', border: InputBorder.none), onChanged: (val) { DatabaseHelper.instance.updateLiveStudentInfo(widget.workbookId, e.value.rollNo, e.value.rollNo, val); e.value.name = val; })),
                                DataCell(IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteConfirmation("Student", e.value.name.isEmpty ? 'Student ${e.value.rollNo}' : e.value.name, () async { await DatabaseHelper.instance.deleteLiveStudent(widget.workbookId, e.value.rollNo); _loadData(); }))),
                              ])).toList(),
                            ))
                          )
                        ],
                      )
                    )
                  )
                ],
              ),
            ),
            // TAB 2 & 3
            SetupWizardWidget(
              palette: const [Colors.blue, Colors.purple, Colors.teal, Colors.indigo, Colors.pink, Colors.orange], initialSubjects: _subjects,
              onSetupComplete: (_, subjects) async { await DatabaseHelper.instance.updateWorkbookSubjects(widget.workbookId, subjects); _loadData(); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Global Subjects Saved Successfully!'), backgroundColor: Colors.green)); },
            ),
            GlobalFinalResultTabWidget(workbookId: widget.workbookId, terms: _terms, subjects: _subjects, students: _students),
          ],
        ),
      ),
    );
  }
}
