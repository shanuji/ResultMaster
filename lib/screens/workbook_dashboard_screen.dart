import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as ex;
import 'package:file_picker/file_picker.dart';
import '../models/data_models.dart';
import '../database/database_helper.dart';
import '../widgets/wavy_header.dart';
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
  String _currentTitle = "";
  String _searchQuery = "";

  @override
  void initState() { super.initState(); _currentTitle = widget.workbookTitle; _loadData(); }

  Future<void> _loadData() async {
    var data = await DatabaseHelper.instance.loadFullWorkbookData(widget.workbookId);
    setState(() { _terms = data['terms']; _students = data['students']; _subjects = data['subjects']; _isLoading = false; });
  }

  void _editTitleDialog() { String tempTitle = _currentTitle; showDialog(context: context, builder: (context) => AlertDialog( title: const Text("Edit Class Name"), content: TextField(autofocus: true, decoration: const InputDecoration(hintText: "Class Name"), controller: TextEditingController(text: _currentTitle), onChanged: (val) => tempTitle = val), actions: [ TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")), ElevatedButton(onPressed: () async { if (tempTitle.trim().isNotEmpty) { await DatabaseHelper.instance.updateWorkbookTitle(widget.workbookId, tempTitle.trim()); setState(() => _currentTitle = tempTitle.trim()); } if (context.mounted) Navigator.pop(context); }, child: const Text("Save")) ] )); }
  void _editTermNameDialog(TermSetup term) { String tempName = term.name; showDialog(context: context, builder: (context) => AlertDialog( title: const Text("Edit Term Name"), content: TextField(autofocus: true, decoration: const InputDecoration(hintText: "Term Name"), controller: TextEditingController(text: term.name), onChanged: (val) => tempName = val), actions: [ TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")), ElevatedButton(onPressed: () async { if (tempName.trim().isNotEmpty) { await DatabaseHelper.instance.updateTermName(term.id, tempName.trim()); _loadData(); } if (context.mounted) Navigator.pop(context); }, child: const Text("Save")) ] )); }

  Future<void> _importExcel() async { try { FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx'], withData: true); if (result != null && result.files.single.bytes != null) { var excel = ex.Excel.decodeBytes(result.files.single.bytes!); for (var table in excel.tables.keys) { for (var row in excel.tables[table]!.rows) { if (row.length >= 2) { String roll = row[0]?.value?.toString().trim() ?? ''; String name = row[1]?.value?.toString().trim() ?? ''; if (roll.isNotEmpty && roll.toLowerCase() != 'roll no') { await DatabaseHelper.instance.insertLiveStudent(widget.workbookId, roll, name); } } } break; } _loadData(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Students imported!'), backgroundColor: Colors.green)); } } catch(e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)); } }
  void _showAddTermDialog() { String termName = ""; showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Add Term'), content: TextField(decoration: const InputDecoration(labelText: 'Term Name'), autofocus: true, onChanged: (val) => termName = val), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), ElevatedButton(onPressed: () async { if (termName.trim().isEmpty) return; if (_terms.any((t) => t.name.trim().toLowerCase() == termName.trim().toLowerCase())) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name exists!'), backgroundColor: Colors.red)); return; } await DatabaseHelper.instance.createTerm(widget.workbookId, termName.trim()); if (context.mounted) Navigator.pop(context); _loadData(); }, child: const Text('Add Term'))])); }
  void _deleteConfirmation(String itemType, String itemName, VoidCallback onDelete) { showDialog(context: context, builder: (context) => AlertDialog(title: Text('Delete $itemType?'), content: Text('Are you sure you want to delete "$itemName"?'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), TextButton(onPressed: () { Navigator.pop(context); onDelete(); }, child: const Text('Delete', style: const TextStyle(color: Colors.red)))])); }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    List<StudentRow> filteredStudents = _searchQuery.isEmpty ? _students : _students.where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase()) || s.rollNo.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: Column(
          children: [
            WavyHeader(title: _currentTitle, leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)), actions: [IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: _editTitleDialog, tooltip: "Edit Class Name")]),
            TabBar(
              labelColor: Theme.of(context).colorScheme.primary, unselectedLabelColor: Colors.grey, indicatorColor: Theme.of(context).colorScheme.primary, indicatorWeight: 3, labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [Tab(icon: Icon(Icons.home), text: "Dash"), Tab(icon: Icon(Icons.people), text: "Students"), Tab(icon: Icon(Icons.menu_book), text: "Subjects"), Tab(icon: Icon(Icons.bar_chart), text: "Results")],
            ),
            Expanded(
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // TAB 1: DASHBOARD
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: Card(color: const Color(0xFFFFF8E1), elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Column(children: [const Icon(Icons.people, color: Colors.orangeAccent, size: 32), const SizedBox(height: 8), const Text("Total Students", style: TextStyle(color: Colors.grey, fontSize: 12)), Text("${_students.length}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22))])))),
                            const SizedBox(width: 16),
                            Expanded(child: Card(color: const Color(0xFFE3F2FD), elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Column(children: [const Icon(Icons.folder, color: Colors.blueAccent, size: 32), const SizedBox(height: 8), const Text("Total Terms", style: TextStyle(color: Colors.grey, fontSize: 12)), Text("${_terms.length}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22))])))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Card(
                            elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Column(
                              children: [
                                Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("TERMS", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00897B), fontSize: 16)), TextButton.icon(onPressed: _showAddTermDialog, icon: const Icon(Icons.add), label: const Text("Add Term"))])),
                                const Divider(height: 1),
                                Expanded(
                                  child: ListView.separated(
                                    itemCount: _terms.length, separatorBuilder: (c, i) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      return ListTile(
                                        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: index.isEven ? Colors.green.shade100 : Colors.orange.shade100, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.folder, color: index.isEven ? Colors.green : Colors.orange)),
                                        title: Text(_terms[index].name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 20), onPressed: () => _editTermNameDialog(_terms[index])),
                                            Container(decoration: BoxDecoration(border: Border.all(color: Colors.red.shade100), borderRadius: BorderRadius.circular(8)), child: IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18), onPressed: () => _deleteConfirmation("Term", _terms[index].name, () async { await DatabaseHelper.instance.deleteTerm(_terms[index].id); _loadData(); }))),
                                          ]
                                        ),
                                        onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => TermWorkspaceScreen(term: _terms[index], subjects: _subjects, allStudents: _students))); _loadData(); },
                                      );
                                    }
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // TAB 2: STUDENTS
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                const Text("STUDENT LIST", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00897B), fontSize: 16)),
                                const Spacer(),
                                Expanded(child: SizedBox(height: 35, child: TextField(decoration: InputDecoration(hintText: 'Search...', prefixIcon: const Icon(Icons.search, size: 18), contentPadding: EdgeInsets.zero, border: OutlineInputBorder(borderRadius: BorderRadius.circular(20))), onChanged: (val) => setState(() => _searchQuery = val)))),
                              ]
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade50, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12)), onPressed: _importExcel, icon: const Icon(Icons.file_upload, size: 16, color: Colors.green), label: const Text('Upload Excel', style: TextStyle(color: Colors.green))),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade50, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12)), onPressed: () { FocusScope.of(context).unfocus(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Changes Saved!'), backgroundColor: Colors.green)); }, icon: const Icon(Icons.save, size: 16, color: Colors.blue), label: const Text('Save', style: TextStyle(color: Colors.blue))),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(style: ElevatedButton.styleFrom(elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12)), onPressed: () async { int nextRoll = 1; while (_students.any((s) => s.rollNo.trim() == nextRoll.toString())) nextRoll++; await DatabaseHelper.instance.insertLiveStudent(widget.workbookId, nextRoll.toString(), ""); _loadData(); }, icon: const Icon(Icons.add, size: 16), label: const Text("Add Student")),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: SingleChildScrollView(scrollDirection: Axis.vertical, child: DataTable(
                              columnSpacing: 16, horizontalMargin: 16, headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                              columns: const [DataColumn(label: Text('Roll No')), DataColumn(label: Text('Name')), DataColumn(label: Text('Action'))],
                              rows: filteredStudents.asMap().entries.map((e) => DataRow(color: MaterialStateProperty.all(e.key.isEven ? Colors.grey[50] : Colors.white), cells: [
                                // FIX: Removed AutoSelectTextField, added strict sizing and wrapping
                                DataCell(SizedBox(width: 60, child: TextFormField(initialValue: e.value.rollNo, decoration: const InputDecoration(hintText: 'Roll No', border: InputBorder.none), onChanged: (val) { DatabaseHelper.instance.updateLiveStudentInfo(widget.workbookId, e.value.rollNo, val, e.value.name); e.value.rollNo = val; }))),
                                DataCell(SizedBox(width: 160, child: TextFormField(initialValue: e.value.name, maxLines: null, keyboardType: TextInputType.multiline, decoration: const InputDecoration(hintText: 'Student Name', border: InputBorder.none), onChanged: (val) { DatabaseHelper.instance.updateLiveStudentInfo(widget.workbookId, e.value.rollNo, e.value.rollNo, val); e.value.name = val; }))),
                                DataCell(Container(decoration: BoxDecoration(border: Border.all(color: Colors.red.shade100), borderRadius: BorderRadius.circular(8)), child: IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 18), onPressed: () => _deleteConfirmation("Student", e.value.name.isEmpty ? 'Student ${e.value.rollNo}' : e.value.name, () async { await DatabaseHelper.instance.deleteLiveStudent(widget.workbookId, e.value.rollNo); _loadData(); })))),
                              ])).toList(),
                            ))
                          )
                        ],
                      ),
                    ),
                  ),

                  // TAB 3 & 4
                  SetupWizardWidget(
                    palette: const [Color(0xFF00897B), Colors.purple, Colors.teal, Colors.indigo, Colors.pink, Colors.orange], initialSubjects: _subjects,
                    onSetupComplete: (_, subjects) async { await DatabaseHelper.instance.updateWorkbookSubjects(widget.workbookId, subjects); _loadData(); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subjects Saved!'), backgroundColor: Colors.green)); },
                  ),
                  GlobalFinalResultTabWidget(workbookId: widget.workbookId, terms: _terms, subjects: _subjects, students: _students),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
