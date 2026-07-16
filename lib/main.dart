import 'dart:ui';
import 'package:flutter/material.dart';
import 'crash_logger.dart';
import 'log_viewer_screen.dart'; // NEW: Importing our hidden log viewer!

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Catch Flutter UI errors (Replaces the Red Screen of Death!)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    CrashLogger.logError(
      details.exception, 
      details.stack, 
      screenName: 'UI Rendering Crash',
    );
  };

  // 2. Catch Background & Asynchronous errors (Prevents silent app crashes!)
  PlatformDispatcher.instance.onError = (error, stack) {
    CrashLogger.logError(
      error, 
      stack, 
      screenName: 'Background Task / Async Error',
    );
    return true;
  };

  // 3. Custom friendly screen when any widget fails to build
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
      // We point to our new Home screen with the Secret Tap Trick built in!
      home: const SecretHomeScreen(),
    );
  }
}

// 4. NEW: A home screen with the secret 5-tap developer mode!
class SecretHomeScreen extends StatefulWidget {
  const SecretHomeScreen({super.key});

  @override
  State<SecretHomeScreen> createState() => _SecretHomeScreenState();
}

class _SecretHomeScreenState extends State<SecretHomeScreen> {
  int _secretTapCount = 0; // This keeps track of how many times you tapped!

  void _onSecretTap() {
    _secretTapCount++;
    if (_secretTapCount >= 5) {
      _secretTapCount = 0; // Reset the counter
      
      // Navigate to your hidden Log Viewer screen!
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LogViewerScreen()),
      );
      
      // Show a fun developer banner at the bottom of the screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("👨‍💻 Developer Mode: Diagnostic Logs Opened!"),
          backgroundColor: Colors.blueGrey,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ResultMaster Workbook"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              "Welcome to ResultMaster!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Your offline marks & result management app.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            
            // 🌟 THIS IS THE SECRET BUTTON! 
            // Tap this text 5 times quickly in your app to open the log screen!
            GestureDetector(
              onTap: _onSecretTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "ResultMaster v1.0.0 (Tap 5x for Logs)",
                  style: TextStyle(
                    color: Colors.blueGrey, 
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
