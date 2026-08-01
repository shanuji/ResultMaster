import 'package:flutter/material.dart';
import '../models/data_models.dart';
import '../database/database_helper.dart';

class GlobalFinalResultTabWidget extends StatefulWidget {
  final int workbookId;
  final List<TermSetup> terms;
  final List<SubjectSetup> subjects;
  final List<StudentRow> students;
  const GlobalFinalResultTabWidget({super.key, required this.workbookId, required this.terms, required this.subjects, required this.students});
  @override
  State<GlobalFinalResultTabWidget> createState() => _GlobalFinalResultTabWidgetState();
}

class _GlobalFinalResultTabWidgetState extends State<GlobalFinalResultTabWidget> {
  bool _freezeRollNo = true; 
  bool _freezeName = true; 
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
  void dispose() { _horizontalScroll1.dispose(); _horizontalScroll2.dispose(); super.dispose(); }

  Color _getPastelColor(int index) {
    List<Color> bases = [Colors.blue, Colors.purple, Colors.teal, Colors.orange, Colors.pink, Colors.indigo];
    return bases[index % bases.length];
  }

  Widget _buildCell(Widget child, double width, {Color? bgColor, bool isHeader = false}) {
    return Container(
      width: width, height: 60, padding: const EdgeInsets.symmetric(horizontal: 4), alignment: Alignment.center,
      decoration: BoxDecoration(color: bgColor ?? Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade300), right: BorderSide(color: Colors.grey.shade300), top: isHeader ? BorderSide(color: Colors.grey.shade300) : BorderSide.none)),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.terms.isEmpty || widget.subjects.isEmpty) { return const Center(child: Text('Create Terms and Subjects first.', style: TextStyle(color: Colors.grey))); }

    List<StudentRow> filteredStudents = _searchQuery.isEmpty ? widget.students : widget.students.where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase()) || s.rollNo.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    List<Widget> fHeaders = []; List<Widget> sHeaders = [];
    var hRoll = _buildCell(const Text('Roll No', style: TextStyle(fontWeight: FontWeight.bold)), 60, bgColor: Colors.blue.shade50, isHeader: true);
    var hName = _buildCell(const Text('Name', style: TextStyle(fontWeight: FontWeight.bold)), 140, bgColor: Colors.blue.shade50, isHeader: true);
    if (_freezeRollNo) fHeaders.add(hRoll); else sHeaders.add(hRoll);
    if (_freezeName) fHeaders.add(hName); else sHeaders.add(hName);
    
    for (var sub in widget.subjects) {
      if (sub.components.isEmpty) {
        for (var term in widget.terms) { sHeaders.add(_buildCell(Text('${sub.name}\n${term.name}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)), 75, bgColor: Colors.blue.shade50, isHeader: true)); }
        sHeaders.add(_buildCell(Text('${sub.name}\nTotal', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)), 75, bgColor: Colors.blue.shade50, isHeader: true));
      } else {
        for (var comp in sub.components) {
          for (var term in widget.terms) { sHeaders.add(_buildCell(Text('${sub.name}\n${comp.name} ${term.name}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)), 75, bgColor: Colors.blue.shade50, isHeader: true)); }
          sHeaders.add(_buildCell(Text('${sub.name}\n${comp.name} Total', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)), 75, bgColor: Colors.blue.shade50, isHeader: true));
        }
      }
    }
    sHeaders.add(_buildCell(const Text('GRAND\nTOTAL', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)), 80, bgColor: Colors.blue.shade50, isHeader: true));
    sHeaders.add(_buildCell(const Text('OVERALL\n%', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)), 80, bgColor: Colors.blue.shade50, isHeader: true));
    sHeaders.add(_buildCell(const Text('RESULT', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)), 80, bgColor: Colors.blue.shade50, isHeader: true));
    sHeaders.add(_buildCell(const Text('PROMOTE\nOVERALL', textAlign: TextAlign.center, style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)), 80, bgColor: Colors.blue.shade50, isHeader: true));

    double globalMaxMarks = 0.0;
    for (var sub in widget.subjects) { globalMaxMarks += (sub.maxMarks * widget.terms.length); }

    List<Widget> fBody = []; List<Widget> sBody = [];

    for (int i = 0; i < filteredStudents.length; i++) {
      var student = filteredStudents[i];
      Color rowColor = i.isEven ? Colors.grey.shade200 : Colors.white; 
      
      var cellRoll = _buildCell(Container(width: 32, height: 32, decoration: const BoxDecoration(color: Color(0xFFE0F2F1), shape: BoxShape.circle), alignment: Alignment.center, child: Text(student.rollNo, style: const TextStyle(color: Color(0xFF00695C), fontWeight: FontWeight.bold))), 60, bgColor: rowColor); 
      var cellName = _buildCell(Text(student.name.isEmpty ? 'Student ${student.rollNo}' : student.name, softWrap: true, maxLines: 2, overflow: TextOverflow.ellipsis), 140, bgColor: rowColor);
      List<Widget> fCells = []; List<Widget> sCells = [];

      if (_freezeRollNo) fCells.add(cellRoll); else sCells.add(cellRoll);
      if (_freezeName) fCells.add(cellName); else sCells.add(cellName);
      
      double studentGrandTotal = 0.0;
      bool naturallyFailed = false;

      for (int subIdx = 0; subIdx < widget.subjects.length; subIdx++) {
        var sub = widget.subjects[subIdx];
        Color subColor = _getPastelColor(subIdx);
        Color cellBg = subColor.withOpacity(0.05); 
        Color totalBg = subColor.withOpacity(0.20);

        if (sub.components.isEmpty) {
          double subjectTotal = 0.0;
          for (var term in widget.terms) {
            double s = student.getSubjectScore(term.id, sub); subjectTotal += s;
            sCells.add(_buildCell(Text(student.termMarks[term.id]?[sub.name] ?? "-"), 75, bgColor: cellBg));
            if (sub.includeInPassFail) { bool passedNormally = s >= sub.passingMarks; if (!passedNormally && student.isSubjectAttempted(term.id, sub)) naturallyFailed = true; }
          }
          studentGrandTotal += subjectTotal;
          sCells.add(_buildCell(Text(subjectTotal.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)), 75, bgColor: totalBg));
        } else {
          for (var comp in sub.components) {
            double compTotal = 0.0;
            for (var term in widget.terms) {
              String markKey = '${sub.name}_${comp.name}';
              double s = double.tryParse(student.termMarks[term.id]?[markKey] ?? "") ?? 0.0; compTotal += s;
              sCells.add(_buildCell(Text(student.termMarks[term.id]?[markKey] ?? "-"), 75, bgColor: cellBg));
            }
            studentGrandTotal += compTotal;
            sCells.add(_buildCell(Text(compTotal.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)), 75, bgColor: totalBg));
          }
          for (var term in widget.terms) { if (sub.includeInPassFail && student.isSubjectAttempted(term.id, sub)) { for (var c in sub.components) { if (c.passingMarks > 0 && (double.tryParse(student.termMarks[term.id]?['${sub.name}_${c.name}'] ?? "") ?? 0.0) < c.passingMarks) naturallyFailed = true; } } }
        }
      }

      double pct = globalMaxMarks > 0 ? (studentGrandTotal / globalMaxMarks) * 100 : 0.0;
      sCells.add(_buildCell(Text(studentGrandTotal.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)), 80, bgColor: rowColor));
      sCells.add(_buildCell(Text('${pct.toStringAsFixed(2)}%'), 80, bgColor: rowColor));
      
      bool hasAnySubjectPromotion = false;
      for (var t in widget.terms) { if (student.termPromotions[t.id]?.values.contains(true) == true) hasAnySubjectPromotion = true; }
      bool isPromoted = student.isPromotedOverall || hasAnySubjectPromotion;
      String statusText = isPromoted ? 'PROMOTED' : (naturallyFailed ? 'FAIL' : 'PASS');
      Color statusColor = isPromoted ? Colors.orange : (naturallyFailed ? Colors.red : Colors.green);

      sCells.add(_buildCell(Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)), 80, bgColor: rowColor));
      
      if (!naturallyFailed) {
         sCells.add(_buildCell(const Icon(Icons.check_circle, color: Colors.green, size: 20), 80, bgColor: rowColor));
      } else {
         sCells.add(_buildCell(Switch(value: student.isPromotedOverall, activeColor: Colors.blue, onChanged: (val) async { await DatabaseHelper.instance.updateStudentOverallPromotion(widget.workbookId, student.rollNo, val); setState(() { student.isPromotedOverall = val; }); }), 80, bgColor: rowColor));
      }

      if (fCells.isNotEmpty) fBody.add(Row(children: fCells));
      sBody.add(Row(children: sCells));
    }

    return Column(
      children: [
        Container(
          color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(flex: 1, child: SizedBox(height: 40, child: TextField(decoration: InputDecoration(hintText: 'Search...', prefixIcon: const Icon(Icons.search, size: 18), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20))), onChanged: (val) => setState(() => _searchQuery = val)))),
              const Spacer(),
              const Icon(Icons.push_pin, size: 16, color: Colors.blue), const SizedBox(width: 6), const Text("Freeze:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
              const SizedBox(width: 8), const Text("Roll", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Switch(value: _freezeRollNo, activeColor: Colors.blue, onChanged: (val) => setState(() => _freezeRollNo = val)),
              const SizedBox(width: 8), const Text("Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Switch(value: _freezeName, activeColor: Colors.blue, onChanged: (val) => setState(() => _freezeName = val)),
            ],
          ),
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
