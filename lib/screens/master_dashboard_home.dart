import 'package:flutter/material.dart';
import '../features/result_workbook/data/repositories/sqlite_result_workbook_repository.dart';
import 'workbook_dashboard_screen.dart';
// Update this import path to match the exact location of your wizard page
import '../features/result_workbook/presentation/pages/new_result_wizard_page.dart'; 

class MasterDashboardHome extends StatefulWidget {
  const MasterDashboardHome({Key? key}) : super(key: key);

  @override
  State<MasterDashboardHome> createState() => _MasterDashboardHomeState();
}

class _MasterDashboardHomeState extends State<MasterDashboardHome> {
  final SqliteResultWorkbookRepository _repository = SqliteResultWorkbookRepository();
  List<dynamic> _workbooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkbooks();
  }

  Future<void> _loadWorkbooks() async {
    setState(() => _isLoading = true);
    
    try {
      final data = await _repository.getAllWorkbooks(); 
      setState(() {
        _workbooks = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading workbooks: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ResultMaster'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _workbooks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No workbooks found',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _workbooks.length,
                  padding: const EdgeInsets.all(8.0),
                  itemBuilder: (context, index) {
                    final workbook = _workbooks[index];
                    
                    final int id = workbook is Map ? workbook['id'] : workbook.id;
                    final String title = workbook is Map 
                        ? (workbook['name'] ?? 'Unnamed Workbook') 
                        : (workbook.name ?? 'Unnamed Workbook');
                    
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16.0),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Icon(Icons.book, color: Theme.of(context).primaryColor),
                        ),
                        title: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WorkbookDashboardScreen(workbookId: id),
                            ),
                          ).then((_) => _loadWorkbooks());
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigates directly to the wizard page class instead of relying on string routes
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NewResultWizardPage(), 
            ),
          ).then((_) => _loadWorkbooks());
        },
        icon: const Icon(Icons.add),
        label: const Text('New Workbook'),
      ),
    );
  }
}
