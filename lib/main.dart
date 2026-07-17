import 'dart:convert';
import 'dart:io'; // Required for writing the crash log to a file
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; 
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:excel/excel.dart' as ex;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

// ==========================================
// CRASH LOGGER HELPERS
// ==========================================
Future<File> getLogFile() async {
  final dbPath = await getDatabasesPath();
  return File(p.join(dbPath, 'crash_log.txt'));
}

void logCrash(String error, String stackTrace) async {
  try {
    final file = await getLogFile();
    final timestamp = DateTime.now().toIso8601String();
    await file.writeAsString('[$timestamp]\n$error\n$stackTrace\n\n--------------------\n\n', mode: FileMode.append);
  } catch (e) {
    debugPrint('🔴 FAILED TO WRITE LOG: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Catch layout and UI errors
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('🔴 UI CRASH CAUGHT: ${details.exceptionAsString()}');
    logCrash('UI CRASH: ${details.exceptionAsString()}', details.stack.toString());
  };

  // 2. Catch asynchronous and background errors
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('🔴 ASYNC CRASH CAUGHT: $error');
    logCrash('ASYNC CRASH: $error', stack.toString());
    return true; // Prevents the app from instantly crashing
  };

  // 3. Keep the custom error screen for layout bugs
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
              const Text('Oops! Something broke.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
      theme: ThemeData(
        useMaterial3: true, 
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const MasterDashboardHome(),
    );
  }
}

