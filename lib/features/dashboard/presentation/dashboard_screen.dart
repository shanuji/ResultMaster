import 'package:flutter/material.dart';

import '../../class_register/application/class_register_service.dart';
import '../../class_register/presentation/class_register_screen.dart';
import '../../result_workbook/domain/usecases/create_result_workbook.dart';
import '../../result_workbook/presentation/pages/new_result_wizard_page.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.classRegisterService,
    required this.createWorkbook,
  });

  final ClassRegisterService classRegisterService;
  final CreateResultWorkbook createWorkbook;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ResultMaster')),
      body: GridView.count(
        padding: const EdgeInsets.all(24),
        crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 3 : 1,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _DashboardTile(
            title: 'New Result',
            icon: Icons.add_chart,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => NewResultWizardPage(createWorkbook: createWorkbook),
              ),
            ),
          ),
          _DashboardTile(
            title: 'Class Registers',
            icon: Icons.table_chart_outlined,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ClassRegisterScreen(service: classRegisterService),
            )),
          ),
        ],
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  const _DashboardTile({required this.title, required this.icon, required this.onTap});
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: onTap,
          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 42), const SizedBox(height: 12), Text(title)])),
        ),
      );
}
