import 'package:flutter/material.dart';
import '../models/data_models.dart';

class SummarySheetTabWidget extends StatefulWidget {
  final int termId;
  final List<SubjectSetup> subjects; 
  final List<StudentRow> students;
  const SummarySheetTabWidget({super.key, required this.termId, required this.subjects, required this.students});

  @override
  State<SummarySheetTabWidget> createState() => _SummarySheetTabWidgetState();
}

class _SummarySheetTabWidgetState extends State<SummarySheetTabWidget> {
  final ScrollController _horizontalScroll1 = ScrollController();
  final ScrollController _horizontalScroll2 = ScrollController();
  final ScrollController _verticalScroll = ScrollController();

  bool _isStatsExpanded = true;
  bool _isTopVisible = true;

  @override
  void initState() {
    super.initState();
    _horizontalScroll1.addListener(() { if (_horizontalScroll2.hasClients && _horizontalScroll2.offset != _horizontalScroll1.offset) { _horizontalScroll2.jumpTo(_horizontalScroll1.offset); } });
    _horizontalScroll2.addListener(() { if (_horizontalScroll1.hasClients && _horizontalScroll1.offset != _horizontalScroll2.offset) { _horizontalScroll1.jumpTo(_horizontalScroll2.offset); } });
    
    _verticalScroll.addListener(() {
      if (_verticalScroll.offset > 20 && _isTopVisible) { setState(() => _isTopVisible = false); } 
      else if (_verticalScroll.offset <= 20 && !_isTopVisible) { setState(() => _isTopVisible = true); }
    });
  }

  @override
  void dispose() { _horizontalScroll1.dispose(); _horizontalScroll2.dispose(); _verticalScroll.dispose(); super.dispose(); }

