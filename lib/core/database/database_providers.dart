import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'database_service.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService.instance;
});

final databaseProvider = FutureProvider<Database>((ref) async {
  return ref.watch(databaseServiceProvider).database;
});
