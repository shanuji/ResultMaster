import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../../subjects/presentation/subject_tabs_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final databaseState = ref.watch(databaseProvider);
    final subjectTabs = ref.watch(subjectTabsProvider);

    return DefaultTabController(
      length: subjectTabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ResultMaster'),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              for (final tab in subjectTabs) Tab(text: tab.name),
            ],
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _WorkbookHeader(databaseState: databaseState),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    children: [
                      for (final tab in subjectTabs)
                        _WorksheetPreview(title: tab.name),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: 0,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.table_chart_outlined),
              selectedIcon: Icon(Icons.table_chart),
              label: 'Sheets',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkbookHeader extends StatelessWidget {
  const _WorkbookHeader({required this.databaseState});

  final AsyncValue<Object?> databaseState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = databaseState.when(
      data: (_) => 'Offline database ready',
      loading: () => 'Preparing offline database...',
      error: (_, __) => 'Database setup needs attention',
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.grid_on, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Result workbook',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(status, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorksheetPreview extends StatelessWidget {
  const _WorksheetPreview({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: 12,
              itemBuilder: (context, index) {
                final rowLabel = index == 0 ? '' : index.toString();
                return _SheetRow(rowLabel: rowLabel, isHeader: index == 0);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({required this.rowLabel, required this.isHeader});

  final String rowLabel;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    final labels = isHeader ? ['A', 'B', 'C', 'D'] : ['Student', 'Score', 'Grade', 'Remark'];

    return IntrinsicHeight(
      child: Row(
        children: [
          _SheetCell(text: rowLabel, isHeader: true, flex: 1),
          for (final label in labels)
            _SheetCell(text: label, isHeader: isHeader, flex: 3),
        ],
      ),
    );
  }
}

class _SheetCell extends StatelessWidget {
  const _SheetCell({
    required this.text,
    required this.isHeader,
    required this.flex,
  });

  final String text;
  final bool isHeader;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      flex: flex,
      child: Container(
        minHeight: 44,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isHeader ? theme.colorScheme.surfaceContainerHighest : Colors.white,
          border: Border.all(color: const Color(0xFFD9E2DD), width: 0.5),
        ),
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
