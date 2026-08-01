import 'package:flutter/material.dart';
import '../models/data_models.dart';
import '../database/database_helper.dart';
import '../utils/ux_helpers.dart';

const Color _teal = Color(0xFF0A8D82);
const Color _tealDark = Color(0xFF06665F);
const Color _surface = Color(0xFFF4FBFA);

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
  final List<String> _inputKeysOrder = [];
  String _searchQuery = '';

  final ScrollController _horizontalScroll1 = ScrollController();
  final ScrollController _horizontalScroll2 = ScrollController();

  @override
  void initState() {
    super.initState();
    _horizontalScroll1.addListener(() {
      if (_horizontalScroll2.hasClients && _horizontalScroll2.offset != _horizontalScroll1.offset) {
        _horizontalScroll2.jumpTo(_horizontalScroll1.offset);
      }
    });
    _horizontalScroll2.addListener(() {
      if (_horizontalScroll1.hasClients && _horizontalScroll1.offset != _horizontalScroll2.offset) {
        _horizontalScroll1.jumpTo(_horizontalScroll2.offset);
      }
    });
  }

  @override
  void dispose() {
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    _horizontalScroll1.dispose();
    _horizontalScroll2.dispose();
    super.dispose();
  }

  FocusNode _getFocusNode(String key) => _focusNodes.putIfAbsent(key, () => FocusNode());

  String? _validateAndCleanInput(String input, double maxAllowed) {
    String clean = input.toUpperCase().trim();
    if (clean == '999') return 'AB';
    if (clean.isEmpty || clean == 'A' || clean == 'AB') return clean;
    double? val = double.tryParse(clean);
    if (val == null || val > maxAllowed) return null;
    return clean;
  }

  void _showValidationError(double maxAllowed) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: Marks cannot exceed $maxAllowed', style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.subjects.isEmpty) return const Center(child: Text('Go to Subjects setup first.'));
    if (_selectedSubjectIndex >= widget.subjects.length) _selectedSubjectIndex = 0;
    final currentSub = widget.subjects[_selectedSubjectIndex];

    _inputKeysOrder.clear();
    final filteredStudents = _searchQuery.isEmpty
        ? widget.students
        : widget.students.where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase()) || s.rollNo.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    final totalStudents = widget.students.length;
    final enteredCount = widget.students.where((s) => s.isSubjectAttempted(widget.termId, currentSub)).length;
    var passedCount = 0;
    var failedCount = 0;
    var disttCount = 0;
    var sumMarks = 0.0;

    for (var s in widget.students) {
      if (s.isSubjectAttempted(widget.termId, currentSub)) {
        final score = s.getSubjectScore(widget.termId, currentSub);
        sumMarks += score;
        if (s.isSubjectPassed(widget.termId, currentSub)) {
          passedCount++;
        } else {
          failedCount++;
        }
        if (score >= (currentSub.maxMarks * 0.75)) disttCount++;
      }
    }
    final qi = enteredCount > 0 ? (sumMarks / enteredCount) : 0.0;
    final allEntered = enteredCount == totalStudents && totalStudents > 0;

    return ColoredBox(
      color: _surface,
      child: Column(
        children: [
          SubjectSelectorWidget(subjects: widget.subjects, selectedIndex: _selectedSubjectIndex, onSelected: (index) => setState(() => _selectedSubjectIndex = index)),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
            child: SubjectCardWidget(
              subject: currentSub,
              enteredCount: enteredCount,
              totalStudents: totalStudents,
              allEntered: allEntered,
              passedCount: passedCount,
              failedCount: failedCount,
              qi: qi,
              distinctionCount: disttCount,
            ),
          ),
          SearchToolbarWidget(onSearchChanged: (val) => setState(() => _searchQuery = val), onSave: () {
            FocusScope.of(context).unfocus();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marks Saved!'), backgroundColor: Colors.green));
          }),
          Expanded(
            child: MarksTableWidget(
              termId: widget.termId,
              subject: currentSub,
              students: filteredStudents,
              inputKeysOrder: _inputKeysOrder,
              horizontalScroll1: _horizontalScroll1,
              horizontalScroll2: _horizontalScroll2,
              getFocusNode: _getFocusNode,
              validateAndCleanInput: _validateAndCleanInput,
              showValidationError: _showValidationError,
              onChanged: () => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }
}

class SubjectSelectorWidget extends StatelessWidget {
  final List<SubjectSetup> subjects;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const SubjectSelectorWidget({super.key, required this.subjects, required this.selectedIndex, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [_teal, _tealDark])),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: subjects.asMap().entries.map((entry) {
            final selected = entry.key == selectedIndex;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                child: FilterChip(
                  label: Text(entry.value.name.isEmpty ? 'Unnamed' : entry.value.name),
                  selected: selected,
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  labelStyle: TextStyle(color: selected ? Colors.white : _tealDark, fontWeight: FontWeight.w700, fontSize: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  selectedColor: _teal,
                  backgroundColor: Colors.white,
                  side: BorderSide(color: selected ? Colors.white.withOpacity(.9) : Colors.white.withOpacity(.55)),
                  shape: const StadiumBorder(),
                  onSelected: (value) { if (value) onSelected(entry.key); },
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class SubjectCardWidget extends StatelessWidget {
  final SubjectSetup subject;
  final int enteredCount;
  final int totalStudents;
  final bool allEntered;
  final int passedCount;
  final int failedCount;
  final double qi;
  final int distinctionCount;

  const SubjectCardWidget({super.key, required this.subject, required this.enteredCount, required this.totalStudents, required this.allEntered, required this.passedCount, required this.failedCount, required this.qi, required this.distinctionCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_teal, Color(0xFF15B8A8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _teal.withOpacity(.22), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent, splashColor: Colors.white.withOpacity(.08), highlightColor: Colors.white.withOpacity(.05)),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
          collapsedIconColor: Colors.white,
          iconColor: Colors.white,
          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(.2), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 19)),
          title: Text('Subject  •  ${subject.name}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Row(children: [
              _InfoPill(label: 'Max', value: subject.maxMarks.toStringAsFixed(0)),
              const SizedBox(width: 6),
              _InfoPill(label: 'Entered', value: '$enteredCount/$totalStudents', filled: allEntered),
            ]),
          ),
          children: [StatisticsWidget(passedCount: passedCount, failedCount: failedCount, qi: qi, distinctionCount: distinctionCount)],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;
  final bool filled;
  const _InfoPill({required this.label, required this.value, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: filled ? Colors.white : Colors.white.withOpacity(.18), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withOpacity(.28))),
      child: Text('$label: $value', style: TextStyle(color: filled ? _tealDark : Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}

class StatisticsWidget extends StatelessWidget {
  final int passedCount;
  final int failedCount;
  final double qi;
  final int distinctionCount;

  const StatisticsWidget({super.key, required this.passedCount, required this.failedCount, required this.qi, required this.distinctionCount});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _StatTile('Passed', passedCount.toString(), Icons.check_rounded, Colors.green),
      _StatTile('Failed', failedCount.toString(), Icons.close_rounded, Colors.redAccent),
      _StatTile('QI', qi.toStringAsFixed(2), Icons.bar_chart_rounded, Colors.blue),
      _StatTile('Distt', distinctionCount.toString(), Icons.workspace_premium_rounded, Colors.purple),
    ]);
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatTile(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
        decoration: BoxDecoration(color: Colors.white.withOpacity(.9), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(.65))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: color, size: 17), const SizedBox(height: 2), Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)), Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900))]),
      ),
    );
  }
}

