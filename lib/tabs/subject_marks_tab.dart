import 'package:flutter/material.dart';
import '../data_models.dart';
import '../mark_input_field.dart';

// ==========================================
// TAB 2: SUBJECT SHEETS (Supports Dynamic Columns)
// ==========================================
class SubjectMarksTab extends StatefulWidget {
  final List<SubjectSetup> subjects;
  final List<StudentRow> students;
  final List<StudentRow> allStudents;

  const SubjectMarksTab({super.key, required this.subjects, required this.students, required this.allStudents});

  @override
  State<SubjectMarksTab> createState() => _SubjectMarksTabState();
}

class _SubjectMarksTabState extends State<SubjectMarksTab> {
  int _selectedSubjectIndex = 0;

  // Modified validation engine to return specific errors
  String? _validateAndCleanInput(String input, double maxAllowed, String studentName, String componentName) {
    String clean = input.toUpperCase().trim();
    if (clean.isEmpty) return "";
    if (clean == "A" || clean == "AB") return clean; 
    
    if (!RegExp(r'^[0-9]+(\.[0-9]+)?$').hasMatch(clean)) {
      _showValidationError("Invalid characters entered for $studentName.");
      return null;
    }
    
    double? val = double.tryParse(clean);
    if (val == null || val > maxAllowed) {
      _showValidationError("Invalid! $studentName's score in $componentName cannot exceed ${maxAllowed.toStringAsFixed(0)}.");
      return null;
    }
    
    return clean;
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.subjects.isEmpty) return const Center(child: Text("No subjects configured."));
    
    if (_selectedSubjectIndex >= widget.subjects.length) {
      _selectedSubjectIndex = 0;
    }
    
    final currentSub = widget.subjects[_selectedSubjectIndex];

    int totalStudents = widget.allStudents.length;
    int enteredCount = widget.allStudents.where((s) => s.isSubjectAttempted(currentSub)).length;

    bool isComplete = (enteredCount == totalStudents && totalStudents > 0);
    Color headerBgColor = isComplete ? Colors.green[200]! : Colors.red[100]!;

    int passedCount = 0;
    int failedCount = 0;
    int disttCount = 0;
    double sumMarks = 0.0;
    
    for (var s in widget.students) {
      if (s.isSubjectAttempted(currentSub)) {
        double score = s.getSubjectScore(currentSub);
        sumMarks += score;
        if (score >= currentSub.passingMarks) passedCount++; else failedCount++;
        if (score >= (currentSub.maxMarks * 0.75)) disttCount++;
      }
    }
    double qi = enteredCount > 0 ? (sumMarks / enteredCount) : 0.0;

    List<DataColumn> gridColumns = [
      const DataColumn(label: Text('Roll No')), 
      const DataColumn(label: Text('Name')), 
    ];

    if (currentSub.components.isEmpty) {
      gridColumns.add(DataColumn(label: Text('Marks\n(Max: ${currentSub.maxMarks.toStringAsFixed(0)})')));
    } else {
      for (var c in currentSub.components) {
        gridColumns.add(DataColumn(label: Text('${c.name}\n(Max: ${c.maxMarks.toStringAsFixed(0)})')));
      }
    }

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(8),
          child: Row(
            children: widget.subjects.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(entry.value.name),
                  selected: entry.key == _selectedSubjectIndex,
                  selectedColor: entry.value.themeColor.withOpacity(0.4),
                  onSelected: (selected) { if (selected) setState(() => _selectedSubjectIndex = entry.key); },
                ),
              );
            }).toList(),
          ),
        ),
        
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          color: headerBgColor, 
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subject: ${currentSub.name} (Max: ${currentSub.maxMarks.toStringAsFixed(0)})', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              Text('Entered: $enteredCount / $totalStudents', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
        ),

        Container(
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey[400]!)),
          child: IntrinsicWidth(
            child: Column(
              children: [
                _buildStatRow("Passed", passedCount.toString()),
                _buildStatRow("Failed", failedCount.toString()),
                _buildStatRow("QI", qi.toStringAsFixed(2)),
                const Divider(height: 1, thickness: 1),
                _buildStatRow("DISTT", disttCount.toString(), isWhite: true),
              ],
            ),
          ),
        ),
        
        const Divider(height: 1, thickness: 2),

        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: gridColumns,
                rows: widget.students.map((student) {
                  bool isFail = student.isSubjectAttempted(currentSub) && student.getSubjectScore(currentSub) < currentSub.passingMarks;
                  Color? cellColor = isFail ? Colors.red[100] : null;

                  List<DataCell> rowCells = [
                    DataCell(Text(student.rollNo)),
                    DataCell(Text(student.name)),
                  ];

                  if (currentSub.components.isEmpty) {
                    final currentVal = student.marks[currentSub.name] ?? "";
                    rowCells.add(
                      DataCell(
                        Container(
                          color: cellColor,
                          child: MarkInputField(
                            // Adding ValueKey with value ensures field completely resets text on invalid changes
                            key: ValueKey('${student.rollNo}${currentSub.name}$currentVal'),
                            initialValue: currentVal,
                            onFocusLostOrSubmitted: (newValue) {
                              final verified = _validateAndCleanInput(newValue, currentSub.maxMarks, student.name, currentSub.name);
                              
                              // Trigger state rebuild always if invalid to strip the bad typed number from view
                              setState(() {
                                if (verified != null) {
                                  student.marks[currentSub.name] = verified;
                                }
                              });
                            },
                          ),
                        ),
                      ),
                    );
                  } else {
                    for (var c in currentSub.components) {
                      String markKey = '${currentSub.name}_${c.name}';
                      final currentVal = student.marks[markKey] ?? "";
                      rowCells.add(
                        DataCell(
                          Container(
                            color: cellColor,
                            child: MarkInputField(
                              key: ValueKey('${student.rollNo}${markKey}$currentVal'),
                              initialValue: currentVal,
                              onFocusLostOrSubmitted: (newValue) {
                                final verified = _validateAndCleanInput(newValue, c.maxMarks, student.name, c.name);
                                
                                setState(() {
                                  if (verified != null) {
                                    student.marks[markKey] = verified;
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                      );
                    }
                  }

                  return DataRow(cells: rowCells);
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, {bool isWhite = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          color: isWhite ? Colors.white : Colors.grey[200],
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Container(
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.grey[400]!))),
          child: Text(value, textAlign: TextAlign.center),
        ),
      ],
    );
  }
}
