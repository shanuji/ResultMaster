import 'package:flutter/material.dart';
import '../models/data_models.dart';
import '../database/database_helper.dart';

class FinalResultScreen extends StatefulWidget {
  final int workbookId;
  final String workbookTitle;
  const FinalResultScreen({super.key, required this.workbookId, required this.workbookTitle});

  @override
  State<FinalResultScreen> createState() => _FinalResultScreenState();
}

class _FinalResultScreenState extends State<FinalResultScreen> {
  List<TermSetup> _terms = [];
  List<StudentRow> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await DatabaseHelper.instance.loadFullWorkbookData(widget.workbookId);
    setState(() { _terms = data['terms']; _students = data['students']; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    return Scaffold(
      appBar: AppBar(title: Text('${widget.workbookTitle} - Final Result'), backgroundColor: Colors.green[100]),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Final Multi-Term Spanning Grid coming up next!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Successfully loaded ${_terms.length} terms and ${_students.length} students.', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
