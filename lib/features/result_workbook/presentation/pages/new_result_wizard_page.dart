import 'package:flutter/material.dart';

import '../../domain/entities/result_workbook.dart';
import '../../domain/usecases/create_result_workbook.dart';

class NewResultWizardPage extends StatefulWidget {
  const NewResultWizardPage({super.key, required this.createWorkbook});

  final CreateResultWorkbook createWorkbook;

  @override
  State<NewResultWizardPage> createState() => _NewResultWizardPageState();
}

class _NewResultWizardPageState extends State<NewResultWizardPage> {
  final _formKey = GlobalKey<FormState>();
  final _year = TextEditingController(text: '2026-27');
  final _className = TextEditingController(text: 'III');
  final _section = TextEditingController(text: 'A');
  final _exam = TextEditingController(text: 'Periodic Test 1');
  final _classRegisterId = TextEditingController();
  StudentSourceType _source = StudentSourceType.newList;
  final List<Student> _students = <Student>[];
  final List<SubjectConfig> _subjects = <SubjectConfig>[
    const SubjectConfig(name: 'English', components: <AssessmentComponent>[
      AssessmentComponent(name: 'FA'),
      AssessmentComponent(name: 'Notebook'),
      AssessmentComponent(name: 'Project'),
      AssessmentComponent(name: 'Half Yearly'),
    ]),
  ];
  final Set<String> _passSubjects = <String>{'English'};
  final Map<String, TextEditingController> _passMarks = <String, TextEditingController>{
    'English': TextEditingController(text: '33'),
  };
  int _currentStep = 0;
  bool _saving = false;