// ==========================================
// SQLITE DATABASE ENGINE
// ==========================================
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('result_master.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE workbooks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workbook_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        max_marks REAL NOT NULL,
        passing_marks REAL NOT NULL,
        include_in_pass_fail INTEGER NOT NULL,
        theme_color INTEGER NOT NULL,
        components_json TEXT,
        FOREIGN KEY (workbook_id) REFERENCES workbooks (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workbook_id INTEGER NOT NULL,
        roll_no TEXT NOT NULL,
        name TEXT NOT NULL,
        remarks TEXT,
        FOREIGN KEY (workbook_id) REFERENCES workbooks (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE student_marks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workbook_id INTEGER NOT NULL,
        roll_no TEXT NOT NULL,
        mark_key TEXT NOT NULL,
        mark_value TEXT NOT NULL,
        FOREIGN KEY (workbook_id) REFERENCES workbooks (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<List<Map<String, dynamic>>> fetchAllWorkbooks() async {
    final db = await instance.database;
    return await db.query('workbooks', orderBy: 'id DESC');
  }

  Future<int> createWorkbook(String title, List<SubjectSetup> subjects) async {
    final db = await instance.database;
    int workbookId = await db.insert('workbooks', {
      'title': title,
      'created_at': DateTime.now().toIso8601String(),
    });

    for (var sub in subjects) {
      List<Map<String, dynamic>> comps = sub.components.map((c) => {'name': c.name, 'maxMarks': c.maxMarks}).toList();
      await db.insert('subjects', {
        'workbook_id': workbookId,
        'name': sub.name,
        'max_marks': sub.maxMarks,
        'passing_marks': sub.passingMarks,
        'include_in_pass_fail': sub.includeInPassFail ? 1 : 0,
        'theme_color': sub.themeColor.value,
        'components_json': jsonEncode(comps),
      });
    }

    List<String> defaultNames = ["Tanush Bhal", "Aarav Sharma", "Isha Patel", "Reyansh Gupta"];
    for (int i = 0; i < defaultNames.length; i++) {
      await db.insert('students', {
        'workbook_id': workbookId,
        'roll_no': (i + 1).toString(),
        'name': defaultNames[i],
        'remarks': '',
      });
    }
    return workbookId;
  }

  Future<void> deleteWorkbook(int id) async {
    final db = await instance.database;
    await db.delete('workbooks', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>> loadWorkbookData(int workbookId) async {
    final db = await instance.database;

    final subMaps = await db.query('subjects', where: 'workbook_id = ?', whereArgs: [workbookId]);
    List<SubjectSetup> subjects = subMaps.map((map) {
      var sub = SubjectSetup(
        name: map['name'] as String,
        maxMarks: map['max_marks'] as double,
        passingMarks: map['passing_marks'] as double,
        includeInPassFail: (map['include_in_pass_fail'] as int) == 1,
        themeColor: Color(map['theme_color'] as int),
      );
      if (map['components_json'] != null) {
        List dynamicList = jsonDecode(map['components_json'] as String);
        sub.components = dynamicList.map((c) => SubjectComponent(name: c['name'], maxMarks: (c['maxMarks'] as num).toDouble())).toList();
      }
      return sub;
    }).toList();

    final studMaps = await db.query('students', where: 'workbook_id = ?', whereArgs: [workbookId], orderBy: 'CAST(roll_no AS INTEGER) ASC, roll_no ASC');
    final markMaps = await db.query('student_marks', where: 'workbook_id = ?', whereArgs: [workbookId]);
    
    Map<String, Map<String, String>> structuralMarks = {};
    for (var m in markMaps) {
      String roll = m['roll_no'] as String;
      String key = m['mark_key'] as String;
      String val = m['mark_value'] as String;
      if (!structuralMarks.containsKey(roll)) structuralMarks[roll] = {};
      structuralMarks[roll]![key] = val;
    }

    List<StudentRow> students = studMaps.map((map) {
      String roll = map['roll_no'] as String;
      return StudentRow(
        rollNo: roll,
        name: map['name'] as String,
        remarks: map['remarks'] as String? ?? "",
        marks: structuralMarks[roll] ?? {},
      );
    }).toList();

    return {'subjects': subjects, 'students': students};
  }

  Future<void> saveLiveMark({required int workbookId, required String rollNo, required String markKey, required String value}) async {
    final db = await instance.database;
    await db.delete('student_marks', where: 'workbook_id = ? AND roll_no = ? AND mark_key = ?', whereArgs: [workbookId, rollNo, markKey]);
    if (value.isNotEmpty) {
      await db.insert('student_marks', {'workbook_id': workbookId, 'roll_no': rollNo, 'mark_key': markKey, 'mark_value': value});
    }
  }

  Future<void> insertLiveStudent(int workbookId, String rollNo, String name) async {
    final db = await instance.database;
    await db.insert('students', {'workbook_id': workbookId, 'roll_no': rollNo, 'name': name, 'remarks': ''});
  }

  Future<void> deleteLiveStudent(int workbookId, String rollNo) async {
    final db = await instance.database;
    await db.delete('students', where: 'workbook_id = ? AND roll_no = ?', whereArgs: [workbookId, rollNo]);
    await db.delete('student_marks', where: 'workbook_id = ? AND roll_no = ?', whereArgs: [workbookId, rollNo]);
  }

  Future<void> clearAllStudents(int workbookId) async {
    final db = await instance.database;
    await db.delete('students', where: 'workbook_id = ?', whereArgs: [workbookId]);
    await db.delete('student_marks', where: 'workbook_id = ?', whereArgs: [workbookId]);
  }

  Future<void> updateLiveStudentInfo(int workbookId, String oldRollNo, String newRollNo, String name) async {
    final db = await instance.database;
    await db.update('students', {'roll_no': newRollNo, 'name': name}, where: 'workbook_id = ? AND roll_no = ?', whereArgs: [workbookId, oldRollNo]);
    if (oldRollNo != newRollNo) {
      await db.update('student_marks', {'roll_no': newRollNo}, where: 'workbook_id = ? AND roll_no = ?', whereArgs: [workbookId, oldRollNo]);
    }
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
// NEW: IN-APP LOG VIEWER SCREEN
// ==========================================
class CrashLogScreen extends StatefulWidget {
  const CrashLogScreen({super.key});
  @override
  State<CrashLogScreen> createState() => _CrashLogScreenState();
}

class _CrashLogScreenState extends State<CrashLogScreen> {
  String _logs = "Loading logs...";

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      final file = await getLogFile();
      if (await file.exists()) {
        final contents = await file.readAsString();
        setState(() => _logs = contents.isEmpty ? "No crashes recorded yet!" : contents);
      } else {
        setState(() => _logs = "No crashes recorded yet!");
      }
    } catch (e) {
      setState(() => _logs = "Error reading logs: $e");
    }
  }

  Future<void> _clearLogs() async {
    try {
      final file = await getLogFile();
      if (await file.exists()) {
        await file.delete();
      }
      setState(() => _logs = "Logs cleared.");
    } catch (e) {
      setState(() => _logs = "Error clearing logs: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crash Logs'),
        backgroundColor: Colors.red[100],
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Clear Logs',
            onPressed: _clearLogs,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: SelectableText(
          _logs,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ),
    );
  }
}

// ==========================================
// CORE MASTER LANDING DASHBOARD
// ==========================================
class MasterDashboardHome extends StatefulWidget {
  const MasterDashboardHome({super.key});
  @override
  State<MasterDashboardHome> createState() => _MasterDashboardHomeState();
}

class _MasterDashboardHomeState extends State<MasterDashboardHome> {
  List<Map<String, dynamic>> _workbooks = [];
  bool _isLoading = true;
  final List<Color> _palette = [Colors.blue, Colors.purple, Colors.teal, Colors.indigo, Colors.pink, Colors.orange, Colors.cyan, Colors.green];

  @override
  void initState() {
    super.initState();
    _refreshWorkbooks();
  }

  Future<void> _refreshWorkbooks() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.fetchAllWorkbooks();
    setState(() {
      _workbooks = data;
      _isLoading = false;
    });
  }

  void _launchSetupWizard() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SetupWizardWidget(
        palette: _palette,
        onSetupComplete: (title, subjects) async {
          int id = await DatabaseHelper.instance.createWorkbook(title, subjects);
          _refreshWorkbooks();
          _openWorkbook(id, title);
        },
      ),
    );
  }

  void _openWorkbook(int id, String title) async {
    final data = await DatabaseHelper.instance.loadWorkbookData(id);
    if (!mounted) return;
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkbookWorkspaceScreen(
          workbookId: id,
          workbookTitle: title,
          initialSubjects: data['subjects'],
          initialStudents: data['students'],
        ),
      ),
    );
    _refreshWorkbooks();
  }

  void _deleteWorkbookConfirm(int id, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workbook?'),
        content: Text('Are you sure you want to permanently delete "$title" and all its grades? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteWorkbook(id);
              Navigator.pop(context);
              _refreshWorkbooks();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ResultMaster Hub', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.red),
            tooltip: 'View Crash Logs',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CrashLogScreen()));
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _workbooks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.folder_open, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No workbooks created yet.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _launchSetupWizard,
                        icon: const Icon(Icons.add),
                        label: const Text('Create New Result'),
                      )
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _workbooks.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final item = _workbooks[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.assignment)),
                        title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Created: ${item['created_at'].toString().substring(0, 10)}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _deleteWorkbookConfirm(item['id'], item['title']),
                        ),
                        onTap: () => _openWorkbook(item['id'], item['title']),
                      ),
                    );
                  },
                ),
      floatingActionButton: _workbooks.isEmpty 
          ? null 
          : FloatingActionButton(onPressed: _launchSetupWizard, child: const Icon(Icons.add)),
    );
  }
}

