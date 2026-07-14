import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DashboardActionType {
  newResult,
  openResult,
  classRegisters,
  templates,
  backup,
  settings,
}

class DashboardAction {
  const DashboardAction({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final DashboardActionType type;
  final String title;
  final String subtitle;
  final IconData icon;
}

final dashboardActionsProvider = Provider<List<DashboardAction>>((ref) {
  return const [
    DashboardAction(
      type: DashboardActionType.newResult,
      title: 'New Result',
      subtitle: 'Create a workbook-style result sheet',
      icon: Icons.note_add_outlined,
    ),
    DashboardAction(
      type: DashboardActionType.openResult,
      title: 'Open Result',
      subtitle: 'Continue an offline result workbook',
      icon: Icons.folder_open_outlined,
    ),
    DashboardAction(
      type: DashboardActionType.classRegisters,
      title: 'Class Registers',
      subtitle: 'Manage learners, scores, and attendance',
      icon: Icons.groups_2_outlined,
    ),
    DashboardAction(
      type: DashboardActionType.templates,
      title: 'Templates',
      subtitle: 'Reuse subject and grading layouts',
      icon: Icons.table_chart_outlined,
    ),
    DashboardAction(
      type: DashboardActionType.backup,
      title: 'Backup',
      subtitle: 'Export and restore local data safely',
      icon: Icons.backup_outlined,
    ),
    DashboardAction(
      type: DashboardActionType.settings,
      title: 'Settings',
      subtitle: 'Configure school, grading, and app options',
      icon: Icons.settings_outlined,
    ),
  ];
});
