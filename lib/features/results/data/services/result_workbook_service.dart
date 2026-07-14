import 'package:sqflite/sqflite.dart';

import '../../domain/entities/result_workbook.dart';
import '../models/result_workbook_model.dart';

class ResultWorkbookService {
  const ResultWorkbookService(this._database);

  final Database _database;

  Future<List<ResultWorkbook>> listWorkbooks() async {
    final rows = await _database.query('result_workbooks', orderBy: 'updated_at DESC');
    return rows.map((row) => ResultWorkbookModel.fromMap(row)).toList(growable: false);
  }

  Future<void> saveWorkbook(ResultWorkbookModel workbook) async {
    await _database.insert('result_workbooks', workbook.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
