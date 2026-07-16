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
class SubjectSetup {
  String name;
  double maxMarks;
  double passingMarks;
  bool includeInPassFail;
  bool includeInPercentage;

  SubjectSetup({
    required this.name,
    this.maxMarks = 100.0,
    this.passingMarks = 33.0,
    this.includeInPassFail = true,
    this.includeInPercentage = true,
  });
}

class StudentRow {
  final String rollNo;
  final String name;
  final Map<String, String> marks;

  StudentRow({
    required this.rollNo,
    required this.name,
    required this.marks,
  });
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

  void _handleSecretTap() {
    setState(() {
      _tapCount++;
      if (_tapCount >= 5) {
        _tapCount = 0;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LogViewerScreen()),
        );
      }
    });
  }

  void _launchSetupWizard() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SetupWizardWidget(
        onSetupComplete: (title, subjects) {
          setState(() {
            _workbookTitle = title;
            _configuredSubjects = subjects;
            _isWorkbookActive = true;
            
            _studentsTable = [
              StudentRow(rollNo: "1", name: "Tanush Bhal", marks: {for (var s in subjects) s.name: "40"}),
              StudentRow(rollNo: "2", name: "Aarav Sharma", marks: {for (var s in subjects) s.name: "AB"}),
              StudentRow(rollNo: "3", name: "Isha Patel", marks: {for (var s in subjects) s.name: "85"}),
              StudentRow(rollNo: "4", name: "Reyansh Gupta", marks: {for (var s in subjects) s.name: "25"}),
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
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => _isWorkbookActive = false),
          )
        ] : null,
      ),
      body: _isWorkbookActive
          ? WorkbookDashboardWidget(
              subjects: _configuredSubjects,
              students: _studentsTable,
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.school, size: 80, color: Colors.blue),
                    const SizedBox(height: 24),
                    const Text(
                      'Welcome to ResultMaster!',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your offline marks & result management app.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _launchSetupWizard,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Dynamic Workbook Wizard'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 48),
                    GestureDetector(
                      onTap: _handleSecretTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'ResultMaster v1.0.0 (Tap 5x for Logs)',
                          style: TextStyle(color: Colors.grey[700], fontSize: 12),
                        ),
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
// DYNAMIC COMPONENT WIZARD SETUP SCREEN
// ==========================================
class SetupWizardWidget extends StatefulWidget {
  final Function(String title, List<SubjectSetup> subjects) onSetupComplete;

  const SetupWizardWidget({super.key, required this.onSetupComplete});

  @override
  State<SetupWizardWidget> createState() => _SetupWizardWidgetState();
}

class _SetupWizardWidgetState extends State<SetupWizardWidget> {
  final _titleController = TextEditingController(text: "Class 3 Assessment Workspace");
  final List<SubjectSetup> _subjects = [
    SubjectSetup(name: "ENG.", maxMarks: 100, passingMarks: 33),
    SubjectSetup(name: "HINDI", maxMarks: 100, passingMarks: 33),
    SubjectSetup(name: "MATH", maxMarks: 100, passingMarks: 33),
    SubjectSetup(name: "SCIENCE", maxMarks: 100, passingMarks: 33),
    SubjectSetup(name: "S.ST.", maxMarks: 100, passingMarks: 33),
    SubjectSetup(name: "FMM", maxMarks: 100, passingMarks: 33, includeInPassFail: false, includeInPercentage: false),
    SubjectSetup(name: "S.K.T.", maxMarks: 100, passingMarks: 33, includeInPassFail: false, includeInPercentage: false),
  ];

  void _addNewSubjectField() {
    setState(() {
      _subjects.add(SubjectSetup(name: "NEW SUBJ"));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24, left: 16, right: 16,
      ),
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Configure Assessment Setup', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Workbook Title / Examination Name', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _subjects.length,
              itemBuilder: (context, index) {
                final sub = _subjects[index];
                return Card(
                  key: ValueKey(index),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
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
                                decoration: const InputDecoration(labelText: 'Max Marks'),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: sub.includeInPassFail,
                                  onChanged: (val) => setState(() => sub.includeInPassFail = val ?? true),
                                ),
                                const Text('Decides Pass/Fail', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                            Row(
                              children: [
                                Checkbox(
                                  value: sub.includeInPercentage,
                                  onChanged: (val) => setState(() => sub.includeInPercentage = val ?? true),
                                ),
                                const Text('Include in Total %', style: TextStyle(fontSize: 12)),
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
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addNewSubjectField,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Subject Matrix'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onSetupComplete(_titleController.text, _subjects);
                    },
                    child: const Text('Build Sheets'),
                  ),
                ),
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
class WorkbookDashboardWidget extends StatelessWidget {
  final List<SubjectSetup> subjects;
  final List<StudentRow> students;

  const WorkbookDashboardWidget({super.key, required this.subjects, required this.students});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const Material(
            color: Colors.blue,
            child: TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: [
                Tab(icon: Icon(Icons.edit_note), text: "Marks Entry Rows"),
                Tab(icon: Icon(Icons.assignment_turned_in), text: "Final Calculation Sheet"),
                Tab(icon: Icon(Icons.analytics), text: "Statistical Summary"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                MarksEntryTab(subjects: subjects, students: students),
                FinalSheetTab(subjects: subjects, students: students),
                SummarySheetTab(subjects: subjects, students: students),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// TAB 1: EDITABLE MARKS ENTRY GRID
// ==========================================
class MarksEntryTab extends StatefulWidget {
  final List<SubjectSetup> subjects;
  final List<StudentRow> students;

  const MarksEntryTab({super.key, required this.subjects, required this.students});

  @override
  State<MarksEntryTab> createState() => _MarksEntryTabState();
}

class _MarksEntryTabState extends State<MarksEntryTab> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
          columns: [
            const DataColumn(label: Text('Roll No')),
            const DataColumn(label: Text('Student Name')),
            ...widget.subjects.map((s) => DataColumn(label: Text('${s.name}\n(Max: ${s.maxMarks.toStringAsFixed(0)})'))),
          ],
          rows: widget.students.map((student) {
            return DataRow(
              cells: [
                DataCell(Text(student.rollNo)),
                DataCell(Text(student.name)),
                ...widget.subjects.map((sub) {
                  return DataCell(
                    TextFormField(
                      initialValue: student.marks[sub.name],
                      keyboardType: TextInputType.text,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(border: InputBorder.none),
                      onChanged: (newValue) {
                        student.marks[sub.name] = newValue.toUpperCase().trim();
                      },
                    ),
                  );
                }),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ==========================================
// TAB 2: FINAL DYNAMIC CALCULATION SHEET
// ==========================================
class FinalSheetTab extends StatelessWidget {
  final List<SubjectSetup> subjects;
  final List<StudentRow> students;

  const FinalSheetTab({super.key, required this.subjects, required this.students});

  double _parseScore(String value) {
    if (value == "AB" || value == "NA" || value.isEmpty) return 0.0;
    return double.tryParse(value) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.blue[50]),
          columns: [
            const DataColumn(label: Text('Roll No')),
            const DataColumn(label: Text('Student Name')),
            ...subjects.map((s) => DataColumn(label: Text(s.name))),
            const DataColumn(label: Text('Total Marks')),
            const DataColumn(label: Text('Max Marks')),
            const DataColumn(label: Text('Percentage')),
            const DataColumn(label: Text('Pass / Fail')),
            const DataColumn(label: Text('Remarks')),
          ],
          rows: students.map((student) {
            double totalObtained = 0.0;
            double totalMaxPossible = 0.0;
            bool failedMandatory = false;

            for (var sub in subjects) {
              double score = _parseScore(student.marks[sub.name] ?? "");
              
              if (sub.includeInPercentage) {
                totalObtained += score;
                totalMaxPossible += sub.maxMarks;
              }

              if (sub.includeInPassFail && score < sub.passingMarks) {
                failedMandatory = true;
              }
            }

            double percentage = totalMaxPossible > 0 ? (totalObtained / totalMaxPossible) * 100 : 0.0;
            bool isPassed = !failedMandatory;
            String remarkStr = isPassed ? "Excellent Progress" : "Needs Remedial Support";

            return DataRow(
              cells: [
                DataCell(Text(student.rollNo)),
                DataCell(Text(student.name)),
                ...subjects.map((sub) => DataCell(Text(student.marks[sub.name] ?? "0"))),
                DataCell(Text(totalObtained.toStringAsFixed(1))),
                DataCell(Text(totalMaxPossible.toStringAsFixed(0))),
                DataCell(Text('${percentage.toStringAsFixed(2)}%')),
                DataCell(
    
