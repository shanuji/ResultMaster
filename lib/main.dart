import 'dart:ui';
import 'package:flutter/material.dart';
import 'crash_logger.dart';
import 'log_viewer_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    CrashLogger.logError(details.exception, details.stack, screenName: 'UI Rendering Crash');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    CrashLogger.logError(error, stack, screenName: 'Background Task / Async Error');
    return true;
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bug_report, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              const Text('Oops! Layout Error.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(details.exceptionAsString(), style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  };

  runApp(const ResultMasterApp());
}

class ResultMasterApp extends StatelessWidget {
  const ResultMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ResultMaster',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      home: const ResultMasterWorkbookHome(),
    );
  }
}

// ==========================================
// DATA MODELS
// ==========================================
class SubjectComponent {
  String name;
  double maxMarks;
  SubjectComponent({required this.name, required this.maxMarks});
}

class SubjectSetup {
  String name;
  double maxMarks;
  double passingMarks;
  bool includeInPassFail;
  bool includeInPercentage;
  Color themeColor;
  List<SubjectComponent> components;

  SubjectSetup({
    required this.name,
    this.maxMarks = 100.0,
    this.passingMarks = 33.0,
    this.includeInPassFail = true,
    this.includeInPercentage = true,
    this.themeColor = Colors.blue,
    List<SubjectComponent>? components,
  }) : components = components ?? [];

  void recalculateMaxMarks() {
    if (components.isNotEmpty) maxMarks = components.fold(0.0, (sum, c) => sum + c.maxMarks);
  }
}

class StudentRow {
  String rollNo;
  String name;
  Map<String, String> marks;
  String remarks;
  Set<String> pinnedSubjects;

  StudentRow({
    required this.rollNo,
    required this.name,
    required this.marks,
    this.remarks = "",
    Set<String>? pinnedSubjects,
  }) : pinnedSubjects = pinnedSubjects ?? {};

  double getSubjectScore(SubjectSetup sub) {
    if (sub.components.isEmpty) {
      String val = marks[sub.name] ?? "";
      return double.tryParse(val) ?? 0.0;
    } else {
      double total = 0.0;
      for (var c in sub.components) {
        String val = marks["${sub.name}_${c.name}"] ?? "";
        total += double.tryParse(val) ?? 0.0;
      }
      return total;
    }
  }

  bool isSubjectAttempted(SubjectSetup sub) {
    if (sub.components.isEmpty) {
      String val = (marks[sub.name] ?? "").trim().toUpperCase();
      return val.isNotEmpty && (double.tryParse(val) != null || val == "A" || val == "AB");
    } else {
      for (var c in sub.components) {
        String val = (marks["${sub.name}_${c.name}"] ?? "").trim().toUpperCase();
        if (val.isNotEmpty && (double.tryParse(val) != null || val == "A" || val == "AB")) return true;
      }
      return false;
    }
  }
}

// ==========================================
// WORKBOOK HOME
// ==========================================
class ResultMasterWorkbookHome extends StatefulWidget {
  const ResultMasterWorkbookHome({super.key});
  @override
  State<ResultMasterWorkbookHome> createState() => _ResultMasterWorkbookHomeState();
}

class _ResultMasterWorkbookHomeState extends State<ResultMasterWorkbookHome> {
  String? _workbookTitle;
  List<SubjectSetup> _configuredSubjects = [];
  List<StudentRow> _studentsTable = [];
  bool _isWorkbookActive = false;

  final List<Color> _palette = [
    Colors.blue, Colors.purple, Colors.teal, Colors.indigo, Colors.pink, Colors.orange, Colors.cyan, Colors.green,
  ];

