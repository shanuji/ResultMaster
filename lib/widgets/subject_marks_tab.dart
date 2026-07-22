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
  @override
  void dispose() { for (var node in _focusNodes.values) { node.dispose(); } super.dispose(); }
  FocusNode _getFocusNode(String key) => _focusNodes.putIfAbsent(key, () => FocusNode());

  // ... (Keep your existing _validateAndCleanInput and _showValidationError methods here) ...
  String? _validateAndCleanInput(String input, double maxAllowed, String studentName) {
    String clean = input.toUpperCase().trim(); if (clean == '999') return 'AB'; if (clean.isEmpty) return ""; if (clean == "A" || clean == "AB") return clean;
    double? val = double.tryParse(clean); if (val == null || val > maxAllowed) return null; return clean;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.subjects.isEmpty) return const Center(child: Text("Go to the Setup tab to add subjects first."));
    if (_selectedSubjectIndex >= widget.subjects.length) _selectedSubjectIndex = 0;
    final currentSub = widget.subjects[_selectedSubjectIndex];
    
    List<DataColumn> gridColumns = [const DataColumn(label: Text('Roll No')), const DataColumn(label: Text('Name'))];
    if (currentSub.components.isEmpty) { gridColumns.add(DataColumn(label: Text('Marks (Max: ${currentSub.maxMarks.toStringAsFixed(0)})'))); } 
    else { for (var c in currentSub.components) { gridColumns.add(DataColumn(label: Text('${c.name}\n(Max: ${c.maxMarks.toStringAsFixed(0)})'))); } }
    gridColumns.add(const DataColumn(label: Text('Promote'))); // Option A Column

    return Column(
      children: [
        SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.all(8), child: Row(children: widget.subjects.asMap().entries.map((entry) => Padding(padding: const EdgeInsets.only(right: 8.0), child: ChoiceChip(label: Text(entry.value.name.isEmpty ? 'Unnamed' : entry.value.name), selected: entry.key == _selectedSubjectIndex, selectedColor: entry.value.themeColor.withOpacity(0.4), onSelected: (selected) { if (selected) setState(() => _selectedSubjectIndex = entry.key); }))).toList())),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical, child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, child: DataTable(
                columns: gridColumns,
                rows: widget.students.asMap().entries.map((entry) {
                  int sIdx = entry.key; var student = entry.value;
                  bool isPromoted = student.termPromotions[widget.termId]?[currentSub.name] == true;
                  bool isFail = currentSub.includeInPassFail && student.isSubjectAttempted(widget.termId, currentSub) && !student.isSubjectPassed(widget.termId, currentSub);
                  Color? cellColor = isPromoted ? Colors.blue[50] : (isFail ? Colors.red[100] : (sIdx.isEven ? Colors.grey[100] : Colors.white));
                  
                  List<DataCell> rowCells = [DataCell(SizedBox(width: 50, child: Text(student.rollNo))), DataCell(Text(student.name.isEmpty ? 'Student ${student.rollNo}' : student.name))];
                  
                  if (currentSub.components.isEmpty) {
                    final fieldKey = '${student.rollNo}_${currentSub.name}';
                    rowCells.add(DataCell(Container(color: cellColor, child: MarkInputField(key: ValueKey(fieldKey), initialValue: student.termMarks[widget.termId]?[currentSub.name] ?? "", focusNode: _getFocusNode(fieldKey), onFocusLostOrSubmitted: (val) async { final verified = _validateAndCleanInput(val, currentSub.maxMarks, student.name); if (verified != null) { student.termMarks[widget.termId] ??= {}; student.termMarks[widget.termId]![currentSub.name] = verified; await DatabaseHelper.instance.saveLiveMark(termId: widget.termId, rollNo: student.rollNo, markKey: currentSub.name, value: verified); } setState((){}); }, onNext: null))));
                  } else {
                    for (var c in currentSub.components) {
                      String markKey = '${currentSub.name}_${c.name}'; final fieldKey = '${student.rollNo}_$markKey';
                      rowCells.add(DataCell(Container(color: cellColor, child: MarkInputField(key: ValueKey(fieldKey), initialValue: student.termMarks[widget.termId]?[markKey] ?? "", focusNode: _getFocusNode(fieldKey), onFocusLostOrSubmitted: (val) async { final verified = _validateAndCleanInput(val, c.maxMarks, student.name); if (verified != null) { student.termMarks[widget.termId] ??= {}; student.termMarks[widget.termId]![markKey] = verified; await DatabaseHelper.instance.saveLiveMark(termId: widget.termId, rollNo: student.rollNo, markKey: markKey, value: verified); } setState((){}); }, onNext: null))));
                    }
                  }
                  
                  // OPTION A: PROMOTE BUTTON
                  rowCells.add(DataCell(IconButton(
                    icon: Icon(isPromoted ? Icons.star : Icons.star_border, color: isPromoted ? Colors.amber : Colors.grey),
                    tooltip: 'Promote in ${currentSub.name}',
                    onPressed: () async {
                      bool newVal = !isPromoted;
                      student.termPromotions[widget.termId] ??= {}; student.termPromotions[widget.termId]![currentSub.name] = newVal;
                      await DatabaseHelper.instance.toggleSubjectPromotion(widget.termId, student.rollNo, currentSub.name, newVal);
                      setState(() {});
                    }
                  )));
                  return DataRow(color: MaterialStateProperty.all(sIdx.isEven ? Colors.grey[50] : Colors.white), cells: rowCells);
                }).toList(),
              ),
            ),
          ),
        )
      ],
    );
  }
}
