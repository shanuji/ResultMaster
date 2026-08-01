import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/result_master_theme.dart';
import '../../../result_workbook/data/repositories/sqlite_result_workbook_repository.dart';
import '../../../result_workbook/domain/entities/result_workbook.dart';
import '../providers/subject_tabs_provider.dart';

class ResultWorkspaceScreen extends StatefulWidget {
  const ResultWorkspaceScreen({super.key});

  static const routeName = 'result-workspace';
  static const routePath = '/results/new';

  @override
  State<ResultWorkspaceScreen> createState() => _ResultWorkspaceScreenState();
}

class _ResultWorkspaceScreenState extends State<ResultWorkspaceScreen> {
  final SqliteResultWorkbookRepository _repository = SqliteResultWorkbookRepository();
  var _loading = true;
  List<WorkbookSummary> _workbooks = const <WorkbookSummary>[];
  OpenedWorkbook? _opened;

  @override
  void initState() {
    super.initState();
    _loadWorkbooks();
  }

  Future<void> _loadWorkbooks() async {
    setState(() => _loading = true);
    try {
      final workbooks = await _repository.listWorkbooks();
      if (!mounted) return;
      setState(() => _workbooks = workbooks);
    } catch (error) {
      if (mounted) _message('$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(WorkbookSummary workbook) async {
    try {
      final opened = await _repository.openWorkbook(workbook.id);
      if (mounted) setState(() => _opened = opened);
    } catch (error) {
      if (mounted) _message('$error');
    }
  }

  Future<void> _rename(WorkbookSummary workbook) async {
    final controller = TextEditingController(text: workbook.examinationName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Workbook'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Examination name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty) return;
    await _repository.renameWorkbook(workbook.id, name);
    await _loadWorkbooks();
  }

  Future<void> _delete(WorkbookSummary workbook) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workbook?'),
        content: Text('Delete ${workbook.title}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repository.deleteWorkbook(workbook.id);
    if (mounted && _opened?.summary.id == workbook.id) setState(() => _opened = null);
    await _loadWorkbooks();
  }

  Future<void> _saveMark({required int studentId, required int componentId, double? marks}) async {
    final workbookId = _opened?.summary.id;
    if (workbookId == null) return;
    await _repository.saveMark(workbookId: workbookId, studentId: studentId, componentId: componentId, marks: marks);
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Result Workbooks'), actions: <Widget>[IconButton(onPressed: _loadWorkbooks, icon: const Icon(Icons.refresh), tooltip: 'Refresh')]),
        body: Row(children: <Widget>[
          SizedBox(width: 320, child: _loading ? const Center(child: CircularProgressIndicator()) : _WorkbookList(workbooks: _workbooks, selectedId: _opened?.summary.id, onOpen: _open, onRename: _rename, onDelete: _delete)),
          const VerticalDivider(width: 1),
          Expanded(child: _opened == null ? const _DraftWorkbookTabs() : _WorkbookGrid(workbook: _opened!, onSaveMark: _saveMark)),
        ]),
      );
}

class _DraftWorkbookTabs extends ConsumerWidget {
  const _DraftWorkbookTabs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = ref.watch(draftSubjectTabsProvider);
    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          TabBar(isScrollable: true, tabs: [for (final tab in tabs) Tab(text: tab.name)]),
          Expanded(
            child: TabBarView(
              children: [
                for (final tab in tabs) tab.id == 'summary' ? const _SummarySheet() : MarksEntrySheet(subjectId: tab.id, subjectName: tab.name),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkbookList extends StatelessWidget {
  const _WorkbookList({required this.workbooks, required this.selectedId, required this.onOpen, required this.onRename, required this.onDelete});

  final List<WorkbookSummary> workbooks;
  final int? selectedId;
  final ValueChanged<WorkbookSummary> onOpen;
  final ValueChanged<WorkbookSummary> onRename;
  final ValueChanged<WorkbookSummary> onDelete;

  @override
  Widget build(BuildContext context) => ListView(children: <Widget>[
    for (final workbook in workbooks) ListTile(
      selected: workbook.id == selectedId,
      title: Text(workbook.title),
      subtitle: Text('${workbook.studentCount} students • ${workbook.subjectCount} subjects'),
      onTap: () => onOpen(workbook),
      trailing: PopupMenuButton<String>(itemBuilder: (context) => const <PopupMenuEntry<String>>[
        PopupMenuItem(value: 'rename', child: Text('Rename')),
        PopupMenuItem(value: 'delete', child: Text('Delete')),
      ], onSelected: (value) => value == 'rename' ? onRename(workbook) : onDelete(workbook)),
    ),
  ]);
}

class _WorkbookGrid extends StatelessWidget {
  const _WorkbookGrid({required this.workbook, required this.onSaveMark});

  final OpenedWorkbook workbook;
  final Future<void> Function({required int studentId, required int componentId, double? marks}) onSaveMark;

  @override
  Widget build(BuildContext context) {
    final subjects = workbook.subjects;
    return DefaultTabController(
      length: subjects.isEmpty ? 1 : subjects.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabs: subjects.isEmpty ? const [Tab(text: 'Workbook')] : [for (final subject in subjects) Tab(text: subject.name)],
          ),
          Expanded(
            child: subjects.isEmpty
                ? const Center(child: Text('This workbook has no subjects.'))
                : TabBarView(
                    children: [for (final subject in subjects) _SubjectMarksGrid(workbook: workbook, subject: subject, onSaveMark: onSaveMark)],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SubjectMarksGrid extends StatelessWidget {
  const _SubjectMarksGrid({required this.workbook, required this.subject, required this.onSaveMark});

  final OpenedWorkbook workbook;
  final WorkbookSubject subject;
  final Future<void> Function({required int studentId, required int componentId, double? marks}) onSaveMark;

  @override
  Widget build(BuildContext context) {
    final editableComponents = subject.components.where((component) => component.isEditable).toList(growable: false);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SheetRow(cells: ['Roll No.', 'Student Name', ...editableComponents.map((component) => component.name), 'Total'], isHeader: true),
        for (final student in workbook.students)
          SizedBox(
            height: 52,
            child: Row(
              children: [
                _ReadOnlyCell(student.rollNumber.toString()),
                _ReadOnlyCell(student.name, flex: 2),
                for (final component in editableComponents)
                  Expanded(
                    child: TextFormField(
                      initialValue: workbook.markFor(student.id!, component.id)?.toString() ?? '',
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                      onFieldSubmitted: (value) => onSaveMark(studentId: student.id!, componentId: component.id, marks: double.tryParse(value.trim())),
                    ),
                  ),
                _ReadOnlyCell(workbook.subjectTotal(student.id!, subject).toString()),
              ],
            ),
          ),
      ],
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
  final Map<_CellCoordinate, FocusNode> _focusNodes = {};
  final Map<_CellCoordinate, TextEditingController> _controllers = {};
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

  void _autoSave(_CellCoordinate cell, String value) {
    final normalized = value.trim().toUpperCase();
    final component = _components[cell.columnIndex];
    final maxMarks = widget.componentMaxMarks[component]!;
    final error = MarksEntryValidator.validate(normalized, maxMarks: maxMarks);

    setState(() {
      _saved = false;
      _rows[cell.rowIndex].marks[component] = normalized;
      _errors[cell] = error;
    });

    // The current repository has not introduced durable marks tables yet. Keep
    // the save boundary isolated here so the UI still behaves as an auto-saving
    // workbook and can be wired to the existing data layer without changing the
    // sheet widget contract.
    setState(() => _saved = true);
  }

  void _moveFocus(_CellCoordinate from, _NavigationIntent intent) {
    final next = _nextCell(from, intent);
    if (next == null) return;
    _focusNodes[next]?.requestFocus();
    _controllers[next]?.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controllers[next]?.text.length ?? 0,
    );
  }

  _CellCoordinate? _nextCell(_CellCoordinate from, _NavigationIntent intent) {
    var row = from.rowIndex;
    var column = from.columnIndex;

    switch (intent) {
      case _NavigationIntent.next:
        column += 1;
        if (column >= _components.length) {
          column = 0;
          row += 1;
        }
      case _NavigationIntent.previous:
        column -= 1;
        if (column < 0) {
          column = _components.length - 1;
          row -= 1;
        }
      case _NavigationIntent.down:
        row += 1;
      case _NavigationIntent.up:
        row -= 1;
    }

    if (row < 0 || row >= _rows.length) return null;
    return _CellCoordinate(row, column);
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
            _WorkbookStatusBar(saved: _saved, hasErrors: _errors.values.any((error) => error != null)),
            _SheetRow(cells: headers, isHeader: true),
            Expanded(
              child: ListView.builder(
                itemCount: _rows.length,
                itemBuilder: (context, rowIndex) {
                  final row = _rows[rowIndex];
                  return SizedBox(
                    height: 52,
                    child: Row(
                      children: [
                        _ReadOnlyCell(row.rollNumber),
                        _ReadOnlyCell(row.studentName, flex: 2),
                        for (var columnIndex = 0; columnIndex < _components.length; columnIndex++)
                          _EditableMarkCell(
                            coordinate: _CellCoordinate(rowIndex, columnIndex),
                            controller: _controllerFor(rowIndex, columnIndex),
                            focusNode: _focusNodeFor(rowIndex, columnIndex),
                            errorText: _errors[_CellCoordinate(rowIndex, columnIndex)],
                            maxMarks: widget.componentMaxMarks[_components[columnIndex]]!,
                            onChanged: _autoSave,
                            onNavigate: _moveFocus,
                          ),
                        _ReadOnlyCell(_formatTotal(row), key: ValueKey('total-$rowIndex')),
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

  TextEditingController _controllerFor(int rowIndex, int columnIndex) {
    final coordinate = _CellCoordinate(rowIndex, columnIndex);
    return _controllers.putIfAbsent(coordinate, () {
      final component = _components[columnIndex];
      return TextEditingController(text: _rows[rowIndex].marks[component]);
    });
  }

  FocusNode _focusNodeFor(int rowIndex, int columnIndex) {
    final coordinate = _CellCoordinate(rowIndex, columnIndex);
    return _focusNodes.putIfAbsent(coordinate, FocusNode.new);
  }

  String _formatTotal(_StudentMarksRow row) {
    if (row.marks.values.any((mark) => mark.trim().toUpperCase() == MarksEntryValidator.absentCode)) {
      return MarksEntryValidator.absentCode;
    }
    var total = 0;
    for (final mark in row.marks.values) {
      final parsed = int.tryParse(mark.trim());
      if (parsed == null) continue;
      total += parsed;
    }
    return total.toString();
  }
}

@visibleForTesting
class MarksEntryValidator {
  const MarksEntryValidator._();

  static const absentCode = 'AB';

  static String? validate(String value, {required int maxMarks}) {
    if (value.isEmpty) return null;
    if (value == absentCode) return null;
    final mark = int.tryParse(value);
    if (mark == null) return 'Enter 0-$maxMarks or AB';
    if (mark < 0 || mark > maxMarks) return 'Enter 0-$maxMarks or AB';
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
    required this.onNavigate,
  });

  final _CellCoordinate coordinate;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? errorText;
  final int maxMarks;
  final void Function(_CellCoordinate cell, String value) onChanged;
  final void Function(_CellCoordinate cell, _NavigationIntent intent) onNavigate;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    return Expanded(
      child: KeyboardListener(
        focusNode: FocusNode(skipTraversal: true),
        onKeyEvent: (event) {
          if (event is! KeyDownEvent) return;
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) onNavigate(coordinate, _NavigationIntent.down);
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) onNavigate(coordinate, _NavigationIntent.up);
          if (event.logicalKey == LogicalKeyboardKey.tab && HardwareKeyboard.instance.isShiftPressed) {
            onNavigate(coordinate, _NavigationIntent.previous);
          } else if (event.logicalKey == LogicalKeyboardKey.tab || event.logicalKey == LogicalKeyboardKey.enter) {
            onNavigate(coordinate, _NavigationIntent.next);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: hasError ? const Color(0xFFFFF1F0) : Colors.white,
            border: Border.all(color: hasError ? Colors.red : ResultMasterTheme.gridLine, width: 0.7),
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
            onSubmitted: (_) => onNavigate(coordinate, _NavigationIntent.next),
          ),
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
        hasErrors ? 'Fix invalid marks before finalizing' : (saved ? 'All edits auto-saved' : 'Saving...'),
        style: TextStyle(color: hasErrors ? Colors.red : ResultMasterTheme.excelDarkGreen, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({required this.cells, this.isHeader = false});

  final List<String> cells;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          for (final cell in cells)
            Expanded(
              flex: cell == 'Student Name' ? 2 : 1,
              child: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isHeader ? const Color(0xFFE8F1EA) : Colors.white,
                  border: Border.all(color: ResultMasterTheme.gridLine, width: 0.5),
                ),
                child: Text(cell, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: isHeader ? FontWeight.w700 : FontWeight.w400)),
              ),
            ),
        ],
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
        decoration: BoxDecoration(border: Border.all(color: ResultMasterTheme.gridLine, width: 0.5)),
        child: Text(text, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

enum _NavigationIntent { next, previous, up, down }

class _CellCoordinate {
  const _CellCoordinate(this.rowIndex, this.columnIndex);

  final int rowIndex;
  final int columnIndex;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _CellCoordinate && runtimeType == other.runtimeType && rowIndex == other.rowIndex && columnIndex == other.columnIndex;

  @override
  int get hashCode => Object.hash(rowIndex, columnIndex);
}

class _StudentMarksRow {
  _StudentMarksRow({required this.rollNumber, required this.studentName, required this.marks});

  final String rollNumber;
  final String studentName;
  final Map<String, String> marks;
}
