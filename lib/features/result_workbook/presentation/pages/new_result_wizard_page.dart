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
      appBar: AppBar(
        title: const Text('New Result Workbook', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
      ),
      body: Form(
        key: _formKey,
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Theme.of(context).primaryColor),
          ),
          child: Stepper(
            type: StepperType.vertical,
            physics: const BouncingScrollPhysics(),
            currentStep: _currentStep,
            onStepTapped: (step) => setState(() => _currentStep = step),
            controlsBuilder: _controls,
            steps: <Step>[
              Step(
                title: const Text('Basic Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), 
                content: _basicDetails(),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: const Text('Student Source', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), 
                content: _studentSource(),
                isActive: _currentStep >= 1,
                state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: const Text('Subjects', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), 
                content: _subjectsStep(),
                isActive: _currentStep >= 2,
                state: _currentStep > 2 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: const Text('Pass Criteria', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), 
                content: _passCriteria(),
                isActive: _currentStep >= 3,
                state: _currentStep > 3 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: const Text('Confirmation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), 
                content: _confirmation(),
                isActive: _currentStep >= 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _controls(BuildContext context, ControlsDetails details) {
    final isLastStep = _currentStep == 4;
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _saving
                  ? null
                  : isLastStep
                      ? _createWorkbook
                      : () => setState(() => _currentStep++),
              icon: _saving
                  ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(isLastStep ? Icons.check_circle : Icons.arrow_forward),
              label: Text(isLastStep ? 'Create Workbook' : 'Continue', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          if (_currentStep > 0) ...[
            const SizedBox(width: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _saving ? null : () => setState(() => _currentStep--),
              child: const Text('Back', style: TextStyle(fontSize: 16)),
            ),
          ]
        ],
      ),
    );
  }

  // Added SizedBox for proper spacing between fields
  Widget _basicDetails() => Column(
    children: <Widget>[
      const SizedBox(height: 8),
      _field(_year, 'Academic Year', '2026-27', Icons.calendar_today),
      const SizedBox(height: 16),
      _field(_className, 'Class', 'III', Icons.school),
      const SizedBox(height: 16),
      _field(_section, 'Section', 'A', Icons.group),
      const SizedBox(height: 16),
      _field(_exam, 'Examination Name', 'Periodic Test 1', Icons.assignment),
    ]);

  Widget _studentSource() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Card(
          elevation: 0,
          color: Colors.grey.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: Column(
            children: [
              RadioListTile<StudentSourceType>(
                value: StudentSourceType.newList,
                groupValue: _source,
                onChanged: (value) => setState(() => _source = value!),
                title: const Text('Create a new student list', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const Divider(height: 1),
              RadioListTile<StudentSourceType>(
                value: StudentSourceType.classRegister,
                groupValue: _source,
                onChanged: (value) => setState(() => _source = value!),
                title: const Text('Use existing Class Register', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Imports students with preserved roll numbers.'),
              ),
            ],
          ),
        ),
        if (_source == StudentSourceType.classRegister) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _classRegisterId,
            decoration: InputDecoration(
              labelText: 'Class Register ID',
              prefixIcon: const Icon(Icons.numbers),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            keyboardType: TextInputType.number,
            validator: (value) => _source == StudentSourceType.classRegister && int.tryParse(value ?? '') == null
                ? 'Select an existing Class Register'
                : null,
          ),
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: _addStudent, 
          icon: const Icon(Icons.person_add), 
          label: const Text('Add Student')
        ),
        const SizedBox(height: 8),
        ..._students.map((s) => ListTile(
          leading: CircleAvatar(backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1), child: Text('${s.rollNumber}')),
          title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w500)),
        )),
      ]);

  Widget _subjectsStep() => Column(children: <Widget>[
        for (var i = 0; i < _subjects.length; i++) Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(_subjects[i].name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('${_subjects[i].components.map((c) => c.name).join(' + ')} = TOTAL', style: TextStyle(color: Colors.grey.shade700)),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(onPressed: i == 0 ? null : () => _moveSubject(i, -1), icon: const Icon(Icons.arrow_upward, size: 20)),
                IconButton(onPressed: i == _subjects.length - 1 ? null : () => _moveSubject(i, 1), icon: const Icon(Icons.arrow_downward, size: 20)),
                IconButton(onPressed: () => _editSubject(i), icon: const Icon(Icons.edit, size: 20, color: Colors.blue)),
                IconButton(onPressed: () => setState(() => _subjects.removeAt(i)), icon: const Icon(Icons.delete, size: 20, color: Colors.red)),
              ]),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
          ),
          onPressed: () => _editSubject(null), 
          icon: const Icon(Icons.add), 
          label: const Text('Add Subject')
        ),
      ]);

  Widget _passCriteria() => Column(children: _subjects.map((subject) {
        _passMarks.putIfAbsent(subject.name, () => TextEditingController(text: '33'));
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CheckboxListTile(
              value: _passSubjects.contains(subject.name),
              onChanged: (value) => setState(() => value! ? _passSubjects.add(subject.name) : _passSubjects.remove(subject.name)),
              title: Text(subject.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
                child: TextFormField(
                  controller: _passMarks[subject.name],
                  decoration: InputDecoration(
                    labelText: 'Pass marks / %',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ),
          ),
        );
      }).toList());

  Widget _confirmation() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2))
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _confirmRow(Icons.info_outline, 'Basic Details', '${_year.text} | Class ${_className.text}-${_section.text} | ${_exam.text}'),
            const Divider(height: 24),
            _confirmRow(Icons.people_alt_outlined, 'Student Source', _source == StudentSourceType.newList ? 'New student list' : 'Class Register #${_classRegisterId.text}'),
            const Divider(height: 24),
            _confirmRow(Icons.menu_book, 'Subjects (${_subjects.length})', _subjects.map((s) => s.name).join(', ')),
          ],
        ),
      );

  Widget _confirmRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        )
      ],
    );
  }

  // Upgraded text field with rounded borders and icons
  Widget _field(TextEditingController controller, String label, String example, IconData icon) => TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label, 
          hintText: example,
          prefixIcon: Icon(icon, color: Colors.grey.shade600),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
      );

  Future<void> _addStudent() async => setState(() => _students.add(Student(rollNumber: _students.length + 1, name: 'Student ${_students.length + 1}')));

  Future<void> _editSubject(int? index) async {
    final name = TextEditingController(text: index == null ? '' : _subjects[index].name);
    final components = TextEditingController(text: index == null ? '' : _subjects[index].components.map((c) => c.name).join('\n'));
    final result = await showDialog<SubjectConfig>(context: context, builder: (context) => AlertDialog(
      title: Text(index == null ? 'Add Subject' : 'Edit Subject', style: const TextStyle(fontWeight: FontWeight.bold)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        TextField(controller: name, decoration: InputDecoration(labelText: 'Subject name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 16),
        TextField(controller: components, decoration: InputDecoration(labelText: 'Assessment components (one per line)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), minLines: 3, maxLines: 6),
      ]),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          onPressed: () => Navigator.pop(context, SubjectConfig(
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
