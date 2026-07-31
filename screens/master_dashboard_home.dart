// REPLACE ONLY THIS FILE
// lib/screens/master_dashboard_home.dart

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

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
        final timestamp = DateTime.now()
            .toIso8601String()
            .replaceAll(':', '-')
            .substring(0, 19);

        await Share.shareXFiles(
          [
            XFile.fromData(
              bytes,
              mimeType: 'application/octet-stream',
              name: 'ResultMaster_Backup_$timestamp.db',
            )
          ],
          text: 'ResultMaster Backup',
        );
      }
    } catch (_) {}
  }

  Future<void> _importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles();

      if (result == null || result.files.single.path == null) return;

      final backupFile = File(result.files.single.path!);

      if (!mounted) return;

      final restore = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Restore Backup"),
          content: const Text(
              "This will replace the existing database.\nContinue?"),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel")),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Restore")),
          ],
        ),
      );

      if (restore == true) {
        final dbPath = await getDatabasesPath();
        await backupFile.copy(p.join(dbPath, "result_master.db"));
        _refreshWorkbooks();
      }
    } catch (_) {}
  }

  void _createNewWorkbookDialog() {
    String title = "";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Create Workbook"),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            labelText: "Workbook Title",
          ),
          onChanged: (v) => title = v,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          FilledButton(
            onPressed: () async {
              if (title.trim().isEmpty) return;

              final id = await DatabaseHelper.instance
                  .createWorkbook(title.trim());

              if (!mounted) return;

              Navigator.pop(context);

              _refreshWorkbooks();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkbookDashboardScreen(
                    workbookId: id,
                    workbookTitle: title.trim(),
                  ),
                ),
              ).then((_) => _refreshWorkbooks());
            },
            child: const Text("Create"),
          )
        ],
      ),
    );
  }

  void _deleteWorkbookConfirm(int id, String title) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Workbook"),
        content: Text('Delete "$title"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await DatabaseHelper.instance.deleteWorkbook(id);

              if (!mounted) return;

              Navigator.pop(context);

              _refreshWorkbooks();
            },
            child: const Text("Delete"),
          )
        ],
      ),
    );
  }

  Widget _tab(
      String title, IconData icon, bool selected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: selected
                ? const LinearGradient(
                    colors: [
                      Color(0xff1CB5A3),
                      Color(0xff0A8D82),
                    ],
                  )
                : null,
            color: selected ? null : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: selected
                      ? Colors.white
                      : Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : Colors.black87,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _workbookCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        leading: Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [
                Color(0xffCFF7F1),
                Color(0xffE8FCF8),
              ],
            ),
          ),
          child: const Icon(
            Icons.menu_book_rounded,
            color: Color(0xff0A8D82),
          ),
        ),
        title: Text(
          item["title"],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            item["created_at"].toString().substring(0, 16),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded,
              color: Colors.redAccent),
          onPressed: () =>
              _deleteWorkbookConfirm(item["id"], item["title"]),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkbookDashboardScreen(
                workbookId: item["id"],
                workbookTitle: item["title"],
              ),
            ),
          ).then((_) => _refreshWorkbooks());
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F8FA),
      floatingActionButton: _isWorkbooksTab
          ? FloatingActionButton.extended(
              onPressed: _createNewWorkbookDialog,
              icon: const Icon(Icons.add),
              label: const Text("Workbook"),
            )
          : null,
      body: Column(
        children: [
          WavyHeader(
            title: "ResultMaster Hub",
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CrashLogScreen(),
                  ),
                ),
              )
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xffEEF3F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  _tab(
                    "My Workbooks",
                    Icons.folder_copy_rounded,
                    _isWorkbooksTab,
                    () => setState(() => _isWorkbooksTab = true),
                  ),
                  const SizedBox(width: 8),
                  _tab(
                    "Data & Backup",
                    Icons.cloud_done_rounded,
                    !_isWorkbooksTab,
                    () => setState(() => _isWorkbooksTab = false),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _isWorkbooksTab
                    ? _workbooks.isEmpty
                        ? Center(
                            child: FilledButton.icon(
                              onPressed: _createNewWorkbookDialog,
                              icon: const Icon(Icons.add),
                              label: const Text("Create Workbook"),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 4),
                            itemCount: _workbooks.length,
                            itemBuilder: (_, i) =>
                                _workbookCard(_workbooks[i]),
                          )
                    : Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FilledButton.icon(
                              onPressed: _exportBackup,
                              icon: const Icon(Icons.upload),
                              label: const Text("Export Backup"),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _importBackup,
                              icon: const Icon(Icons.restore),
                              label: const Text("Restore Backup"),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
