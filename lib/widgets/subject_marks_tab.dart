import 'package:flutter/material.dart';
import '../models/data_models.dart';
import '../database/database_helper.dart';
import '../utils/ux_helpers.dart';

class SubjectMarksTabWidget extends StatefulWidget {
  final int termId;
  final List<SubjectSetup> subjects;
  final List<StudentRow> students;
  const SubjectMarksTabWidget({super.key, required this.termId, required this.subjects, required this.students});
  @override
  State<SubjectMarksTabWidget> createState() => _SubjectMarksTabWidgetState();
}

class _SubjectMarksTabWidgetState extends State<SubjectMarksTabWidget> {
  int _selectedSubjectIndex = 0;
  final Map<String, FocusNode> _focusNodes = {};
  List<String> _inputKeysOrder = [];
  String _searchQuery = "";

  @override
  void dispose() { for (var node in _focusNodes.values) { node.dispose(); } super.dispose(); }
  FocusNode _getFocusNode(String key) => _focusNodes.putIfAbsent(key, () => FocusNode());

  String? _validateAndCleanInput(String input, double maxAllowed) {
    String clean = input.toUpperCase().trim(); if (clean == '999') return 'AB'; if (clean.isEmpty || clean == "A" || clean == "AB") return clean;
    double? val = double.tryParse(clean); if (val == null || val > maxAllowed) return null; return clean;
  }

  void _showValidationError(double maxAllowed) { ScaffoldMessenger.of(context).clearSnackBars(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: Marks cannot exceed $maxAllowed', style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.red)); }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
        child: Column(children: [ Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 16)), const SizedBox(height: 6), Text(title, style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.bold), textAlign: TextAlign.center), const SizedBox(height: 2), Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.subjects.isEmpty) return const Center(child: Text("Go to Subjects setup first."));
    if (_selectedSubjectIndex >= widget.subjects.length) _selectedSubjectIndex = 0;
    final currentSub = widget.subjects[_selectedSubjectIndex];
    
