class ClassRegisterFailure implements Exception {
  const ClassRegisterFailure(this.message);
  final String message;
  @override
  String toString() => message;
}
