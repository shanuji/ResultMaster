import 'package:result_master/features/class_register/domain/class_register_failure.dart';
import 'package:result_master/features/class_register/domain/student.dart';
import 'package:result_master/features/class_register/domain/student_validator.dart';
import 'package:test/test.dart';

void main() {
  const validator = StudentValidator();

  test('rejects blank roll number', () {
    expect(
      () => validator.validate(const Student(registerId: 1, rollNumber: ' ', name: 'Asha'), const []),
      throwsA(isA<ClassRegisterFailure>()),
    );
  });

  test('rejects blank student name', () {
    expect(
      () => validator.validate(const Student(registerId: 1, rollNumber: '1', name: ''), const []),
      throwsA(isA<ClassRegisterFailure>()),
    );
  });

  test('rejects duplicate roll numbers case-insensitively', () {
    const existing = [Student(id: 5, registerId: 1, rollNumber: 'A-01', name: 'Asha')];
    expect(
      () => validator.validate(const Student(registerId: 1, rollNumber: 'a-01', name: 'Bala'), existing),
      throwsA(isA<ClassRegisterFailure>()),
    );
  });
}
