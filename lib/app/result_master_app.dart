import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'theme/result_master_theme.dart';

class ResultMasterApp extends ConsumerWidget {
  const ResultMasterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'ResultMaster',
      debugShowCheckedModeBanner: false,
      theme: ResultMasterTheme.light(),
      darkTheme: ResultMasterTheme.dark(),
      routerConfig: router,
    );
  }
}
