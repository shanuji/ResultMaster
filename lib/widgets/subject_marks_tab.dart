import 'package:flutter/material.dart';
import '../data_models.dart';
import '../mark_input_field.dart';

// ==========================================
// TAB 2: SUBJECT SHEETS (Premium Custom Table UI)
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
      _showValidationError("Invalid! $studentName's score cannot exceed ${maxAllowed.toStringAsFixed(0)}.");
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

    // Dynamically calculate table column widths based on components
    Map<int, TableColumnWidth> tableColumnWidths = {
      0: const FlexColumnWidth(1.2), // Roll No
      1: const FlexColumnWidth(3.8), // Name
    };
    int colIndex = 2;
    int markCols = currentSub.components.isEmpty ? 1 : currentSub.components.length;
    for(int i = 0; i < markCols; i++) {
       tableColumnWidths[colIndex++] = const FlexColumnWidth(2.8); // Marks fields
    }
    tableColumnWidths[colIndex] = const FlexColumnWidth(1.2); // Promo Column

    // Dynamically build header cells
    List<Widget> headerCells = [
      _buildTableHeader('Roll No'),
      _buildTableHeader('Name'),
    ];
    if (currentSub.components.isEmpty) {
      headerCells.add(_buildTableHeader('Marks (Max: ${currentSub.maxMarks.toStringAsFixed(0)})'));
    } else {
      for (var c in currentSub.components) {
        headerCells.add(_buildTableHeader('${c.name} (Max: ${c.maxMarks.toStringAsFixed(0)})'));
      }
    }
    headerCells.add(_buildTableHeader('Promo'));

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // 1. HORIZONTAL SUBJECT SELECTOR
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: widget.subjects.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(entry.value.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  selected: entry.key == _selectedSubjectIndex,
                  selectedColor: entry.value.themeColor.withOpacity(0.3),
                  onSelected: (selected) { if (selected) setState(() => _selectedSubjectIndex = entry.key); },
                ),
              );
            }).toList(),
          ),
        ),

        // 2. PREMIUM STATS CARD
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Card Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bookmark, color: Colors.teal.shade700),
                        const SizedBox(width: 8),
                        Text('${currentSub.name}  (Max: ${currentSub.maxMarks.toStringAsFixed(0)})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Entered: $enteredCount / $totalStudents',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 4 Metric Pill Boxes
                Row(
                  children: [
                    Expanded(child: _buildStatCard(Icons.check, Colors.green, passedCount.toString(), 'Promoted')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatCard(Icons.close, Colors.red, failedCount.toString(), 'Not Promoted')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatCard(Icons.bar_chart, Colors.blue, 'QI ${qi.toStringAsFixed(2)}', 'Quality Index')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatCard(Icons.pie_chart, Colors.purple, 'Distt $disttCount', 'Division')),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 3. CUSTOM RESPONSIVE TABLE
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Table(
              columnWidths: tableColumnWidths,
              border: TableBorder.symmetric(inside: BorderSide(color: Colors.grey.shade200)),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                // Table Header Row
                TableRow(
                  decoration: BoxDecoration(color: Colors.teal.shade50),
                  children: headerCells,
                ),
                // Data Rows
                ...widget.students.map((student) {
                  bool isAttempted = student.isSubjectAttempted(currentSub);
                  bool isPass = isAttempted && student.getSubjectScore(currentSub) >= currentSub.passingMarks;

                  List<Widget> rowCells = [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(student.rollNo, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600, fontSize: 16)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                      child: Text(student.name, style: const TextStyle(fontSize: 14)),
                    ),
                  ];

                  // Add Marks Inputs dynamically based on components
                  if (currentSub.components.isEmpty) {
                    final currentVal = student.marks[currentSub.name] ?? "";
                    rowCells.add(_buildInputCell(student, currentSub.name, currentVal, currentSub.maxMarks, currentSub.name));
                  } else {
                    for (var c in currentSub.components) {
                      String markKey = '${currentSub.name}_${c.name}';
                      final currentVal = student.marks[markKey] ?? "";
                      rowCells.add(_buildInputCell(student, markKey, currentVal, c.maxMarks, c.name));
                    }
                  }

                  // Promo Status Icon
                  rowCells.add(
                    Icon(
                      isAttempted ? (isPass ? Icons.check_circle : Icons.star_border) : Icons.circle_outlined,
                      color: isAttempted ? (isPass ? Colors.green : Colors.grey) : Colors.grey.shade300,
                      size: 28,
                    ),
                  );

                  return TableRow(children: rowCells);
                }).toList(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 80), // Padding to prevent FAB overlap
      ],
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 4.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
      ),
    );
  }

  Widget _buildInputCell(StudentRow student, String markKey, String currentVal, double maxMarks, String compName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: MarkInputField(
        key: ValueKey('${student.rollNo}$markKey$currentVal'),
        initialValue: currentVal,
        onFocusLostOrSubmitted: (newValue) {
          final verified = _validateAndCleanInput(newValue, maxMarks, student.name, compName);
          setState(() {
            if (verified != null) {
              student.marks[markKey] = verified;
            }
          });
        },
      ),
    );
  }

  Widget _buildStatCard(IconData icon, MaterialColor color, String value, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color.shade600),
              const SizedBox(width: 4),
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade700), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
