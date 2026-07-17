import 'dart:ui';
import 'package:flutter/material.dart';
import 'data_models.dart';
import 'setup_wizard.dart';
import 'workbook_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
