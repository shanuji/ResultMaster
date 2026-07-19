import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/excel_theme.dart';
import '../application/class_register_service.dart';
import '../data/excel_register_codec.dart';
import '../domain/class_register.dart';
import '../domain/student.dart';
import 'class_register_controller.dart';

class ClassRegisterScreen extends StatefulWidget {
  const ClassRegisterScreen({super.key, required this.service});
  final ClassRegisterService service;

  @override
  State<ClassRegisterScreen> createState() => _ClassRegisterScreenState();
}

class _ClassRegisterScreenState extends State<ClassRegisterScreen> {
  late final ClassRegisterController controller;

  @override
  void initState() {
    super.initState();
    controller = ClassRegisterController(widget.service)..load();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Scaffold(
          appBar: AppBar(title: const Text('Class Registers'), actions: [
            IconButton(onPressed: () => _registerDialog(), icon: const Icon(Icons.add), tooltip: 'Create New Register'),
            IconButton(onPressed: controller.selected == null ? null : () => _registerDialog(register: controller.selected), icon: const Icon(Icons.edit), tooltip: 'Rename Register'),
            IconButton(onPressed: controller.selected == null ? null : _confirmDeleteRegister, icon: const Icon(Icons.delete_outline), tooltip: 'Delete Register'),
            IconButton(onPressed: controller.selected == null ? null : _importExcel, icon: const Icon(Icons.upload_file), tooltip: 'Import Excel'),
            IconButton(onPressed: controller.selected == null ? null : () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Use ExcelRegisterCodec to export this register to .xlsx.'))), icon: const Icon(Icons.download), tooltip: 'Export Excel'),
          ]),
          body: Row(children: [
            SizedBox(width: 260, child: _RegisterList(controller: controller)),
            const VerticalDivider(width: 1),
            Expanded(child: controller.selected == null ? const Center(child: Text('Create or open a class register.')) : _StudentTable(controller: controller)),
          ]),
          floatingActionButton: controller.selected == null ? null : FloatingActionButton.extended(onPressed: () => _studentDialog(), icon: const Icon(Icons.person_add_alt), label: const Text('Add Student')),
        ),
      );


  Future<void> _importExcel() async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: const <String>['xlsx']);
    final path = picked?.files.single.path;
    if (path == null) return;
    try {
      final codec = ExcelRegisterCodec();
      final workbook = await codec.inspectFile(File(path));
      if (!mounted) return;
      final selection = await showDialog<_ImportSelection>(context: context, builder: (_) => _ImportMappingDialog(workbook: workbook));
      if (selection == null) return;
      final imported = workbook.students(controller.selected!.id, worksheet: selection.worksheet, rollNumberColumn: selection.rollColumn, studentNameColumn: selection.nameColumn);
      final summary = await controller.importStudents(imported, mode: selection.mode);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported ${summary.imported} students (${summary.mode.name}); skipped ${summary.blankRowsSkipped} blank rows.')));
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _registerDialog({ClassRegister? register}) async {
    final text = TextEditingController(text: register?.name ?? '');
    final value = await showDialog<String>(context: context, builder: (_) => AlertDialog(title: Text(register == null ? 'Create New Register' : 'Rename Register'), content: TextField(controller: text, autofocus: true, decoration: const InputDecoration(labelText: 'Register name')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, text.text), child: const Text('Save'))]));
    if (value == null) return;
    await _run(() => register == null ? controller.createRegister(value) : controller.renameSelected(value));
  }

  Future<void> _confirmDeleteRegister() async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Delete Register?'), content: Text('Delete ${controller.selected!.name} and all students?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'))]));
    if (ok == true) await _run(controller.deleteSelected);
  }

  Future<void> _studentDialog({Student? student}) async {
    final roll = TextEditingController(text: student?.rollNumber ?? '');
    final name = TextEditingController(text: student?.name ?? '');
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: Text(student == null ? 'Add Student' : 'Edit Student'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: roll, decoration: const InputDecoration(labelText: 'Roll Number')), TextField(controller: name, decoration: const InputDecoration(labelText: 'Student Name'))]), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save'))]));
    if (ok != true) return;
    await _run(() => student == null ? controller.addStudent(roll.text, name.text) : controller.updateStudent(student, roll.text, name.text));
  }

  Future<void> _run(Future<void> Function() action) async {
    try { await action(); } catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error'))); }
  }
}


class _RegisterList extends StatelessWidget {
  const _RegisterList({required this.controller});
  final ClassRegisterController controller;
  @override
  Widget build(BuildContext context) => ListView(children: [for (final register in controller.registers) ListTile(selected: controller.selected?.id == register.id, title: Text(register.name), subtitle: Text('${register.updatedAt.toLocal()}'), onTap: () => controller.select(register))]);
}

