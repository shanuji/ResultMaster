import 'package:flutter/foundation.dart';

import '../application/class_register_service.dart';
import '../domain/class_register.dart';
import '../domain/student.dart';

class ClassRegisterController extends ChangeNotifier {
  ClassRegisterController(this._service);
  final ClassRegisterService _service;

  List<ClassRegister> registers = const [];
  ClassRegister? selected;
  List<Student> students = const [];
  String rollQuery = '';
  String nameQuery = '';

  Future<void> load() async {
    registers = await _service.registers();
    selected ??= registers.firstOrNull;
    await refreshStudents();
    notifyListeners();
  }

  Future<void> createRegister(String name) async {
    selected = await _service.createRegister(name);
    await load();
  }

  Future<void> renameSelected(String name) async {
    final current = selected;
    if (current == null) return;
    await _service.renameRegister(current.id, name);
    selected = null;
    await load();
  }

  Future<void> deleteSelected() async {
    final current = selected;
    if (current == null) return;
    await _service.deleteRegister(current.id);
    selected = null;
    await load();
  }

  Future<void> select(ClassRegister register) async {
    selected = register;
    await refreshStudents();
    notifyListeners();
  }

  Future<void> refreshStudents() async {
    final current = selected;
    students = current == null ? const [] : await _service.students(current.id, rollQuery: rollQuery, nameQuery: nameQuery);
  }

  Future<void> search({String? roll, String? name}) async {
    rollQuery = roll ?? rollQuery;
    nameQuery = name ?? nameQuery;
    await refreshStudents();
    notifyListeners();
  }

  Future<void> addStudent(String rollNumber, String name) async {
    final current = selected!;
    await _service.addStudent(Student(registerId: current.id, rollNumber: rollNumber, name: name));
    await refreshStudents();
    notifyListeners();
  }

  Future<void> updateStudent(Student student, String rollNumber, String name) async {
    await _service.updateStudent(student.copyWith(rollNumber: rollNumber, name: name));
    await refreshStudents();
    notifyListeners();
  }

  Future<ImportSummary> importStudents(List<Student> imported, {ImportMode mode = ImportMode.replace}) async {
    final current = selected!;
    final summary = await _service.importStudents(current.id, imported, mode: mode);
    await refreshStudents();
    notifyListeners();
    return summary;
  }

  Future<void> deleteStudent(Student student) async {
    await _service.deleteStudent(student.id!);
    await refreshStudents();
    notifyListeners();
  }
}
