import 'dart:ui';
import 'package:flutter/material.dart';
import 'crash_logger.dart';
import 'log_viewer_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Catch Flutter UI errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    CrashLogger.logError(
      details.exception, 
      details.stack, 
      screenName: 'UI Rendering Crash',
    );
  };

  // 2. Catch Background & Asynchronous errors
  PlatformDispatcher.instance.onError = (error, stack) {
    CrashLogger.logError(
      error, 
      stack, 
      screenName: 'Background Task / Async Error',
    );
    return true;
  };

  // 3. Custom friendly screen when any widget fails to build
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
              const Text(
                'Oops! Something went wrong in the rendering engine.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                details.exceptionAsString(),
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
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
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const ResultMasterWorkbookHome(),
    );
  }
}

// ==========================================
// DATA ARCHITECTURE / MODELS
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
    if (components.isNotEmpty) {
      maxMarks = components.fold(0.0, (sum, c) => sum + c.maxMarks);
    }
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
      String val = (marks[sub.name] ?? "").trim();
      return val.isNotEmpty && val != "AB" && val != "NA" && double.tryParse(val) != null;
    } else {
      for (var c in sub.components) {
        String val = (marks["${sub.name}_${c.name}"] ?? "").trim();
        if (val.isNotEmpty && val != "AB" && val != "NA" && double.tryParse(val) != null) {
          return true;
        }
      }
      return false;
    }
  }
}

// ==========================================
// WORKBOOK HOME SCREEN
// ==========================================
class ResultMasterWorkbookHome extends StatefulWidget {
  const ResultMasterWorkbookHome({super.key});

  @override
  State<ResultMasterWorkbookHome> createState() => _ResultMasterWorkbookHomeState();
}

class _ResultMasterWorkbookHomeState extends State<ResultMasterWorkbookHome> {
  int _tapCount = 0;
  String? _workbookTitle;
  List<SubjectSetup> _configuredSubjects = [];
  List<StudentRow> _studentsTable = [];
  bool _isWorkbookActive = false;

  final List<Color> _palette = [
    Colors.blue, Colors.purple, Colors.teal, Colors.indigo, Colors.pink,
    Colors.orange, Colors.cyan, Colors.deepOrange, Colors.green,
  ];

  void _handleSecretTap() {
    setState(() {
      _tapCount++;
      if (_tapCount >= 5) {
        _tapCount = 0;
        Navigator.push(context, MaterialPageRoute(builder: (context) => const LogViewerScreen()));
      }
    });
  }

