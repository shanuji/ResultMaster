import '../domain/class_register.dart';
import '../domain/class_register_failure.dart';
import '../domain/class_register_repository.dart';
import '../domain/student.dart';
import '../domain/student_validator.dart';

class ClassRegisterService {
  ClassRegisterService(this._repository, {StudentValidator validator = const StudentValidator()})
      : _validator = validator;

  final ClassRegisterRepository _repository;
  final StudentValidator _validator;

  Future<List<ClassRegister>> registers() => _repository.watchRegisters();

  Future<ClassRegister> createRegister(String name) {
    if (name.trim().isEmpty) throw const ClassRegisterFailure('Register name cannot be blank.');
    return _repository.createRegister(name.trim());
  }

  Future<void> renameRegister(int registerId, String name) {
    if (name.trim().isEmpty) throw const ClassRegisterFailure('Register name cannot be blank.');
    return _repository.renameRegister(registerId, name.trim());
  }

  Future<void> deleteRegister(int registerId) => _repository.deleteRegister(registerId);

  Future<List<Student>> students(int registerId, {String? rollQuery, String? nameQuery}) =>
      _repository.students(registerId, rollQuery: rollQuery, nameQuery: nameQuery);

  Future<Student> addStudent(Student student) async {
    final existing = await _repository.students(student.registerId);
    final normalized = student.copyWith(rollNumber: student.rollNumber.trim(), name: student.name.trim());
    _validator.validate(normalized, existing);
    return _repository.addStudent(normalized);
  }

  Future<void> updateStudent(Student student) async {
    final existing = await _repository.students(student.registerId);
    final normalized = student.copyWith(rollNumber: student.rollNumber.trim(), name: student.name.trim());
    _validator.validate(normalized, existing);
    await _repository.updateStudent(normalized);
  }

  Future<void> deleteStudent(int studentId) => _repository.deleteStudent(studentId);

  Future<void> importStudents(int registerId, List<Student> imported) async {
    final seen = <String>{};
    for (final student in imported) {
      final normalized = student.copyWith(registerId: registerId, rollNumber: student.rollNumber.trim(), name: student.name.trim());
      _validator.validate(normalized, const <Student>[]);
      if (!seen.add(normalized.rollNumber.toLowerCase())) {
        throw const ClassRegisterFailure('Import contains duplicate Roll Numbers.');
      }
    }
    await _repository.replaceStudents(registerId, imported);
  }
}
