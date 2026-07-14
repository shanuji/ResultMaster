import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/result_master_theme.dart';
import '../../../results/presentation/screens/result_workspace_screen.dart';
import '../providers/dashboard_actions_provider.dart';
import '../widgets/dashboard_action_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const routeName = 'dashboard';
  static const routePath = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.watch(dashboardActionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ResultMaster'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _DashboardHero(onCreateResult: () => context.go(ResultWorkspaceScreen.routePath)),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 260,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];
                return DashboardActionCard(
                  action: action,
                  onTap: action.type == DashboardActionType.newResult
                      ? () => context.go(ResultWorkspaceScreen.routePath)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({required this.onCreateResult});

  final VoidCallback onCreateResult;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: const BoxDecoration(
        color: ResultMasterTheme.excelGreen,
        border: Border(bottom: BorderSide(color: ResultMasterTheme.excelDarkGreen, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Offline result workbooks for every class',
            style: textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Create Excel-like sheets, add subjects as tabs, and keep school data on this Android device.',
            style: textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onCreateResult,
            icon: const Icon(Icons.add),
            label: const Text('Start New Result'),
          ),
        ],
      ),
    );
  }
}
