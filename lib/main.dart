import 'package:flutter/material.dart';
import 'screens/master_dashboard_home.dart';
import 'app/theme/result_master_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ResultMasterApp());
}

class ResultMasterApp extends StatelessWidget {
  const ResultMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ResultMaster',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ResultMasterTheme.light(),
      home: const MasterDashboardHome(),
    );
  }
}
