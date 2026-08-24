import 'package:flutter/material.dart';

import '../../../../app/theme/result_master_theme.dart';
import '../providers/subject_tabs_provider.dart';

class ResultWorkspaceScreen extends StatelessWidget {
  const ResultWorkspaceScreen({super.key});

  static const routeName = 'result-workspace';
  static const routePath = '/results/new';

  @override
  Widget build(BuildContext context) {
    return const _ResultWorkspaceBody();
  }
}

class _ResultWorkspaceBody extends StatelessWidget {
  const _ResultWorkspaceBody();

  @override
  Widget build(BuildContext context) {
    final tabs = const [
      SubjectTab(id: 'summary', name: 'Summary', position: 0),
      SubjectTab(id: 'mathematics', name: 'Mathematics', position: 1),
      SubjectTab(id: 'english', name: 'English', position: 2),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('New Result Workbook'),
          bottom: TabBar(
            isScrollable: true,
            tabs: [for (final tab in tabs) Tab(text: tab.name)],
          ),
        ),
        body: TabBarView(
          children: [
            const _SummarySheet(),
            MarksEntrySheet(
              subjectId: tabs[1].id,
              subjectName: tabs[1].name,
            ),
            MarksEntrySheet(
              subjectId: tabs[2].id,
              subjectName: tabs[2].name,
            ),
          ],
        ),
      ),
    );
  }
}

@visibleForTesting
class MarksEntrySheet extends StatefulWidget {
  const MarksEntrySheet({
    super.key,
    required this.subjectId,
    required this.subjectName,
    this.studentCount = 8,
    this.componentMaxMarks = const {'CA': 20, 'Exam': 80},
  });

  final String subjectId;
  final String subjectName;
  final int studentCount;
  final Map<String, int> componentMaxMarks;

  @override
  State<MarksEntrySheet> createState() => _MarksEntrySheetState();
}

class _MarksEntrySheetState extends State<MarksEntrySheet> {
  late final List<_StudentMarksRow> _rows;
  late final List<String> _components;
  final Map<_CellCoordinate, TextEditingController> _controllers = {};
  final Map<_CellCoordinate, FocusNode> _focusNodes = {};
  final Map<_CellCoordinate, String?> _errors = {};
  bool _saved = true;