    _inputKeysOrder.clear(); 
    List<StudentRow> filteredStudents = _searchQuery.isEmpty ? widget.students : widget.students.where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase()) || s.rollNo.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    int totalStudents = widget.students.length; 
    int enteredCount = widget.students.where((s) => s.isSubjectAttempted(widget.termId, currentSub)).length;
    int passedCount = 0; int failedCount = 0; int disttCount = 0; double sumMarks = 0.0;
    
    for (var s in widget.students) {
      if (s.isSubjectAttempted(widget.termId, currentSub)) {
        double score = s.getSubjectScore(widget.termId, currentSub); sumMarks += score;
        if (s.isSubjectPassed(widget.termId, currentSub)) passedCount++; else failedCount++;
        if (score >= (currentSub.maxMarks * 0.75)) disttCount++;
      }
    }
    double qi = enteredCount > 0 ? (sumMarks / enteredCount) : 0.0;

    List<DataColumn> gridColumns = [const DataColumn(label: Text('Roll No')), const DataColumn(label: Text('Name'))];
    if (currentSub.components.isEmpty) { gridColumns.add(DataColumn(label: Text('Marks\n(Max: ${currentSub.maxMarks.toStringAsFixed(0)})', textAlign: TextAlign.center))); } 
    else { for (var c in currentSub.components) { gridColumns.add(DataColumn(label: Text('${c.name}\n(Max: ${c.maxMarks.toStringAsFixed(0)})', textAlign: TextAlign.center))); } }
    gridColumns.add(const DataColumn(label: Text('Promote')));

    return Column(
      children: [
        SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.all(12), child: Row(children: widget.subjects.asMap().entries.map((entry) => Padding(padding: const EdgeInsets.only(right: 8.0), child: ChoiceChip(label: Text(entry.value.name.isEmpty ? 'Unnamed' : entry.value.name, style: TextStyle(color: entry.key == _selectedSubjectIndex ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)), selected: entry.key == _selectedSubjectIndex, selectedColor: const Color(0xFF00897B), backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: entry.key == _selectedSubjectIndex ? const Color(0xFF00897B) : Colors.grey.shade300)), onSelected: (selected) { if (selected) setState(() => _selectedSubjectIndex = entry.key); }))).toList())),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [const Icon(Icons.book, color: Color(0xFF00897B), size: 20), const SizedBox(width: 8), Text('Subject: ${currentSub.name} (Max: ${currentSub.maxMarks.toStringAsFixed(0)})', style: const TextStyle(fontWeight: FontWeight.bold))]), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Text('Entered: $enteredCount / $totalStudents', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00897B), fontSize: 12)))]),
          ),
        ),
        Padding(padding: const EdgeInsets.all(12.0), child: Row(children: [_buildStatCard("Passed", passedCount.toString(), Icons.check, Colors.green), _buildStatCard("Failed", failedCount.toString(), Icons.close, Colors.redAccent), _buildStatCard("QI (Avg)", qi.toStringAsFixed(2), Icons.bar_chart, Colors.blue), _buildStatCard("Distt", disttCount.toString(), Icons.pie_chart, Colors.purple)])),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0), child: SizedBox(height: 35, child: TextField(decoration: InputDecoration(hintText: 'Search Student...', prefixIcon: const Icon(Icons.search, size: 18), contentPadding: EdgeInsets.zero, border: OutlineInputBorder(borderRadius: BorderRadius.circular(20))), onChanged: (val) => setState(() => _searchQuery = val)))),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical, child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, child: DataTable(
                columnSpacing: 16, horizontalMargin: 16, headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                columns: gridColumns,
                rows: filteredStudents.asMap().entries.map((entry) {
                  int sIdx = entry.key; var student = entry.value;
                  bool isPromoted = student.termPromotions[widget.termId]?[currentSub.name] == true;
                  List<DataCell> rowCells = [DataCell(Text(student.rollNo, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))), DataCell(Text(student.name.isEmpty ? 'Student ${student.rollNo}' : student.name))];
                  
                  if (currentSub.components.isEmpty) {
                    final fieldKey = '${student.rollNo}_${currentSub.name}'; _inputKeysOrder.add(fieldKey);
                    rowCells.add(DataCell(Center(child: Container(margin: const EdgeInsets.symmetric(vertical: 6), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)), child: MarkInputField(key: ValueKey(fieldKey), initialValue: student.termMarks[widget.termId]?[currentSub.name] ?? "", focusNode: _getFocusNode(fieldKey), onFocusLostOrSubmitted: (val) async { final verified = _validateAndCleanInput(val, currentSub.maxMarks); if (verified != null) { student.termMarks[widget.termId] ??= {}; student.termMarks[widget.termId]![currentSub.name] = verified; await DatabaseHelper.instance.saveLiveMark(termId: widget.termId, rollNo: student.rollNo, markKey: currentSub.name, value: verified); setState((){}); } else { _showValidationError(currentSub.maxMarks); _getFocusNode(fieldKey).requestFocus(); } }, onNext: () { int idx = _inputKeysOrder.indexOf(fieldKey); if (idx != -1 && idx + 1 < _inputKeysOrder.length) FocusScope.of(context).requestFocus(_getFocusNode(_inputKeysOrder[idx + 1])); })))));
                  } else {
                    for (var c in currentSub.components) {
                      String markKey = '${currentSub.name}_${c.name}'; final fieldKey = '${student.rollNo}_$markKey'; _inputKeysOrder.add(fieldKey);
                      rowCells.add(DataCell(Center(child: Container(margin: const EdgeInsets.symmetric(vertical: 6), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)), child: MarkInputField(key: ValueKey(fieldKey), initialValue: student.termMarks[widget.termId]?[markKey] ?? "", focusNode: _getFocusNode(fieldKey), onFocusLostOrSubmitted: (val) async { final verified = _validateAndCleanInput(val, c.maxMarks); if (verified != null) { student.termMarks[widget.termId] ??= {}; student.termMarks[widget.termId]![markKey] = verified; await DatabaseHelper.instance.saveLiveMark(termId: widget.termId, rollNo: student.rollNo, markKey: markKey, value: verified); setState((){}); } else { _showValidationError(c.maxMarks); _getFocusNode(fieldKey).requestFocus(); } }, onNext: () { int idx = _inputKeysOrder.indexOf(fieldKey); if (idx != -1 && idx + 1 < _inputKeysOrder.length) FocusScope.of(context).requestFocus(_getFocusNode(_inputKeysOrder[idx + 1])); })))));
                    }
                  }
                  rowCells.add(DataCell(Center(child: IconButton(icon: Icon(isPromoted ? Icons.star : Icons.star_border, color: isPromoted ? Colors.amber : Colors.grey), onPressed: () async { bool newVal = !isPromoted; student.termPromotions[widget.termId] ??= {}; student.termPromotions[widget.termId]![currentSub.name] = newVal; await DatabaseHelper.instance.toggleSubjectPromotion(widget.termId, student.rollNo, currentSub.name, newVal); setState(() {}); })))));
                  return DataRow(key: ValueKey(student.rollNo), color: MaterialStateProperty.all(sIdx.isEven ? Colors.grey[50] : Colors.white), cells: rowCells);
                }).toList(),
              ),
            ),
          ),
        )
      ],
    );
  }
}
