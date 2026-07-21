import 'package:flutter/material.dart';
import '../models/data_models.dart';
import '../database/database_helper.dart';
import '../utils/ux_helpers.dart';

class SubjectMarksTabWidget extends StatefulWidget {
  final int workbookId;
  final List<SubjectSetup> subjects;
  final List<StudentRow> students;
  final List<StudentRow> allStudents;
  const SubjectMarksTabWidget({super.key, required this.workbookId, required this.subjects, required this.students, required this.allStudents});
  @override
  State<SubjectMarksTabWidget> createState() => _SubjectMarksTabWidgetState();
}

class _SubjectMarksTabWidgetState extends State<SubjectMarksTabWidget> {
  int _selectedSubjectIndex = 0;
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void dispose() { 
    for (var node in _focusNodes.values) { node.dispose(); } 
    super.dispose(); 
  }

  FocusNode _getFocusNode(String key) => _focusNodes.putIfAbsent(key, () => FocusNode());
  
  String? _validateAndCleanInput(String input, double maxAllowed, String studentName, String componentName, {bool showSnack = true}) {
    String clean = input.toUpperCase().trim(); 
    if (clean == '999') return 'AB'; 
    if (clean.isEmpty) return ""; 
    if (clean == "A" || clean == "AB") return clean;
    if (!RegExp(r'^[0-9]+(\.[0-9]+)?$').hasMatch(clean)) { if (showSnack) _showValidationError("Invalid characters for $studentName."); return null; }
    double? val = double.tryParse(clean);
    if (val == null || val > maxAllowed) { if (showSnack) _showValidationError("Invalid! $studentName cannot exceed ${maxAllowed.toStringAsFixed(0)}."); return null; }
    return clean;
  }