// ==========================================
// ACTIVE INDIVIDUAL WORKSPACE SCREEN
// ==========================================
class WorkbookWorkspaceScreen extends StatefulWidget {
  final int workbookId;
  final String workbookTitle;
  final List<SubjectSetup> initialSubjects;
  final List<StudentRow> initialStudents;

  const WorkbookWorkspaceScreen({
    super.key,
    required this.workbookId,
    required this.workbookTitle,
    required this.initialSubjects,
    required this.initialStudents,
  });

  @override
  State<WorkbookWorkspaceScreen> createState() => _WorkbookWorkspaceScreenState();
}

class _WorkbookWorkspaceScreenState extends State<WorkbookWorkspaceScreen> {
  late String _currentTitle;
  late List<SubjectSetup> _subjects;
  late List<StudentRow> _students;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.workbookTitle;
    _subjects = widget.initialSubjects;
    _students = widget.initialStudents;
  }

  void _openFileBrowserWizard() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true, 
      );

      if (result != null && result.files.single.bytes != null) {
        var bytes = result.files.single.bytes!;
        var excel = ex.Excel.decodeBytes(bytes);
        
        List<StudentRow> newParsedList = [];
        
        // Parse the very first sheet in the document
        for (var table in excel.tables.keys) {
          var sheet = excel.tables[table]!;
          for (var row in sheet.rows) {
            if (row.length >= 2) {
              String roll = row[0]?.value?.toString().trim() ?? '';
              String name = row[1]?.value?.toString().trim() ?? '';
              
              // Ignore headers
              if (roll.isNotEmpty && roll.toLowerCase() != 'roll no' && roll.toLowerCase() != 'rollno') {
                if (name.isEmpty) name = "Student $roll";
                newParsedList.add(StudentRow(rollNo: roll, name: name, marks: {}));
              }
            }
          }
          break; // Stop after first sheet to prevent duplicates
        }

        if (newParsedList.isNotEmpty) {
          await DatabaseHelper.instance.clearAllStudents(widget.workbookId);
          for (var student in newParsedList) {
            await DatabaseHelper.instance.insertLiveStudent(widget.workbookId, student.rollNo, student.name);
          }
          setState(() { _students = newParsedList; });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully imported ${newParsedList.length} students!'), backgroundColor: Colors.green));
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No valid student data found in the Excel file.'), backgroundColor: Colors.orange));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error reading file: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _exportAsExcel() async {
    var excel = ex.Excel.createExcel();
    ex.Sheet sheet = excel['Sheet1'];

    sheet.appendRow([
      ex.TextCellValue("Roll No"),
      ex.TextCellValue("Name"),
      ..._subjects.map((s) => ex.TextCellValue(s.name)),
      ex.TextCellValue("Total"),
      ex.TextCellValue("Percentage"),
      ex.TextCellValue("Result")
    ]);

    for (var s in _students) {
      double totalObtained = 0.0;
      double totalMax = 0.0;
      bool failed = false;
      List<ex.CellValue> subValues = [];

      for (var sub in _subjects) {
        totalMax += sub.maxMarks;
        if (s.isSubjectAttempted(sub)) {
          double score = s.getSubjectScore(sub);
          totalObtained += score;
          if (sub.includeInPassFail && score < sub.passingMarks) failed = true;
          subValues.add(ex.DoubleCellValue(score));
        } else {
          subValues.add(ex.TextCellValue("-"));
        }
      }
      double pct = totalMax > 0 ? (totalObtained / totalMax) * 100 : 0.0;

      sheet.appendRow([
        ex.TextCellValue(s.rollNo),
        ex.TextCellValue(s.name),
        ...subValues,
        ex.DoubleCellValue(totalObtained),
        ex.TextCellValue('${pct.toStringAsFixed(2)}%'),
        ex.TextCellValue(failed ? "FAIL" : "PASS")
      ]);
    }

    var bytes = excel.encode();
    if (bytes != null) {
      await Share.shareXFiles(
        [XFile.fromData(Uint8List.fromList(bytes), mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', name: '$_currentTitle.xlsx')],
        text: 'Excel Report Card Grid',
      );
    }
  }

  void _exportAsPDF() async {
    final pdfDoc = pw.Document();
    
    pdfDoc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) => [
          pw.Header(level: 0, child: pw.Text(_currentTitle, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: ['Roll No', 'Name', ..._subjects.map((s) => s.name), 'Total', '%', 'Result'],
            data: _students.map((s) {
              double totalObtained = 0.0; double totalMax = 0.0; bool failed = false;
              List<String> rowCells = [s.rollNo, s.name];

              for (var sub in _subjects) {
                totalMax += sub.maxMarks;
                if (s.isSubjectAttempted(sub)) {
                  double score = s.getSubjectScore(sub);
                  totalObtained += score;
                  if (sub.includeInPassFail && score < sub.passingMarks) failed = true;
                  rowCells.add(score.toStringAsFixed(1));
                } else {
                  rowCells.add("-");
                }
              }
              double pct = totalMax > 0 ? (totalObtained / totalMax) * 100 : 0.0;
              rowCells.addAll([totalObtained.toStringAsFixed(1), '${pct.toStringAsFixed(2)}%', failed ? "FAIL" : "PASS"]);
              return rowCells;
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.center,
          )
        ]
      )
    );

    final bytes = await pdfDoc.save();
    await Share.shareXFiles(
      [XFile.fromData(bytes, mimeType: 'application/pdf', name: '$_currentTitle.pdf')],
      text: 'PDF Grade Sheet Report',
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Choose Download Format', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green[50], padding: const EdgeInsets.symmetric(vertical: 14)),
                    icon: const Icon(Icons.table_view, color: Colors.green),
                    label: const Text('Excel (.xlsx)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    onPressed: () { Navigator.pop(context); _exportAsExcel(); },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50], padding: const EdgeInsets.symmetric(vertical: 14)),
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    label: const Text('PDF (.pdf)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    onPressed: () { Navigator.pop(context); _exportAsPDF(); },
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredStudents = _students.where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase()) || s.rollNo.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentTitle),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          actions: [
            IconButton(icon: const Icon(Icons.download), tooltip: 'Download Records', onPressed: _showExportOptions),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.people), text: "Master List"),
              Tab(icon: Icon(Icons.subject), text: "Subject Sheets"),
              Tab(icon: Icon(Icons.assignment_turned_in), text: "Final Calculation"),
              Tab(icon: Icon(Icons.analytics), text: "Statistical Summary"),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search Roll No or Name...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[50]),
                              onPressed: _openFileBrowserWizard,
                              icon: const Icon(Icons.file_upload, size: 18),
                              label: const Text('Upload Excel File'),
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                int nextRoll = 1;
                                while (_students.any((s) => s.rollNo.trim() == nextRoll.toString())) nextRoll++;
                                String newRoll = nextRoll.toString();
                                String newName = "New Student";
                                await DatabaseHelper.instance.insertLiveStudent(widget.workbookId, newRoll, newName);
                                setState(() { _students.add(StudentRow(rollNo: newRoll, name: newName, marks: {})); });
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
                              rows: filteredStudents.map((student) {
                                return DataRow(cells: [
                                  DataCell(TextFormField(
                                    initialValue: student.rollNo,
                                    decoration: const InputDecoration(border: InputBorder.none),
                                    onChanged: (val) async {
                                      String oldRoll = student.rollNo;
                                      student.rollNo = val;
                                      await DatabaseHelper.instance.updateLiveStudentInfo(widget.workbookId, oldRoll, val, student.name);
                                      setState(() {});
                                    },
                                  )),
                                  DataCell(TextFormField(
                                    initialValue: student.name,
                                    decoration: const InputDecoration(border: InputBorder.none),
                                    onChanged: (val) async {
                                      student.name = val;
                                      await DatabaseHelper.instance.updateLiveStudentInfo(widget.workbookId, student.rollNo, student.rollNo, val);
                                    },
                                  )),
                                  DataCell(IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      await DatabaseHelper.instance.deleteLiveStudent(widget.workbookId, student.rollNo);
                                      setState(() { _students.remove(student); });
                                    },
                                  )),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SubjectMarksTabWidget(workbookId: widget.workbookId, subjects: _subjects, students: filteredStudents, allStudents: _students),
                  FinalSheetTabWidget(subjects: _subjects, students: filteredStudents),
                  SummarySheetTabWidget(subjects: _subjects, students: filteredStudents),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// CUSTOM INPUT FIELD (Focus-Aware Fix)
// ==========================================
class MarkInputField extends StatefulWidget {
  final String initialValue;
  final Function(String) onFocusLostOrSubmitted;

  const MarkInputField({super.key, required this.initialValue, required this.onFocusLostOrSubmitted});

  @override
  State<MarkInputField> createState() => _MarkInputFieldState();
}

class _MarkInputFieldState extends State<MarkInputField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        widget.onFocusLostOrSubmitted(_controller.text);
      }
    });
  }

  @override
  void didUpdateWidget(covariant MarkInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue && _controller.text != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      textAlign: TextAlign.center,
      decoration: const InputDecoration(hintText: "-", border: InputBorder.none),
      onFieldSubmitted: (val) => widget.onFocusLostOrSubmitted(val),
    );
  }
}

