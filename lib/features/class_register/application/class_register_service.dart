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

  Future<ImportSummary> importStudents(int registerId, List<Student> imported, {ImportMode mode = ImportMode.replace}) async {
    final existing = mode == ImportMode.append ? await _repository.students(registerId) : const <Student>[];
    final normalizedStudents = <Student>[];
    final seen = <String>{};
    var blankRowsSkipped = 0;
    for (final student in imported) {
      final normalized = student.copyWith(registerId: registerId, rollNumber: student.rollNumber.trim(), name: student.name.trim());
      if (normalized.rollNumber.isEmpty && normalized.name.isEmpty) {
        blankRowsSkipped++;
        continue;
      }
      _validator.validate(normalized, <Student>[...existing, ...normalizedStudents]);
      if (!seen.add(normalized.rollNumber.toLowerCase())) {
        throw ClassRegisterFailure('Import contains duplicate Roll Number: ${normalized.rollNumber}.');
      }
      normalizedStudents.add(normalized);
    }
    if (mode == ImportMode.replace) {
      await _repository.replaceStudents(registerId, normalizedStudents);
    } else {
      await _repository.appendStudents(registerId, normalizedStudents);
    }
    return ImportSummary(imported: normalizedStudents.length, blankRowsSkipped: blankRowsSkipped, mode: mode);
  }
}


enum ImportMode { replace, append }

class ImportSummary {
  const ImportSummary({required this.imported, required this.blankRowsSkipped, required this.mode});

  final int imported;
  final int blankRowsSkipped;
  final ImportMode mode;
}
