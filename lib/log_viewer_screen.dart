import 'package:flutter/material.dart';
import 'crash_logger.dart';

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  String _logs = "Loading logs...";

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final logs = await CrashLogger.readLogs();
    setState(() {
      _logs = logs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Diagnostics & Error Logs"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        actions: [
          // Clear Logs Button
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: "Clear Logs",
            onPressed: () async {
              await CrashLogger.clearLogs();
              _loadLogs();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Error logs cleared.")),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // The Export & Share Button at the top
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.share),
                label: const Text(
                  "EXPORT & SHARE LOGS", 
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () => CrashLogger.exportLogs(),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Log History:", 
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            // Scrollable terminal-style text view for the logs
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _logs,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.greenAccent, // Retro terminal green!
                    ),
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