  @override
  void dispose() {
    _year.dispose();
    _className.dispose();
    _section.dispose();
    _exam.dispose();
    _classRegisterId.dispose();
    for (final controller in _passMarks.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Result Workbook')),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepTapped: (step) => setState(() => _currentStep = step),
          controlsBuilder: _controls,
          steps: <Step>[
            Step(title: const Text('Basic Details'), content: _basicDetails()),
            Step(title: const Text('Student Source'), content: _studentSource()),
            Step(title: const Text('Subjects'), content: _subjectsStep()),
            Step(title: const Text('Pass Criteria'), content: _passCriteria()),
            Step(title: const Text('Confirmation'), content: _confirmation()),
          ],
        ),
      ),
    );
  }

  Widget _controls(BuildContext context, ControlsDetails details) {
    final isLastStep = _currentStep == 4;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Wrap(spacing: 12, children: <Widget>[
        if (_currentStep > 0)
          OutlinedButton(
            onPressed: _saving ? null : () => setState(() => _currentStep--),
            child: const Text('Back'),
          ),
        FilledButton.icon(
          onPressed: _saving
              ? null
              : isLastStep
                  ? _createWorkbook
                  : () => setState(() => _currentStep++),
          icon: _saving
              ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator())
              : Icon(isLastStep ? Icons.save : Icons.navigate_next),
          label: Text(isLastStep ? 'Create Workbook' : 'Next'),
        ),
      ]),
    );
  }

  Widget _basicDetails() => Column(children: <Widget>[
        _field(_year, 'Academic Year', '2026-27'),
        _field(_className, 'Class', 'III'),
        _field(_section, 'Section', 'A'),
        _field(_exam, 'Examination Name', 'Periodic Test 1'),
      ]);

  Widget _studentSource() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        RadioListTile<StudentSourceType>(
          value: StudentSourceType.newList,
          groupValue: _source,
          onChanged: (value) => setState(() => _source = value!),
          title: const Text('Create a new student list'),
        ),
        RadioListTile<StudentSourceType>(
          value: StudentSourceType.classRegister,
          groupValue: _source,
          onChanged: (value) => setState(() => _source = value!),
          title: const Text('Use an existing Class Register'),
          subtitle: const Text('Students are imported with preserved roll numbers when a register is selected.'),
        ),
        if (_source == StudentSourceType.classRegister)
          TextFormField(
            controller: _classRegisterId,
            decoration: const InputDecoration(labelText: 'Class Register ID'),
            keyboardType: TextInputType.number,
            validator: (value) => _source == StudentSourceType.classRegister && int.tryParse(value ?? '') == null
                ? 'Select an existing Class Register'
                : null,
          ),
        OutlinedButton.icon(onPressed: _addStudent, icon: const Icon(Icons.person_add), label: const Text('Add Student')),
        ..._students.map((s) => ListTile(title: Text('${s.rollNumber}. ${s.name}'))),
      ]);

  Widget _subjectsStep() => Column(children: <Widget>[
        for (var i = 0; i < _subjects.length; i++) Card(
          child: ListTile(
            title: Text(_subjects[i].name),
            subtitle: Text('${_subjects[i].components.map((c) => c.name).join(' + ')} = TOTAL (read-only)'),
            trailing: Wrap(children: <Widget>[
              IconButton(onPressed: i == 0 ? null : () => _moveSubject(i, -1), icon: const Icon(Icons.arrow_upward)),
              IconButton(onPressed: i == _subjects.length - 1 ? null : () => _moveSubject(i, 1), icon: const Icon(Icons.arrow_downward)),
              IconButton(onPressed: () => _editSubject(i), icon: const Icon(Icons.edit)),
              IconButton(onPressed: () => setState(() => _subjects.removeAt(i)), icon: const Icon(Icons.delete)),
            ]),
          ),
        ),
        OutlinedButton.icon(onPressed: () => _editSubject(null), icon: const Icon(Icons.add), label: const Text('Add Subject')),
      ]);

  Widget _passCriteria() => Column(children: _subjects.map((subject) {
        _passMarks.putIfAbsent(subject.name, () => TextEditingController(text: '33'));
        return CheckboxListTile(
          value: _passSubjects.contains(subject.name),
          onChanged: (value) => setState(() => value! ? _passSubjects.add(subject.name) : _passSubjects.remove(subject.name)),
          title: Text(subject.name),
          subtitle: TextFormField(
            controller: _passMarks[subject.name],
            decoration: const InputDecoration(labelText: 'Pass marks or pass percentage'),
            keyboardType: TextInputType.number,
          ),
        );
      }).toList());

  Widget _confirmation() => Align(
        alignment: Alignment.centerLeft,
        child: Text('''Basic Details: ${_year.text}, Class ${_className.text}-${_section.text}, ${_exam.text}
Student Source: ${_source == StudentSourceType.newList ? 'New student list' : 'Existing Class Register #${_classRegisterId.text}'}
Subjects: ${_subjects.map((s) => '${s.name} (${s.components.map((c) => c.name).join(', ')}, TOTAL)').join('; ')}
Pass Criteria: ${_passSubjects.map((s) => '$s: ${_passMarks[s]?.text ?? ''}').join('; ')}'''),
      );

  Widget _field(TextEditingController controller, String label, String example) => TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, hintText: example),
        validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
      );

  Future<void> _addStudent() async => setState(() => _students.add(Student(rollNumber: _students.length + 1, name: 'Student ${_students.length + 1}')));

  Future<void> _editSubject(int? index) async {
    final name = TextEditingController(text: index == null ? '' : _subjects[index].name);
    final components = TextEditingController(text: index == null ? '' : _subjects[index].components.map((c) => c.name).join('\n'));
    final result = await showDialog<SubjectConfig>(context: context, builder: (context) => AlertDialog(
      title: Text(index == null ? 'Add Subject' : 'Rename Subject / Components'),
      content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Subject name')),
        TextField(controller: components, decoration: const InputDecoration(labelText: 'Assessment components, one per line'), minLines: 3, maxLines: 6),
      ]),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, SubjectConfig(
          name: name.text.trim(),
          components: components.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).map((e) => AssessmentComponent(name: e)).toList(),
        )), child: const Text('Save')),
      ],
    ));
    if (result != null && result.name.isNotEmpty && result.components.isNotEmpty) {
      setState(() => index == null ? _subjects.add(result) : _subjects[index] = result);
    }
  }

  void _moveSubject(int index, int delta) => setState(() {
        final subject = _subjects.removeAt(index);
        _subjects.insert(index + delta, subject);
      });

  Future<void> _createWorkbook() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final criteria = _passSubjects.map((subject) => PassCriterion(subjectName: subject, passMarks: double.tryParse(_passMarks[subject]?.text ?? ''))).toList();
    try {
      final created = await widget.createWorkbook(ResultWorkbookDraft(
        academicYear: _year.text.trim(), className: _className.text.trim(), section: _section.text.trim(), examinationName: _exam.text.trim(),
        studentSourceType: _source, classRegisterId: int.tryParse(_classRegisterId.text), subjects: _subjects, passCriteria: criteria, newStudents: _students,
      ));
      if (mounted) Navigator.pop(context, created);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
