import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class CrashLogger {
  static const String _fileName = 'resultmaster_crash_log.txt';

  // 1. Get the secret file on the phone where we save logs
  static Future<File> _getLogFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  // 2. Write an error to the log file with Date, Time, and Details
  static Future<void> logError(Object error, StackTrace? stackTrace, {String? screenName}) async {
    try {
      final file = await _getLogFile();
      final timestamp = DateTime.now().toString();
      final currentScreen = screenName ?? 'Unknown Screen';

      // Format the log entry cleanly
      final logEntry = '''
=========================================
TIME: $timestamp
SCREEN: $currentScreen
ERROR: ${error.toString()}
STACK TRACE:
${stackTrace?.toString() ?? 'No stack trace available.'}
=========================================

''';

      // Write to the file (mode: FileMode.append adds to the bottom instead of overwriting)
      await file.writeAsString(logEntry, mode: FileMode.append);
      if (kDebugMode) {
        print("Error logged successfully to file!");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Failed to write to log file: $e");
      }
    }
  }

  // 3. Read all saved logs so we can display them in the app
  static Future<String> readLogs() async {
    try {
      final file = await _getLogFile();
      if (await file.exists()) {
        return await file.readAsString();
      } else {
        return "No errors logged yet! Everything is running smoothly.";
      }
    } catch (e) {
      return "Failed to read logs: $e";
    }
  }

  // 4. Clear the log file once issues are fixed
  static Future<void> clearLogs() async {
    try {
      final file = await _getLogFile();
      if (await file.exists()) {
        await file.writeAsString(''); // Overwrite with empty string
      }
    } catch (e) {
      if (kDebugMode) {
        print("Failed to clear logs: $e");
      }
    }
  }

  // 5. Export/Share the log file via email, WhatsApp, etc.
  static Future<void> exportLogs() async {
    try {
      final file = await _getLogFile();
      if (await file.exists()) {
        // Use share_plus to open the native phone share menu
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'ResultMaster Error Logs',
          text: 'Attached is the crash log file from ResultMaster.',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("Failed to export logs: $e");
      }
    }
  }
}
