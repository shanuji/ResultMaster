import 'package:flutter_test/flutter_test.dart';
import 'package:result_master/features/result_workbook/domain/entities/result_workbook.dart';
import 'package:result_master/features/result_workbook/domain/repositories/result_workbook_repository.dart';
import 'package:result_master/features/result_workbook/domain/usecases/create_result_workbook.dart';

class FakeResultWorkbookRepository implements ResultWorkbookRepository {
  ResultWorkbookDraft? savedDraft;

  @override
  Future<CreatedWorkbook> createWorkbook(ResultWorkbookDraft draft) async {
    savedDraft = draft;
    return CreatedWorkbook(id: 1, draft: draft);
  }

  @override
  Future<List<Student>> getClassRegisterStudents(int classRegisterId) async => const <Student>[];
}

void main() {
  test('creates workbook draft with components and pass criteria', () async {
    final repository = FakeResultWorkbookRepository();
    final usecase = CreateResultWorkbook(repository);
    final draft = ResultWorkbookDraft(
      academicYear: '2026-27',
      className: 'III',
      section: 'A',
      examinationName: 'Periodic Test 1',
      studentSourceType: StudentSourceType.newList,
      subjects: const <SubjectConfig>[
        SubjectConfig(
          name: 'English',
          components: <AssessmentComponent>[AssessmentComponent(name: 'FA')],
        ),
      ],
      passCriteria: const <PassCriterion>[PassCriterion(subjectName: 'English', passMarks: 33)],
    );

    final created = await usecase(draft);

    expect(created.id, 1);
    expect(repository.savedDraft, draft);
  });
}
