
import 'package:flutter/material.dart';
import '../models/data_models.dart';

class FinalSheetTabWidget extends StatefulWidget {
  final List<SubjectSetup> subjects; 
  final List<StudentRow> students;
  const FinalSheetTabWidget({super.key, required this.subjects, required this.students});
  @override
  State<FinalSheetTabWidget> createState() => _FinalSheetTabWidgetState();
}

class _FinalSheetTabWidgetState extends State<FinalSheetTabWidget> {
  String _sortField = 'rollNo'; 
  bool _isAscending = true; 
  late List<StudentRow> _sortedStudents;
  
  bool _freezeRollNo = true; 
  bool _freezeName = true; 
  
  @override
  void initState() { super.initState(); _sortedStudents = List.from(widget.students); _applySort(); }
  @override
  void didUpdateWidget(covariant FinalSheetTabWidget oldWidget) { super.didUpdateWidget(oldWidget); _sortedStudents = List.from(widget.students); _applySort(); }
  
  double _getTotal(StudentRow student) { double total = 0.0; for (var sub in widget.subjects) { if (student.isSubjectAttempted(sub)) total += student.getSubjectScore(sub); } return total; }
  double _getPct(StudentRow student) { double totalObtained = _getTotal(student); double totalMax = widget.subjects.fold(0.0, (sum, sub) => sum + sub.maxMarks); return totalMax > 0 ? (totalObtained / totalMax) * 100 : 0.0; }
  
  void _applySort() { 
    if (_sortField.isEmpty) return;
    _sortedStudents.sort((a, b) { 
      int mod = _isAscending ? 1 : -1; 
      if (_sortField == 'rollNo') return ((double.tryParse(a.rollNo) ?? 0).compareTo(double.tryParse(b.rollNo) ?? 0)) * mod; 
      else if (_sortField == 'name') return a.name.toLowerCase().compareTo(b.name.toLowerCase()) * mod; 
      else if (_sortField == 'total') return _getTotal(a).compareTo(_getTotal(b)) * mod; 
      else if (_sortField == 'pct') return _getPct(a).compareTo(_getPct(b)) * mod; 
      return 0; 
    }); 
  }

  void _setSort(String field, bool asc) {
    setState(() { _sortField = field; _isAscending = asc; _applySort(); });
  }

