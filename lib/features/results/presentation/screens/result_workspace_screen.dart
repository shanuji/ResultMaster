import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/result_master_theme.dart';
import '../providers/subject_tabs_provider.dart';

class ResultWorkspaceScreen extends ConsumerWidget {
  const ResultWorkspaceScreen({super.key});

  static const routeName = 'result-workspace';
  static const routePath = '/results/new';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = ref.watch(draftSubjectTabsProvider);

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('New Result Workbook'),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [for (final tab in tabs) Tab(text: tab.name)],
          ),
        ),
        body: TabBarView(
          children: [
            for (final tab in tabs)
              _SpreadsheetPlaceholder(subjectName: tab.name),
          ],
        ),
      ),
    );
  }
}

class _SpreadsheetPlaceholder extends StatelessWidget {
  const _SpreadsheetPlaceholder({required this.subjectName});

  final String subjectName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: ResultMasterTheme.gridLine),
        ),
        child: Column(
          children: [
            _SheetRow(cells: ['A', 'B', 'C', 'D', 'E'], isHeader: true),
            _SheetRow(cells: ['Student', subjectName, 'CA', 'Exam', 'Total']),
            for (var index = 1; index <= 8; index++)
              _SheetRow(cells: ['$index', 'Learner $index', '-', '-', '=SUM(C$index:D$index)']),
          ],
        ),
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({required this.cells, this.isHeader = false});

  final List<String> cells;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          for (final cell in cells)
            Expanded(
              child: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isHeader ? const Color(0xFFE8F1EA) : Colors.white,
                  border: Border.all(color: ResultMasterTheme.gridLine, width: 0.5),
                ),
                child: Text(cell, overflow: TextOverflow.ellipsis),
              ),
            ),
        ],
      ),
    );
  }
}
