import 'package:flutter/material.dart';
import '../models/data_models.dart';
import '../features/result_workbook/data/repositories/sqlite_result_workbook_repository.dart';

class SubjectMarksTab extends StatelessWidget {
  final int workbookId;
  final int termId;
  final SubjectSetup subject;
  final List<StudentRow> students;
  final SqliteResultWorkbookRepository repository;
  final VoidCallback onMarksSaved;

  const SubjectMarksTab({
    Key? key,
    required this.workbookId,
    required this.termId,
    required this.subject,
    required this.students,
    required this.repository,
    required this.onMarksSaved,
  }) : super(key: key);

  Future<void> _saveMark(int studentId, int componentId, String value) async {
    await repository.saveTermMark(
      workbookId: workbookId,
      termId: termId,
      studentId: studentId,
      componentId: componentId,
      marks: value,
    );
    onMarksSaved(); 
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        final termMarks = student.getMarksForTerm(termId);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ExpansionTile(
            title: Text('${student.rollNo} - ${student.name}'),
            children: subject.components.map((component) {
              
              if (!component.isEditable) return const SizedBox.shrink();

              final currentMark = termMarks[component.id] ?? '';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextFormField(
                  initialValue: currentMark,
                  decoration: InputDecoration(
                    labelText: '${component.name} (Max: ${component.maxMarks})',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onFieldSubmitted: (value) => _saveMark(student.id, component.id, value),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
