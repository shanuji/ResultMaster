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
import '../widgets/premium_ui.dart';

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
    if (data['students'].isEmpty) {
      await DatabaseHelper.instance.insertLiveStudent(widget.workbookId, "1", "");
      await DatabaseHelper.instance.insertLiveStudent(widget.workbookId, "2", "");
      data = await DatabaseHelper.instance.loadFullWorkbookData(widget.workbookId);
    }
    setState(() { _terms = data['terms']; _students = data['students']; _subjects = data['subjects']; _isLoading = false; });
  }

  void _editTitleDialog() {
    String tempTitle = _currentTitle;
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text("Edit Class Name"),
      content: TextField(autofocus: true, decoration: const InputDecoration(hintText: "Class Name"), controller: TextEditingController(text: _currentTitle), onChanged: (val) => tempTitle = val),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(onPressed: () async { if (tempTitle.trim().isNotEmpty) { await DatabaseHelper.instance.updateWorkbookTitle(widget.workbookId, tempTitle.trim()); setState(() => _currentTitle = tempTitle.trim()); } if (context.mounted) Navigator.pop(context); }, child: const Text("Save"))
      ]
    ));
  }

  Future<void> _importExcel() async { try { FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx'], withData: true); if (result != null && result.files.single.bytes != null) { var excel = ex.Excel.decodeBytes(result.files.single.bytes!); for (var table in excel.tables.keys) { for (var row in excel.tables[table]!.rows) { if (row.length >= 2) { String roll = row[0]?.value?.toString().trim() ?? ''; String name = row[1]?.value?.toString().trim() ?? ''; if (roll.isNotEmpty && roll.toLowerCase() != 'roll no') { await DatabaseHelper.instance.insertLiveStudent(widget.workbookId, roll, name); } } } break; } _loadData(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Students imported!'), backgroundColor: Colors.green)); } } catch(e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)); } }
  void _showAddTermDialog() { String termName = ""; showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Add Term'), content: TextField(decoration: const InputDecoration(labelText: 'Term Name'), autofocus: true, onChanged: (val) => termName = val), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), ElevatedButton(onPressed: () async { if (termName.trim().isEmpty) return; if (_terms.any((t) => t.name.trim().toLowerCase() == termName.trim().toLowerCase())) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name exists!'), backgroundColor: Colors.red)); return; } await DatabaseHelper.instance.createTerm(widget.workbookId, termName.trim()); if (context.mounted) Navigator.pop(context); _loadData(); }, child: const Text('Add Term'))])); }
  void _deleteConfirmation(String itemType, String itemName, VoidCallback onDelete) { showDialog(context: context, builder: (context) => AlertDialog(title: Text('Delete $itemType?'), content: Text('Are you sure you want to delete "$itemName"?'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), TextButton(onPressed: () { Navigator.pop(context); onDelete(); }, child: const Text('Delete', style: const TextStyle(color: Colors.red)))])); }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    List<StudentRow> filteredStudents = _searchQuery.isEmpty ? _students : _students.where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase()) || s.rollNo.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Column(
          children: [
            WavyHeader(
              title: _currentTitle,
              leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
              actions: [IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: _editTitleDialog, tooltip: "Edit Class Name")],
            ),
            TabBar(
              labelColor: Theme.of(context).colorScheme.primary, unselectedLabelColor: Colors.grey, indicatorColor: Theme.of(context).colorScheme.primary, indicatorWeight: 3, labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [Tab(icon: Icon(Icons.home), text: "Dashboard"), Tab(icon: Icon(Icons.menu_book), text: "Subjects"), Tab(icon: Icon(Icons.bar_chart), text: "Final Results")],
            ),
            Expanded(
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isTablet = constraints.maxWidth >= 760;
                      final dashboard = _DashboardOverview(
                        terms: _terms,
                        students: _students,
                        subjects: _subjects,
                        filteredStudents: filteredStudents,
                        searchQuery: _searchQuery,
                        onSearchChanged: (val) => setState(() => _searchQuery = val),
                        onAddTerm: _showAddTermDialog,
                        onImportExcel: _importExcel,
                        onAddStudent: () async {
                          int nextRoll = 1;
                          while (_students.any((s) => s.rollNo.trim() == nextRoll.toString())) nextRoll++;
                          await DatabaseHelper.instance.insertLiveStudent(widget.workbookId, nextRoll.toString(), "");
                          _loadData();
                        },
                        onOpenTerm: (term) async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TermWorkspaceScreen(term: term, subjects: _subjects, allStudents: _students),
                            ),
                          );
                          _loadData();
                        },
                        onDeleteTerm: (term) => _deleteConfirmation("Term", term.name, () async {
                          await DatabaseHelper.instance.deleteTerm(term.id);
                          _loadData();
                        }),
                        onDeleteStudent: (student) => _deleteConfirmation(
                          "Student",
                          student.name.isEmpty ? 'Student ${student.rollNo}' : student.name,
                          () async {
                            await DatabaseHelper.instance.deleteLiveStudent(widget.workbookId, student.rollNo);
                            _loadData();
                          },
                        ),
                        onUpdateStudent: (student, roll, name) {
                          DatabaseHelper.instance.updateLiveStudentInfo(widget.workbookId, student.rollNo, roll, name);
                          student.rollNo = roll;
                          student.name = name;
                        },
                      );
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        child: Padding(
                          key: ValueKey(isTablet),
                          padding: EdgeInsets.all(isTablet ? 20 : 12),
                          child: dashboard,
                        ),
                      );
                    },
                  ),
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

