import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/excel_theme.dart';
import 'features/class_register/application/class_register_service.dart';
import 'features/class_register/data/sqlite_class_register_repository.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/result_workbook/data/repositories/sqlite_result_workbook_repository.dart';
import 'features/result_workbook/domain/usecases/create_result_workbook.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final classRegisterRepository = await SqliteClassRegisterRepository.open();
  final createWorkbook = CreateResultWorkbook(SqliteResultWorkbookRepository());

  runApp(
    ResultMasterApp(
      classRegisterService: ClassRegisterService(classRegisterRepository),
      createWorkbook: createWorkbook,
    ),
  );
}

class ResultMasterApp extends StatelessWidget {
  const ResultMasterApp({
    super.key,
    required this.classRegisterService,
    required this.createWorkbook,
  });

  final ClassRegisterService classRegisterService;
  final CreateResultWorkbook createWorkbook;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ResultMaster',
      debugShowCheckedModeBanner: false,
      theme: ExcelTheme.light(),
      home: DashboardScreen(
        classRegisterService: classRegisterService,
        createWorkbook: createWorkbook,
      ),
    );
  }
}
