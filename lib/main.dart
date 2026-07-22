import 'package:flutter/material.dart';
import 'screens/master_dashboard_home.dart';

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
      debugShowCheckedModeBanner: false, // <-- FIX 1: This removes the "Debug" banner in the top right corner
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MasterDashboardHome(),
    );
  }
}
