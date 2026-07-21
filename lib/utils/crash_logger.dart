
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

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
      if (await file.exists()) await file.delete();
      setState(() => _logs = "Logs cleared.");
    } catch (e) {
      setState(() => _logs = "Error clearing logs: $e");
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crash Logs'), backgroundColor: Colors.red[100],
        actions: [IconButton(icon: const Icon(Icons.delete), tooltip: 'Clear Logs', onPressed: _clearLogs)],
      ),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16.0), child: SelectableText(_logs, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
    );
  }
}
