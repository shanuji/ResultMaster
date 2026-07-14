import 'package:flutter/material.dart';

import 'features/result_workbook/data/repositories/sqlite_result_workbook_repository.dart';
import 'features/result_workbook/domain/usecases/create_result_workbook.dart';
import 'features/result_workbook/presentation/pages/new_result_wizard_page.dart';

void main() {
  runApp(const ResultMasterApp());
}

class ResultMasterApp extends StatelessWidget {
  const ResultMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final createWorkbook = CreateResultWorkbook(SqliteResultWorkbookRepository());
    return MaterialApp(
      title: 'ResultMaster',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: HomePage(createWorkbook: createWorkbook),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.createWorkbook});

  final CreateResultWorkbook createWorkbook;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ResultMaster')),
      body: const Center(child: Text('Create and manage offline school results.')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => NewResultWizardPage(createWorkbook: createWorkbook),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Result'),
      ),
    );
  }
}
