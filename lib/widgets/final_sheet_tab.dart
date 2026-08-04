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
  
  final ScrollController _horizontalScroll1 = ScrollController();
  final ScrollController _horizontalScroll2 = ScrollController();
  final ScrollController _verticalScroll = ScrollController();
  bool _isTopVisible = true;

  @override
  void initState() { 
    super.initState(); 
    _sortedStudents = List.from(widget.students); _applySort(); 
    _horizontalScroll1.addListener(() { if (_horizontalScroll2.hasClients && _horizontalScroll2.offset != _horizontalScroll1.offset) { _horizontalScroll2.jumpTo(_horizontalScroll1.offset); } });
    _horizontalScroll2.addListener(() { if (_horizontalScroll1.hasClients && _horizontalScroll1.offset != _horizontalScroll2.offset) { _horizontalScroll1.jumpTo(_horizontalScroll2.offset); } });
    
    _verticalScroll.addListener(() {
      if (_verticalScroll.offset > 20 && _isTopVisible) { setState(() => _isTopVisible = false); } 
      else if (_verticalScroll.offset <= 20 && !_isTopVisible) { setState(() => _isTopVisible = true); }
    });
  }

  @override
  void dispose() { _horizontalScroll1.dispose(); _horizontalScroll2.dispose(); _verticalScroll.dispose(); super.dispose(); }

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

  Widget _buildCell(Widget child, double width, {Color? bgColor, bool isHeader = false}) {
    return Container(
      width: width, height: 60, padding: const EdgeInsets.symmetric(horizontal: 4), alignment: Alignment.center,
      decoration: BoxDecoration(color: bgColor ?? Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade300), right: BorderSide(color: Colors.grey.shade300), top: isHeader ? BorderSide(color: Colors.grey.shade300) : BorderSide.none)),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> fHeaders = []; List<Widget> sHeaders = [];
    Widget buildSortHeader(String label, String field) {
      return GestureDetector(onTap: () => _setSort(field, _sortField == field ? !_isAscending : true), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.bold)), if (_sortField == field) Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 14)]));
    }
    
    var hRoll = _buildCell(buildSortHeader('Roll', 'rollNo'), 60, bgColor: const Color(0xFFE0F2F1), isHeader: true);
    var hName = _buildCell(buildSortHeader('Name', 'name'), 160, bgColor: const Color(0xFFE0F2F1), isHeader: true);
    if (_freezeRollNo) fHeaders.add(hRoll); else sHeaders.add(hRoll);
    if (_freezeName) fHeaders.add(hName); else sHeaders.add(hName);

    for (var sub in widget.subjects) { sHeaders.add(_buildCell(Text(sub.name.isEmpty ? 'Unnamed' : sub.name, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center), 70, bgColor: const Color(0xFFE0F2F1), isHeader: true)); }
    sHeaders.add(_buildCell(buildSortHeader('Total', 'total'), 80, bgColor: const Color(0xFFE0F2F1), isHeader: true));
    sHeaders.add(_buildCell(buildSortHeader('%', 'pct'), 70, bgColor: const Color(0xFFE0F2F1), isHeader: true));
    sHeaders.add(_buildCell(const Text('Result', style: TextStyle(fontWeight: FontWeight.bold)), 65, bgColor: const Color(0xFFE0F2F1), isHeader: true)); // SHRUNK

    List<Widget> fBody = []; List<Widget> sBody = [];

    for (int i = 0; i < _sortedStudents.length; i++) {
      var student = _sortedStudents[i];
      Color rowColor = i.isEven ? Colors.white : Colors.grey.shade50;
      double totalObtained = 0.0; double totalMax = 0.0; bool naturallyFailed = false; 
      
      List<Widget> subjectCells = [];
      for (var sub in widget.subjects) {
        totalMax += sub.maxMarks; String displayMark = "-";
        if (student.isSubjectAttempted(widget.termId, sub)) {
          double score = student.getSubjectScore(widget.termId, sub); totalObtained += score;
          if (sub.includeInPassFail) {
            bool passedNormally = false;
            if (sub.components.isNotEmpty) { passedNormally = true; for (var c in sub.components) { if (c.passingMarks > 0 && (double.tryParse(student.termMarks[widget.termId]?['${sub.name}_${c.name}'] ?? "") ?? 0.0) < c.passingMarks) passedNormally = false; } } 
            else { passedNormally = score >= sub.passingMarks; }
            if (!passedNormally) naturallyFailed = true;
          }
          if (sub.components.isEmpty && (student.termMarks[widget.termId]?[sub.name] == "A" || student.termMarks[widget.termId]?[sub.name] == "AB")) { displayMark = student.termMarks[widget.termId]![sub.name]!; } 
          else { displayMark = score.toStringAsFixed(1); if (displayMark.endsWith('.0')) displayMark = displayMark.substring(0, displayMark.length - 2); }
        }
        bool isFailMark = displayMark != "-" && displayMark != "A" && displayMark != "AB" && double.parse(displayMark) < sub.passingMarks;
        subjectCells.add(_buildCell(Text(displayMark, style: TextStyle(color: isFailMark ? Colors.red : Colors.black87, fontWeight: isFailMark ? FontWeight.bold : FontWeight.normal)), 70, bgColor: rowColor));
      }
      
      double pct = totalMax > 0 ? (totalObtained / totalMax) * 100 : 0.0;
      var cellRoll = _buildCell(Container(width: 32, height: 32, decoration: const BoxDecoration(color: Color(0xFFE0F2F1), shape: BoxShape.circle), alignment: Alignment.center, child: Text(student.rollNo, style: const TextStyle(color: Color(0xFF00695C), fontWeight: FontWeight.bold))), 60, bgColor: rowColor); 
      var cellName = _buildCell(Text(student.name.isEmpty ? 'Student ${student.rollNo}' : student.name, softWrap: true, maxLines: 2, overflow: TextOverflow.ellipsis), 160, bgColor: rowColor);

      List<Widget> fCells = []; List<Widget> sCells = [];
      if (_freezeRollNo) fCells.add(cellRoll); else sCells.add(cellRoll);
      if (_freezeName) fCells.add(cellName); else sCells.add(cellName);

      sCells.addAll(subjectCells); 
      sCells.add(_buildCell(Text(totalObtained.toStringAsFixed(1)), 80, bgColor: rowColor)); 
      sCells.add(_buildCell(Text('${pct.toStringAsFixed(2)}%'), 70, bgColor: rowColor));
      
      bool hasSubjectPromotion = student.termPromotions[widget.termId]?.values.contains(true) ?? false;
      String statusText = hasSubjectPromotion ? 'PROMOTED' : (naturallyFailed ? 'FAIL' : 'PASS');
      Color statusColor = hasSubjectPromotion ? Colors.orange : (naturallyFailed ? Colors.red : Colors.green);
      sCells.add(_buildCell(Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)), 65, bgColor: rowColor));

      if (fCells.isNotEmpty) fBody.add(Row(children: fCells));
      sBody.add(Row(children: sCells));
    }

    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 250), curve: Curves.easeInOut,
          child: _isTopVisible ? Container(
            color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.push_pin, size: 16, color: Color(0xFF00897B)), const SizedBox(width: 6), const Text("Freeze Columns:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF00897B))),
                const Spacer(), const Text("Roll No", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Switch(value: _freezeRollNo, activeColor: const Color(0xFF00897B), onChanged: (val) => setState(() => _freezeRollNo = val)),
                const SizedBox(width: 16), const Text("Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Switch(value: _freezeName, activeColor: const Color(0xFF00897B), onChanged: (val) => setState(() => _freezeName = val)),
              ],
            ),
          ) : const SizedBox(width: double.infinity),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)), clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Row(children: [
                  if (fHeaders.isNotEmpty) Row(children: fHeaders),
                  Expanded(child: SingleChildScrollView(controller: _horizontalScroll1, scrollDirection: Axis.horizontal, child: Row(children: sHeaders))),
                ]),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _verticalScroll,
                    scrollDirection: Axis.vertical,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (fBody.isNotEmpty) Column(children: fBody),
                        Expanded(child: SingleChildScrollView(controller: _horizontalScroll2, scrollDirection: Axis.horizontal, child: Column(children: sBody))),
                      ]
                    )
                  )
                )
              ]
            )
          ),
        ),
      ],
    );
  }
}