class _StudentTable extends StatelessWidget {
  const _StudentTable({required this.controller});
  final ClassRegisterController controller;
  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(padding: const EdgeInsets.all(8), child: Row(children: [Expanded(child: TextField(decoration: const InputDecoration(labelText: 'Search by Roll Number'), onChanged: (v) => controller.search(roll: v))), const SizedBox(width: 12), Expanded(child: TextField(decoration: const InputDecoration(labelText: 'Search by Student Name'), onChanged: (v) => controller.search(name: v)))])),
        Container(color: ExcelTheme.headerGreen, child: const Row(children: [_Cell('S.No.', flex: 1, header: true), _Cell('Roll No.', flex: 2, header: true), _Cell('Student Name', flex: 4, header: true), _Cell('Actions', flex: 2, header: true)])),
        Expanded(child: ListView.builder(itemCount: controller.students.length, itemBuilder: (context, index) { final student = controller.students[index]; return Container(color: index.isEven ? Colors.white : ExcelTheme.alternateRow, child: Row(children: [_Cell('${index + 1}', flex: 1), _Cell(student.rollNumber, flex: 2), _Cell(student.name, flex: 4), Expanded(flex: 2, child: Row(children: [IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => context.findAncestorStateOfType<_ClassRegisterScreenState>()!._studentDialog(student: student)), IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => controller.deleteStudent(student))]))])); })),
      ]);
}

class _Cell extends StatelessWidget {
  const _Cell(this.text, {required this.flex, this.header = false});
  final String text; final int flex; final bool header;
  @override
  Widget build(BuildContext context) => Expanded(flex: flex, child: Container(decoration: BoxDecoration(border: Border.all(color: ExcelTheme.gridLine, width: .5)), padding: const EdgeInsets.all(10), child: Text(text, style: TextStyle(fontWeight: header ? FontWeight.w700 : FontWeight.w400))));
}


class _ImportSelection {
  const _ImportSelection({required this.worksheet, required this.rollColumn, required this.nameColumn, required this.mode});
  final String worksheet;
  final String rollColumn;
  final String nameColumn;
  final ImportMode mode;
}

class _ImportMappingDialog extends StatefulWidget {
  const _ImportMappingDialog({required this.workbook});
  final ExcelRegisterWorkbook workbook;

  @override
  State<_ImportMappingDialog> createState() => _ImportMappingDialogState();
}

class _ImportMappingDialogState extends State<_ImportMappingDialog> {
  late String worksheet = widget.workbook.sheetNames.first;
  String? rollColumn;
  String? nameColumn;
  ImportMode mode = ImportMode.replace;

  @override
  Widget build(BuildContext context) {
    final columns = widget.workbook.columns(worksheet);
    rollColumn ??= columns.contains('Roll Number') ? 'Roll Number' : columns.firstOrNull;
    nameColumn ??= columns.contains('Student Name') ? 'Student Name' : (columns.length > 1 ? columns[1] : columns.firstOrNull);
    return AlertDialog(
      title: const Text('Import Students from Excel'),
      content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        DropdownButtonFormField<String>(value: worksheet, decoration: const InputDecoration(labelText: 'Worksheet'), items: [for (final sheet in widget.workbook.sheetNames) DropdownMenuItem(value: sheet, child: Text(sheet))], onChanged: (value) => setState(() { worksheet = value!; rollColumn = null; nameColumn = null; })),
        DropdownButtonFormField<String>(value: rollColumn, decoration: const InputDecoration(labelText: 'Roll Number column'), items: [for (final column in columns) DropdownMenuItem(value: column, child: Text(column))], onChanged: (value) => setState(() => rollColumn = value)),
        DropdownButtonFormField<String>(value: nameColumn, decoration: const InputDecoration(labelText: 'Student Name column'), items: [for (final column in columns) DropdownMenuItem(value: column, child: Text(column))], onChanged: (value) => setState(() => nameColumn = value)),
        RadioListTile<ImportMode>(value: ImportMode.replace, groupValue: mode, onChanged: (value) => setState(() => mode = value!), title: const Text('Replace Existing')),
        RadioListTile<ImportMode>(value: ImportMode.append, groupValue: mode, onChanged: (value) => setState(() => mode = value!), title: const Text('Append')),
      ]),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: rollColumn == null || nameColumn == null ? null : () => Navigator.pop(context, _ImportSelection(worksheet: worksheet, rollColumn: rollColumn!, nameColumn: nameColumn!, mode: mode)), child: const Text('Import')),
      ],
    );
  }
}
