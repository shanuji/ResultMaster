import 'dart:ui';
import 'package:flutter/material.dart';
import 'crash_logger.dart';

// NOTE: If your app has other imports at the top of your original main.dart 
// (like your workbook or home screen files), keep/add them right here!

void main() async {
  // 1. Ensure Flutter bindings are initialized before setting up error hooks
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Catch Flutter UI errors (Replaces the Red Screen of Death!)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    CrashLogger.logError(
      details.exception, 
      details.stack, 
      screenName: 'UI Rendering Crash',
    );
  };

  // 3. Catch Background & Asynchronous errors (Prevents silent app crashes!)
  PlatformDispatcher.instance.onError = (error, stack) {
    CrashLogger.logError(
      error, 
      stack, 
      screenName: 'Background Task / Async Error',
    );
    return true; // Tells Flutter: "We handled it, don't terminate the app!"
  };

  // 4. Custom friendly screen when any widget fails to build
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.orange, size: 60),
              const SizedBox(height: 16),
              const Text(
                "Oops! Something went wrong here.",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Don't worry, your data is safe. This error has been logged automatically so we can fix it.",
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.share),
                label: const Text("Export Error Log"),
                onPressed: () => CrashLogger.exportLogs(),
              ),
            ],
          ),
        ),
      ),
    );
  };

  // 5. Run the application
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterialDesign: true,
      ),
      // ⚠️ IMPORTANT: If your original file had a specific screen listed here 
      // instead of Scaffold(...) (like HomeScreen() or WorkbookScreen()), 
      // just change this one line back to your screen!
      home: const Scaffold(
        body: Center(
          child: Text("ResultMaster is running safely with Crash Logging!"),
        ),
      ),
    );
  }
}
