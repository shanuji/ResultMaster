import '../entities/result_workbook.dart';

abstract class ResultWorkbookRepository {
  Future<List<Student>> getClassRegisterStudents(int classRegisterId);
  Future<List<WorkbookSummary>> listWorkbooks();
  Future<OpenedWorkbook> openWorkbook(int workbookId);
  Future<CreatedWorkbook> createWorkbook(ResultWorkbookDraft draft);
  Future<void> renameWorkbook(int workbookId, String examinationName);
  Future<void> deleteWorkbook(int workbookId);
  Future<void> saveMark({required int workbookId, required int studentId, required int componentId, double? marks});
}