  Widget _buildExpandedStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
        child: Column(
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 20)),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedStatPill(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(title.isNotEmpty ? "$title $value" : value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        )
      ),
    );
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
    int grandAppeared = 0; int grandPassed = 0; int grandDistinction = 0;
    double totalPassPctSum = 0.0; double totalQiSum = 0.0; int subjectsAttemptedCount = 0;
    Map<String, int> grandBrackets = {'0-20': 0, '21-32.9': 0, '33-40': 0, '41-50': 0, '51-59.9': 0, '60': 0, '61-70': 0, '71-74.9': 0, '75-80': 0, '81-90': 0, '90': 0, '91-94.9': 0, '95-100': 0};
    
    List<Widget> leftBody = []; List<Widget> rightBody = [];

    for (int index = 0; index < widget.subjects.length; index++) {
      var sub = widget.subjects[index]; Color rowColor = index.isEven ? Colors.white : Colors.grey.shade50;
      int appeared = 0; int passed = 0; int distinction = 0; double sumMarks = 0.0; 
      Map<String, int> distribution = {'0-20': 0, '21-32.9': 0, '33-40': 0, '41-50': 0, '51-59.9': 0, '60': 0, '61-70': 0, '71-74.9': 0, '75-80': 0, '81-90': 0, '90': 0, '91-94.9': 0, '95-100': 0};
      
      for (var row in widget.students) {
        if (!row.isSubjectAttempted(widget.termId, sub)) continue;
        double score = row.getSubjectScore(widget.termId, sub); appeared++; sumMarks += score;
        if (row.isSubjectPassed(widget.termId, sub)) passed++; if (score >= (sub.maxMarks * 0.75)) distinction++;
        if (score >= 0 && score < 21) distribution['0-20'] = distribution['0-20']! + 1; else if (score >= 21 && score < 32.9) distribution['21-32.9'] = distribution['21-32.9']! + 1; else if (score >= 33 && score < 40) distribution['33-40'] = distribution['33-40']! + 1; else if (score >= 41 && score < 50) distribution['41-50'] = distribution['41-50']! + 1; else if (score >= 51 && score < 59.9) distribution['51-59.9'] = distribution['51-59.9']! + 1; else if (score == 60) distribution['60'] = distribution['60']! + 1; else if (score >= 61 && score < 70) distribution['61-70'] = distribution['61-70']! + 1; else if (score >= 71 && score < 74.9) distribution['71-74.9'] = distribution['71-74.9']! + 1; else if (score >= 75 && score < 80) distribution['75-80'] = distribution['75-80']! + 1; else if (score >= 81 && score < 90) distribution['81-90'] = distribution['81-90']! + 1; else if (score == 90) distribution['90'] = distribution['90']! + 1; else if (score >= 91 && score < 94.9) distribution['91-94.9'] = distribution['91-94.9']! + 1; else if (score >= 95 && score <= 100) distribution['95-100'] = distribution['95-100']! + 1;
      }
      
      double passPct = appeared > 0 ? (passed / appeared) * 100 : 0.0; double qi = appeared > 0 ? (sumMarks / appeared) : 0.0;
      if (appeared > 0) { subjectsAttemptedCount++; totalPassPctSum += passPct; totalQiSum += qi; }
      grandAppeared += appeared; grandPassed += passed; grandDistinction += distinction; distribution.forEach((key, val) => grandBrackets[key] = grandBrackets[key]! + val);
      
      leftBody.add(_buildCell(Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold)), 140, bgColor: rowColor));
      rightBody.add(Row(children: [
        _buildCell(Text(appeared.toString()), 60, bgColor: rowColor), _buildCell(Text(passed.toString()), 60, bgColor: rowColor), _buildCell(Text('${passPct.toStringAsFixed(2)}%'), 75, bgColor: rowColor), _buildCell(Text(distinction.toString()), 60, bgColor: rowColor), _buildCell(Text(qi.toStringAsFixed(2)), 60, bgColor: rowColor),
        ...distribution.values.map((v) => _buildCell(Text(v.toString()), 60, bgColor: rowColor)).toList()
      ]));
    }

    double avgPassPct = subjectsAttemptedCount > 0 ? (totalPassPctSum / subjectsAttemptedCount) : 0.0;
    double avgQi = subjectsAttemptedCount > 0 ? (totalQiSum / subjectsAttemptedCount) : 0.0;

    leftBody.add(_buildCell(const Text('SUM', style: TextStyle(fontWeight: FontWeight.bold)), 140, bgColor: Colors.teal.shade50));
    rightBody.add(Row(children: [
      _buildCell(Text(grandAppeared.toString(), style: const TextStyle(fontWeight: FontWeight.bold)), 60, bgColor: Colors.teal.shade50), _buildCell(Text(grandPassed.toString(), style: const TextStyle(fontWeight: FontWeight.bold)), 60, bgColor: Colors.teal.shade50), _buildCell(const Text('-'), 75, bgColor: Colors.teal.shade50), _buildCell(Text(grandDistinction.toString(), style: const TextStyle(fontWeight: FontWeight.bold)), 60, bgColor: Colors.teal.shade50), _buildCell(const Text('-'), 60, bgColor: Colors.teal.shade50),
      ...grandBrackets.values.map((v) => _buildCell(Text(v.toString()), 60, bgColor: Colors.teal.shade50)).toList()
    ]));
    
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 250), curve: Curves.easeInOut,
          child: _isTopVisible ? GestureDetector(
            onTap: () => setState(() => _isStatsExpanded = !_isStatsExpanded),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Summary Overview", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF00897B))),
                      Icon(_isStatsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey.shade600)
                    ],
                  ),
                  AnimatedCrossFade(
                    firstChild: Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Row(
                        children: [
                          _buildExpandedStatCard("Subjects", widget.subjects.length.toString(), Icons.menu_book, Colors.orange),
                          _buildExpandedStatCard("Pass %", "${avgPassPct.toStringAsFixed(2)}%", Icons.verified, Colors.blue),
                          _buildExpandedStatCard("Distinctions", grandDistinction.toString(), Icons.bar_chart, Colors.purple),
                          _buildExpandedStatCard("QI", avgQi.toStringAsFixed(2), Icons.star, Colors.green),
                        ],
                      ),
                    ),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Row(
                        children: [
                          _buildCollapsedStatPill("", widget.subjects.length.toString(), Icons.menu_book, Colors.orange),
                          _buildCollapsedStatPill("", "${avgPassPct.toStringAsFixed(2)}%", Icons.verified, Colors.blue),
                          _buildCollapsedStatPill("", grandDistinction.toString(), Icons.bar_chart, Colors.purple),
                          _buildCollapsedStatPill("QI", avgQi.toStringAsFixed(2), Icons.star, Colors.green),
                        ],
                      ),
                    ),
                    crossFadeState: _isStatsExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                    duration: const Duration(milliseconds: 300),
                  )
                ],
              ),
            ),
          ) : const SizedBox(width: double.infinity),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)), clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Row(children: [
                  _buildCell(const Text('SUBJECT', style: TextStyle(fontWeight: FontWeight.bold)), 140, bgColor: const Color(0xFFE0F2F1), isHeader: true),
                  Expanded(child: SingleChildScrollView(controller: _horizontalScroll1, scrollDirection: Axis.horizontal, child: Row(children: [
                    _buildCell(const Text('APP', style: TextStyle(fontWeight: FontWeight.bold)), 60, bgColor: const Color(0xFFE0F2F1), isHeader: true), _buildCell(const Text('PASS', style: TextStyle(fontWeight: FontWeight.bold)), 60, bgColor: const Color(0xFFE0F2F1), isHeader: true), _buildCell(const Text('PASS %', style: TextStyle(fontWeight: FontWeight.bold)), 75, bgColor: const Color(0xFFE0F2F1), isHeader: true), _buildCell(const Text('DISTT', style: TextStyle(fontWeight: FontWeight.bold)), 60, bgColor: const Color(0xFFE0F2F1), isHeader: true), _buildCell(const Text('QI', style: TextStyle(fontWeight: FontWeight.bold)), 60, bgColor: const Color(0xFFE0F2F1), isHeader: true),
                    ...['0-20', '21-32.9', '33-40', '41-50', '51-59.9', '60', '61-70', '71-74.9', '75-80', '81-90', '90', '91-94.9', '95-100'].map((e) => _buildCell(Text(e, style: const TextStyle(fontWeight: FontWeight.bold)), 60, bgColor: const Color(0xFFE0F2F1), isHeader: true)).toList()
                  ]))),
                ]),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _verticalScroll,
                    scrollDirection: Axis.vertical,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(children: leftBody),
                        Expanded(child: SingleChildScrollView(controller: _horizontalScroll2, scrollDirection: Axis.horizontal, child: Column(children: rightBody))),
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
