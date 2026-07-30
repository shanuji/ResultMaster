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
    // FIX: No longer adding "Subject 1" and "Subject 2" by default to match clean mockup.
    if (_subjects.isEmpty) { _subjects.add(SubjectSetup(name: '', themeColor: widget.palette[0])); }
  }

  void _confirmDelete(String message, VoidCallback onDelete) { showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Confirm Deletion'), content: Text(message), actions: [ TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), TextButton(onPressed: () { Navigator.pop(context); onDelete(); }, child: const Text('Delete', style: TextStyle(color: Colors.red))) ])); }
  void _addSubject() { setState(() { _subjects.add(SubjectSetup(name: '', themeColor: widget.palette[_subjects.length % widget.palette.length])); }); }
  void _removeSubject(int index) { _confirmDelete("Delete entire subject?", () => setState(() => _subjects.removeAt(index))); }
  void _addComponent(int subjectIndex) { setState(() { _subjects[subjectIndex].components.add(SubjectComponent(name: '', maxMarks: 0)); }); }
  void _removeComponent(int subjectIndex, int componentIndex) { _confirmDelete("Delete this component?", () => setState(() { _subjects[subjectIndex].components.removeAt(componentIndex); _subjects[subjectIndex].recalculateMaxMarks(); })); }

  InputDecoration _customInputDecoration(String label) {
    return InputDecoration(
      labelText: label, isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Container(
            width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.info, color: Colors.blue, size: 28), const SizedBox(width: 12),
              Expanded(child: RichText(text: const TextSpan(style: TextStyle(color: Colors.blue, fontSize: 13, height: 1.4), children: [TextSpan(text: 'These subjects apply automatically to every term.', style: TextStyle(fontWeight: FontWeight.bold))]))),
            ]),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: _subjects.length, itemBuilder: (context, index) {
              final sub = _subjects[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12), elevation: 0, color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: sub.themeColor, width: 1.5)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [ Expanded(child: TextFormField(initialValue: sub.name, decoration: _customInputDecoration('Subject Name'), onChanged: (val) => sub.name = val)), IconButton(icon: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(4)), child: const Icon(Icons.delete, color: Colors.white, size: 16)), onPressed: () => _removeSubject(index)) ]),
                      const SizedBox(height: 12),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Include in Pass/Fail', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Switch(value: sub.includeInPassFail, activeColor: Theme.of(context).colorScheme.primary, onChanged: (val) => setState(() => sub.includeInPassFail = val))]),
                      if (sub.components.isEmpty) ...[
                        const SizedBox(height: 8),
                        Row(children: [ Expanded(child: TextFormField(initialValue: sub.maxMarks.toString(), decoration: _customInputDecoration('Max Marks'), keyboardType: TextInputType.number, onChanged: (val) => sub.maxMarks = double.tryParse(val) ?? 100.0)), const SizedBox(width: 12), Expanded(child: TextFormField(initialValue: sub.passingMarks.toString(), decoration: _customInputDecoration('Pass Marks'), keyboardType: TextInputType.number, onChanged: (val) => sub.passingMarks = double.tryParse(val) ?? 33.0)) ]),
                      ] else ...[
                        const SizedBox(height: 8), const Text('Components (Theory, Practical, etc.)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), const Text('Hint: Passing marks = 0 means component is ignored.', style: TextStyle(fontSize: 11, color: Colors.grey)), const SizedBox(height: 8),
                        Row(children: [ Expanded(flex: 2, child: Text('Comp. Name', style: TextStyle(fontSize: 11, color: Colors.grey.shade600))), const SizedBox(width: 8), Expanded(child: Text('Max', style: TextStyle(fontSize: 11, color: Colors.grey.shade600))), const SizedBox(width: 8), Expanded(child: Text('Pass', style: TextStyle(fontSize: 11, color: Colors.grey.shade600))), const SizedBox(width: 32) ]),
                        const Divider(height: 8),
                        ...sub.components.asMap().entries.map((cEntry) {
                          int cIdx = cEntry.key; var comp = cEntry.value;
                          return Padding(padding: const EdgeInsets.only(top: 8.0), child: Row(children: [ Expanded(flex: 2, child: TextFormField(initialValue: comp.name, decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.only(bottom: 4)), onChanged: (val) => comp.name = val)), const SizedBox(width: 8), Expanded(child: TextFormField(initialValue: comp.maxMarks.toString(), decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.only(bottom: 4)), keyboardType: TextInputType.number, onChanged: (val) { setState(() { comp.maxMarks = double.tryParse(val) ?? 0.0; sub.recalculateMaxMarks(); }); })), const SizedBox(width: 8), Expanded(child: TextFormField(initialValue: comp.passingMarks > 0 ? comp.passingMarks.toString() : "", decoration: const InputDecoration(hintText: '0', isDense: true, contentPadding: EdgeInsets.only(bottom: 4)), keyboardType: TextInputType.number, onChanged: (val) => comp.passingMarks = double.tryParse(val) ?? 0.0)), IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20), onPressed: () => _removeComponent(index, cIdx), padding: EdgeInsets.zero, constraints: const BoxConstraints()) ]));
                        }),
                      ],
                      const SizedBox(height: 12), Center(child: TextButton.icon(onPressed: () => _addComponent(index), icon: const Icon(Icons.add_circle_outline, size: 18), label: const Text('Add Component'))),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(padding: const EdgeInsets.all(12.0), child: Row(children: [ Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(side: BorderSide(color: Theme.of(context).colorScheme.primary), padding: const EdgeInsets.symmetric(vertical: 12), foregroundColor: Theme.of(context).colorScheme.primary), onPressed: _addSubject, icon: const Icon(Icons.add), label: const Text('Add Subject'))), const SizedBox(width: 12), Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)), onPressed: () => widget.onSetupComplete("Global", _subjects), icon: const Icon(Icons.save), label: const Text('Save Setup'))), ]))
      ],
    );
  }
}
