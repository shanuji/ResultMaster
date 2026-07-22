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
  List<String> _inputKeysOrder = []; // Used to track exact order of fields for Enter key navigation

  @override
  void dispose() { for (var node in _focusNodes.values) { node.dispose(); } super.dispose(); }
  FocusNode _getFocusNode(String key) => _focusNodes.putIfAbsent(key, () => FocusNode());

  String? _validateAndCleanInput(String input, double maxAllowed) {
    String clean = input.toUpperCase().trim(); 
    if (clean == '999') return 'AB'; 
    if (clean.isEmpty || clean == "A" || clean == "AB") return clean;
    double? val = double.tryParse(clean); 
    if (val == null || val > maxAllowed) return null; 
    return clean;
  }

  void _showValidationError(double maxAllowed) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Error: Marks cannot exceed the maximum limit of $maxAllowed', style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.subjects.isEmpty) return const Center(child: Text("Go to the Setup tab to add subjects first."));
    if (_selectedSubjectIndex >= widget.subjects.length) _selectedSubjectIndex = 0;
    final currentSub = widget.subjects[_selectedSubjectIndex];
    
    _inputKeysOrder.clear(); // Reset order for the current view

    List<DataColumn> gridColumns = [const DataColumn(label: Text('Roll No')), const DataColumn(label: Text('Name'))];
    if (currentSub.components.isEmpty) { gridColumns.add(DataColumn(label: Text('Marks\n(Max: ${currentSub.maxMarks.toStringAsFixed(0)})'))); } 
    else { for (var c in currentSub.components) { gridColumns.add(DataColumn(label: Text('${c.name}\n(Max: ${c.maxMarks.toStringAsFixed(0)})'))); } }
    gridColumns.add(const DataColumn(label: Text('Promote')));

    return Column(
      children: [
        SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.all(8), child: Row(children: widget.subjects.asMap().entries.map((entry) => Padding(padding: const EdgeInsets.only(right: 8.0), child: ChoiceChip(label: Text(entry.value.name.isEmpty ? 'Unnamed' : entry.value.name), selected: entry.key == _selectedSubjectIndex, selectedColor: entry.value.themeColor.withOpacity(0.4), onSelected: (selected) { if (selected) setState(() => _selectedSubjectIndex = entry.key); }))).toList())),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical, child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, child: DataTable(
                columnSpacing: 20, // Reduced spacing for tighter fit
                columns: gridColumns,
                rows: widget.students.asMap().entries.map((entry) {
                  int sIdx = entry.key; var student = entry.value;
                  bool isPromoted = student.termPromotions[widget.termId]?[currentSub.name] == true;
                  bool isFail = currentSub.includeInPassFail && student.isSubjectAttempted(widget.termId, currentSub) && !student.isSubjectPassed(widget.termId, currentSub);
                  Color? cellColor = isPromoted ? Colors.blue[50] : (isFail ? Colors.red[100] : (sIdx.isEven ? Colors.grey[100] : Colors.white));
                  
                  // Auto-fit text without SizedBox constraint
                  List<DataCell> rowCells = [DataCell(Text(student.rollNo)), DataCell(Text(student.name.isEmpty ? 'Student ${student.rollNo}' : student.name))];
                  
                  if (currentSub.components.isEmpty) {
                    final fieldKey = '${student.rollNo}_${currentSub.name}';
                    _inputKeysOrder.add(fieldKey);
                    rowCells.add(DataCell(Container(color: cellColor, child: MarkInputField(key: ValueKey(fieldKey), initialValue: student.termMarks[widget.termId]?[currentSub.name] ?? "", focusNode: _getFocusNode(fieldKey), 
                      onFocusLostOrSubmitted: (val) async { 
                        final verified = _validateAndCleanInput(val, currentSub.maxMarks); 
                        if (verified != null) { student.termMarks[widget.termId] ??= {}; student.termMarks[widget.termId]![currentSub.name] = verified; await DatabaseHelper.instance.saveLiveMark(termId: widget.termId, rollNo: student.rollNo, markKey: currentSub.name, value: verified); setState((){}); }
                        else { _showValidationError(currentSub.maxMarks); _getFocusNode(fieldKey).requestFocus(); }
                      }, 
                      onNext: () { int idx = _inputKeysOrder.indexOf(fieldKey); if (idx != -1 && idx + 1 < _inputKeysOrder.length) FocusScope.of(context).requestFocus(_getFocusNode(_inputKeysOrder[idx + 1])); }))));
                  } else {
                    for (var c in currentSub.components) {
                      String markKey = '${currentSub.name}_${c.name}'; final fieldKey = '${student.rollNo}_$markKey';
                      _inputKeysOrder.add(fieldKey);
                      rowCells.add(DataCell(Container(color: cellColor, child: MarkInputField(key: ValueKey(fieldKey), initialValue: student.termMarks[widget.termId]?[markKey] ?? "", focusNode: _getFocusNode(fieldKey), 
                        onFocusLostOrSubmitted: (val) async { 
                          final verified = _validateAndCleanInput(val, c.maxMarks); 
                          if (verified != null) { student.termMarks[widget.termId] ??= {}; student.termMarks[widget.termId]![markKey] = verified; await DatabaseHelper.instance.saveLiveMark(termId: widget.termId, rollNo: student.rollNo, markKey: markKey, value: verified); setState((){}); }
                          else { _showValidationError(c.maxMarks); _getFocusNode(fieldKey).requestFocus(); }
                        }, 
                        onNext: () { int idx = _inputKeysOrder.indexOf(fieldKey); if (idx != -1 && idx + 1 < _inputKeysOrder.length) FocusScope.of(context).requestFocus(_getFocusNode(_inputKeysOrder[idx + 1])); }))));
                    }
                  }
                  
                  rowCells.add(DataCell(IconButton(icon: Icon(isPromoted ? Icons.star : Icons.star_border, color: isPromoted ? Colors.amber : Colors.grey), onPressed: () async { bool newVal = !isPromoted; student.termPromotions[widget.termId] ??= {}; student.termPromotions[widget.termId]![currentSub.name] = newVal; await DatabaseHelper.instance.toggleSubjectPromotion(widget.termId, student.rollNo, currentSub.name, newVal); setState(() {}); })));
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
