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
  
  final ScrollController _horizontalScroll1 = ScrollController();
  final ScrollController _horizontalScroll2 = ScrollController();

  @override
  void initState() {
    super.initState();
    _horizontalScroll1.addListener(() { if (_horizontalScroll2.hasClients && _horizontalScroll2.offset != _horizontalScroll1.offset) { _horizontalScroll2.jumpTo(_horizontalScroll1.offset); } });
    _horizontalScroll2.addListener(() { if (_horizontalScroll1.hasClients && _horizontalScroll1.offset != _horizontalScroll2.offset) { _horizontalScroll1.jumpTo(_horizontalScroll2.offset); } });
  }

  @override
  void dispose() { 
    for (var node in _focusNodes.values) { node.dispose(); } 
    _horizontalScroll1.dispose(); _horizontalScroll2.dispose();
    super.dispose(); 
  }
  
  FocusNode _getFocusNode(String key) => _focusNodes.putIfAbsent(key, () => FocusNode());

  String? _validateAndCleanInput(String input, double maxAllowed) {
    String clean = input.toUpperCase().trim(); if (clean == '999') return 'AB'; if (clean.isEmpty || clean == "A" || clean == "AB") return clean;
    double? val = double.tryParse(clean); if (val == null || val > maxAllowed) return null; return clean;
  }

  void _showValidationError(double maxAllowed) { ScaffoldMessenger.of(context).clearSnackBars(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: Marks cannot exceed $maxAllowed', style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.red)); }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.3))),
        child: Column(children: [ 
          Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 14)), 
          const SizedBox(height: 4), 
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontWeight: FontWeight.bold), textAlign: TextAlign.center), 
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), 
        ]),
      ),
    );
  }

  Widget _buildCell(Widget child, double width, {Color? bgColor, bool isHeader = false}) {
    return Container(
      width: width, height: 60, padding: const EdgeInsets.symmetric(horizontal: 6), alignment: Alignment.center,
      decoration: BoxDecoration(color: bgColor ?? Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade300), right: BorderSide(color: Colors.grey.shade300), top: isHeader ? BorderSide(color: Colors.grey.shade300) : BorderSide.none)),
      child: child,
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
    bool allEntered = enteredCount == totalStudents && totalStudents > 0;

    List<Widget> rightHeaders = [];
    if (currentSub.components.isEmpty) { rightHeaders.add(_buildCell(Text('Marks\n(Max: ${currentSub.maxMarks.toStringAsFixed(0)})', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)), 80, bgColor: const Color(0xFFE0F2F1), isHeader: true)); } 
    else { for (var c in currentSub.components) { rightHeaders.add(_buildCell(Text('${c.name}\n(Max: ${c.maxMarks.toStringAsFixed(0)})', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)), 80, bgColor: const Color(0xFFE0F2F1), isHeader: true)); } }
    rightHeaders.add(_buildCell(const Text('Promote', style: TextStyle(fontWeight: FontWeight.bold)), 80, bgColor: const Color(0xFFE0F2F1), isHeader: true));

    List<Widget> leftBodyRows = []; List<Widget> rightBodyRows = [];
    for (int i = 0; i < filteredStudents.length; i++) {
      var student = filteredStudents[i]; Color rowColor = i.isEven ? Colors.white : Colors.grey.shade50;
      bool isPromoted = student.termPromotions[widget.termId]?[currentSub.name] == true;
      bool naturallyPassed = true;
      if (currentSub.includeInPassFail && student.isSubjectAttempted(widget.termId, currentSub)) {
        if (currentSub.components.isEmpty) { naturallyPassed = student.getSubjectScore(widget.termId, currentSub) >= currentSub.passingMarks; } 
        else { for (var c in currentSub.components) { if (c.passingMarks > 0 && (double.tryParse(student.termMarks[widget.termId]?['${currentSub.name}_${c.name}'] ?? "") ?? 0.0) < c.passingMarks) { naturallyPassed = false; } } }
      }

      leftBodyRows.add(Row(children: [
        _buildCell(Text(student.rollNo, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), 60, bgColor: rowColor),
        _buildCell(Text(student.name.isEmpty ? 'Student ${student.rollNo}' : student.name, maxLines: 2, overflow: TextOverflow.ellipsis, softWrap: true), 140, bgColor: rowColor),
      ]));

      List<Widget> rRow = [];
      Widget buildInput(String fieldKey, double max) {
        return Container(width: 75, height: 35, decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 4), child: Center(child: MarkInputField(key: ValueKey(fieldKey), initialValue: student.termMarks[widget.termId]?[fieldKey.split('_').last] ?? "", focusNode: _getFocusNode(fieldKey), onFocusLostOrSubmitted: (val) async { final verified = _validateAndCleanInput(val, max); if (verified != null) { student.termMarks[widget.termId] ??= {}; student.termMarks[widget.termId]![fieldKey.split('_').last] = verified; await DatabaseHelper.instance.saveLiveMark(termId: widget.termId, rollNo: student.rollNo, markKey: fieldKey.split('_').last, value: verified); setState((){}); } else { _showValidationError(max); _getFocusNode(fieldKey).requestFocus(); } }, onNext: () { int idx = _inputKeysOrder.indexOf(fieldKey); if (idx != -1 && idx + 1 < _inputKeysOrder.length) FocusScope.of(context).requestFocus(_getFocusNode(_inputKeysOrder[idx + 1])); })));
      }

      if (currentSub.components.isEmpty) { final fieldKey = '${student.rollNo}_${currentSub.name}'; _inputKeysOrder.add(fieldKey); rRow.add(_buildCell(buildInput(fieldKey, currentSub.maxMarks), 80, bgColor: rowColor)); } 
      else { for (var c in currentSub.components) { String markKey = '${currentSub.name}_${c.name}'; final fieldKey = '${student.rollNo}_$markKey'; _inputKeysOrder.add(fieldKey); rRow.add(_buildCell(buildInput(fieldKey, c.maxMarks), 80, bgColor: rowColor)); } }

      if (!currentSub.includeInPassFail || !student.isSubjectAttempted(widget.termId, currentSub)) { rRow.add(_buildCell(const Text("-"), 80, bgColor: rowColor)); } 
      else if (naturallyPassed) { rRow.add(_buildCell(const Icon(Icons.check_circle, color: Colors.green, size: 20), 80, bgColor: rowColor)); } 
      else { rRow.add(_buildCell(IconButton(icon: Icon(isPromoted ? Icons.star : Icons.star_border, color: isPromoted ? Colors.amber : Colors.grey), onPressed: () async { bool newVal = !isPromoted; student.termPromotions[widget.termId] ??= {}; student.termPromotions[widget.termId]![currentSub.name] = newVal; await DatabaseHelper.instance.toggleSubjectPromotion(widget.termId, student.rollNo, currentSub.name, newVal); setState(() {}); }), 80, bgColor: rowColor)); }
      rightBodyRows.add(Row(children: rRow));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12.0, left: 12.0, right: 12.0),
          child: Wrap(
            spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
            children: widget.subjects.asMap().entries.map((entry) => ChoiceChip(
              label: Text(entry.value.name.isEmpty ? 'Unnamed' : entry.value.name, style: TextStyle(color: entry.key == _selectedSubjectIndex ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)), 
              selected: entry.key == _selectedSubjectIndex, selectedColor: const Color(0xFF00897B), backgroundColor: Colors.white, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: entry.key == _selectedSubjectIndex ? const Color(0xFF00897B) : Colors.grey.shade300)), 
              onSelected: (selected) { if (selected) setState(() => _selectedSubjectIndex = entry.key); }
            )).toList()
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [const Icon(Icons.book, color: Color(0xFF00897B), size: 20), const SizedBox(width: 8), Text('Subject: ${currentSub.name} (Max: ${currentSub.maxMarks.toStringAsFixed(0)})', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))]), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: allEntered ? Colors.green : Colors.red.shade50, borderRadius: BorderRadius.circular(12)), child: Text('Entered: $enteredCount / $totalStudents', style: TextStyle(fontWeight: FontWeight.bold, color: allEntered ? Colors.white : Colors.red, fontSize: 12)))]),
          ),
        ),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Row(children: [_buildStatCard("Passed", passedCount.toString(), Icons.check, Colors.green), _buildStatCard("Failed", failedCount.toString(), Icons.close, Colors.redAccent), _buildStatCard("QI", qi.toStringAsFixed(2), Icons.bar_chart, Colors.blue), _buildStatCard("Distt", disttCount.toString(), Icons.pie_chart, Colors.purple)])),
        Padding(
          padding: const EdgeInsets.all(12.0), 
          child: Row(
            children: [
              Expanded(child: SizedBox(height: 40, child: TextField(decoration: InputDecoration(hintText: 'Search Student...', prefixIcon: const Icon(Icons.search, size: 18), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20))), onChanged: (val) => setState(() => _searchQuery = val)))),
              const SizedBox(width: 8),
              ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade50, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12)), onPressed: () { FocusScope.of(context).unfocus(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marks Saved!'), backgroundColor: Colors.green)); }, icon: const Icon(Icons.save, size: 16, color: Colors.blue), label: const Text('Save', style: TextStyle(color: Colors.blue))),
            ],
          )
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)), clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Row(children: [
                  Row(children: [_buildCell(const Text('Roll No', style: TextStyle(fontWeight: FontWeight.bold)), 60, bgColor: const Color(0xFFE0F2F1), isHeader: true), _buildCell(const Text('Name', style: TextStyle(fontWeight: FontWeight.bold)), 140, bgColor: const Color(0xFFE0F2F1), isHeader: true)]),
                  Expanded(child: SingleChildScrollView(controller: _horizontalScroll1, scrollDirection: Axis.horizontal, child: Row(children: rightHeaders))),
                ]),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(children: leftBodyRows),
                        Expanded(child: SingleChildScrollView(controller: _horizontalScroll2, scrollDirection: Axis.horizontal, child: Column(children: rightBodyRows))),
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