// ==========================================
// WIDGET: TAB 2 - SUBJECT MARKS
// ==========================================
class SubjectMarksTabWidget extends StatefulWidget {
  final int workbookId;
  final List<SubjectSetup> subjects;
  final List<StudentRow> students;
  final List<StudentRow> allStudents;

  const SubjectMarksTabWidget({super.key, required this.workbookId, required this.subjects, required this.students, required this.allStudents});

  @override
  State<SubjectMarksTabWidget> createState() => _SubjectMarksTabWidgetState();
}

class _SubjectMarksTabWidgetState extends State<SubjectMarksTabWidget> {
  int _selectedSubjectIndex = 0;

  String? _validateAndCleanInput(String input, double maxAllowed, String studentName, String componentName) {
    String clean = input.toUpperCase().trim();
    if (clean.isEmpty) return "";
    if (clean == "A" || clean == "AB") return clean;

    if (!RegExp(r'^[0-9]+(\.[0-9]+)?$').hasMatch(clean)) {
      _showValidationError("Invalid characters entered for $studentName.");
      return null;
    }
    double? val = double.tryParse(clean);
    if (val == null || val > maxAllowed) {
      _showValidationError("Invalid! $studentName's score in $componentName cannot exceed ${maxAllowed.toStringAsFixed(0)}.");
      return null;
    }
    return clean;
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.subjects.isEmpty) return const Center(child: Text("No subjects configured."));
    if (_selectedSubjectIndex >= widget.subjects.length) _selectedSubjectIndex = 0;
    
