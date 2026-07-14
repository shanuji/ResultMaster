import 'class_register_failure.dart';
import 'student.dart';

class StudentValidator {
  const StudentValidator();

  void validate(Student student, Iterable<Student> existing) {
    if (student.rollNumber.trim().isEmpty) {
      throw const ClassRegisterFailure('Roll Number cannot be blank.');
    }
    if (student.name.trim().isEmpty) {
      throw const ClassRegisterFailure('Student Name cannot be blank.');
    }
    final normalized = student.rollNumber.trim().toLowerCase();
    final duplicate = existing.any((entry) =>
        entry.id != student.id && entry.rollNumber.trim().toLowerCase() == normalized);
    if (duplicate) {
      throw const ClassRegisterFailure('Roll Numbers must be unique within a register.');
    }
  }
}
