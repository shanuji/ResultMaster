import 'package:flutter/material.dart';
import '../models/data_models.dart';

class SetupWizardWidget extends StatefulWidget {
  final List<Color> palette;
  final List<SubjectSetup>? initialSubjects;
  final Function(String, List<SubjectSetup>) onSetupComplete;
  const SetupWizardWidget({super.key, required this.palette, required this.onSetupComplete, this.initialSubjects});
  @override
  State<SetupWizardWidget> createState() => _SetupWizardWidgetState();
}

class _SetupWizardWidgetState extends State<SetupWizardWidget> {
  late List<SubjectSetup> _subjects;

  @override
  void initState() {
    super.initState();
    _subjects = widget.initialSubjects != null ? List.from(widget.initialSubjects!) : [];
    if (_subjects.isEmpty) {
      _subjects.add(SubjectSetup(name: 'Subject 1', themeColor: widget.palette[0]));
      _subjects.add(SubjectSetup(name: 'Subject 2', themeColor: widget.palette[1]));
    }
  }

  void _confirmDelete(String message, VoidCallback onDelete) {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Confirm Deletion'), content: Text(message),
      actions: [ TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), TextButton(onPressed: () { Navigator.pop(context); onDelete(); }, child: const Text('Delete', style: TextStyle(color: Colors.red))) ]
    ));
  }

  void _addSubject() { setState(() { _subjects.add(SubjectSetup(name: '', themeColor: widget.palette[_subjects.length % widget.palette.length])); }); }
  void _removeSubject(int index) { _confirmDelete("Are you sure you want to delete this entire subject and all its marks?", () => setState(() => _subjects.removeAt(index))); }
  void _addComponent(int subjectIndex) { setState(() { _subjects[subjectIndex].components.add(SubjectComponent(name: '', maxMarks: 0)); }); }
  void _removeComponent(int subjectIndex, int componentIndex) { _confirmDelete("Are you sure you want to delete this component?", () => setState(() { _subjects[subjectIndex].components.removeAt(componentIndex); _subjects[subjectIndex].recalculateMaxMarks(); })); }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(width: double.infinity, color: Colors.blue[50], padding: const EdgeInsets.all(12), child: const Text('These subjects are GLOBAL. They will automatically apply to every Term you create.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue), textAlign: TextAlign.center)),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16), itemCount: _subjects.length, itemBuilder: (context, index) {
              final sub = _subjects[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16), elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: sub.themeColor, width: 2)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [ Expanded(child: TextFormField(initialValue: sub.name, decoration: const InputDecoration(labelText: 'Subject Name', border: OutlineInputBorder()), onChanged: (val) => sub.name = val)), IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeSubject(index)) ]),
                      const SizedBox(height: 16),
                      SwitchListTile(title: const Text('Include in Final Pass/Fail'), value: sub.includeInPassFail, onChanged: (val) => setState(() => sub.includeInPassFail = val)),
                      if (sub.components.isEmpty) ...[
                        Row(children: [ Expanded(child: TextFormField(initialValue: sub.maxMarks.toString(), decoration: const InputDecoration(labelText: 'Max Marks'), keyboardType: TextInputType.number, onChanged: (val) => sub.maxMarks = double.tryParse(val) ?? 100.0)), const SizedBox(width: 16), Expanded(child: TextFormField(initialValue: sub.passingMarks.toString(), decoration: const InputDecoration(labelText: 'Passing Marks'), keyboardType: TextInputType.number, onChanged: (val) => sub.passingMarks = double.tryParse(val) ?? 33.0)) ]),
                      ] else ...[
                        const Divider(), const Text('Components (Theory, Practical, etc.)', style: TextStyle(fontWeight: FontWeight.bold)),
                        SwitchListTile(title: const Text('Must pass EACH component to pass subject', style: TextStyle(fontSize: 12)), value: sub.requirePassPerComponent, onChanged: (val) => setState(() => sub.requirePassPerComponent = val), dense: true),
                        ...sub.components.asMap().entries.map((cEntry) {
                          int cIdx = cEntry.key; var comp = cEntry.value;
                          return Padding(padding: const EdgeInsets.only(top: 8.0), child: Row(children: [ Expanded(flex: 2, child: TextFormField(initialValue: comp.name, decoration: const InputDecoration(labelText: 'Component Name', isDense: true), onChanged: (val) => comp.name = val)), const SizedBox(width: 8), Expanded(child: TextFormField(initialValue: comp.maxMarks.toString(), decoration: const InputDecoration(labelText: 'Max M.', isDense: true), keyboardType: TextInputType.number, onChanged: (val) { setState(() { comp.maxMarks = double.tryParse(val) ?? 0.0; sub.recalculateMaxMarks(); }); })), const SizedBox(width: 8), Expanded(child: TextFormField(initialValue: comp.passingMarks.toString(), decoration: const InputDecoration(labelText: 'Pass M.', isDense: true), keyboardType: TextInputType.number, onChanged: (val) => comp.passingMarks = double.tryParse(val) ?? 0.0)), IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () => _removeComponent(index, cIdx), padding: EdgeInsets.zero, constraints: const BoxConstraints()) ]));
                        }),
                      ],
                      const SizedBox(height: 8), TextButton.icon(onPressed: () => _addComponent(index), icon: const Icon(Icons.add_circle_outline), label: const Text('Add Sub-Component')),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0), child: Row(children: [ Expanded(child: OutlinedButton.icon(onPressed: _addSubject, icon: const Icon(Icons.add), label: const Text('Add Subject'))), const SizedBox(width: 16), Expanded(child: ElevatedButton.icon(onPressed: () => widget.onSetupComplete("Global", _subjects), icon: const Icon(Icons.save), label: const Text('Save Global Subjects'))), ]),
        )
      ],
    );
  }
}
