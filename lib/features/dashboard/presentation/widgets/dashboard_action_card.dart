import 'package:flutter/material.dart';

import '../providers/dashboard_actions_provider.dart';

class DashboardActionCard extends StatelessWidget {
  const DashboardActionCard({required this.action, this.onTap, super.key});

  final DashboardAction action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(action.icon, color: colorScheme.primary, size: 32),
              const Spacer(),
              Text(action.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(action.subtitle, maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
