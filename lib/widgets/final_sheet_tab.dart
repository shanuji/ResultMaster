import 'package:flutter/material.dart';
import '../models/data_models.dart';

class FinalSheetTabWidget extends StatefulWidget {
  final int termId;
  final List<SubjectSetup> subjects; 
  final List<StudentRow> students;
  const FinalSheetTabWidget({super.key, required this.termId, required this.subjects, required this.students});
  @override
  State<FinalSheetTabWidget> createState() => _FinalSheetTabWidgetState();
}

class _FinalSheetTabWidgetState extends State<FinalSheetTabWidget> {
  String _sortField = 'rollNo'; 
  bool _isAscending = true; 
  late List<StudentRow> _sortedStudents;
  bool _freezeRollNo = true; bool _freezeName = true; 
  
  @override
  void initState() { super.initState(); _sortedStudents = List.from(widget.students); _applySort(); }
  @override
  void didUpdateWidget(covariant FinalSheetTabWidget oldWidget) { super.didUpdateWidget(oldWidget); _sortedStudents = List.from(widget.students); _applySort(); }
  
  double _getTotal(StudentRow student) { double total = 0.0; for (var sub in widget.subjects) { if (student.isSubjectAttempted(widget.termId, sub)) total += student.getSubjectScore(widget.termId, sub); } return total; }
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

  void _setSort(String field, bool asc) { setState(() { _sortField = field; _isAscending = asc; _applySort(); }); }

  @override
  Widget build(BuildContext context) {
    List<DataColumn> fixedCols = []; List<DataColumn> scrollCols = [];
    var colRoll = DataColumn(label: const Text('Roll No \u2191', style: TextStyle(fontWeight: FontWeight.bold)), onSort: (idx, asc) => _setSort('rollNo', asc));
    var colName = DataColumn(label: const Text('Name', style: TextStyle(fontWeight: FontWeight.bold)), onSort: (idx, asc) => _setSort('name', asc));

    if (_freezeRollNo) fixedCols.add(colRoll); else scrollCols.add(colRoll);
    if (_freezeName) fixedCols.add(colName); else scrollCols.add(colName);
    for (var sub in widget.subjects) { scrollCols.add(DataColumn(label: Text(sub.name.isEmpty ? 'Unnamed' : sub.name, style: const TextStyle(fontWeight: FontWeight.bold)))); }
    
    var colTotal = DataColumn(label: const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true, onSort: (idx, asc) => _setSort('total', asc));
    var colPct = DataColumn(label: const Text('%', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true, onSort: (idx, asc) => _setSort('pct', asc));
    scrollCols.add(colTotal); scrollCols.add(colPct); scrollCols.add(const DataColumn(label: Text('Result', style: TextStyle(fontWeight: FontWeight.bold))));

    List<DataRow> fixedRows = []; List<DataRow> scrollRows = [];

    for (int i = 0; i < _sortedStudents.length; i++) {
      var student = _sortedStudents[i];
      double totalObtained = 0.0; double totalMax = 0.0; bool naturallyFailed = false; 
      
      List<DataCell> subjectCells = [];
      for (var sub in widget.subjects) {
        totalMax += sub.maxMarks; String displayMark = "-";
        if (student.isSubjectAttempted(widget.termId, sub)) {
          double score = student.getSubjectScore(widget.termId, sub); totalObtained += score;
          if (sub.includeInPassFail) {
            bool passedNormally = false;
            if (sub.components.isNotEmpty) {
              passedNormally = true;
              for (var c in sub.components) { if (c.passingMarks > 0 && (double.tryParse(student.termMarks[widget.termId]?['${sub.name}_${c.name}'] ?? "") ?? 0.0) < c.passingMarks) passedNormally = false; }
            } else { passedNormally = score >= sub.passingMarks; }
            if (!passedNormally) naturallyFailed = true;
          }
          if (sub.components.isEmpty && (student.termMarks[widget.termId]?[sub.name] == "A" || student.termMarks[widget.termId]?[sub.name] == "AB")) { displayMark = student.termMarks[widget.termId]![sub.name]!; } 
          else { displayMark = score.toStringAsFixed(1); if (displayMark.endsWith('.0')) displayMark = displayMark.substring(0, displayMark.length - 2); }
        }
        bool isFailMark = displayMark != "-" && displayMark != "A" && displayMark != "AB" && double.parse(displayMark) < sub.passingMarks;
        subjectCells.add(DataCell(Center(child: Text(displayMark, style: TextStyle(color: isFailMark ? Colors.red : Colors.black87, fontWeight: isFailMark ? FontWeight.bold : FontWeight.normal)))));
      }
      
      double pct = totalMax > 0 ? (totalObtained / totalMax) * 100 : 0.0;
      
      var cellRoll = DataCell(Container(width: 32, height: 32, decoration: const BoxDecoration(color: Color(0xFFE0F2F1), shape: BoxShape.circle), alignment: Alignment.center, child: Text(student.rollNo, style: const TextStyle(color: Color(0xFF00695C), fontWeight: FontWeight.bold)))); 
      
      // FIX: Force max lines and wrap text inside a fixed-width container to prevent 90-pixel overflow!
      var cellName = DataCell(SizedBox(width: 120, child: Text(student.name.isEmpty ? 'Student ${student.rollNo}' : student.name, softWrap: true, maxLines: 2, overflow: TextOverflow.ellipsis)));

      List<DataCell> fCells = []; List<DataCell> sCells = [];
      if (_freezeRollNo) fCells.add(cellRoll); else sCells.add(cellRoll);
      if (_freezeName) fCells.add(cellName); else sCells.add(cellName);

      sCells.addAll(subjectCells); sCells.add(DataCell(Center(child: Text(totalObtained.toStringAsFixed(1))))); sCells.add(DataCell(Center(child: Text('${pct.toStringAsFixed(2)}%'))));
      
      bool hasSubjectPromotion = student.termPromotions[widget.termId]?.values.contains(true) ?? false;
      String statusText = hasSubjectPromotion ? 'PROMOTED' : (naturallyFailed ? 'FAIL' : 'PASS');
      Color statusColor = hasSubjectPromotion ? Colors.orange : (naturallyFailed ? Colors.red : Colors.green);
      sCells.add(DataCell(Center(child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)))));

      Color rowColor = i.isEven ? Colors.white : Colors.grey[50]!;
      if (fixedCols.isNotEmpty) fixedRows.add(DataRow(color: MaterialStateProperty.all(rowColor), cells: fCells));
      scrollRows.add(DataRow(color: MaterialStateProperty.all(rowColor), cells: sCells));
    }

