import '../entities/result_workbook.dart';
import '../repositories/result_workbook_repository.dart';

class CreateResultWorkbook {
  const CreateResultWorkbook(this.repository);

  final ResultWorkbookRepository repository;

  Future<CreatedWorkbook> call(ResultWorkbookDraft draft) {
    if (draft.subjects.isEmpty) {
      throw ArgumentError('At least one subject is required.');
    }
    for (final subject in draft.subjects) {
      if (subject.components.isEmpty) {
        throw ArgumentError('Each subject must have at least one component.');
      }
    }
    return repository.createWorkbook(draft);
  }
}
