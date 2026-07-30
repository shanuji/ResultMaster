import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as ex;
import 'package:file_picker/file_picker.dart';
import '../models/data_models.dart';
import '../database/database_helper.dart';
import '../utils/ux_helpers.dart';
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

  // ... (Keep _importExcel, _showAddTermDialog, and _deleteConfirmation exactly the same) ...
  Future<void> _importExcel() async { try { FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx'], withData: true); if (result != null && result.files.single.bytes != null) { var excel = ex.Excel.decodeBytes(result.files.single.bytes!); for (var table in excel.tables.keys) { for (var row in excel.tables[table]!.rows) { if (row.length >= 2) { String roll = row[0]?.value?.toString().trim() ?? ''; String name = row[1]?.value?.toString().trim() ?? ''; if (roll.isNotEmpty && roll.toLowerCase() != 'roll no') { await DatabaseHelper.instance.insertLiveStudent(widget.workbookId, roll, name); } } } break; } _loadData(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Students imported successfully!'), backgroundColor: Colors.green)); } } catch(e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error reading Excel: $e'), backgroundColor: Colors.red)); } }
  void _showAddTermDialog() { String termName = ""; showDialog( context: context, builder: (context) => AlertDialog( title: const Text('Add New Term'), content: TextField(decoration: const InputDecoration(labelText: 'Term Name (e.g. Term 1)'), autofocus: true, onChanged: (val) => termName = val), actions: [ TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), ElevatedButton( onPressed: () async { if (termName.trim().isEmpty) return; if (_terms.any((t) => t.name.trim().toLowerCase() == termName.trim().toLowerCase())) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A term with this name already exists!'), backgroundColor: Colors.red)); return; } await DatabaseHelper.instance.createTerm(widget.workbookId, termName.trim()); if (context.mounted) Navigator.pop(context); _loadData(); }, child: const Text('Add Term') ) ], ) ); }
  void _deleteConfirmation(String itemType, String itemName, VoidCallback onDelete) { showDialog(context: context, builder: (context) => AlertDialog(title: Text('Delete $itemType?'), content: Text('Are you sure you want to permanently delete "$itemName"?'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), TextButton(onPressed: () { Navigator.pop(context); onDelete(); }, child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))) ])); }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Column(
          children: [
            WavyHeader(
              title: widget.workbookTitle,
              leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
              actions: [IconButton(icon: const Icon(Icons.notifications_none), onPressed: (){})],
            ),
            TabBar(
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).colorScheme.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [Tab(icon: Icon(Icons.home), text: "Dashboard"), Tab(icon: Icon(Icons.menu_book), text: "Global Subjects"), Tab(icon: Icon(Icons.bar_chart), text: "Global Final Results")],
            ),
            Expanded(
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // TAB 1: DASHBOARD (Matching Screenshot 6)
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Top Summary Cards
                        Row(
                          children: [
                            Expanded(child: Card(color: const Color(0xFFFFF8E1), elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12), child: Row(children: [const Icon(Icons.people, color: Colors.orangeAccent, size: 36), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Total Students", style: TextStyle(color: Colors.grey, fontSize: 12)), Text("${_students.length}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24))])])))),
                            const SizedBox(width: 12),
                            Expanded(child: Card(color: const Color(0xFFE3F2FD), elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12), child: Row(children: [const Icon(Icons.folder, color: Colors.blueAccent, size: 36), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Total Terms", style: TextStyle(color: Colors.grey, fontSize: 12)), Text("${_terms.length}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24))])])))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Terms Section
                        Card(
                          elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            children: [
                              Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("TERMS", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00897B), fontSize: 16)), TextButton.icon(onPressed: _showAddTermDialog, icon: const Icon(Icons.add), label: const Text("Add Term"))])),
                              const Divider(height: 1),
                              ListView.separated(
                                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                                itemCount: _terms.length, separatorBuilder: (c, i) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: index.isEven ? Colors.green.shade100 : Colors.orange.shade100, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.folder, color: index.isEven ? Colors.green : Colors.orange)),
                                    title: Text(_terms[index].name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    trailing: Container(decoration: BoxDecoration(border: Border.all(color: Colors.red.shade100), borderRadius: BorderRadius.circular(8)), child: IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18), onPressed: () => _deleteConfirmation("Term", _terms[index].name, () async { await DatabaseHelper.instance.deleteTerm(_terms[index].id); _loadData(); }))),
                                    onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => TermWorkspaceScreen(term: _terms[index], subjects: _subjects, allStudents: _students))); _loadData(); },
                                  );
                                }
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Student List Section
                        Card(
                          elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            children: [
                              Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("STUDENT LIST", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00897B), fontSize: 16)), Row(children: [IconButton(icon: const Icon(Icons.upload_file, color: Colors.green), onPressed: _importExcel, tooltip: "Upload Excel"), TextButton.icon(onPressed: () async { int nextRoll = 1; while (_students.any((s) => s.rollNo.trim() == nextRoll.toString())) nextRoll++; await DatabaseHelper.instance.insertLiveStudent(widget.workbookId, nextRoll.toString(), ""); _loadData(); }, icon: const Icon(Icons.add), label: const Text("Add Student"))])])),
                              const Divider(height: 1),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columnSpacing: 24, headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                                  columns: const [DataColumn(label: Text('Roll No')), DataColumn(label: Text('Name')), DataColumn(label: Text('Action'))],
                                  rows: _students.asMap().entries.map((e) => DataRow(color: MaterialStateProperty.all(e.key.isEven ? Colors.grey[50] : Colors.white), cells: [
                                    DataCell(AutoSelectTextField(initialValue: e.value.rollNo, decoration: const InputDecoration(hintText: 'Roll No', border: InputBorder.none), onChanged: (val) { DatabaseHelper.instance.updateLiveStudentInfo(widget.workbookId, e.value.rollNo, val, e.value.name); e.value.rollNo = val; })),
                                    DataCell(AutoSelectTextField(initialValue: e.value.name, decoration: InputDecoration(hintText: 'Student ${e.value.rollNo}', border: InputBorder.none), onChanged: (val) { DatabaseHelper.instance.updateLiveStudentInfo(widget.workbookId, e.value.rollNo, e.value.rollNo, val); e.value.name = val; })),
                                    DataCell(Container(decoration: BoxDecoration(border: Border.all(color: Colors.red.shade100), borderRadius: BorderRadius.circular(8)), child: IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18), onPressed: () => _deleteConfirmation("Student", e.value.name.isEmpty ? 'Student ${e.value.rollNo}' : e.value.name, () async { await DatabaseHelper.instance.deleteLiveStudent(widget.workbookId, e.value.rollNo); _loadData(); })))),
                                  ])).toList(),
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  
                  // TAB 2 & 3
                  SetupWizardWidget(
                    palette: const [Color(0xFF00897B), Colors.purple, Colors.teal, Colors.indigo, Colors.pink, Colors.orange], initialSubjects: _subjects,
                    onSetupComplete: (_, subjects) async { await DatabaseHelper.instance.updateWorkbookSubjects(widget.workbookId, subjects); _loadData(); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Global Subjects Saved Successfully!'), backgroundColor: Colors.green)); },
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