class SearchToolbarWidget extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSave;

  const SearchToolbarWidget({super.key, required this.onSearchChanged, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
      child: Row(children: [
        Expanded(
          child: SizedBox(
            height: 42,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search student...',
                prefixIcon: const Icon(Icons.search_rounded, size: 19, color: _teal),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _teal.withOpacity(.13))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _teal, width: 1.2)),
              ),
              onChanged: onSearchChanged,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 44,
          height: 44,
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [_teal, Color(0xFF13B6A7)]), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: _teal.withOpacity(.25), blurRadius: 12, offset: const Offset(0, 5))]),
            child: IconButton(onPressed: onSave, icon: const Icon(Icons.save_rounded, color: Colors.white, size: 20), tooltip: 'Save'),
          ),
        ),
      ]),
    );
  }
}

typedef FocusNodeGetter = FocusNode Function(String key);
typedef MarkValidator = String? Function(String input, double maxAllowed);
typedef ValidationError = void Function(double maxAllowed);

class MarksTableWidget extends StatelessWidget {
  final int termId;
  final SubjectSetup subject;
  final List<StudentRow> students;
  final List<String> inputKeysOrder;
  final ScrollController horizontalScroll1;
  final ScrollController horizontalScroll2;
  final FocusNodeGetter getFocusNode;
  final MarkValidator validateAndCleanInput;
  final ValidationError showValidationError;
  final VoidCallback onChanged;

