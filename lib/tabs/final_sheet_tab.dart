import 'package:flutter/material.dart';
import '../data_models.dart';

// ==========================================
// TAB 3: FINAL CALCULATION (Sorting & Pass/Fail toggle logic)
// ==========================================
class FinalSheetTab extends StatefulWidget {
  final List<SubjectSetup> subjects;
  final List<StudentRow> students;

  const FinalSheetTab({super.key, required this.subjects, required this.students});

  @override
  State<FinalSheetTab> createState() => _FinalSheetTabState();
}

class _FinalSheetTabState extends State<FinalSheetTab> {
  int? _sortColumnIndex;
  bool _isAscending = true;
  late List<StudentRow> _sortedStudents;

  @override
  void initState() {
    super.initState();
    _sortedStudents = List.from(widget.students);
  }

  @override
  void didUpdateWidget(covariant FinalSheetTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sortedStudents = List.from(widget.students);
    _applySort();
  }

  double _getTotal(StudentRow student) {
    double total = 0.0;
    for (var sub in widget.subjects) {
      if (student.isSubjectAttempted(sub)) {
        total += student.getSubjectScore(sub);
      }
    }
    return total;
  }

  double _getPct(StudentRow student) {
    double totalObtained = _getTotal(student);
    double totalMax = widget.subjects.fold(0.0, (sum, sub) => sum + sub.maxMarks);
    return totalMax > 0 ? (totalObtained / totalMax) * 100 : 0.0;
  }

  void _applySort() {
    if (_sortColumnIndex == null) return;
    
    _sortedStudents.sort((a, b) {
      int mod = _isAscending ? 1 : -1;
      
      if (_sortColumnIndex == 0) { 
        double rollA = double.tryParse(a.rollNo) ?? 0;
        double rollB = double.tryParse(b.rollNo) ?? 0;
        return rollA.compareTo(rollB) * mod;
      } else if (_sortColumnIndex == 1) { 
        return a.name.toLowerCase().compareTo(b.name.toLowerCase()) * mod;
      } else if (_sortColumnIndex == widget.subjects.length + 2) { 
        return _getTotal(a).compareTo(_getTotal(b)) * mod;
      } else if (_sortColumnIndex == widget.subjects.length + 3) { 
        return _getPct(a).compareTo(_getPct(b)) * mod;
      }
      return 0;
    });
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _isAscending = ascending;
      _applySort();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.blue[50]),
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _isAscending,
          columns: [
            DataColumn(label: const Text('Roll No'), onSort: _onSort),
            DataColumn(label: const Text('Name'), onSort: _onSort),
            ...widget.subjects.map((sub) => DataColumn(label: Text(sub.name))),
            DataColumn(label: const Text('Total'), onSort: _onSort, numeric: true),
            DataColumn(label: const Text('%'), onSort: _onSort, numeric: true),
            const DataColumn(label: Text('Result')),
          ],
          rows: _sortedStudents.map((student) {
            double totalObtained = 0.0;
            double totalMax = 0.0;
            bool failed = false;

            List<DataCell> subjectCells = [];

            for (var sub in widget.subjects) {
              totalMax += sub.maxMarks;
              String displayMark = "-";

              if (student.isSubjectAttempted(sub)) {
                double score = student.getSubjectScore(sub);
                totalObtained += score;
                
                if (sub.includeInPassFail && score < sub.passingMarks) {
                  failed = true; 
                }

                if (sub.components.isEmpty && (student.marks[sub.name] == "A" || student.marks[sub.name] == "AB")) {
                  displayMark = student.marks[sub.name]!;
                } else {
                  displayMark = score.toStringAsFixed(1);
                  if (displayMark.endsWith('.0')) displayMark = displayMark.substring(0, displayMark.length - 2);
                }
              }
              subjectCells.add(DataCell(Text(displayMark)));
            }

            double pct = totalMax > 0 ? (totalObtained / totalMax) * 100 : 0.0;

            return DataRow(
              cells: [
                DataCell(Text(student.rollNo)),
                DataCell(Text(student.name)),
                ...subjectCells,
                DataCell(Text(totalObtained.toStringAsFixed(1))),
                DataCell(Text('${pct.toStringAsFixed(2)}%')),
                DataCell(Text(failed ? 'FAIL' : 'PASS', style: TextStyle(color: failed ? Colors.red : Colors.green, fontWeight: FontWeight.bold))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