    int? fixedSortIndex; int? scrollSortIndex;
    if (_sortField == 'rollNo' && _freezeRollNo) fixedSortIndex = fixedCols.indexOf(colRoll);
    if (_sortField == 'name' && _freezeName) fixedSortIndex = fixedCols.indexOf(colName);
    if (_sortField == 'rollNo' && !_freezeRollNo) scrollSortIndex = scrollCols.indexOf(colRoll);
    if (_sortField == 'name' && !_freezeName) scrollSortIndex = scrollCols.indexOf(colName);
    if (_sortField == 'total') scrollSortIndex = scrollCols.indexOf(colTotal);
    if (_sortField == 'pct') scrollSortIndex = scrollCols.indexOf(colPct);

    return Column(
      children: [
        Container(
          color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.push_pin, size: 16, color: Color(0xFF00897B)), const SizedBox(width: 6), const Text("Freeze Columns:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF00897B))),
              const Spacer(), const Text("Roll No", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Switch(value: _freezeRollNo, activeColor: const Color(0xFF00897B), onChanged: (val) => setState(() => _freezeRollNo = val)),
              const SizedBox(width: 16), const Text("Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Switch(value: _freezeName, activeColor: const Color(0xFF00897B), onChanged: (val) => setState(() => _freezeName = val)),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: fixedCols.isEmpty ? 
              SingleChildScrollView(scrollDirection: Axis.vertical, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(columnSpacing: 24, headingRowColor: MaterialStateProperty.all(const Color(0xFFE0F2F1)), sortColumnIndex: scrollSortIndex, sortAscending: _isAscending, columns: scrollCols, rows: scrollRows)))
              : 
              SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DataTable(columnSpacing: 24, headingRowColor: MaterialStateProperty.all(const Color(0xFFE0F2F1)), dataRowMinHeight: 48, dataRowMaxHeight: 48, sortColumnIndex: fixedSortIndex, sortAscending: _isAscending, columns: fixedCols, rows: fixedRows),
                    Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(columnSpacing: 24, headingRowColor: MaterialStateProperty.all(const Color(0xFFE0F2F1)), dataRowMinHeight: 48, dataRowMaxHeight: 48, sortColumnIndex: scrollSortIndex, sortAscending: _isAscending, columns: scrollCols, rows: scrollRows))),
                  ],
                ),
              ),
          ),
        ),
      ],
    );
  }
}