  @override
  Widget build(BuildContext context) {
    List<DataColumn> fixedCols = [];
    List<DataColumn> scrollCols = [];

    var colRoll = DataColumn(label: const Text('Roll No'), onSort: (idx, asc) => _setSort('rollNo', asc));
    var colName = DataColumn(label: const Text('Name'), onSort: (idx, asc) => _setSort('name', asc));

    if (_freezeRollNo) fixedCols.add(colRoll); else scrollCols.add(colRoll);
    if (_freezeName) fixedCols.add(colName); else scrollCols.add(colName);

    for (var sub in widget.subjects) {
      scrollCols.add(DataColumn(label: Text(sub.name.isEmpty ? 'Unnamed' : sub.name)));
    }
    
    var colTotal = DataColumn(label: const Text('Total'), numeric: true, onSort: (idx, asc) => _setSort('total', asc));
    var colPct = DataColumn(label: const Text('%'), numeric: true, onSort: (idx, asc) => _setSort('pct', asc));
    
    scrollCols.add(colTotal);
    scrollCols.add(colPct);
    scrollCols.add(const DataColumn(label: Text('Result')));

    List<DataRow> fixedRows = [];
    List<DataRow> scrollRows = [];

    for (int i = 0; i < _sortedStudents.length; i++) {
      var student = _sortedStudents[i];
      double totalObtained = 0.0; double totalMax = 0.0; bool failed = false; 
      
      List<DataCell> subjectCells = [];
      for (var sub in widget.subjects) {
        totalMax += sub.maxMarks; String displayMark = "-";
        if (student.isSubjectAttempted(sub)) {
          double score = student.getSubjectScore(sub); totalObtained += score;
          if (sub.includeInPassFail && !student.isSubjectPassed(sub)) failed = true;
          if (sub.components.isEmpty && (student.marks[sub.name] == "A" || student.marks[sub.name] == "AB")) {
            displayMark = student.marks[sub.name]!; 
          } else { 
            displayMark = score.toStringAsFixed(1); if (displayMark.endsWith('.0')) displayMark = displayMark.substring(0, displayMark.length - 2); 
          }
        }
        subjectCells.add(DataCell(Text(displayMark)));
      }
      
      double pct = totalMax > 0 ? (totalObtained / totalMax) * 100 : 0.0;

      var cellRoll = DataCell(SizedBox(width: 50, child: Text(student.rollNo)));
      var cellName = DataCell(Text(student.name.isEmpty ? '-' : student.name));

      List<DataCell> fCells = [];
      List<DataCell> sCells = [];

      if (_freezeRollNo) fCells.add(cellRoll); else sCells.add(cellRoll);
      if (_freezeName) fCells.add(cellName); else sCells.add(cellName);

      sCells.addAll(subjectCells);
      sCells.add(DataCell(Text(totalObtained.toStringAsFixed(1))));
      sCells.add(DataCell(Text('${pct.toStringAsFixed(2)}%')));
      sCells.add(DataCell(Text(failed ? 'FAIL' : 'PASS', style: TextStyle(color: failed ? Colors.red : Colors.green, fontWeight: FontWeight.bold))));

      Color rowColor = i.isEven ? Colors.grey[100]! : Colors.white;
      if (fixedCols.isNotEmpty) fixedRows.add(DataRow(color: MaterialStateProperty.all(rowColor), cells: fCells));
      scrollRows.add(DataRow(color: MaterialStateProperty.all(rowColor), cells: sCells));
    }

    int? fixedSortIndex;
    if (_sortField == 'rollNo' && _freezeRollNo) fixedSortIndex = fixedCols.indexOf(colRoll);
    if (_sortField == 'name' && _freezeName) fixedSortIndex = fixedCols.indexOf(colName);
    
    int? scrollSortIndex;
    if (_sortField == 'rollNo' && !_freezeRollNo) scrollSortIndex = scrollCols.indexOf(colRoll);
    if (_sortField == 'name' && !_freezeName) scrollSortIndex = scrollCols.indexOf(colName);
    if (_sortField == 'total') scrollSortIndex = scrollCols.indexOf(colTotal);
    if (_sortField == 'pct') scrollSortIndex = scrollCols.indexOf(colPct);

    return Column(
      children: [
        Container(
          color: Colors.blue[50], padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.push_pin, size: 16, color: Colors.blue),
              const SizedBox(width: 6),
              const Text("Freeze Columns:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
              const Spacer(),
              const Text("Roll No", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Switch(value: _freezeRollNo, activeColor: Colors.blue, onChanged: (val) => setState(() => _freezeRollNo = val)),
              const SizedBox(width: 16),
              const Text("Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Switch(value: _freezeName, activeColor: Colors.blue, onChanged: (val) => setState(() => _freezeName = val)),
            ],
          ),
        ),
        Expanded(
          child: fixedCols.isEmpty ? 
            SingleChildScrollView(
              scrollDirection: Axis.vertical, 
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.blue[100]), 
                  sortColumnIndex: scrollSortIndex, sortAscending: _isAscending,
                  columns: scrollCols,
                  rows: scrollRows,
                ),
              ),
            )
            : 
            SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DataTable(
                    headingRowColor: MaterialStateProperty.all(Colors.blue[100]), dataRowMinHeight: 48, dataRowMaxHeight: 48,
                    sortColumnIndex: fixedSortIndex, sortAscending: _isAscending,
                    columns: fixedCols,
                    rows: fixedRows,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(Colors.blue[100]), dataRowMinHeight: 48, dataRowMaxHeight: 48, 
                        sortColumnIndex: scrollSortIndex, sortAscending: _isAscending,
                        columns: scrollCols,
                        rows: scrollRows,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ),
      ],
    );
  }
}
