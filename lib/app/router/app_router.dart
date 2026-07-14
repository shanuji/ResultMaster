import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/results/presentation/screens/result_workspace_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: DashboardScreen.routePath,
    routes: [
      GoRoute(
        path: DashboardScreen.routePath,
        name: DashboardScreen.routeName,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: ResultWorkspaceScreen.routePath,
        name: ResultWorkspaceScreen.routeName,
        builder: (context, state) => const ResultWorkspaceScreen(),
      ),
    ],
  );
});