  void _launchSetupWizard({bool isEditMode = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SetupWizardWidget(
        palette: _palette,
        initialTitle: isEditMode ? _workbookTitle : null,
        initialSubjects: isEditMode ? _configuredSubjects : null,
        onSetupComplete: (title, subjects) {
          setState(() {
            _workbookTitle = title;
            _configuredSubjects = subjects;
            if (!isEditMode) {
              _studentsTable = [
                StudentRow(rollNo: "1", name: "Tanush Bhal", marks: {}),
                StudentRow(rollNo: "2", name: "Aarav Sharma", marks: {}),
                StudentRow(rollNo: "3", name: "Isha Patel", marks: {}),
                StudentRow(rollNo: "4", name: "Reyansh Gupta", marks: {}),
              ];
            }
            _isWorkbookActive = true;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isWorkbookActive ? _workbookTitle! : 'ResultMaster'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: _isWorkbookActive ? [
          IconButton(icon: const Icon(Icons.settings), onPressed: () => _launchSetupWizard(isEditMode: true)),
          IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _isWorkbookActive = false))
        ] : null,
      ),
      body: _isWorkbookActive
          ? WorkbookDashboardWidget(subjects: _configuredSubjects, students: _studentsTable, onStudentsUpdated: () => setState(() {}))
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.school, size: 80, color: Colors.blue),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _launchSetupWizard(isEditMode: false),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Dynamic Workbook'),
                  ),
                ],
              ),
            ),
    );
  }
}

// ==========================================
// SETUP WIZARD
// ==========================================
class SetupWizardWidget extends StatefulWidget {
  final List<Color> palette;
  final String? initialTitle;
  final List<SubjectSetup>? initialSubjects;
  final Function(String, List<SubjectSetup>) onSetupComplete;

  const SetupWizardWidget({super.key, required this.palette, this.initialTitle, this.initialSubjects, required this.onSetupComplete});

  @override
  State<SetupWizardWidget> createState() => _SetupWizardWidgetState();
}

