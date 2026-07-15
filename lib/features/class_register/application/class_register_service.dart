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

  Future<ClassRegisterImportSummary> importStudents(
    int registerId,
    List<Student> imported, {
    required ClassRegisterImportMode mode,
    int skipped = 0,
    Iterable<String> duplicateRollNumbers = const <String>[],
  }) async {
    final existing = mode == ClassRegisterImportMode.append ? await _repository.students(registerId) : const <Student>[];
    final normalizedStudents = <Student>[];
    final seen = <String>{};
    final duplicates = duplicateRollNumbers.map((rollNumber) => rollNumber.trim()).where((rollNumber) => rollNumber.isNotEmpty).toSet();
    var skippedRows = skipped;

    for (final student in imported) {
      final normalized = student.copyWith(registerId: registerId, rollNumber: student.rollNumber.trim(), name: student.name.trim());
      try {
        _validator.validate(normalized, [...existing, ...normalizedStudents]);
      } on ClassRegisterFailure {
        duplicates.add(normalized.rollNumber);
        skippedRows++;
        continue;
      }
      if (!seen.add(normalized.rollNumber.toLowerCase())) {
        duplicates.add(normalized.rollNumber);
        skippedRows++;
        continue;
      }
      normalizedStudents.add(normalized);
    }

    if (mode == ClassRegisterImportMode.replaceExisting) {
      await _repository.replaceStudents(registerId, normalizedStudents);
    } else {
      await _repository.appendStudents(registerId, normalizedStudents);
    }

    return ClassRegisterImportSummary(
      imported: normalizedStudents.length,
      skipped: skippedRows,
      duplicateRollNumbers: duplicates.toList(growable: false)..sort(),
    );
  }
}

enum ClassRegisterImportMode { replaceExisting, append }

class ClassRegisterImportSummary {
  const ClassRegisterImportSummary({
    required this.imported,
    required this.skipped,
    required this.duplicateRollNumbers,
  });

  final int imported;
  final int skipped;
  final List<String> duplicateRollNumbers;

  int get duplicates => duplicateRollNumbers.length;
}
