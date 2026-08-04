import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as ex;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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

class _WorkbookDashboardScreenState extends State<WorkbookDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TermSetup> _terms = [];
  List<StudentRow> _students = [];
  List<SubjectSetup> _subjects = [];
  bool _isLoading = true;
  String _currentTitle = "";
  String _searchQuery = "";
  
  final ScrollController _verticalScroll = ScrollController();
  bool _isTopVisible = true;
  final Map<String, FocusNode> _studentFocusNodes = {};

  @override
  void initState() { 
    super.initState(); 
    _tabController = TabController(length: 4, vsync: this);
    _currentTitle = widget.workbookTitle; 
    _loadData(); 
    _verticalScroll.addListener(() {
      if (_verticalScroll.offset > 20 && _isTopVisible) { setState(() => _isTopVisible = false); } 
      else if (_verticalScroll.offset <= 20 && !_isTopVisible) { setState(() => _isTopVisible = true); }
    });
  }

  @override
  void dispose() {
    _tabController.dispose(); _verticalScroll.dispose();
    for (var node in _studentFocusNodes.values) { node.dispose(); }
    super.dispose();
  }

  FocusNode _getStudentNode(String key) => _studentFocusNodes.putIfAbsent(key, () => FocusNode());

  Future<void> _loadData() async {
    var data = await DatabaseHelper.instance.loadFullWorkbookData(widget.workbookId);
    setState(() { _terms = data['terms']; _students = data['students']; _subjects = data['subjects']; _isLoading = false; });
  }

  void _editTitleDialog() { String tempTitle = _currentTitle; showDialog(context: context, builder: (context) => AlertDialog( title: const Text("Edit Class Name"), content: TextField(autofocus: true, decoration: const InputDecoration(hintText: "Class Name"), controller: TextEditingController(text: _currentTitle), onChanged: (val) => tempTitle = val), actions: [ TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")), ElevatedButton(onPressed: () async { if (tempTitle.trim().isNotEmpty) { await DatabaseHelper.instance.updateWorkbookTitle(widget.workbookId, tempTitle.trim()); setState(() => _currentTitle = tempTitle.trim()); } if (context.mounted) Navigator.pop(context); }, child: const Text("Save")) ] )); }
  void _editTermNameDialog(TermSetup term) { String tempName = term.name; showDialog(context: context, builder: (context) => AlertDialog( title: const Text("Edit Term Name"), content: TextField(autofocus: true, decoration: const InputDecoration(hintText: "Term Name"), controller: TextEditingController(text: term.name), onChanged: (val) => tempName = val), actions: [ TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")), ElevatedButton(onPressed: () async { if (tempName.trim().isNotEmpty) { await DatabaseHelper.instance.updateTermName(term.id, tempName.trim()); _loadData(); } if (context.mounted) Navigator.pop(context); }, child: const Text("Save")) ] )); }
  Future<void> _importExcel() async { try { FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx'], withData: true); if (result != null && result.files.single.bytes != null) { var excel = ex.Excel.decodeBytes(result.files.single.bytes!); for (var table in excel.tables.keys) { for (var row in excel.tables[table]!.rows) { if (row.length >= 2) { String roll = row[0]?.value?.toString().trim() ?? ''; String name = row[1]?.value?.toString().trim() ?? ''; if (roll.isNotEmpty && roll.toLowerCase() != 'roll no') { await DatabaseHelper.instance.insertLiveStudent(widget.workbookId, roll, name); } } } break; } _loadData(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Students imported!'), backgroundColor: Colors.green)); } } catch(e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)); } }
  void _showAddTermDialog() { String termName = ""; showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Add Term'), content: TextField(decoration: const InputDecoration(labelText: 'Term Name'), autofocus: true, onChanged: (val) => termName = val), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), ElevatedButton(onPressed: () async { if (termName.trim().isEmpty) return; if (_terms.any((t) => t.name.trim().toLowerCase() == termName.trim().toLowerCase())) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name exists!'), backgroundColor: Colors.red)); return; } await DatabaseHelper.instance.createTerm(widget.workbookId, termName.trim()); if (context.mounted) Navigator.pop(context); _loadData(); }, child: const Text('Add Term'))])); }
  void _deleteConfirmation(String itemType, String itemName, VoidCallback onDelete) { showDialog(context: context, builder: (context) => AlertDialog(title: Text('Delete $itemType?'), content: Text('Are you sure you want to delete "$itemName"?'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), TextButton(onPressed: () { Navigator.pop(context); onDelete(); }, child: const Text('Delete', style: const TextStyle(color: Colors.red)))])); }

  Future<void> _addNewStudentFocus() async {
    int nextRoll = 1; while (_students.any((s) => s.rollNo.trim() == nextRoll.toString())) nextRoll++; 
    await DatabaseHelper.instance.insertLiveStudent(widget.workbookId, nextRoll.toString(), ""); 
    await _loadData();
    Future.delayed(const Duration(milliseconds: 100), () => _getStudentNode('roll_${_students.length - 1}').requestFocus());
  }

  // FIXED EXCEL EXPORT (Renames instead of deleting to avoid Unmodifiable List Error)
  Future<void> _exportToExcel() async {
    setState(() => _isLoading = true);
    try {
      var excel = ex.Excel.createExcel();
      String defaultSheetName = excel.getDefaultSheet() ?? 'Sheet1';
      excel.rename(defaultSheetName, 'Student List');
      
      var sheetStudents = excel['Student List'];
      sheetStudents.appendRow(['Roll No', 'Name']);
      for (var s in _students) { sheetStudents.appendRow([s.rollNo, s.name]); }

      var sheetGlobal = excel['Global Final Result'];
      List<dynamic> globalHeaders = ['Roll No', 'Name'];
      for (var sub in _subjects) { for (var term in _terms) { globalHeaders.add('${sub.name} ${term.name}'); } globalHeaders.add('${sub.name} Total'); }
      globalHeaders.addAll(['GRAND TOTAL', 'OVERALL %']);
      sheetGlobal.appendRow(globalHeaders);

      double globalMax = 0; for (var sub in _subjects) { globalMax += (sub.maxMarks * _terms.length); }
      for (var s in _students) {
        List<dynamic> row = [s.rollNo, s.name];
        double grandTotal = 0;
        for (var sub in _subjects) {
          double subTotal = 0;
          for (var term in _terms) { double score = s.getSubjectScore(term.id, sub); subTotal += score; row.add(s.termMarks[term.id]?[sub.name] ?? "-"); }
          grandTotal += subTotal; row.add(subTotal);
        }
        row.addAll([grandTotal, '${globalMax > 0 ? (grandTotal / globalMax * 100).toStringAsFixed(2) : 0}%']);
        sheetGlobal.appendRow(row);
      }

      for (var term in _terms) {
        var termSheet = excel['${term.name} Final'];
        List<dynamic> tHeaders = ['Roll No', 'Name'];
        for (var sub in _subjects) { tHeaders.add(sub.name); }
        tHeaders.addAll(['Total', '%']);
        termSheet.appendRow(tHeaders);

        double termMax = _subjects.fold(0.0, (sum, sub) => sum + sub.maxMarks);
        for (var s in _students) {
          List<dynamic> row = [s.rollNo, s.name];
          double termTotal = 0;
          for (var sub in _subjects) { double score = s.getSubjectScore(term.id, sub); termTotal += score; row.add(s.termMarks[term.id]?[sub.name] ?? "-"); }
          row.addAll([termTotal, '${termMax > 0 ? (termTotal / termMax * 100).toStringAsFixed(2) : 0}%']);
          termSheet.appendRow(row);
        }

        for (var sub in _subjects) {
          var subSheet = excel['${term.name} - ${sub.name}'];
          List<dynamic> subHeaders = ['Roll No', 'Name'];
          if (sub.components.isEmpty) { subHeaders.add('Marks'); } else { for(var c in sub.components) subHeaders.add(c.name); }
          subHeaders.add('Promoted');
          subSheet.appendRow(subHeaders);
          for (var s in _students) {
            List<dynamic> sRow = [s.rollNo, s.name];
            if (sub.components.isEmpty) { sRow.add(s.termMarks[term.id]?[sub.name] ?? "-"); } else { for(var c in sub.components) sRow.add(s.termMarks[term.id]?['${sub.name}_${c.name}'] ?? "-"); }
            sRow.add(s.termPromotions[term.id]?[sub.name] == true ? "YES" : "NO");
            subSheet.appendRow(sRow);
          }
        }
      }

      var bytes = excel.encode();
      if (bytes != null) {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/ResultMaster_${_currentTitle.replaceAll(' ', '_')}.xlsx');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(file.path)], text: 'ResultMaster Excel Export');
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excel Exported Successfully!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    List<StudentRow> filteredStudents = _searchQuery.isEmpty ? _students : _students.where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase()) || s.rollNo.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return PopScope(
      canPop: _tabController.index == 0,
      onPopInvoked: (didPop) { if (!didPop) { _tabController.animateTo(0); } },
      child: Scaffold(
        resizeToAvoidBottomInset: false, // Prevents keyboard from squishing the layout
        body: Column(
          children: [
            WavyHeader(
              title: _currentTitle, 
              leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)), 
              actions: [
                IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: _editTitleDialog, tooltip: "Edit Class Name"),
                TextButton.icon(onPressed: _exportToExcel, icon: const Icon(Icons.download, color: Colors.white, size: 18), label: const Text("Download Result", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))
              ]
            ),
            TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.primary, unselectedLabelColor: Colors.grey, indicatorColor: Theme.of(context).colorScheme.primary, indicatorWeight: 3, labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              tabs: const [Tab(icon: Icon(Icons.home), text: "Dashboard"), Tab(icon: Icon(Icons.people), text: "Student List"), Tab(icon: Icon(Icons.menu_book), text: "Subject List"), Tab(icon: Icon(Icons.bar_chart), text: "Final Result")],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
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
                    padding: const EdgeInsets.all(12.0),
                    child: Card(
                      elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          AnimatedSize(
                            duration: const Duration(milliseconds: 250), curve: Curves.easeInOut,
                            child: _isTopVisible ? Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      const Text("STUDENT LIST", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00897B), fontSize: 14)),
                                      const Spacer(),
                                      Expanded(child: SizedBox(height: 35, child: TextField(style: const TextStyle(color: Colors.black87), decoration: InputDecoration(hintText: 'Search...', hintStyle: const TextStyle(color: Colors.grey), prefixIcon: const Icon(Icons.search, size: 18), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none)), onChanged: (val) => setState(() => _searchQuery = val)))),
                                    ]
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                  child: Wrap(
                                    spacing: 8, runSpacing: 8, alignment: WrapAlignment.end,
                                    children: [
                                      ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade50, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12)), onPressed: _importExcel, icon: const Icon(Icons.file_upload, size: 16, color: Colors.green), label: const Text('Upload Excel', style: TextStyle(color: Colors.green))),
                                      ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade50, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12)), onPressed: () { FocusScope.of(context).unfocus(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Changes Saved! SQLite Auto-saves constantly.'), backgroundColor: Colors.green)); }, icon: const Icon(Icons.save, size: 16, color: Colors.blue), label: const Text('Save', style: TextStyle(color: Colors.blue))),
                                      ElevatedButton.icon(style: ElevatedButton.styleFrom(elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12)), onPressed: _addNewStudentFocus, icon: const Icon(Icons.add, size: 16), label: const Text("Add Student")),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ]
                            ) : const SizedBox(width: double.infinity),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), color: Colors.blue.shade50,
                            child: const Row(
                              children: [
                                SizedBox(width: 60, child: Text('Roll No', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                SizedBox(width: 48, child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              controller: _verticalScroll,
                              itemCount: filteredStudents.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                var s = filteredStudents[index];
                                return Container(
                                  color: index.isEven ? Colors.white : Colors.grey[50],
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 60, 
                                        child: TextFormField(
                                          focusNode: _getStudentNode('roll_$index'), initialValue: s.rollNo, 
                                          decoration: const InputDecoration(border: InputBorder.none, isDense: true), 
                                          textInputAction: TextInputAction.next, textAlignVertical: TextAlignVertical.center, 
                                          onFieldSubmitted: (_) => _getStudentNode('name_$index').requestFocus(), 
                                          onChanged: (val) { DatabaseHelper.instance.updateLiveStudentInfo(widget.workbookId, s.rollNo, val, s.name); s.rollNo = val; }
                                        )
                                      ),
                                      Expanded(
                                        child: TextFormField(
                                          focusNode: _getStudentNode('name_$index'), initialValue: s.name, 
                                          keyboardType: TextInputType.text, // NO multiline, prevents box expansion
                                          textInputAction: TextInputAction.next,
                                          decoration: const InputDecoration(border: InputBorder.none, isDense: true, hintText: 'Student Name'), 
                                          textAlignVertical: TextAlignVertical.center, 
                                          onFieldSubmitted: (_) { if (index + 1 < filteredStudents.length) { _getStudentNode('roll_${index+1}').requestFocus(); } else { _addNewStudentFocus(); } }, 
                                          onChanged: (val) { DatabaseHelper.instance.updateLiveStudentInfo(widget.workbookId, s.rollNo, s.rollNo, val); s.name = val; }
                                        )
                                      ),
                                      SizedBox(
                                        width: 48, 
                                        child: IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 18), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => _deleteConfirmation("Student", s.name.isEmpty ? 'Student ${s.rollNo}' : s.name, () async { await DatabaseHelper.instance.deleteLiveStudent(widget.workbookId, s.rollNo); _loadData(); }))
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
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