    final currentSub = widget.subjects[_selectedSubjectIndex];
    int totalStudents = widget.allStudents.length;
    int enteredCount = widget.allStudents.where((s) => s.isSubjectAttempted(currentSub)).length;
    bool isComplete = (enteredCount == totalStudents && totalStudents > 0);

    int passedCount = 0; int failedCount = 0; int disttCount = 0; double sumMarks = 0.0;
    for (var s in widget.students) {
      if (s.isSubjectAttempted(currentSub)) {
        double score = s.getSubjectScore(currentSub);
        sumMarks += score;
        if (score >= currentSub.passingMarks) passedCount++; else failedCount++;
        if (score >= (currentSub.maxMarks * 0.75)) disttCount++;
      }
    }
    double qi = enteredCount > 0 ? (sumMarks / enteredCount) : 0.0;

    List<DataColumn> gridColumns = [const DataColumn(label: Text('Roll No')), const DataColumn(label: Text('Name'))];
    if (currentSub.components.isEmpty) {
      gridColumns.add(DataColumn(label: Text('Marks\n(Max: ${currentSub.maxMarks.toStringAsFixed(0)})')));
    } else {
      for (var c in currentSub.components) {
        gridColumns.add(DataColumn(label: Text('${c.name}\n(Max: ${c.maxMarks.toStringAsFixed(0)})')));
      }
    }

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(8),
          child: Row(
            children: widget.subjects.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(entry.value.name),
                  selected: entry.key == _selectedSubjectIndex,
                  selectedColor: entry.value.themeColor.withOpacity(0.4),
                  onSelected: (selected) { if (selected) setState(() => _selectedSubjectIndex = entry.key); },
                ),
              );
            }).toList(),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          color: isComplete ? Colors.green[200]! : Colors.red[100]!,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subject: ${currentSub.name} (Max: ${currentSub.maxMarks.toStringAsFixed(0)})', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Entered: $enteredCount / $totalStudents', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey[400]!)),
          child: IntrinsicWidth(
            child: Column(
              children: [
                _buildStatRow("Passed", passedCount.toString()),
                _buildStatRow("Failed", failedCount.toString()),
                _buildStatRow("QI", qi.toStringAsFixed(2)),
                const Divider(height: 1, thickness: 1),
                _buildStatRow("DISTT", disttCount.toString(), isWhite: true),
              ],
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
                columns: gridColumns,
                rows: widget.students.map((student) {
                  bool isFail = student.isSubjectAttempted(currentSub) && student.getSubjectScore(currentSub) < currentSub.passingMarks;
                  Color? cellColor = isFail ? Colors.red[100] : null;
                  List<DataCell> rowCells = [DataCell(Text(student.rollNo)), DataCell(Text(student.name))];

                  if (currentSub.components.isEmpty) {
                    final currentVal = student.marks[currentSub.name] ?? "";
                    rowCells.add(DataCell(
                      Container(
                        color: cellColor,
                        child: MarkInputField(
                          key: ValueKey('${student.rollNo}_${currentSub.name}_$currentVal'),
                          initialValue: currentVal,
                          onFocusLostOrSubmitted: (newValue) async {
                            final verified = _validateAndCleanInput(newValue, currentSub.maxMarks, student.name, currentSub.name);
                            if (verified != null) {
                              student.marks[currentSub.name] = verified;
                              await DatabaseHelper.instance.saveLiveMark(workbookId: widget.workbookId, rollNo: student.rollNo, markKey: currentSub.name, value: verified);
                            }
                            setState(() {});
                          },
                        ),
                      ),
                    ));
                  } else {
                    for (var c in currentSub.components) {
                      String markKey = '${currentSub.name}_${c.name}';
                      final currentVal = student.marks[markKey] ?? "";
                      rowCells.add(DataCell(
                        Container(
                          color: cellColor,
                          child: MarkInputField(
                            key: ValueKey('${student.rollNo}_${markKey}_$currentVal'),
                            initialValue: currentVal,
                            onFocusLostOrSubmitted: (newValue) async {
                              final verified = _validateAndCleanInput(newValue, c.maxMarks, student.name, c.name);
                              if (verified != null) {
                                student.marks[markKey] = verified;
                                await DatabaseHelper.instance.saveLiveMark(workbookId: widget.workbookId, rollNo: student.rollNo, markKey: markKey, value: verified);
                              }
                              setState(() {});
                            },
                          ),
                        ),
                      ));
                    }
                  }
                  return DataRow(cells: rowCells);
                }).toList(),
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildStatRow(String label, String value, {bool isWhite = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 80, padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), color: isWhite ? Colors.white : Colors.grey[200], child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
        Container(width: 60, padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.grey[400]!))), child: Text(value, textAlign: TextAlign.center)),
      ],
    );
  }
}

