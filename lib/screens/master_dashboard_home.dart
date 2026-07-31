import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

import '../database/database_helper.dart';
import '../utils/crash_logger.dart';
import '../widgets/wavy_header.dart';
import 'workbook_dashboard_screen.dart';

class MasterDashboardHome extends StatefulWidget {
  const MasterDashboardHome({super.key});
  @override
  State<MasterDashboardHome> createState() => _MasterDashboardHomeState();
}

class _MasterDashboardHomeState extends State<MasterDashboardHome> {
  List<Map<String, dynamic>> _workbooks = [];
  bool _isLoading = true;
  bool _isWorkbooksTab = true;

  @override
  void initState() { super.initState(); _refreshWorkbooks(); }

  Future<void> _refreshWorkbooks() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.fetchAllWorkbooks();
    setState(() { _workbooks = data; _isLoading = false; });
  }

  Future<void> _exportBackup() async { try { final dbPath = await getDatabasesPath(); final path = p.join(dbPath, 'result_master.db'); final file = File(path); if (await file.exists()) { final bytes = await file.readAsBytes(); final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19); await Share.shareXFiles([XFile.fromData(bytes, mimeType: 'application/octet-stream', name: 'ResultMaster_Backup_$timestamp.db')], text: 'Here is my database backup!'); } else { if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No database found to backup yet.'))); } } catch (e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup failed: $e'))); } }
  Future<void> _importBackup() async { try { FilePickerResult? result = await FilePicker.platform.pickFiles(); if (result != null && result.files.single.path != null) { File backupFile = File(result.files.single.path!); if (!mounted) return; bool? confirm = await showDialog( context: context, builder: (context) => AlertDialog( title: const Text('Restore Database?'), content: const Text('WARNING: This will wipe all current data and replace it with the backup. Continue?'), actions: [ TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Restore', style: TextStyle(color: Colors.red))), ], ) ); if (confirm == true) { final dbPath = await getDatabasesPath(); final path = p.join(dbPath, 'result_master.db'); await backupFile.copy(path); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup Restored Successfully!'), backgroundColor: Colors.green)); _refreshWorkbooks(); } } } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $e'), backgroundColor: Colors.red)); } }
  void _createNewWorkbookDialog() { String title = ""; showDialog( context: context, builder: (context) => AlertDialog( title: const Text('Create New Workbook'), content: TextField(decoration: const InputDecoration(hintText: 'e.g., Class 4A', labelText: 'Workbook Title'), autofocus: true, onChanged: (val) => title = val), actions: [ TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), ElevatedButton( onPressed: () async { if (title.trim().isNotEmpty) { int id = await DatabaseHelper.instance.createWorkbook(title.trim()); if (mounted) Navigator.pop(context); _refreshWorkbooks(); Navigator.push(context, MaterialPageRoute(builder: (context) => WorkbookDashboardScreen(workbookId: id, workbookTitle: title.trim()))).then((_) => _refreshWorkbooks()); } }, child: const Text('Create'), ), ], ), ); }
  void _deleteWorkbookConfirm(int id, String title) { showDialog( context: context, builder: (context) => AlertDialog( title: const Text('Delete Workbook?'), content: Text('Are you sure you want to permanently delete "$title"?'), actions: [ TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), TextButton(onPressed: () async { await DatabaseHelper.instance.deleteWorkbook(id); Navigator.pop(context); _refreshWorkbooks(); }, child: const Text('Delete', style: TextStyle(color: Colors.red))), ], ), ); }

  Widget _buildPillButton(String title, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _isWorkbooksTab = title == "My Workbooks"),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300, width: 1.5),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          WavyHeader(
            title: 'ResultMaster Hub',
            actions: [IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CrashLogScreen())))],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPillButton("My Workbooks", Icons.folder, _isWorkbooksTab),
                const SizedBox(width: 16),
                _buildPillButton("Data & Backup", Icons.security, !_isWorkbooksTab),
              ],
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : _isWorkbooksTab 
                ? _workbooks.isEmpty 
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.folder_open, size: 64, color: Colors.grey), const SizedBox(height: 16), const Text('No workbooks created yet.', style: TextStyle(fontSize: 16, color: Colors.grey)), const SizedBox(height: 16), ElevatedButton.icon(onPressed: _createNewWorkbookDialog, icon: const Icon(Icons.add), label: const Text('Create Workbook'))]))
                  : ListView.builder(
                      itemCount: _workbooks.length, padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final item = _workbooks[index];
                        return Card(
                          elevation: 1, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.assignment, color: Theme.of(context).colorScheme.primary)),
                            title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            subtitle: Text('Created: ${item['created_at'].toString().substring(0, 16)}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            trailing: Container(decoration: BoxDecoration(border: Border.all(color: Colors.red.shade100, width: 2), borderRadius: BorderRadius.circular(8)), child: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), onPressed: () => _deleteWorkbookConfirm(item['id'], item['title']))),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => WorkbookDashboardScreen(workbookId: item['id'], workbookTitle: item['title']))).then((_) => _refreshWorkbooks()),
                          ),
                        );
                      }
                    )
                : Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.cloud_sync, size: 80, color: Colors.blueAccent),
                        const SizedBox(height: 24),
                        const Text('Secure Your Data', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        const SizedBox(height: 40),
                        // FIXED: Adjusted foreground color to make text readable
                        ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[50], foregroundColor: Colors.blue[900], padding: const EdgeInsets.symmetric(vertical: 16)), icon: const Icon(Icons.upload_file), label: const Text('Export Database Backup', style: TextStyle(fontWeight: FontWeight.bold)), onPressed: _exportBackup),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[50], foregroundColor: Colors.deepOrange[900], padding: const EdgeInsets.symmetric(vertical: 16)), icon: const Icon(Icons.settings_backup_restore), label: const Text('Restore from Backup File', style: TextStyle(fontWeight: FontWeight.bold)), onPressed: _importBackup),
                      ],
                    ),
                  ),
          )
        ],
      ),
      floatingActionButton: _isWorkbooksTab ? FloatingActionButton(onPressed: _createNewWorkbookDialog, backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white, child: const Icon(Icons.add)) : null,
    );
  }
}
