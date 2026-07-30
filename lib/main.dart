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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // The new beautiful Teal color scheme
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00897B), primary: const Color(0xFF00897B)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Slightly off-white for contrast with white cards
      ),
      home: const MasterDashboardHome(),
    );
  }
}