// ==========================================
// WIDGET: FINAL CALCULATION TAB
// ==========================================
class FinalSheetTabWidget extends StatefulWidget {
  final List<SubjectSetup> subjects;
  final List<StudentRow> students;
  const FinalSheetTabWidget({super.key, required this.subjects, required this.students});

  @override
  State<FinalSheetTabWidget> createState() => _FinalSheetTabWidgetState();
}

class _FinalSheetTabWidgetState extends State<FinalSheetTabWidget> {
  int? _sortColumnIndex;
  bool _isAscending = true;
  late List<StudentRow> _sortedStudents;

  @override
  void initState() {
    super.initState();
    _sortedStudents = List.from(widget.students);
  }

  @override
  void didUpdateWidget(covariant FinalSheetTabWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sortedStudents = List.from(widget.students);
    _applySort();
  }

  double _getTotal(StudentRow student) {
    double total = 0.0;
    for (var sub in widget.subjects) {
      if (student.isSubjectAttempted(sub)) total += student.getSubjectScore(sub);
    }
    return total;
  }

  double _getPct(StudentRow student) {
    double totalObtained = _getTotal(student);
    double totalMax = widget.subjects.fold(0.0, (sum, sub) => sum + sub.maxMarks);
    return totalMax > 0 ? (totalObtained / totalMax) * 100 : 0.0;
  }

