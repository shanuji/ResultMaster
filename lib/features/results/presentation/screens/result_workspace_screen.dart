import 'package:flutter/material.dart';

import '../../../../app/theme/result_master_theme.dart';
import '../../../result_workbook/data/repositories/sqlite_result_workbook_repository.dart';
import '../../../result_workbook/domain/entities/result_workbook.dart';

class ResultWorkspaceScreen extends StatefulWidget {
  const ResultWorkspaceScreen({super.key});

  static const routeName = 'result-workspace';
  static const routePath = '/results/new';

  @override
  State<ResultWorkspaceScreen> createState() => _ResultWorkspaceScreenState();
}

class _ResultWorkspaceScreenState extends State<ResultWorkspaceScreen> {
  final _repository = SqliteResultWorkbookRepository();
  List<WorkbookSummary> _workbooks = const <WorkbookSummary>[];
  OpenedWorkbook? _opened;
  bool _loading = true;

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
      setState(() {
        _workbooks = workbooks;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _message('$error');
    }
  }

  Future<void> _open(WorkbookSummary summary) async {
    final opened = await _repository.openWorkbook(summary.id);
    if (!mounted) return;
    setState(() => _opened = opened);
  }

  Future<void> _rename(WorkbookSummary summary) async {
    final controller = TextEditingController(text: summary.examinationName);
    final name = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: const Text('Rename Workbook'),
      content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Examination name')),
      actions: <Widget>[TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save'))],
    ));
    if (name == null || name.trim().isEmpty) return;
    await _repository.renameWorkbook(summary.id, name);
    await _loadWorkbooks();
    if (_opened?.summary.id == summary.id) await _open(summary);
  }

  Future<void> _delete(WorkbookSummary summary) async {
    final ok = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Delete Workbook?'),
      content: Text('Delete ${summary.title} and all saved marks?'),
      actions: <Widget>[TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'))],
    ));
    if (ok != true) return;
    await _repository.deleteWorkbook(summary.id);
    if (!mounted) return;
    setState(() => _opened = null);
    await _loadWorkbooks();
  }

  Future<void> _saveMark(OpenedWorkbook workbook, Student student, WorkbookComponent component, String value) async {
    await _repository.saveMark(workbookId: workbook.summary.id, studentId: student.id!, componentId: component.id, marks: double.tryParse(value));
    await _open(workbook.summary);
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Result Workbooks'), actions: <Widget>[IconButton(onPressed: _loadWorkbooks, icon: const Icon(Icons.refresh), tooltip: 'Refresh')]),
    body: Row(children: <Widget>[
      SizedBox(width: 320, child: _loading ? const Center(child: CircularProgressIndicator()) : _WorkbookList(workbooks: _workbooks, selectedId: _opened?.summary.id, onOpen: _open, onRename: _rename, onDelete: _delete)),
      const VerticalDivider(width: 1),
      Expanded(child: _opened == null ? const Center(child: Text('Open a workbook, or create one from the New Result wizard.')) : _WorkbookGrid(workbook: _opened!, onSaveMark: _saveMark)),
    ]),
  );
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
  final Future<void> Function(OpenedWorkbook workbook, Student student, WorkbookComponent component, String value) onSaveMark;

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: workbook.subjects.length + 1,
    child: Column(children: <Widget>[
      Material(color: ResultMasterTheme.excelGreen, child: TabBar(isScrollable: true, tabs: <Widget>[for (final subject in workbook.subjects) Tab(text: subject.name), const Tab(text: 'Final')]),),
      Expanded(child: TabBarView(children: <Widget>[
        for (final subject in workbook.subjects) _SubjectSheet(workbook: workbook, subject: subject, onSaveMark: onSaveMark),
        _FinalSheet(workbook: workbook),
      ])),
    ]),
  );
}

class _SubjectSheet extends StatelessWidget {
  const _SubjectSheet({required this.workbook, required this.subject, required this.onSaveMark});

  final OpenedWorkbook workbook;
  final WorkbookSubject subject;
  final Future<void> Function(OpenedWorkbook workbook, Student student, WorkbookComponent component, String value) onSaveMark;

  @override
  Widget build(BuildContext context) => ListView(children: <Widget>[
    _SheetRow(cells: <String>['Roll No', 'Student Name', ...subject.components.map((c) => c.name)], isHeader: true),
    for (final student in workbook.students) Row(children: <Widget>[
      _Cell('${student.rollNumber}'),
      _Cell(student.name),
      for (final component in subject.components) Expanded(child: component.isTotal
        ? _ReadOnlyCell('${workbook.subjectTotal(student.id!, subject)}')
        : TextFormField(initialValue: workbook.markFor(student.id!, component.id)?.toString() ?? '', keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder()), onFieldSubmitted: (value) => onSaveMark(workbook, student, component, value))),
    ]),
  ]);
}

class _FinalSheet extends StatelessWidget {
  const _FinalSheet({required this.workbook});

  final OpenedWorkbook workbook;

  @override
  Widget build(BuildContext context) => ListView(children: <Widget>[
    _SheetRow(cells: <String>['Roll No', 'Student Name', ...workbook.subjects.map((s) => s.name), 'Total Marks', 'Maximum Marks', 'Percentage', 'Pass / Fail', 'Remarks'], isHeader: true),
    for (final student in workbook.students) _finalRow(student),
  ]);

  Widget _finalRow(Student student) {
    final subjectTotals = [for (final subject in workbook.subjects) workbook.subjectTotal(student.id!, subject)];
    final total = subjectTotals.fold<double>(0, (sum, mark) => sum + mark);
    final maximum = workbook.subjects.fold<double>(0, (sum, subject) => sum + subject.components.where((c) => !c.isTotal).length * 100);
    final percentage = maximum == 0 ? 0 : total / maximum * 100;
    final passed = workbook.passCriteria.every((criterion) {
      final index = workbook.subjects.indexWhere((subject) => subject.name == criterion.subjectName);
      if (index == -1) return true;
      final required = criterion.passMarks ?? 0;
      return subjectTotals[index] >= required;
    });
    return _SheetRow(cells: <String>['${student.rollNumber}', student.name, ...subjectTotals.map((m) => '$m'), '$total', '$maximum', percentage.toStringAsFixed(2), passed ? 'Pass' : 'Fail', passed ? 'Promoted' : 'Needs Improvement']);
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({required this.cells, this.isHeader = false});

  final List<String> cells;
  final bool isHeader;

  @override
  Widget build(BuildContext context) => Row(children: <Widget>[for (final cell in cells) _Cell(cell, header: isHeader)]);
}

class _Cell extends StatelessWidget {
  const _Cell(this.text, {this.header = false});

  final String text;
  final bool header;

  @override
  Widget build(BuildContext context) => Expanded(child: Container(alignment: Alignment.centerLeft, padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: header ? const Color(0xFFE8F1EA) : Colors.white, border: Border.all(color: ResultMasterTheme.gridLine, width: .5)), child: Text(text, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: header ? FontWeight.w700 : FontWeight.w400))));
}

class _ReadOnlyCell extends StatelessWidget {
  const _ReadOnlyCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(alignment: Alignment.centerLeft, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF7F7F7), border: Border.all(color: ResultMasterTheme.gridLine, width: .5)), child: Text(text));
}
