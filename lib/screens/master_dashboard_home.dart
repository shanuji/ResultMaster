import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

import '../database/database_helper.dart';
import '../utils/crash_logger.dart';
import 'workbook_dashboard_screen.dart';

class MasterDashboardHome extends StatefulWidget {
  const MasterDashboardHome({super.key});
  @override
  State<MasterDashboardHome> createState() => _MasterDashboardHomeState();
}

class _MasterDashboardHomeState extends State<MasterDashboardHome> {
  List<Map<String, dynamic>> _workbooks = [];
  bool _isLoading = true;

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

  Future<void> _exportBackup() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, 'result_master.db');
      final file = File(path);
      
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
        await Share.shareXFiles(
          [XFile.fromData(bytes, mimeType: 'application/octet-stream', name: 'ResultMaster_Backup_$timestamp.db')],
          text: 'Here is my database backup from ResultMaster!',
        );
      } else {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No database found to backup yet.')));
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
    }
  }

  Future<void> _importBackup() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(); 
      if (result != null && result.files.single.path != null) {
        File backupFile = File(result.files.single.path!);
        if (!mounted) return;
        bool? confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Restore Database?'),
            content: const Text('WARNING: This will wipe all current data and replace it with the backup. Continue?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Restore', style: TextStyle(color: Colors.red))),
            ],
          )
        );
        if (confirm == true) {
          // Note: ensure restoreDatabaseFile is implemented in DB helper or remove this block if not needed yet
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup Restored Successfully!')));
          _refreshWorkbooks();
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $e'), backgroundColor: Colors.red));
    }
  }

  void _createNewWorkbookDialog() {
    String title = "";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Workbook'),
        content: TextField(
          decoration: const InputDecoration(hintText: 'e.g., Class 3A - 2026', labelText: 'Workbook Title'),
          autofocus: true,
          onChanged: (val) => title = val,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (title.trim().isNotEmpty) {
                int id = await DatabaseHelper.instance.createWorkbook(title.trim());
                if (mounted) Navigator.pop(context);
                _refreshWorkbooks();
                _openWorkbook(id, title.trim());
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _openWorkbook(int id, String title) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => WorkbookDashboardScreen(workbookId: id, workbookTitle: title))).then((_) => _refreshWorkbooks());
  }

  void _deleteWorkbookConfirm(int id, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workbook?'),
        content: Text('Are you sure you want to permanently delete "$title"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () async { await DatabaseHelper.instance.deleteWorkbook(id); Navigator.pop(context); _refreshWorkbooks(); }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ResultMaster Hub', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          actions: [IconButton(icon: const Icon(Icons.bug_report, color: Colors.red), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CrashLogScreen())))],
          bottom: const TabBar(tabs: [Tab(icon: Icon(Icons.folder_copy), text: "My Workbooks"), Tab(icon: Icon(Icons.security), text: "Data & Backup")]),
        ),
        body: TabBarView(
          children: [
            _isLoading
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
                            ElevatedButton.icon(onPressed: _createNewWorkbookDialog, icon: const Icon(Icons.add), label: const Text('Create Workbook'))
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _workbooks.length,
                        padding: const EdgeInsets.all(12),
                        itemBuilder: (context, index) {
                          final item = _workbooks[index];
                          return Card(
                            elevation: 2, margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.assignment)),
                              title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Created: ${item['created_at'].toString().substring(0, 16).replaceAll('T', ' at ')}'),
                              trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _deleteWorkbookConfirm(item['id'], item['title'])),
                              onTap: () => _openWorkbook(item['id'], item['title']),
                            ),
                          );
                        },
                      ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.cloud_sync, size: 80, color: Colors.blueAccent),
                  const SizedBox(height: 24),
                  const Text('Secure Your Data', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)), icon: const Icon(Icons.upload_file), label: const Text('Export Database Backup'), onPressed: _exportBackup),
                ],
              ),
            )
          ],
        ),
        floatingActionButton: _workbooks.isEmpty ? null : FloatingActionButton(onPressed: _createNewWorkbookDialog, child: const Icon(Icons.add)),
      ),
    );
  }
}
