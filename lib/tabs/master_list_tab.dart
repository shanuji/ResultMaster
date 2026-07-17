import 'package:flutter/material.dart';
import '../data_models.dart';

// ==========================================
// TAB 1: MASTER LIST 
// ==========================================
class MasterListTab extends StatelessWidget {
  final List<StudentRow> students;
  final List<StudentRow> allStudents;
  final VoidCallback onUpdate;

  const MasterListTab({super.key, required this.students, required this.allStudents, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              const Text('Names & Roll Numbers editable ONLY here.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12)),
              ElevatedButton.icon(
                onPressed: () {
                  int nextRoll = 1;
                  while (allStudents.any((s) => s.rollNo.trim() == nextRoll.toString())) nextRoll++;
                  allStudents.add(StudentRow(rollNo: nextRoll.toString(), name: "New Student", marks: {}));
                  onUpdate();
                },
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Add Student'),
              )
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [DataColumn(label: Text('Roll No')), DataColumn(label: Text('Name')), DataColumn(label: Text('Actions'))],
                rows: students.map((student) {
                  return DataRow(cells: [
                    DataCell(TextFormField(initialValue: student.rollNo, decoration: const InputDecoration(border: InputBorder.none), onChanged: (val) { student.rollNo = val; onUpdate(); })),
                    DataCell(TextFormField(initialValue: student.name, decoration: const InputDecoration(border: InputBorder.none), onChanged: (val) => student.name = val)),
                    DataCell(IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () { allStudents.remove(student); onUpdate(); })),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
