import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/class_register/application/class_register_service.dart';
import '../../features/class_register/data/sqlite_class_register_repository.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/result_workbook/data/repositories/sqlite_result_workbook_repository.dart';
import '../../features/result_workbook/domain/usecases/create_result_workbook.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    routes: [
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        builder: (context, state) => FutureBuilder<SqliteClassRegisterRepository>(
          future: SqliteClassRegisterRepository.open(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return DashboardScreen(
              classRegisterService: ClassRegisterService(snapshot.requireData),
              createWorkbook: CreateResultWorkbook(
                SqliteResultWorkbookRepository(),
              ),
            );
          },
        ),
      ),
    ],
  );
});
