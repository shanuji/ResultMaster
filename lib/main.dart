import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'utils/crash_logger.dart';
import 'screens/master_dashboard_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('🔴 UI CRASH CAUGHT: ${details.exceptionAsString()}');
    logCrash('UI CRASH: ${details.exceptionAsString()}', details.stack.toString());
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('🔴 ASYNC CRASH CAUGHT: $error');
    logCrash('ASYNC CRASH: $error', stack.toString());
    return true; 
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bug_report, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              const Text('Oops! Something broke.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(details.exceptionAsString(), style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  };

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
        useMaterial3: true, 
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const MasterDashboardHome(),
    );
  }
}