  @override
  void initState() {
    super.initState();
    _components = widget.componentMaxMarks.keys.toList(growable: false);
    _rows = List.generate(
      widget.studentCount,
      (index) => _StudentMarksRow(
        rollNumber: '${index + 1}',
        studentName: 'Learner ${index + 1}',
        marks: {for (final component in _components) component: ''},
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _updateMark(_CellCoordinate cell, String value) {
    final component = _components[cell.columnIndex];
    final normalized = value.trim().toUpperCase();
    final maxMarks = widget.componentMaxMarks[component]!;
    final error = MarksEntryValidator.validate(normalized, maxMarks: maxMarks);

    setState(() {
      _saved = false;
      _rows[cell.rowIndex].marks[component] = normalized;
      _errors[cell] = error;
      _saved = true;
    });
  }

  void _moveToNextCell(_CellCoordinate current) {
    var row = current.rowIndex;
    var column = current.columnIndex + 1;
    if (column >= _components.length) {
      column = 0;
      row += 1;
    }
    if (row >= _rows.length) return;

    final next = _CellCoordinate(row, column);
    final node = _focusNodes[next];
    if (node == null) return;
    node.requestFocus();
    final controller = _controllers[next];
    if (controller != null) {
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
    }
  }

  TextEditingController _controllerFor(_CellCoordinate cell) {
    return _controllers.putIfAbsent(cell, () {
      final component = _components[cell.columnIndex];
      return TextEditingController(text: _rows[cell.rowIndex].marks[component]);
    });
  }

  FocusNode _focusNodeFor(_CellCoordinate cell) {
    return _focusNodes.putIfAbsent(cell, FocusNode.new);
  }

  String _formatTotal(_StudentMarksRow row) {
    if (row.marks.values.any((mark) => mark == MarksEntryValidator.absentCode)) {
      return MarksEntryValidator.absentCode;
    }

    var total = 0;
    for (final mark in row.marks.values) {
      total += int.tryParse(mark) ?? 0;
    }
    return total.toString();
  }

  @override
  Widget build(BuildContext context) {
    final headers = ['Roll No.', 'Student Name', ..._components, 'Total'];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: ResultMasterTheme.gridLine),
        ),
        child: Column(
          children: [
            _WorkbookStatusBar(
              saved: _saved,
              hasErrors: _errors.values.any((error) => error != null),
            ),
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  for (final header in headers)
                    _HeaderCell(
                      text: header,
                      flex: header == 'Student Name' ? 2 : 1,
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _rows.length,
                itemBuilder: (context, rowIndex) {
                  final row = _rows[rowIndex];
                  return SizedBox(
                    height: 56,
                    child: Row(
                      children: [
                        _ReadOnlyCell(row.rollNumber),
                        _ReadOnlyCell(row.studentName, flex: 2),
                        for (var columnIndex = 0;
                            columnIndex < _components.length;
                            columnIndex++)
                          _EditableMarkCell(
                            coordinate: _CellCoordinate(rowIndex, columnIndex),
                            controller: _controllerFor(
                              _CellCoordinate(rowIndex, columnIndex),
                            ),
                            focusNode: _focusNodeFor(
                              _CellCoordinate(rowIndex, columnIndex),
                            ),
                            errorText: _errors[
                              _CellCoordinate(rowIndex, columnIndex)
                            ],
                            maxMarks: widget.componentMaxMarks[
                                _components[columnIndex]]!,
                            onChanged: _updateMark,
                            onSubmitted: _moveToNextCell,
                          ),
                        _ReadOnlyCell(
                          _formatTotal(row),
                          key: ValueKey('total-$rowIndex'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@visibleForTesting
class MarksEntryValidator {
  const MarksEntryValidator._();

  static const absentCode = 'AB';

  static String? validate(String value, {required int maxMarks}) {
    if (value.isEmpty || value == absentCode) return null;
    final mark = int.tryParse(value);
    if (mark == null || mark < 0 || mark > maxMarks) {
      return 'Enter 0-$maxMarks or AB';
    }
    return null;
  }
}

class _EditableMarkCell extends StatelessWidget {
  const _EditableMarkCell({
    required this.coordinate,
    required this.controller,
    required this.focusNode,
    required this.errorText,
    required this.maxMarks,
    required this.onChanged,
    required this.onSubmitted,
  });

  final _CellCoordinate coordinate;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? errorText;
  final int maxMarks;
  final void Function(_CellCoordinate, String) onChanged;
  final ValueChanged<_CellCoordinate> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: hasError ? const Color(0xFFFFF1F0) : Colors.white,
          border: Border.all(
            color: hasError ? Colors.red : ResultMasterTheme.gridLine,
            width: 0.7,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: TextField(
          key: ValueKey('mark-${coordinate.rowIndex}-${coordinate.columnIndex}'),
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            hintText: '0-$maxMarks',
            errorText: errorText,
            errorStyle: const TextStyle(fontSize: 9, height: 0.8),
          ),
          onChanged: (value) => onChanged(coordinate, value),
          onSubmitted: (_) => onSubmitted(coordinate),
        ),
      ),
    );
  }
}

class _SummarySheet extends StatelessWidget {
  const _SummarySheet();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Summary will calculate totals from each configured subject.'),
    );
  }
}

class _WorkbookStatusBar extends StatelessWidget {
  const _WorkbookStatusBar({required this.saved, required this.hasErrors});

  final bool saved;
  final bool hasErrors;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFFF6FAF7),
      child: Text(
        hasErrors
            ? 'Fix invalid marks before finalizing'
            : (saved ? 'All edits auto-saved' : 'Saving...'),
        style: TextStyle(
          color: hasErrors ? Colors.red : ResultMasterTheme.excelDarkGreen,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.text, required this.flex});

  final String text;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F1EA),
          border: Border.all(color: ResultMasterTheme.gridLine, width: 0.5),
        ),
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _ReadOnlyCell extends StatelessWidget {
  const _ReadOnlyCell(this.text, {super.key, this.flex = 1});

  final String text;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: ResultMasterTheme.gridLine, width: 0.5),
        ),
        child: Text(text, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _CellCoordinate {
  const _CellCoordinate(this.rowIndex, this.columnIndex);

  final int rowIndex;
  final int columnIndex;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _CellCoordinate &&
            other.rowIndex == rowIndex &&
            other.columnIndex == columnIndex;
  }

  @override
  int get hashCode => Object.hash(rowIndex, columnIndex);
}

class _StudentMarksRow {
  _StudentMarksRow({
    required this.rollNumber,
    required this.studentName,
    required this.marks,
  });

  final String rollNumber;
  final String studentName;
  final Map<String, String> marks;
}