  const MarksTableWidget({super.key, required this.termId, required this.subject, required this.students, required this.inputKeysOrder, required this.horizontalScroll1, required this.horizontalScroll2, required this.getFocusNode, required this.validateAndCleanInput, required this.showValidationError, required this.onChanged});

  Widget _cell(Widget child, double width, {required Color bgColor, bool isHeader = false}) {
    return Container(
      width: width,
      height: isHeader ? 42 : 46,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bgColor, border: Border(bottom: BorderSide(color: Colors.grey.shade200), right: BorderSide(color: Colors.grey.shade200))),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final rightHeaders = <Widget>[];
    if (subject.components.isEmpty) {
      rightHeaders.add(_cell(Text('Marks\nMax ${subject.maxMarks.toStringAsFixed(0)}', textAlign: TextAlign.center, style: _headerStyle), 74, bgColor: const Color(0xFFE6F6F4), isHeader: true));
    } else {
      for (var c in subject.components) {
        rightHeaders.add(_cell(Text('${c.name}\nMax ${c.maxMarks.toStringAsFixed(0)}', textAlign: TextAlign.center, style: _headerStyle, maxLines: 2, overflow: TextOverflow.ellipsis), 74, bgColor: const Color(0xFFE6F6F4), isHeader: true));
      }
    }
    rightHeaders.add(_cell(const Text('Promote', style: _headerStyle), 72, bgColor: const Color(0xFFE6F6F4), isHeader: true));

    final leftRows = <Widget>[];
    final rightRows = <Widget>[];
    for (var i = 0; i < students.length; i++) {
      final student = students[i];
      final rowColor = i.isEven ? Colors.white : const Color(0xFFF8FCFB);
      leftRows.add(Row(children: [
        _cell(Text(student.rollNo, style: TextStyle(fontWeight: FontWeight.w800, color: Colors.grey.shade700, fontSize: 12)), 58, bgColor: rowColor),
        _cell(Text(student.name.isEmpty ? 'Student ${student.rollNo}' : student.name, maxLines: 2, overflow: TextOverflow.ellipsis, softWrap: true, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)), 138, bgColor: rowColor),
      ]));
      rightRows.add(StudentRowWidget(termId: termId, subject: subject, student: student, rowColor: rowColor, inputKeysOrder: inputKeysOrder, getFocusNode: getFocusNode, validateAndCleanInput: validateAndCleanInput, showValidationError: showValidationError, onChanged: onChanged, cellBuilder: _cell));
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _teal.withOpacity(.15)), borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 16, offset: const Offset(0, 8))]),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        HeaderRowWidget(rightHeaders: rightHeaders, horizontalScroll: horizontalScroll1, cellBuilder: _cell),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Column(children: leftRows),
              Expanded(child: SingleChildScrollView(controller: horizontalScroll2, scrollDirection: Axis.horizontal, child: Column(children: rightRows))),
            ]),
          ),
        ),
      ]),
    );
  }
}

const TextStyle _headerStyle = TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5, color: _tealDark, height: 1.05);

typedef CellBuilder = Widget Function(Widget child, double width, {required Color bgColor, bool isHeader});

class HeaderRowWidget extends StatelessWidget {
  final List<Widget> rightHeaders;
  final ScrollController horizontalScroll;
  final CellBuilder cellBuilder;

  const HeaderRowWidget({super.key, required this.rightHeaders, required this.horizontalScroll, required this.cellBuilder});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Row(children: [
        cellBuilder(const Text('Roll', style: _headerStyle), 58, bgColor: const Color(0xFFE6F6F4), isHeader: true),
        cellBuilder(const Text('Name', style: _headerStyle), 138, bgColor: const Color(0xFFE6F6F4), isHeader: true),
      ]),
      Expanded(child: SingleChildScrollView(controller: horizontalScroll, scrollDirection: Axis.horizontal, child: Row(children: rightHeaders))),
    ]);
  }
}

