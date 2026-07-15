import 'dart:io';

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

  Future<void> _importExcel() async {
    final selectedRegister = controller.selected;
    if (selectedRegister == null) return;
    await _run(() async {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);
      final path = result?.files.single.path;
      if (path == null) return;

      final codec = ExcelRegisterCodec();
      final workbook = await codec.inspectFile(File(path));
      if (!mounted) return;
      final config = await showDialog<_ImportConfig>(
        context: context,
        builder: (_) => _ImportMappingDialog(workbook: workbook),
      );
      if (config == null) return;

      final preview = await codec.previewImport(
        file: workbook.file,
        sheetName: config.sheet.name,
        rollNumberColumn: config.rollNumberColumn.index,
        studentNameColumn: config.studentNameColumn.index,
        registerId: selectedRegister.id,
      );
      final summary = await controller.importStudents(
        preview.students,
        mode: config.mode,
        skipped: preview.skipped,
        duplicateRollNumbers: preview.duplicateRollNumbers,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Import Summary'),
          content: Text(
            'Imported: ${summary.imported}\n'
            'Skipped: ${summary.skipped}\n'
            'Duplicates: ${summary.duplicates}'
            '${summary.duplicateRollNumbers.isEmpty ? '' : '\n\nDuplicate Roll Numbers: ${summary.duplicateRollNumbers.join(', ')}'}',
          ),
          actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    try { await action(); } catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error'))); }
  }
}

class _ImportConfig {
  const _ImportConfig({required this.sheet, required this.rollNumberColumn, required this.studentNameColumn, required this.mode});
  final ExcelRegisterSheet sheet;
  final ExcelRegisterColumn rollNumberColumn;
  final ExcelRegisterColumn studentNameColumn;
  final ClassRegisterImportMode mode;
}

class _ImportMappingDialog extends StatefulWidget {
  const _ImportMappingDialog({required this.workbook});
  final ExcelRegisterWorkbook workbook;

  @override
  State<_ImportMappingDialog> createState() => _ImportMappingDialogState();
}

class _ImportMappingDialogState extends State<_ImportMappingDialog> {
  late ExcelRegisterSheet sheet = widget.workbook.sheets.first;
  late ExcelRegisterColumn rollColumn = _preferredColumn('Roll Number') ?? sheet.columns.first;
  late ExcelRegisterColumn nameColumn = _preferredColumn('Student Name') ?? (sheet.columns.length > 1 ? sheet.columns[1] : sheet.columns.first);
  ClassRegisterImportMode mode = ClassRegisterImportMode.append;

  ExcelRegisterColumn? _preferredColumn(String header) {
    for (final column in sheet.columns) {
      if (column.header.toLowerCase() == header.toLowerCase()) return column;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Import Students from Excel'),
        content: SizedBox(
          width: 420,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<ExcelRegisterSheet>(
              value: sheet,
              decoration: const InputDecoration(labelText: 'Worksheet'),
              items: [for (final item in widget.workbook.sheets) DropdownMenuItem(value: item, child: Text(item.name))],
              onChanged: (value) => setState(() {
                sheet = value!;
                rollColumn = _preferredColumn('Roll Number') ?? sheet.columns.first;
                nameColumn = _preferredColumn('Student Name') ?? (sheet.columns.length > 1 ? sheet.columns[1] : sheet.columns.first);
              }),
            ),
            DropdownButtonFormField<ExcelRegisterColumn>(
              value: rollColumn,
              decoration: const InputDecoration(labelText: 'Roll Number column'),
              items: [for (final column in sheet.columns) DropdownMenuItem(value: column, child: Text(column.label))],
              onChanged: (value) => setState(() => rollColumn = value!),
            ),
            DropdownButtonFormField<ExcelRegisterColumn>(
              value: nameColumn,
              decoration: const InputDecoration(labelText: 'Student Name column'),
              items: [for (final column in sheet.columns) DropdownMenuItem(value: column, child: Text(column.label))],
              onChanged: (value) => setState(() => nameColumn = value!),
            ),
            RadioListTile<ClassRegisterImportMode>(
              value: ClassRegisterImportMode.append,
              groupValue: mode,
              onChanged: (value) => setState(() => mode = value!),
              title: const Text('Append'),
              contentPadding: EdgeInsets.zero,
            ),
            RadioListTile<ClassRegisterImportMode>(
              value: ClassRegisterImportMode.replaceExisting,
              groupValue: mode,
              onChanged: (value) => setState(() => mode = value!),
              title: const Text('Replace Existing'),
              contentPadding: EdgeInsets.zero,
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: rollColumn.index == nameColumn.index ? null : () => Navigator.pop(context, _ImportConfig(sheet: sheet, rollNumberColumn: rollColumn, studentNameColumn: nameColumn, mode: mode)),
            child: const Text('Import'),
          ),
        ],
      );
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