  void _showValidationError(String message) { 
    ScaffoldMessenger.of(context).clearSnackBars(); 
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.redAccent, duration: const Duration(seconds: 3), behavior: SnackBarBehavior.floating)); 
  }

  @override
  Widget build(BuildContext context) {
    if (widget.subjects.isEmpty) return const Center(child: Text("No subjects configured."));
    if (_selectedSubjectIndex >= widget.subjects.length) _selectedSubjectIndex = 0;
    final currentSub = widget.subjects[_selectedSubjectIndex];
    int totalStudents = widget.allStudents.length; 
    int enteredCount = widget.allStudents.where((s) => s.isSubjectAttempted(currentSub)).length;
    bool isComplete = (enteredCount == totalStudents && totalStudents > 0);
    int passedCount = 0; int failedCount = 0; int disttCount = 0; double sumMarks = 0.0;
    
    for (var s in widget.students) {
      if (s.isSubjectAttempted(currentSub)) {
        double score = s.getSubjectScore(currentSub); sumMarks += score;
        if (s.isSubjectPassed(currentSub)) passedCount++; else failedCount++;
        if (score >= (currentSub.maxMarks * 0.75)) disttCount++;
      }
    }
    double qi = enteredCount > 0 ? (sumMarks / enteredCount) : 0.0;
    List<DataColumn> gridColumns = [const DataColumn(label: Text('Roll No')), const DataColumn(label: Text('Name'))];
    if (currentSub.components.isEmpty) { gridColumns.add(DataColumn(label: Text('Marks\n(Max: ${currentSub.maxMarks.toStringAsFixed(0)})'))); } 
    else { for (var c in currentSub.components) { gridColumns.add(DataColumn(label: Text('${c.name.isEmpty ? "Part" : c.name}\n(Max: ${c.maxMarks.toStringAsFixed(0)})'))); } }

    return Column(
      children: [
        SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.all(8), child: Row(children: widget.subjects.asMap().entries.map((entry) => Padding(padding: const EdgeInsets.only(right: 8.0), child: ChoiceChip(label: Text(entry.value.name.isEmpty ? 'Unnamed' : entry.value.name), selected: entry.key == _selectedSubjectIndex, selectedColor: entry.value.themeColor.withOpacity(0.4), onSelected: (selected) { if (selected) setState(() => _selectedSubjectIndex = entry.key); }))).toList())),
        Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), color: isComplete ? Colors.green[200]! : Colors.red[100]!, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Subject: ${currentSub.name.isEmpty ? "Unnamed" : currentSub.name} (Max: ${currentSub.maxMarks.toStringAsFixed(0)})', style: const TextStyle(fontWeight: FontWeight.bold)), Text('Entered: $enteredCount / $totalStudents', style: const TextStyle(fontWeight: FontWeight.bold))])),
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16), color: Colors.yellow[50], child: const Text('( 💡 Tip: Enter 999 to mark a student as Absent )', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black87))),
        Container(margin: const EdgeInsets.all(8.0), decoration: BoxDecoration(border: Border.all(color: Colors.grey[400]!)), child: IntrinsicWidth(child: Column(children: [_buildStatRow("Passed", passedCount.toString()), _buildStatRow("Failed", failedCount.toString()), _buildStatRow("QI", qi.toStringAsFixed(2)), const Divider(height: 1, thickness: 1), _buildStatRow("DISTT", disttCount.toString(), isWhite: true)]))),
        const Divider(height: 1, thickness: 2),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical, child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: gridColumns,
                rows: widget.students.asMap().entries.map((entry) {
                  int sIdx = entry.key; var student = entry.value;
                  String displayName = student.name.isEmpty ? 'Student ${student.rollNo}' : student.name;
                  List<DataCell> rowCells = [DataCell(SizedBox(width: 50, child: Text(student.rollNo))), DataCell(Text(displayName))];
                  
                  if (currentSub.components.isEmpty) {
                    final fieldKey = '${student.rollNo}_${currentSub.name}';
                    bool isFail = currentSub.includeInPassFail && student.isSubjectAttempted(currentSub) && !student.isSubjectPassed(currentSub);
                    Color? cellColor = isFail ? Colors.red[100] : (sIdx.isEven ? Colors.grey[100] : Colors.white);
                    
                    rowCells.add(DataCell(Container(color: cellColor, child: MarkInputField(
                      key: ValueKey(fieldKey), initialValue: student.marks[currentSub.name] ?? "", focusNode: _getFocusNode(fieldKey), 
                      onFocusLostOrSubmitted: (newValue) async { final verified = _validateAndCleanInput(newValue, currentSub.maxMarks, displayName, currentSub.name); if (verified != null) { student.marks[currentSub.name] = verified; await DatabaseHelper.instance.saveLiveMark(workbookId: widget.workbookId, rollNo: student.rollNo, markKey: currentSub.name, value: verified); } setState((){}); }, 
                      onNext: sIdx < widget.students.length - 1 ? () => _getFocusNode('${widget.students[sIdx + 1].rollNo}_${currentSub.name}').requestFocus() : null
                    ))));
                  } else {
                    for (var c in currentSub.components) {
                      String markKey = '${currentSub.name}_${c.name}'; final fieldKey = '${student.rollNo}_$markKey';
                      bool isFail = false;
                      if (currentSub.includeInPassFail) {
                        if (currentSub.requirePassPerComponent) {
                          double cScore = double.tryParse(student.marks[markKey] ?? "") ?? 0.0;
                          if (student.marks[markKey]?.isNotEmpty == true && cScore < c.passingMarks) isFail = true;
                        } else {
                          isFail = student.isSubjectAttempted(currentSub) && !student.isSubjectPassed(currentSub);
                        }
                      }
                      Color? cellColor = isFail ? Colors.red[100] : (sIdx.isEven ? Colors.grey[100] : Colors.white);
                      
                      rowCells.add(DataCell(Container(color: cellColor, child: MarkInputField(
                        key: ValueKey(fieldKey), initialValue: student.marks[markKey] ?? "", focusNode: _getFocusNode(fieldKey), 
                        onFocusLostOrSubmitted: (newValue) async { final verified = _validateAndCleanInput(newValue, c.maxMarks, displayName, c.name); if (verified != null) { student.marks[markKey] = verified; await DatabaseHelper.instance.saveLiveMark(workbookId: widget.workbookId, rollNo: student.rollNo, markKey: markKey, value: verified); } setState((){}); }, 
                        onNext: sIdx < widget.students.length - 1 ? () => _getFocusNode('${widget.students[sIdx + 1].rollNo}_$markKey').requestFocus() : null
                      ))));
                    }
                  }
                  return DataRow(color: MaterialStateProperty.all(sIdx.isEven ? Colors.grey[100] : Colors.white), cells: rowCells);
                }).toList(),
              ),
            ),
          ),
        )
      ],
    );
  }
  Widget _buildStatRow(String label, String value, {bool isWhite = false}) => Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 80, padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), color: isWhite ? Colors.white : Colors.grey[200], child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))), Container(width: 60, padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.grey[400]!))), child: Text(value, textAlign: TextAlign.center))]);
}

