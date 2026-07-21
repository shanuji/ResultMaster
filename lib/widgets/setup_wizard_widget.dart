
import 'package:flutter/material.dart';
import '../models/data_models.dart';
import '../utils/ux_helpers.dart';

class SetupWizardWidget extends StatefulWidget {
  final List<Color> palette; 
  final String? initialTitle; 
  final List<SubjectSetup>? initialSubjects; 
  final Function(String, List<SubjectSetup>) onSetupComplete;

  const SetupWizardWidget({super.key, required this.palette, this.initialTitle, this.initialSubjects, required this.onSetupComplete});

  @override
  State<SetupWizardWidget> createState() => _SetupWizardWidgetState();
}

class _SetupWizardWidgetState extends State<SetupWizardWidget> {
  late String _wizardTitle; 
  late List<SubjectSetup> _subjects;

  @override
  void initState() {
    super.initState(); 
    _wizardTitle = widget.initialTitle ?? "";
    if (widget.initialSubjects != null) { 
      _subjects = widget.initialSubjects!.map((s) => SubjectSetup(
        name: s.name, 
        maxMarks: s.maxMarks, 
        passingMarks: s.passingMarks, 
        includeInPassFail: s.includeInPassFail, 
        requirePassPerComponent: s.requirePassPerComponent, 
        themeColor: s.themeColor, 
        components: s.components.map((c) => SubjectComponent(name: c.name, maxMarks: c.maxMarks, passingMarks: c.passingMarks)).toList()
      )).toList(); 
    } else { 
      _subjects = [
        SubjectSetup(name: "ENG.", maxMarks: 100, passingMarks: 33, themeColor: widget.palette[0]), 
        SubjectSetup(name: "HINDI", maxMarks: 100, passingMarks: 33, themeColor: widget.palette[1])
      ]; 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 24, left: 16, right: 16), 
      height: MediaQuery.of(context).size.height * 0.88,
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(widget.initialTitle != null ? 'Edit Setup' : 'Configure Setup', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]),
          AutoSelectTextField(initialValue: _wizardTitle, decoration: const InputDecoration(hintText: 'e.g. Class 3 Assessment', labelText: 'Workbook Title', border: OutlineInputBorder(), floatingLabelBehavior: FloatingLabelBehavior.always), onChanged: (val) => _wizardTitle = val), 
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                ..._subjects.asMap().entries.map((entry) {
                  int index = entry.key; var sub = entry.value;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0), 
                    child: Container(
                      decoration: BoxDecoration(border: Border(left: BorderSide(color: sub.themeColor, width: 6))), 
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [Expanded(child: AutoSelectTextField(initialValue: sub.name, decoration: const InputDecoration(hintText: 'e.g. Math, Science', labelText: 'Subject Name', labelStyle: TextStyle(fontWeight: FontWeight.bold), floatingLabelBehavior: FloatingLabelBehavior.always), onChanged: (val) => sub.name = val)), IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _subjects.removeAt(index)))]),
                          Row(children: [Expanded(child: AutoSelectTextField(key: ValueKey('${sub.name}_max_${sub.components.length}'), initialValue: sub.maxMarks.toStringAsFixed(0), decoration: InputDecoration(labelText: 'Max Marks', filled: sub.components.isNotEmpty, fillColor: Colors.grey[200]), keyboardType: TextInputType.number, enabled: sub.components.isEmpty, onChanged: (val) => sub.maxMarks = double.tryParse(val) ?? 100.0)), const SizedBox(width: 12), Expanded(child: AutoSelectTextField(initialValue: sub.passingMarks.toStringAsFixed(0), decoration: const InputDecoration(labelText: 'Pass Marks'), keyboardType: TextInputType.number, onChanged: (val) => sub.passingMarks = double.tryParse(val) ?? 33.0))]),
                          const SizedBox(height: 8), 
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Bifurcations (Theory/Prac):', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)), TextButton.icon(onPressed: () => setState(() { sub.components.add(SubjectComponent(name: '', maxMarks: 50)); sub.recalculateMaxMarks(); }), icon: const Icon(Icons.add, size: 16), label: const Text('Add Component'))]),
                          
                          if (sub.components.isNotEmpty) ...[
                            SwitchListTile(title: const Text('Components require individual passing marks', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)), value: sub.requirePassPerComponent, activeColor: sub.themeColor, onChanged: (val) => setState(() => sub.requirePassPerComponent = val), dense: true, contentPadding: EdgeInsets.zero),
                            ...sub.components.asMap().entries.map((cEntry) { 
                              int cIdx = cEntry.key; var comp = cEntry.value; 
                              return Padding(padding: const EdgeInsets.only(left: 16.0, top: 4.0), child: Row(children: [
                                Expanded(flex: 2, child: AutoSelectTextField(initialValue: comp.name, decoration: const InputDecoration(hintText: 'e.g. Theory, Prac', labelText: 'Comp. Name', isDense: true, floatingLabelBehavior: FloatingLabelBehavior.always), onChanged: (val) => comp.name = val)), 
                                const SizedBox(width: 8), 
                                Expanded(child: AutoSelectTextField(initialValue: comp.maxMarks.toStringAsFixed(0), decoration: const InputDecoration(labelText: 'Max', isDense: true), keyboardType: TextInputType.number, onChanged: (val) { comp.maxMarks = double.tryParse(val) ?? 0.0; setState(() => sub.recalculateMaxMarks()); })), 
                                if (sub.requirePassPerComponent) ...[
                                  const SizedBox(width: 8),
                                  Expanded(child: AutoSelectTextField(initialValue: comp.passingMarks.toStringAsFixed(0), decoration: const InputDecoration(labelText: 'Pass', isDense: true), keyboardType: TextInputType.number, onChanged: (val) => comp.passingMarks = double.tryParse(val) ?? 0.0)), 
                                ],
                                IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => setState(() { sub.components.removeAt(cIdx); sub.recalculateMaxMarks(); }))
                              ])); 
                            })
                          ],
                          SwitchListTile(title: const Text('Count towards Final Pass/Fail', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)), value: sub.includeInPassFail, activeColor: sub.themeColor, onChanged: (val) => setState(() => sub.includeInPassFail = val), dense: true, contentPadding: EdgeInsets.zero)
                        ],
                      ),
                    ),
                  );
                }).toList(),
                OutlinedButton.icon(onPressed: () => setState(() => _subjects.add(SubjectSetup(name: "", themeColor: widget.palette[_subjects.length % widget.palette.length]))), icon: const Icon(Icons.add_circle_outline), label: const Text('Add Another Subject'))
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.symmetric(vertical: 12.0), child: ElevatedButton(style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)), onPressed: () { Navigator.pop(context); widget.onSetupComplete(_wizardTitle, _subjects); }, child: Text(widget.initialTitle != null ? 'Save Changes' : 'Save Setup & Build Sheets', style: const TextStyle(fontSize: 16))))
        ],
      ),
    );
  }
}