  void _applySort() {
    if (_sortColumnIndex == null) return;
    _sortedStudents.sort((a, b) {
      int mod = _isAscending ? 1 : -1;
      if (_sortColumnIndex == 0) {
        return ((double.tryParse(a.rollNo) ?? 0).compareTo(double.tryParse(b.rollNo) ?? 0)) * mod;
      } else if (_sortColumnIndex == 1) {
        return a.name.toLowerCase().compareTo(b.name.toLowerCase()) * mod;
      } else if (_sortColumnIndex == widget.subjects.length + 2) {
        return _getTotal(a).compareTo(_getTotal(b)) * mod;
      } else if (_sortColumnIndex == widget.subjects.length + 3) {
        return _getPct(a).compareTo(_getPct(b)) * mod;
      }
      return 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Colors.blue[50]),
            sortColumnIndex: _sortColumnIndex,
            sortAscending: _isAscending,
            columns: [
              DataColumn(label: const Text('Roll No'), onSort: (idx, asc) => setState(() { _sortColumnIndex = idx; _isAscending = asc; _applySort(); })),
              DataColumn(label: const Text('Name'), onSort: (idx, asc) => setState(() { _sortColumnIndex = idx; _isAscending = asc; _applySort(); })),
              ...widget.subjects.map((sub) => DataColumn(label: Text(sub.name))),
              DataColumn(label: const Text('Total'), numeric: true, onSort: (idx, asc) => setState(() { _sortColumnIndex = idx; _isAscending = asc; _applySort(); })),
              DataColumn(label: const Text('%'), numeric: true, onSort: (idx, asc) => setState(() { _sortColumnIndex = idx; _isAscending = asc; _applySort(); })),
              const DataColumn(label: Text('Result')),
            ],
            rows: _sortedStudents.map((student) {
              double totalObtained = 0.0; double totalMax = 0.0; bool failed = false;
              List<DataCell> subjectCells = [];

              for (var sub in widget.subjects) {
                totalMax += sub.maxMarks; String displayMark = "-";
                if (student.isSubjectAttempted(sub)) {
                  double score = student.getSubjectScore(sub);
                  totalObtained += score;
                  if (sub.includeInPassFail && score < sub.passingMarks) failed = true;
                  if (sub.components.isEmpty && (student.marks[sub.name] == "A" || student.marks[sub.name] == "AB")) {
                    displayMark = student.marks[sub.name]!;
                  } else {
                    displayMark = score.toStringAsFixed(1);
                    if (displayMark.endsWith('.0')) displayMark = displayMark.substring(0, displayMark.length - 2);
                  }
                }
                subjectCells.add(DataCell(Text(displayMark)));
              }
              double pct = totalMax > 0 ? (totalObtained / totalMax) * 100 : 0.0;
              return DataRow(cells: [
                DataCell(Text(student.rollNo)), DataCell(Text(student.name)), ...subjectCells,
                DataCell(Text(totalObtained.toStringAsFixed(1))), DataCell(Text('${pct.toStringAsFixed(2)}%')),
                DataCell(Text(failed ? 'FAIL' : 'PASS', style: TextStyle(color: failed ? Colors.red : Colors.green, fontWeight: FontWeight.bold))),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// WIDGET: STATISTICAL SUMMARY TAB
// ==========================================
class SummarySheetTabWidget extends StatelessWidget {
  final List<SubjectSetup> subjects;
  final List<StudentRow> students;
  const SummarySheetTabWidget({super.key, required this.subjects, required this.students});

  @override
  Widget build(BuildContext context) {
    int grandAppeared = 0; int grandPassed = 0; int grandDistinction = 0;
    Map<String, int> grandBrackets = {'0-20': 0, '21-32.9': 0, '33-40': 0, '41-50': 0, '51-59.9': 0, '60': 0, '61-70': 0, '71-74.9': 0, '75-80': 0, '81-90': 0, '90': 0, '91-94.9': 0, '95-100': 0};

    final subjectRows = subjects.map((sub) {
      int appeared = 0; int passed = 0; int distinction = 0; double sumMarks = 0.0;
      Map<String, int> distribution = {'0-20': 0, '21-32.9': 0, '33-40': 0, '41-50': 0, '51-59.9': 0, '60': 0, '61-70': 0, '71-74.9': 0, '75-80': 0, '81-90': 0, '90': 0, '91-94.9': 0, '95-100': 0};

      for (var row in students) {
        if (!row.isSubjectAttempted(sub)) continue;
        double score = row.getSubjectScore(sub);
        appeared++; sumMarks += score;
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

      grandAppeared += appeared; grandPassed += passed; grandDistinction += distinction;
      distribution.forEach((key, val) => grandBrackets[key] = grandBrackets[key]! + val);

      return DataRow(cells: [
        DataCell(Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold))), DataCell(Text(appeared.toString())), DataCell(Text(passed.toString())), DataCell(Text('${passPct.toStringAsFixed(2)}%')), DataCell(Text(distinction.toString())), DataCell(Text(qi.toStringAsFixed(2))),
        DataCell(Text(distribution['0-20'].toString())), DataCell(Text(distribution['21-32.9'].toString())), DataCell(Text(distribution['33-40'].toString())), DataCell(Text(distribution['41-50'].toString())), DataCell(Text(distribution['51-59.9'].toString())), DataCell(Text(distribution['60'].toString())), DataCell(Text(distribution['61-70'].toString())), DataCell(Text(distribution['71-74.9'].toString())), DataCell(Text(distribution['75-80'].toString())), DataCell(Text(distribution['81-90'].toString())), DataCell(Text(distribution['90'].toString())), DataCell(Text(distribution['91-94.9'].toString())), DataCell(Text(distribution['95-100'].toString())),
      ]);
    }).toList();

    final sumRow = DataRow(
      color: MaterialStateProperty.all(Colors.orange[100]),
      cells: [
        const DataCell(Text('SUM', style: TextStyle(fontWeight: FontWeight.bold))), DataCell(Text(grandAppeared.toString(), style: const TextStyle(fontWeight: FontWeight.bold))), DataCell(Text(grandPassed.toString(), style: const TextStyle(fontWeight: FontWeight.bold))), const DataCell(Text('-')), DataCell(Text(grandDistinction.toString(), style: const TextStyle(fontWeight: FontWeight.bold))), const DataCell(Text('-')),
        DataCell(Text(grandBrackets['0-20'].toString())), DataCell(Text(grandBrackets['21-32.9'].toString())), DataCell(Text(grandBrackets['33-40'].toString())), DataCell(Text(grandBrackets['41-50'].toString())), DataCell(Text(grandBrackets['51-59.9'].toString())), DataCell(Text(grandBrackets['60'].toString())), DataCell(Text(grandBrackets['61-70'].toString())), DataCell(Text(grandBrackets['71-74.9'].toString())), DataCell(Text(grandBrackets['75-80'].toString())), DataCell(Text(grandBrackets['81-90'].toString())), DataCell(Text(grandBrackets['90'].toString())), DataCell(Text(grandBrackets['91-94.9'].toString())), DataCell(Text(grandBrackets['95-100'].toString())),
      ],
    );

    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.yellow[100]),
              border: TableBorder.all(color: Colors.grey[300]!),
              columns: const [
                DataColumn(label: Text('SUBJECT', style: TextStyle(fontWeight: FontWeight.bold))), DataColumn(label: Text('APPEARED')), DataColumn(label: Text('PASS')), DataColumn(label: Text('PASS %')), DataColumn(label: Text('DISTT')), DataColumn(label: Text('QI (AVG)')),
                DataColumn(label: Text('0-20')), DataColumn(label: Text('21-32.9')), DataColumn(label: Text('33-40')), DataColumn(label: Text('41-50')), DataColumn(label: Text('51-59.9')), DataColumn(label: Text('60')), DataColumn(label: Text('61-70')), DataColumn(label: Text('71-74.9')), DataColumn(label: Text('75-80')), DataColumn(label: Text('81-90')), DataColumn(label: Text('90')), DataColumn(label: Text('91-94.9')), DataColumn(label: Text('95-100')),
              ],
              rows: [...subjectRows, sumRow],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// CONFIGURATION SETUP WIZARD
// ==========================================
class SetupWizardWidget extends StatefulWidget {
  final List<Color> palette;
  final Function(String, List<SubjectSetup>) onSetupComplete;

  const SetupWizardWidget({
    super.key, 
    required this.palette, 
    required this.onSetupComplete, 
  });

  @override
  State<SetupWizardWidget> createState() => _SetupWizardWidgetState();
}

class _SetupWizardWidgetState extends State<SetupWizardWidget> {
  late TextEditingController _titleController;
  late List<SubjectSetup> _subjects;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: "Name of Class");
    _subjects = [
      SubjectSetup(name: "ENG.", maxMarks: 100, passingMarks: 33, themeColor: widget.palette[0]),
      SubjectSetup(name: "HINDI", maxMarks: 100, passingMarks: 33, themeColor: widget.palette[1]),
    ];
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
            child: ListView(
              children: [
                ..._subjects.asMap().entries.map((entry) {
                  int index = entry.key; var sub = entry.value;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Container(
                      decoration: BoxDecoration(border: Border(left: BorderSide(color: sub.themeColor, width: 6))),
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: TextFormField(initialValue: sub.name, decoration: const InputDecoration(labelText: 'Subject Name', labelStyle: TextStyle(fontWeight: FontWeight.bold)), onChanged: (val) => sub.name = val)),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _subjects.removeAt(index)))
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(child: TextFormField(key: ValueKey('${sub.name}_max_${sub.components.length}'), initialValue: sub.maxMarks.toStringAsFixed(0), decoration: InputDecoration(labelText: 'Max Marks', filled: sub.components.isNotEmpty, fillColor: Colors.grey[200]), keyboardType: TextInputType.number, enabled: sub.components.isEmpty, onChanged: (val) => sub.maxMarks = double.tryParse(val) ?? 100.0)),
                              const SizedBox(width: 12),
                              Expanded(child: TextFormField(initialValue: sub.passingMarks.toStringAsFixed(0), decoration: const InputDecoration(labelText: 'Pass Marks'), keyboardType: TextInputType.number, onChanged: (val) => sub.passingMarks = double.tryParse(val) ?? 33.0)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Bifurcations (Theory/Prac):', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                              TextButton.icon(
                                onPressed: () => setState(() { sub.components.add(SubjectComponent(name: 'Part ${sub.components.length + 1}', maxMarks: 50)); sub.recalculateMaxMarks(); }),
                                icon: const Icon(Icons.add, size: 16), label: const Text('Add Component'),
                              )
                            ],
                          ),
                          if (sub.components.isNotEmpty)
                            ...sub.components.asMap().entries.map((cEntry) {
                              int cIdx = cEntry.key; var comp = cEntry.value;
                              return Padding(
                                padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                                child: Row(
                                  children: [
                                    Expanded(child: TextFormField(initialValue: comp.name, decoration: const InputDecoration(labelText: 'Comp. Name', isDense: true), onChanged: (val) => comp.name = val)),
                                    const SizedBox(width: 8),
                                    Expanded(child: TextFormField(initialValue: comp.maxMarks.toStringAsFixed(0), decoration: const InputDecoration(labelText: 'Max Marks', isDense: true), keyboardType: TextInputType.number, onChanged: (val) { comp.maxMarks = double.tryParse(val) ?? 0.0; setState(() => sub.recalculateMaxMarks()); })),
                                    IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => setState(() { sub.components.removeAt(cIdx); sub.recalculateMaxMarks(); }))
                                  ],
                                ),
                              );
                            }).toList(),
                          SwitchListTile(
                            title: const Text('Count towards Final Pass/Fail Result', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            value: sub.includeInPassFail,
                            activeColor: sub.themeColor,
                            onChanged: (val) => setState(() => sub.includeInPassFail = val),
                            dense: true, contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _subjects.add(SubjectSetup(name: "NEW SUBJECT", themeColor: widget.palette[_subjects.length % widget.palette.length]))),
                  icon: const Icon(Icons.add_circle_outline), label: const Text('Add Another Subject'),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              onPressed: () { 
                Navigator.pop(context); 
                widget.onSetupComplete(_titleController.text, _subjects); 
              },
              child: const Text('Save Setup & Build Sheets', style: TextStyle(fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }
}