class StudentRowWidget extends StatelessWidget {
  final int termId;
  final SubjectSetup subject;
  final StudentRow student;
  final Color rowColor;
  final List<String> inputKeysOrder;
  final FocusNodeGetter getFocusNode;
  final MarkValidator validateAndCleanInput;
  final ValidationError showValidationError;
  final VoidCallback onChanged;
  final CellBuilder cellBuilder;

  const StudentRowWidget({super.key, required this.termId, required this.subject, required this.student, required this.rowColor, required this.inputKeysOrder, required this.getFocusNode, required this.validateAndCleanInput, required this.showValidationError, required this.onChanged, required this.cellBuilder});

  @override
  Widget build(BuildContext context) {
    final isPromoted = student.termPromotions[termId]?[subject.name] == true;
    var naturallyPassed = true;
    if (subject.includeInPassFail && student.isSubjectAttempted(termId, subject)) {
      if (subject.components.isEmpty) {
        naturallyPassed = student.getSubjectScore(termId, subject) >= subject.passingMarks;
      } else {
        for (var c in subject.components) {
          if (c.passingMarks > 0 && (double.tryParse(student.termMarks[termId]?['${subject.name}_${c.name}'] ?? '') ?? 0.0) < c.passingMarks) naturallyPassed = false;
        }
      }
    }

    final cells = <Widget>[];
    if (subject.components.isEmpty) {
      final fieldKey = '${student.rollNo}_${subject.name}';
      inputKeysOrder.add(fieldKey);
      cells.add(cellBuilder(_buildInput(context, fieldKey, subject.maxMarks), 74, bgColor: rowColor));
    } else {
      for (var c in subject.components) {
        final markKey = '${subject.name}_${c.name}';
        final fieldKey = '${student.rollNo}_$markKey';
        inputKeysOrder.add(fieldKey);
        cells.add(cellBuilder(_buildInput(context, fieldKey, c.maxMarks), 74, bgColor: rowColor));
      }
    }

    if (!subject.includeInPassFail || !student.isSubjectAttempted(termId, subject)) {
      cells.add(cellBuilder(Text('-', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)), 72, bgColor: rowColor));
    } else if (naturallyPassed) {
      cells.add(cellBuilder(Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: Colors.green.withOpacity(.12), shape: BoxShape.circle), child: const Icon(Icons.check_rounded, color: Colors.green, size: 18)), 72, bgColor: rowColor));
    } else {
      cells.add(cellBuilder(IconButton(visualDensity: VisualDensity.compact, icon: Icon(isPromoted ? Icons.star_rounded : Icons.star_border_rounded, color: isPromoted ? Colors.amber.shade700 : Colors.grey.shade500, size: 22), onPressed: () async {
        final newVal = !isPromoted;
        student.termPromotions[termId] ??= {};
        student.termPromotions[termId]![subject.name] = newVal;
        await DatabaseHelper.instance.toggleSubjectPromotion(termId, student.rollNo, subject.name, newVal);
        onChanged();
      }), 72, bgColor: rowColor));
    }
    return Row(children: cells);
  }

  Widget _buildInput(BuildContext context, String fieldKey, double max) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 64,
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11), border: Border.all(color: _teal.withOpacity(.35), width: .8), boxShadow: [BoxShadow(color: _teal.withOpacity(.08), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Center(
        child: MarkInputField(
          key: ValueKey(fieldKey),
          initialValue: student.termMarks[termId]?[fieldKey.split('_').last] ?? '',
          focusNode: getFocusNode(fieldKey),
          onFocusLostOrSubmitted: (val) async {
            final verified = validateAndCleanInput(val, max);
            if (verified != null) {
              student.termMarks[termId] ??= {};
              student.termMarks[termId]![fieldKey.split('_').last] = verified;
              await DatabaseHelper.instance.saveLiveMark(termId: termId, rollNo: student.rollNo, markKey: fieldKey.split('_').last, value: verified);
              onChanged();
            } else {
              showValidationError(max);
              getFocusNode(fieldKey).requestFocus();
            }
          },
          onNext: () {
            final idx = inputKeysOrder.indexOf(fieldKey);
            if (idx != -1 && idx + 1 < inputKeysOrder.length) FocusScope.of(context).requestFocus(getFocusNode(inputKeysOrder[idx + 1]));
          },
        ),
      ),
    );
  }
}