class _DashboardOverview extends StatelessWidget {
  final List<TermSetup> terms;
  final List<StudentRow> students;
  final List<SubjectSetup> subjects;
  final List<StudentRow> filteredStudents;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAddTerm;
  final VoidCallback onImportExcel;
  final VoidCallback onAddStudent;
  final ValueChanged<TermSetup> onOpenTerm;
  final ValueChanged<TermSetup> onDeleteTerm;
  final ValueChanged<StudentRow> onDeleteStudent;
  final void Function(StudentRow student, String roll, String name) onUpdateStudent;

  const _DashboardOverview({
    required this.terms,
    required this.students,
    required this.subjects,
    required this.filteredStudents,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onAddTerm,
    required this.onImportExcel,
    required this.onAddStudent,
    required this.onOpenTerm,
    required this.onDeleteTerm,
    required this.onDeleteStudent,
    required this.onUpdateStudent,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 760;
      final termsPanel = _TermsPanel(terms: terms, onAddTerm: onAddTerm, onOpenTerm: onOpenTerm, onDeleteTerm: onDeleteTerm);
      final studentsPanel = _StudentsPanel(
        students: students,
        filteredStudents: filteredStudents,
        searchQuery: searchQuery,
        onSearchChanged: onSearchChanged,
        onImportExcel: onImportExcel,
        onAddStudent: onAddStudent,
        onDeleteStudent: onDeleteStudent,
        onUpdateStudent: onUpdateStudent,
      );
      return Column(
        children: [
          GridView.count(
            crossAxisCount: isWide ? 3 : 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: isWide ? 3.2 : 4.4,
            children: [
              PremiumStatCard(label: 'Students', value: '${students.length}', icon: Icons.groups_rounded, colors: const [Color(0xFF21D4B7), Color(0xFF0A8D82)]),
              PremiumStatCard(label: 'Terms', value: '${terms.length}', icon: Icons.folder_copy_rounded, colors: const [Color(0xFF42A5F5), Color(0xFF1565C0)]),
              PremiumStatCard(label: 'Subjects', value: '${subjects.length}', icon: Icons.auto_stories_rounded, colors: const [Color(0xFFFFB74D), Color(0xFFF57C00)]),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: isWide
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: termsPanel), const SizedBox(width: 16), Expanded(flex: 7, child: studentsPanel)])
                : ListView(children: [SizedBox(height: 360, child: termsPanel), const SizedBox(height: 16), SizedBox(height: 520, child: studentsPanel)]),
          ),
        ],
      );
    });
  }
}

class _TermsPanel extends StatelessWidget {
  final List<TermSetup> terms;
  final VoidCallback onAddTerm;
  final ValueChanged<TermSetup> onOpenTerm;
  final ValueChanged<TermSetup> onDeleteTerm;
  const _TermsPanel({required this.terms, required this.onAddTerm, required this.onOpenTerm, required this.onDeleteTerm});

