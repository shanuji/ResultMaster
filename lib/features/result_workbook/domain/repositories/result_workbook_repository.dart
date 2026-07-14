import '../entities/result_workbook.dart';

abstract class ResultWorkbookRepository {
  Future<List<Student>> getClassRegisterStudents(int classRegisterId);
  Future<CreatedWorkbook> createWorkbook(ResultWorkbookDraft draft);
}
