import '../entities/result_workbook.dart';

abstract interface class ResultWorkbookRepository {
  Future<List<ResultWorkbook>> listWorkbooks();
  Future<ResultWorkbook> createWorkbook({required String title, required String className, required String academicYear});
}