  @override
  Widget build(BuildContext context) {
    return PremiumPanel(
      child: Column(children: [
        PremiumSectionHeader(title: 'Terms', subtitle: 'Open a term workspace', icon: Icons.event_note_rounded, trailing: FilledButton.tonalIcon(onPressed: onAddTerm, icon: const Icon(Icons.add_rounded), label: const Text('Add'))),
        const SizedBox(height: 14),
        Expanded(
          child: terms.isEmpty
              ? PremiumEmptyState(icon: Icons.folder_open_rounded, title: 'No terms yet', message: 'Create a term to begin entering marks.', action: FilledButton.icon(onPressed: onAddTerm, icon: const Icon(Icons.add), label: const Text('Add term')))
              : ListView.separated(
                  itemCount: terms.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final term = terms[index];
                    return Material(
                      color: Theme.of(context).colorScheme.primary.withOpacity(.06),
                      borderRadius: BorderRadius.circular(20),
                      child: ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        leading: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white, child: Text('${index + 1}')),
                        title: Text(term.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: const Text('Tap to manage marks and summaries'),
                        trailing: IconButton(icon: const Icon(Icons.delete_outline_rounded), color: Theme.of(context).colorScheme.error, onPressed: () => onDeleteTerm(term)),
                        onTap: () => onOpenTerm(term),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

class _StudentsPanel extends StatelessWidget {
  final List<StudentRow> students;
  final List<StudentRow> filteredStudents;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onImportExcel;
  final VoidCallback onAddStudent;
  final ValueChanged<StudentRow> onDeleteStudent;
  final void Function(StudentRow student, String roll, String name) onUpdateStudent;
  const _StudentsPanel({required this.students, required this.filteredStudents, required this.searchQuery, required this.onSearchChanged, required this.onImportExcel, required this.onAddStudent, required this.onDeleteStudent, required this.onUpdateStudent});

  @override
  Widget build(BuildContext context) {
    return PremiumPanel(
      child: Column(children: [
        PremiumSectionHeader(title: 'Student list', subtitle: 'Inline editable class register', icon: Icons.badge_rounded),
        const SizedBox(height: 14),
        Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.end, children: [
          SizedBox(width: 280, child: TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Search by roll no or name'), onChanged: onSearchChanged)),
          FilledButton.tonalIcon(onPressed: onImportExcel, icon: const Icon(Icons.upload_file_rounded), label: const Text('Upload Excel')),
          FilledButton.icon(onPressed: onAddStudent, icon: const Icon(Icons.person_add_alt_1_rounded), label: const Text('Add Student')),
        ]),
        const SizedBox(height: 12),
        Expanded(
          child: filteredStudents.isEmpty
              ? PremiumEmptyState(icon: Icons.manage_search_rounded, title: searchQuery.isEmpty ? 'No students yet' : 'No matches found', message: searchQuery.isEmpty ? 'Add students manually or import from Excel.' : 'Try a different roll number or name.', action: searchQuery.isEmpty ? FilledButton.icon(onPressed: onAddStudent, icon: const Icon(Icons.add), label: const Text('Add student')) : null)
              : ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: MaterialStatePropertyAll(Theme.of(context).colorScheme.primary.withOpacity(.10)),
                      dataRowMinHeight: 58,
                      dataRowMaxHeight: 68,
                      columnSpacing: 24,
                      columns: const [DataColumn(label: Text('Roll No')), DataColumn(label: Text('Name')), DataColumn(label: Text('Action'))],
                      rows: filteredStudents.asMap().entries.map((e) {
                        final student = e.value;
                        return DataRow(color: MaterialStatePropertyAll(e.key.isEven ? Colors.white : const Color(0xFFF3F6F4).withOpacity(.35)), cells: [
                          DataCell(AutoSelectTextField(initialValue: student.rollNo, decoration: const InputDecoration(hintText: 'Roll No', border: InputBorder.none, filled: false), onChanged: (val) => onUpdateStudent(student, val, student.name))),
                          DataCell(AutoSelectTextField(initialValue: student.name, decoration: InputDecoration(hintText: 'Student ${student.rollNo}', border: InputBorder.none, filled: false), onChanged: (val) => onUpdateStudent(student, student.rollNo, val))),
                          DataCell(IconButton(icon: const Icon(Icons.delete_outline_rounded), color: Theme.of(context).colorScheme.error, onPressed: () => onDeleteStudent(student))),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
        ),
      ]),
    );
  }
}
