import 'package:flutter/material.dart';

import 'core/theme/excel_theme.dart';
import 'features/class_register/data/sqlite_class_register_repository.dart';
import 'features/class_register/application/class_register_service.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await SqliteClassRegisterRepository.open();
  runApp(ResultMasterApp(service: ClassRegisterService(repository)));
}

class ResultMasterApp extends StatelessWidget {
  const ResultMasterApp({super.key, required this.service});
  final ClassRegisterService service;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ResultMaster',
      theme: ExcelTheme.light(),
      home: DashboardScreen(classRegisterService: service),
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
