import 'class_register.dart';
import 'student.dart';

abstract interface class ClassRegisterRepository {
  Future<List<ClassRegister>> watchRegisters();
  Future<ClassRegister> createRegister(String name);
  Future<void> renameRegister(int registerId, String name);
  Future<void> deleteRegister(int registerId);

  Future<List<Student>> students(int registerId, {String? rollQuery, String? nameQuery});
  Future<Student> addStudent(Student student);
  Future<void> updateStudent(Student student);
  Future<void> deleteStudent(int studentId);
  Future<void> replaceStudents(int registerId, List<Student> students);
  Future<void> appendStudents(int registerId, List<Student> students);
}
