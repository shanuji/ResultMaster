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
    );
  }
}