class _SetupWizardWidgetState extends State<SetupWizardWidget> {
  late TextEditingController _titleController;
  late List<SubjectSetup> _subjects;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? "Class 3 Assessment Workspace");
    
    if (widget.initialSubjects != null && widget.initialSubjects!.isNotEmpty) {
      _subjects = List.from(widget.initialSubjects!);
    } else {
      _subjects = [
        SubjectSetup(name: "ENG.", maxMarks: 100, passingMarks: 33, themeColor: widget.palette[0]),
        SubjectSetup(name: "HINDI", maxMarks: 100, passingMarks: 33, themeColor: widget.palette[1]),
        SubjectSetup(name: "MATH", maxMarks: 100, passingMarks: 33, themeColor: widget.palette[2]),
        SubjectSetup(name: "SCIENCE", maxMarks: 100, passingMarks: 33, themeColor: widget.palette[3]),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 24, left: 16, right: 16),
      height: MediaQuery.of(context).size.height * 0.88,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Configure Setup', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Workbook Title', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _subjects.length,
              itemBuilder: (context, index) {
                final sub = _subjects[index];
                return Card(
                  child: Container(
                    decoration: BoxDecoration(border: Border(left: BorderSide(color: sub.themeColor, width: 6))),
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: sub.name,
                          decoration: const InputDecoration(labelText: 'Subject Name'),
                          onChanged: (val) => sub.name = val,
                        ),
                        Row(
                          children: [
                            Expanded(child: TextFormField(initialValue: sub.maxMarks.toStringAsFixed(0), decoration: const InputDecoration(labelText: 'Max Marks'), keyboardType: TextInputType.number, onChanged: (val) => sub.maxMarks = double.tryParse(val) ?? 100.0)),
                            const SizedBox(width: 12),
                            Expanded(child: TextFormField(initialValue: sub.passingMarks.toStringAsFixed(0), decoration: const InputDecoration(labelText: 'Pass Marks'), keyboardType: TextInputType.number, onChanged: (val) => sub.passingMarks = double.tryParse(val) ?? 33.0)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: ElevatedButton(
              onPressed: () { Navigator.pop(context); widget.onSetupComplete(_titleController.text, _subjects); },
              child: const Text('Save Setup & Build Sheets'),
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// WORKBOOK DASHBOARD (Now with 4 Tabs)
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
      length: 4, // Changed back to 4 tabs
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
                Tab(icon: Icon(Icons.analytics), text: "Statistical Summary"), // Restored Tab
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                MasterListTab(students: filteredStudents, allStudents: widget.students, onUpdate: () { widget.onStudentsUpdated(); setState(() {}); }),
                SubjectMarksTab(subjects: widget.subjects, students: filteredStudents, allStudents: widget.students),
                FinalSheetTab(subjects: widget.subjects, students: filteredStudents),
                SummarySheetTab(subjects: widget.subjects, students: filteredStudents), // Restored View
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// TAB 1: MASTER LIST 
// ==========================================
class MasterListTab extends StatelessWidget {
  final List<StudentRow> students;
  final List<StudentRow> allStudents;
  final VoidCallback onUpdate;

  const MasterListTab({super.key, required this.students, required this.allStudents, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          // FIX: Used Wrap instead of Row to stop the Hallmark/Watermark crash on small screens
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              const Text('Names & Roll Numbers editable ONLY here.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12)),
              ElevatedButton.icon(
                onPressed: () {
                  int nextRoll = 1;
                  while (allStudents.any((s) => s.rollNo.trim() == nextRoll.toString())) nextRoll++;
                  allStudents.add(StudentRow(rollNo: nextRoll.toString(), name: "New Student", marks: {}));
                  onUpdate();
                },
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Add Student'),
              )
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [DataColumn(label: Text('Roll No')), DataColumn(label: Text('Name')), DataColumn(label: Text('Actions'))],
                rows: students.map((student) {
                  return DataRow(cells: [
                    DataCell(TextFormField(initialValue: student.rollNo, decoration: const InputDecoration(border: InputBorder.none), onChanged: (val) { student.rollNo = val; onUpdate(); })),
                    DataCell(TextFormField(initialValue: student.name, decoration: const InputDecoration(border: InputBorder.none), onChanged: (val) => student.name = val)),
                    DataCell(IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () { allStudents.remove(student); onUpdate(); })),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// CUSTOM INPUT FIELD (Fixes Keypad Closing)
// ==========================================
class MarkInputField extends StatefulWidget {
  final String initialValue;
  final Function(String) onChanged;

  const MarkInputField({super.key, required this.initialValue, required this.onChanged});

  @override
  State<MarkInputField> createState() => _MarkInputFieldState();
}

class _MarkInputFieldState extends State<MarkInputField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant MarkInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update if the parent changed it externally
    if (oldWidget.initialValue != widget.initialValue && _controller.text != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next, // Action moves to next, no manual double-jump required
      textAlign: TextAlign.center,
      decoration: const InputDecoration(hintText: "-", border: InputBorder.none),
      onChanged: (val) {
        widget.onChanged(val);
      },
    );
  }
}

// ==========================================
// TAB 2: SUBJECT SHEETS 
// ==========================================
class SubjectMarksTab extends StatefulWidget {
  final List<SubjectSetup> subjects;
  final List<StudentRow> students;
  final List<StudentRow> allStudents;

  const SubjectMarksTab({super.key, required this.subjects, required this.students, required this.allStudents});

  @override
  State<SubjectMarksTab> createState() => _SubjectMarksTabState();
}

class _SubjectMarksTabState extends State<SubjectMarksTab> {
  int _selectedSubjectIndex = 0;

  String _cleanMarkInput(String input, double maxAllowed) {
    String clean = input.toUpperCase().trim();
    if (clean.isEmpty) return "";
    if (clean == "A" || clean == "AB") return clean; 
    if (!RegExp(r'^[0-9]+(\.[0-9]+)?$').hasMatch(clean)) return "";
    double? val = double.tryParse(clean);
    if (val == null || val > maxAllowed) return "";
    return clean;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.subjects.isEmpty) return const Center(child: Text("No subjects configured."));
    final currentSub = widget.subjects[_selectedSubjectIndex];

    int totalStudents = widget.allStudents.length;
    int enteredCount = widget.allStudents.where((s) => s.isSubjectAttempted(currentSub)).length;

    // FIX: Header Background Color changes based on completion status
    bool isComplete = (enteredCount == totalStudents && totalStudents > 0);
    Color headerBgColor = isComplete ? Colors.green[200]! : Colors.red[100]!;

    int passedCount = 0;
    int failedCount = 0;
    int disttCount = 0;
    double sumMarks = 0.0;
    
    for (var s in widget.students) {
      if (s.isSubjectAttempted(currentSub)) {
        double score = s.getSubjectScore(currentSub);
        sumMarks += score;
        if (score >= currentSub.passingMarks) passedCount++; else failedCount++;
        if (score >= (currentSub.maxMarks * 0.75)) disttCount++;
      }
    }
    double qi = enteredCount > 0 ? (sumMarks / enteredCount) : 0
