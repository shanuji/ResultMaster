import 'package:flutter/material.dart';
import 'data_models.dart';

// ==========================================
// SETUP WIZARD (BIFURCATION & PASS/FAIL TOGGLE)
// ==========================================
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
  late TextEditingController _titleController;
  late List<SubjectSetup> _subjects;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? "Class 3 Assessment Workspace");
    
    if (widget.initialSubjects != null && widget.initialSubjects!.isNotEmpty) {
      _subjects = List.from(widget.initialSubjects!);
    } else {
      _subjects = [
        SubjectSetup(name: "ENG.", maxMarks: 100, passingMarks: 33, themeColor: widget.palette[0]),
        SubjectSetup(name: "HINDI", maxMarks: 100, passingMarks: 33, themeColor: widget.palette[1]),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Configure Setup', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Workbook Title', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                ..._subjects.asMap().entries.map((entry) {
                  int index = entry.key;
                  SubjectSetup sub = entry.value;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
                    child: Container(
                      decoration: BoxDecoration(border: Border(left: BorderSide(color: sub.themeColor, width: 6))),
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: sub.name,
                                  decoration: const InputDecoration(labelText: 'Subject Name', labelStyle: TextStyle(fontWeight: FontWeight.bold)),
                                  onChanged: (val) => sub.name = val,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => setState(() => _subjects.removeAt(index)),
                              )
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  key: ValueKey('${sub.name}max${sub.components.length}'), 
                                  initialValue: sub.maxMarks.toStringAsFixed(0),
                                  decoration: InputDecoration(labelText: 'Total Max Marks', filled: sub.components.isNotEmpty, fillColor: Colors.grey[200]),
                                  keyboardType: TextInputType.number,
                                  enabled: sub.components.isEmpty, 
                                  onChanged: (val) => sub.maxMarks = double.tryParse(val) ?? 100.0,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  initialValue: sub.passingMarks.toStringAsFixed(0),
                                  decoration: const InputDecoration(labelText: 'Pass Marks'),
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) => sub.passingMarks = double.tryParse(val) ?? 33.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Bifurcations (e.g. Theory/Prac):', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    sub.components.add(SubjectComponent(name: 'Part ${sub.components.length + 1}', maxMarks: 50));
                                    sub.recalculateMaxMarks();
                                  });
                                },
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add Component'),
                              )
                            ],
                          ),
                          if (sub.components.isNotEmpty)
                            ...sub.components.asMap().entries.map((compEntry) {
                              int cIndex = compEntry.key;
                              var comp = compEntry.value;
                              return Padding(
                                padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: comp.name,
                                        decoration: const InputDecoration(labelText: 'Comp. Name', isDense: true),
                                        onChanged: (val) => comp.name = val,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: comp.maxMarks.toStringAsFixed(0),
                                        decoration: const InputDecoration(labelText: 'Max Marks', isDense: true),
                                        keyboardType: TextInputType.number,
                                        onChanged: (val) {
                                          comp.maxMarks = double.tryParse(val) ?? 0.0;
                                          setState(() => sub.recalculateMaxMarks());
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                                      onPressed: () {
                                        setState(() {
                                          sub.components.removeAt(cIndex);
                                          sub.recalculateMaxMarks();
                                        });
                                      },
                                    )
                                  ],
                                ),
                              );
                            }).toList(),
                            
                          const Divider(height: 24),
                          
                          // NEW: Pass/Fail Toggle
                          SwitchListTile(
                            title: const Text('Count towards Final Pass/Fail Result', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: const Text('If off, failing this subject won\'t fail the student.', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                            value: sub.includeInPassFail,
                            activeColor: sub.themeColor,
                            onChanged: (bool value) {
                              setState(() {
                                sub.includeInPassFail = value;
                              });
                            },
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _subjects.add(SubjectSetup(
                          name: "NEW SUBJECT", 
                          maxMarks: 100, 
                          passingMarks: 33, 
                          themeColor: widget.palette[_subjects.length % widget.palette.length]
                        ));
                      });
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Add Another Subject'),
                  ),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              onPressed: () { Navigator.pop(context); widget.onSetupComplete(_titleController.text, _subjects); },
              child: const Text('Save Setup & Build Sheets', style: TextStyle(fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }
}