  void _launchSetupWizard() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SetupWizardWidget(
        palette: _palette,
        onSetupComplete: (title, subjects) {
          setState(() {
            _workbookTitle = title;
            _configuredSubjects = subjects;
            _isWorkbookActive = true;
            
            _studentsTable = [
              StudentRow(rollNo: "1", name: "Tanush Bhal", marks: {}),
              StudentRow(rollNo: "2", name: "Aarav Sharma", marks: {}),
              StudentRow(rollNo: "3", name: "Isha Patel", marks: {}),
              StudentRow(rollNo: "4", name: "Reyansh Gupta", marks: {}),
            ];
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isWorkbookActive ? _workbookTitle! : 'ResultMaster Workbook'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: _isWorkbookActive ? [
          IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _isWorkbookActive = false))
        ] : null,
      ),
      body: _isWorkbookActive
          ? WorkbookDashboardWidget(
              subjects: _configuredSubjects,
              students: _studentsTable,
              onStudentsUpdated: () => setState(() {}),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.school, size: 80, color: Colors.blue),
                    const SizedBox(height: 24),
                    const Text('Welcome to ResultMaster!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Your offline marks & result management app.', style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _launchSetupWizard,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Dynamic Workbook Wizard'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                    ),
                    const SizedBox(height: 48),
                    GestureDetector(
                      onTap: _handleSecretTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                        child: Text('ResultMaster v1.0.0 (Tap 5x for Logs)', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ==========================================
// SETUP WIZARD WITH BIFURCATION BUILDER
// ==========================================
class SetupWizardWidget extends StatefulWidget {
  final List<Color> palette;
  final Function(String title, List<SubjectSetup> subjects) onSetupComplete;

  const SetupWizardWidget({super.key, required this.palette, required this.onSetupComplete});

  @override
  State<SetupWizardWidget> createState() => _SetupWizardWidgetState();
}

class _SetupWizardWidgetState extends State<SetupWizardWidget> {
  final _titleController = TextEditingController(text: "Class 3 Assessment Workspace");
  late List<SubjectSetup> _subjects;

  @override
  void initState() {
    super.initState();
    _subjects = [
      SubjectSetup(name: "ENG.", maxMarks: 100, passingMarks: 33, themeColor: widget.palette[0]),
      SubjectSetup(name: "HINDI", maxMarks: 100, passingMarks: 33, themeColor: widget.palette[1]),
      SubjectSetup(name: "MATH", maxMarks: 100, passingMarks: 33, themeColor: widget.palette[2]),
      SubjectSetup(name: "SCIENCE", maxMarks: 100, passingMarks: 33, themeColor: widget.palette[3]),
      SubjectSetup(name: "S.ST.", maxMarks: 100, passingMarks: 33, themeColor: widget.palette[4]),
      SubjectSetup(name: "FMM", maxMarks: 100, passingMarks: 33, includeInPassFail: false, includeInPercentage: false, themeColor: widget.palette[5]),
      SubjectSetup(name: "S.K.T.", maxMarks: 100, passingMarks: 33, includeInPassFail: false, includeInPercentage: false, themeColor: widget.palette[6]),
    ];
  }

  void _addNewSubjectField() {
    setState(() {
      Color assignedColor = widget.palette[_subjects.length % widget.palette.length];
      _subjects.add(SubjectSetup(name: "NEW SUBJ", themeColor: assignedColor));
    });
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
              const Text('Configure Assessment Setup', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Workbook Title / Examination Name', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _subjects.length,
              itemBuilder: (context, index) {
                final sub = _subjects[index];
                return Card(
                  key: ValueKey(index),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Container(
                    decoration: BoxDecoration(border: Border(left: BorderSide(color: sub.themeColor, width: 6))),
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: sub.name,
                                decoration: const InputDecoration(labelText: 'Subject Name'),
                                onChanged: (val) => sub.name = val,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => setState(() => _subjects.removeAt(index)),
                            )
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: sub.maxMarks.toStringAsFixed(0),
                                readOnly: sub.components.isNotEmpty, 
                                decoration: InputDecoration(
                                  labelText: sub.components.isNotEmpty ? 'Max Marks (Auto)' : 'Max Marks',
                                  filled: sub.components.isNotEmpty,
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (val) => sub.maxMarks = double.tryParse(val) ?? 100.0,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                initialValue: sub.passingMarks.toStringAsFixed(0),
                                decoration: const InputDecoration(labelText: 'Pass Marks'),
                                keyboardType: TextInputType.number,
                                onChanged: (val) => sub.passingMarks = double.tryParse(val) ?? 33.0,
                              ),
                            ),
                          ],
                        ),
                        if (sub.components.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Bifurcated Parts (Theory, Practical, etc.):", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo)),
                                ...sub.components.asMap().entries.map((cEntry) {
                                  int cIdx = cEntry.key;
                                  SubjectComponent comp = cEntry.value;
                                  return Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: TextFormField(
                                          initialValue: comp.name,
                                          decoration: const InputDecoration(labelText: "Part Name (e.g. Theory)", isDense: true),
                                          onChanged: (val) => setState(() => comp.name = val),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: comp.maxMarks.toStringAsFixed(0),
                                          decoration: const InputDecoration(labelText: "Max", isDense: true),
                                          keyboardType: TextInputType.number,
                                          onChanged: (val) {
                                            setState(() {
                                              comp.maxMarks = double.tryParse(val) ?? 0.0;
                                              sub.recalculateMaxMarks();
                                            });
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                                        onPressed: () => setState(() {
                                          sub.components.removeAt(cIdx);
                                          sub.recalculateMaxMarks();
                                        }),
                                      )
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: () => setState(() {
                                sub.components.add(SubjectComponent(name: "Part ${sub.components.length + 1}", maxMarks: 30));
                                sub.recalculateMaxMarks();
                              }),
                              icon: const Icon(Icons.call_split, size: 16),
                              label: const Text("Add Bifurcation Part", style: TextStyle(fontSize: 12)),
                            ),
                            Row(
                              children: [
                                Checkbox(value: sub.includeInPassFail, onChanged: (val) => setState(() => sub.includeInPassFail = val ?? true)),
                                const Text('Pass/Fail', style: TextStyle(fontSize: 11)),
                                Checkbox(value: sub.includeInPercentage, onChanged: (val) => setState(() => sub.includeInPercentage = val ?? true)),
                                const Text('Total %', style: TextStyle(fontSize: 11)),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              children: [
                Expanded(child: OutlinedButton.icon(onPressed: _addNewSubjectField, icon: const Icon(Icons.add), label: const Text('Add Subject Matrix'))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(onPressed: () { Navigator.pop(context); widget.onSetupComplete(_titleController.text, _subjects); }, child: const Text('Build Sheets'))),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// WORKBOOK CORE DASHBOARD
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
    final filteredStudents = widget.students.where((s) {
      final query = _searchQuery.toLowerCase();
      return s.name.toLowerCase().contains(query) || s.rollNo.toLowerCase().contains(query);
    }).toList();

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by Roll No or Student Name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _searchQuery = "")) : null,
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
                Tab(icon: Icon(Icons.people), text: "Master List (Edit Names)"),
                Tab(icon: Icon(Icons.subject), text: "Subject Sheets (Enter Marks)"),
                Tab(icon: Icon(Icons.assignment_turned_in), text: "Final Calculation Sheet"),
                Tab(icon: Icon(Icons.analytics), text: "Statistical Summary"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                MasterListTab(students: filteredStudents, allStudents: widget.students, subjects: widget.subjects, onUpdate: () { widget.onStudentsUpdated(); setState(() {}); }),
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

// ==========================================
// TAB 1: MASTER LIST (WITH DUPLICATE SHIELD)
// ==========================================
class MasterListTab extends StatelessWidget {
  final List<StudentRow> students;
  final List<StudentRow> allStudents;
  final List<SubjectSetup> subjects;
  final VoidCallback onUpdate;

  const MasterListTab({super.key, required this.students, required this.allStudents, required this.subjects, required this.onUpdate});

  void _addNewStudent(BuildContext context) {
    // Smart auto-calculator for next unique roll number!
    int nextRoll = 1;
    while (allStudents.any((s) => s.rollNo.trim() == nextRoll.toString())) {
      nextRoll++;
    }
    allStudents.add(StudentRow(rollNo: nextRoll.toString(), name: "New Student", marks: {}));
    onUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Names & Roll Numbers editable ONLY here.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
              ElevatedButton.icon(
                onPressed: () => _addNewStudent(context),
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Add Student'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[50]),
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
                headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
                columns: const [
                  DataColumn(label: Text('Roll No', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Actions')),
                ],
                rows: students.map((student) {
                  // Real-time scan for duplicates
                  bool isDuplicate = allStudents.where((s) => s.rollNo.trim() == student.rollNo.trim() && s != student).isNotEmpty;

                  return DataRow(
                    cells: [
                      DataCell(
                        Container(
                          color: isDuplicate ? Colors.red[100] : null,
                          child: TextFormField(
                            initialValue: student.rollNo,
                            style: TextStyle(
                              color: isDuplicate ? Colors.red[900] : Colors.black,
                              fontWeight: isDuplicate ? FontWeight.bold : FontWeight.normal,
                            ),
                            decoration: const InputDecoration(border: InputBorder.none, hintText: "Roll No"),
                            onChanged: (val) {
                              student.rollNo = val;
                              onUpdate();
                              
                              // Trigger instant red popup error if a duplicate is created
                              if (allStudents.where((s) => s.rollNo.trim() == val.trim() && s != student).isNotEmpty) {
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: Roll number $val is already entered!'),
                                    backgroundColor: Colors.red[800],
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                      DataCell(
                        TextFormField(
                          initialValue: student.name,
                          decoration: const InputDecoration(border: InputBorder.none),
                          onChanged: (val) => student.name = val,
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () { allStudents.remove(student); onUpdate(); },
                        ),
                      ),
                    ],
                  );
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
// SHARED STATISTICAL SUMMARY CALCULATOR
// ==========================================
class SummaryTableBuilder {
  static List<DataRow> buildRows(List<SubjectSetup> subjects, List<StudentRow> students, {bool includeSumRow = true}) {
    int grandAppeared = 0;
    int grandPassed = 0;
    int grandDistinction = 0;
    Map<String, int> grandBrackets = {
      '0-20': 0, '21-32.9': 0, '33-40': 0, '41-50': 0, '51-59.9': 0,
      '60': 0, '61-70': 0, '71-74.9': 0, '75-80': 0, '81-90': 0,
      '90': 0, '91-94.9': 0, '95-100': 0
    };

    final subjectRows = subjects.map((sub) {
      int appeared = 0;
      int passed = 0;
      int distinction = 0;
      double sumMarks = 0.0;
      Map<String, int> distribution = {
        '0-20': 0, '21-32.9': 0, '33-40': 0, '41-50': 0, '51-59.9': 0,
        '60': 0, '61-70': 0, '71-74.9': 0, '75-80': 0, '81-90': 0,
        '90': 0, '91-94.9': 0, '95-100': 0
      };

      for (var row in students) {
        if (!row.isSubjectAttempted(sub)) continue;
        double score = row.getSubjectScore(sub);
        appeared++;
        sumMarks += score;

        if (score >= sub.passingMarks) passed++;
        if (score >= (sub.maxMarks * 0.75)) distinction++;

        if (score >= 0 && score < 21) distribution['0-20'] = distribution['0-20']! + 1;
        else if (score >= 21 && score < 32.9) distribution['21-32.9'] = distribution['21-32.9']! + 1;
        else if (score >= 33 && score < 40) distribution['33-40'] = distribution['33-40']! + 1;
        else if (score >= 41 && score < 50) distribution['41-50'] = distribution['41-50']! + 1;
        else if (score >= 51 && score < 59.9) distribution['51-59.9'] = distribution['51-59.9']! + 1;
        else if (score == 60) distribution['60'] = distribution['60']! + 1;
        else if (score >= 61 && score < 70) distribution['61-70'] = distribution['61-70']! + 1;
        else if (score >= 71 && score < 74.9) distribution['71-74.9'] = distribution['71-74.9']! + 1;
        else if (score >= 75 && score < 80) distribution['75-80'] = distribution['75-80']! + 1;
        else if (score >= 81 && score < 90) distribution['81-90'] = distribution['81-90']! + 1;
        else if (score == 90) distribution['90'] = distribution['90']! + 1;
        else if (score >= 91 && score < 94.9) distribution['91-94.9'] = distribution['91-94.9']! + 1;
        else if (score >= 95 && score <= 100) distribution['95-100'] = distribution['95-100']! + 1;
      }

      double passPct = appeared > 0 ? (passed / appeared) * 100 : 0.0;
      double qi = appeared > 0 ? (sumMarks / appeared) : 0.0;

      grandAppeared += appeared;
      grandPassed += passed;
      grandDistinction += distinction;
      distribution.forEach((key, val) => grandBrackets[key] = grandBrackets[key]! + val);

      return DataRow(
        cells: [
          DataCell(Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(appeared.toString())),
          DataCell(Text(passed.toString())),
          DataCell(Text('${passPct.toStringAsFixed(2)}%')),
          DataCell(Text(distinction.toString())),
          DataCell(Text(qi.toStringAsFixed(2))),
          DataCell(Text(distribution['0-20'].toString())),
          DataCell(Text(distribution['21-32.9'].toString())),
          DataCell(Text(distribution['33-40'].toString())),
          DataCell(Text(distribution['41-50'].toString())),
          DataCell(Text(distribution['51-59.9'].toString())),
          DataCell(Text(distribution['60'].toString())),
          DataCell(Text(distribution['61-70'].toString())),
          DataCell(Text(distribution['71-74.9'].toString())),
          DataCell(Text(distribution['75-80'].toString())),
          DataCell(Text(distribution['81-90'].toString())),
          DataCell(Text(distribution['90'].toString())),
          DataCell(Text(distribution['91-94.9'].toString())),
          DataCell(Text(distribution['95-100'].toString())),
        ],
      );
    }).toList();

    if (!includeSumRow) return subjectRows;

    final sumRow = DataRow(
      color: MaterialStateProperty.all(Colors.orange[100]),
      cells: [
        const DataCell(Text('SUM', style: TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(grandAppeared.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(grandPassed.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
        const DataCell(Text('-')),
        DataCell(Text(grandDistinction.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
        const DataCell(Text('-')),
        DataCell(Text(grandBrackets['0-20'].toString())),
        DataCell(Text(grandBrackets['21-32.9'].toString())),
        DataCell(Text(grandBrackets['33-40'].toString())),
        DataCell(Text(grandBrackets['41-50'].toString())),
        DataCell(Text(grandBrackets['51-59.9'].toString())),
        DataCell(Text(grandBrackets['60'].toString())),
        DataCell(Text(grandBrackets['61-70'].toString())),
        DataCell(Text(grandBrackets['71-74.9'].toString())),
        DataCell(Text(grandBrackets['75-80'].toString())),
        DataCell(Text(grandBrackets['81-90'].toString())),
        DataCell(Text(grandBrackets['90'].toString())),
        DataCell(Text(grandBrackets['91-94.9'].toString())),
        DataCell(Text(grandBrackets['95-100'].toString())),
      ],
    );

    return [...subjectRows, sumRow];
  }

  static List<DataColumn> getColumns() {
    return const [
      DataColumn(label: Text('SUBJECT', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(label: Text('APPEARED')),
      DataColumn(label: Text('PASS')),
      DataColumn(label: Text('PASS %')),
      DataColumn(label: Text('DISTT')),
      DataColumn(label: Text('QI (AVG)')),
      DataColumn(label: Text('0-20')),
      DataColumn(label: Text('21-32.9')),
      DataColumn(label: Text('33-40')),
      DataColumn(label: Text('41-50')),
      DataColumn(label: Text('51-59.9')),
      DataColumn(label: Text('60')),
      DataColumn(label: Text('61-70')),
      DataColumn(label: Text('71-74.9')),
      DataColumn(label: Text('75-80')),
      DataColumn(label: Text('81-90')),
      DataColumn(label: Text('90')),
      DataColumn(label: Text('91-94.9')),
      DataColumn(label: Text('95-100')),
    ];
  }
}

// ==========================================
// TAB 2: SEPARATE SUBJECT SHEETS + LIVE TABLE
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
    if (clean == "A" || clean == "AB" || clean == "N" || clean == "NA") return clean;
    if (!RegExp(r'^[0-9]+(\.[0-9]+)?$').hasMatch(clean)) return "";
    double? val = double.tryParse(clean);
    if (val == null || val > maxAllowed || val > 100.0) return "";
    return clean;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.subjects.isEmpty) return const Center(child: Text("No subjects configured."));
    final currentSub = widget.subjects[_selectedSubjectIndex];

    int totalStudents = widget.allStudents.length;
    int enteredCount = widget.allStudents.where((s) {
      if (s.pinnedSubjects.contains(currentSub.name)) return false;
      return s.isSubjectAttempted(currentSub);
    }).length;

    bool isComplete = (enteredCount == totalStudents && totalStudents > 0);

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: widget.subjects.asMap().entries.map((entry) {
              final idx = entry.key;
              final sub = entry.value;
              final isSelected = idx == _selectedSubjectIndex;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(sub.name, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                  selected: isSelected,
                  selectedColor: sub.themeColor,
                  onSelected: (selected) { if (selected) setState(() => _selectedSubjectIndex = idx); },
                ),
              );
            }).toList(),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: currentSub.themeColor.withOpacity(0.15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subject: ${currentSub.name} (Max: ${currentSub.maxMarks.toStringAsFixed(0)})', style: TextStyle(fontWeight: FontWeight.bold, color: currentSub.themeColor, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: isComplete ? Colors.green : Colors.red, borderRadius: BorderRadius.circular(16)),
                child: Text('Entered: $enteredCount / $totalStudents', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
        ),
        Container(
          color: Colors.amber[50],
          width: double.infinity,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(Colors.yellow[200]),
                dataRowHeight: 38,
                headingRowHeight: 38,
                border: TableBorder.all(color: Colors.grey[400]!),
                columns: SummaryTableBuilder.getColumns(),
                rows: SummaryTableBuilder.buildRows([currentSub], widget.students, includeSumRow: false),
              ),
            ),
          ),
        ),
        const Divider(height: 1, thickness: 2),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                columns: [
                  const DataColumn(label: Text('Roll No')),
                  const DataColumn(label: Text('Student Name')),
                  if (currentSub.components.isEmpty)
                    DataColumn(label: Text('${currentSub.name} Marks\n(Max: ${currentSub.maxMarks.toStringAsFixed(0)})'))
                  else ...[
                    ...currentSub.components.map((c) => DataColumn(label: Text('${c.name}\n(Max: ${c.maxMarks.toStringAsFixed(0)})'))),
                    DataColumn(label: Text('Total Score\n(Max: ${currentSub.maxMarks.toStringAsFixed(0)})', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
                  ],
                  const DataColumn(label: Text('Pin Review')),
                ],
                rows: widget.students.map((student) {
                  bool isPinned = student.pinnedSubjects.contains(currentSub.name);
                  double totalObtained = student.getSubjectScore(currentSub);
                  bool isFail = student.isSubjectAttempted(currentSub) && totalObtained < currentSub.passingMarks;

                  return DataRow(
                    color: MaterialStateProperty.all(isPinned ? Colors.amber[50] : null),
                    cells: [
                      DataCell(Text(student.rollNo)),
                      DataCell(Text(student.name)),
                      if (currentSub.components.isEmpty)
                        DataCell(
                          Container(
                            color: isFail ? Colors.red[100] : null,
                            child: TextFormField(
                              initialValue: student.marks[currentSub.name],
                              keyboardType: TextInputType.text,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(hintText: "-", border: InputBorder.none),
                              onChanged: (newValue) {
                                setState(() {
                                  student.marks[currentSub.name] = _cleanMarkInput(newValue, currentSub.maxMarks);
                                });
                              },
                            ),
                          ),
                        )
                      else ...[
                        ...currentSub.components.map((comp) {
                          String key = "${currentSub.name}_${comp.name}";
                          return DataCell(
                            Container(
                              color: isFail ? Colors.red[100] : null,
                              child: TextFormField(
                                initialValue: student.marks[key],
                                keyboardType: TextInputType.text,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(hintText: "-", border: InputBorder.none),
                                onChanged: (newValue) {
                                  setState(() {
                                    student.marks[key] = _cleanMarkInput(newValue, comp.maxMarks);
                                  });
                                },
                              ),
                            ),
                          );
                        }),
                        DataCell(
                          Container(
                            color: isFail ? Colors.red[100] : null,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Text(
                              student.isSubjectAttempted(currentSub) ? totalObtained.toStringAsFixed(1) : "-",
                              style: TextStyle(fontWeight: FontWeight.bold, color: isFail ? Colors.red[900] : Colors.indigo[900]),
                            ),
                          ),
                        ),
                      ],
                      DataCell(
                        IconButton(
                          icon: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined, color: isPinned ? Colors.deepOrange : Colors.grey),
                          onPressed: () => setState(() { if (isPinned) student.pinnedSubjects.remove(currentSub.name); else student.pinnedSubjects.add(currentSub.name); }),
                        ),
                      ),
                    ],
                  );
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
// TAB 3: FINAL CALCULATION WITH SORTING
// ==========================================
class FinalSheetTab extends StatefulWidget {
  final List<SubjectSetup> subjects;
  final List<StudentRow> students;

  const FinalSheetTab({super.key, required this.subjects, required this.students});

  @override
  State<FinalSheetTab> createState() => _FinalSheetTabState();
}

class _FinalSheetTabState extends State<FinalSheetTab> {
  int? _sortColumnIndex;
  bool _sortAscending = true;

  double _getTotalObtained(StudentRow student) {
    double total = 0.0;
    for (var sub in widget.subjects) {
      if (sub.includeInPercentage && student.isSubjectAttempted(sub)) {
        total += student.getSubjectScore(sub);
      }
    }
    return total;
  }

  double _getPercentage(StudentRow student) {
    double totalObtained = 0.0;
    double totalMaxPossible = 0.0;
    for (var sub in widget.subjects) {
      if (sub.includeInPercentage) {
        if (student.isSubjectAttempted(sub)) totalObtained += student.getSubjectScore(sub);
        totalMaxPossible += sub.maxMarks;
      }
    }
    return totalMaxPossible > 0 ? (totalObtained / totalMaxPossible) * 100 : 0.0;
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;

      widget.students.sort((a, b) {
        int comparison = 0;
        if (columnIndex == 0) {
          int? rollA = int.tryParse(a.rollNo);
          int? rollB = int.tryParse(b.rollNo);
          comparison = (rollA != null && rollB != null) ? rollA.compareTo(rollB) : a.rollNo.compareTo(b.rollNo);
        } else if (columnIndex == 1) {
          comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        } else if (columnIndex >= 2 && columnIndex < 2 + widget.subjects.length) {
          SubjectSetup sub = widget.subjects[columnIndex - 2];
          comparison = a.getSubjectScore(sub).compareTo(b.getSubjectScore(sub));
        } else if (columnIndex == 2 + widget.subjects.length) {
          comparison = _getTotalObtained(a).compareTo(_getTotalObtained(b));
        } else if (columnIndex == 2 + widget.subjects.length + 2) {
          comparison = _getPercentage(a).compareTo(_getPercentage(b));
        }
        return ascending ? comparison : -comparison;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.blue[50]),
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _sortAscending,
          columns: [
            DataColumn(label: const Text('Roll No'), onSort: _onSort),
            DataColumn(label: const Text('Student Name'), onSort: _onSort),
            ...widget.subjects.asMap().entries.map((entry) {
              int idx = entry.key;
              SubjectSetup sub = entry.value;
              return DataColumn(label: Text(sub.name), onSort: (colIdx, asc) => _onSort(2 + idx, asc));
            }),
            DataColumn(label: const Text('Total Marks'), onSort: (colIdx, asc) => _onSort(2 + widget.subjects.length, asc)),
            const DataColumn(label: Text('Max Marks')),
            DataColumn(label: const Text('Percentage'), onSort: (colIdx, asc) => _onSort(2 + widget.subjects.length + 2, asc)),
            const DataColumn(label: Text('Pass / Fail')),
            const DataColumn(label: Text('Remarks (Editable)')),
          ],
          rows: widget.students.map((student) {
            double totalObtained = _getTotalObtained(student);
            double totalMaxPossible = 0.0;
            bool failedMandatory = false;

            for (var sub in widget.subjects) {
              if (sub.includeInPercentage) totalMaxPossible += sub.maxMarks;
              if (sub.includeInPassFail && student.isSubjectAttempted(sub) && student.getSubjectScore(sub) < sub.passingMarks) {
                failedMandatory = true;
              }
            }

            double percentage = totalMaxPossible > 0 ? (totalObtained / totalMaxPossible) * 100 : 0.0;
            bool isPassed = !failedMandatory;

            return DataRow(
              cells: [
                DataCell(Text(student.rollNo)),
                DataCell(Text(student.name)),
                ...widget.subjects.map((sub) => DataCell(Text(student.isSubjectAttempted(sub) ? student.getSubjectScore(sub).toStringAsFixed(1) : "-"))),
                DataCell(Text(totalObtained.toStringAsFixed(1))),
                DataCell(Text(totalMaxPossible.toStringAsFixed(0))),
                DataCell(Text('${percentage.toStringAsFixed(2)}%')),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: isPassed ? Colors.green[100] : Colors.red[100], borderRadius: BorderRadius.circular(12)),
                    child: Text(isPassed ? 'PASS' : 'FAIL', style: TextStyle(color: isPassed ? Colors.green[800] : Colors.red[800], fontWeight: FontWeight.bold)),
                  ),
                ),
                DataCell(TextFormField(initialValue: student.remarks, decoration: const InputDecoration(hintText: "Add note...", border: InputBorder.none), onChanged: (val) => student.remarks = val)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ==========================================
// TAB 4: SUMMARY ENGINE WITH "SUM" ROW
// ==========================================
class SummarySheetTab extends StatelessWidget {
  final List<SubjectSetup> subjects;
  final List<StudentRow> students;

  const SummarySheetTab({super.key, required this.subjects, required this.students});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Colors.yellow[100]),
            border: TableBorder.all(color: Colors.grey[300]!),
            columns: SummaryTableBuilder.getColumns(),
            rows: SummaryTableBuilder.buildRows(subjects, students, includeSumRow: true),
          ),
        ),
      ),
    );
  }
}

