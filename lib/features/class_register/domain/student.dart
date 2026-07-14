class Student {
  const Student({
    this.id,
    required this.registerId,
    required this.rollNumber,
    required this.name,
    this.metadata = const <String, Object?>{},
  });

  final int? id;
  final int registerId;
  final String rollNumber;
  final String name;

  /// Reserved for future fields such as parent details, contact data, groups,
  /// and optional demographics. The UI intentionally displays only roll number
  /// and student name during Sprint 2.
  final Map<String, Object?> metadata;

  Student copyWith({
    int? id,
    int? registerId,
    String? rollNumber,
    String? name,
    Map<String, Object?>? metadata,
  }) {
    return Student(
      id: id ?? this.id,
      registerId: registerId ?? this.registerId,
      rollNumber: rollNumber ?? this.rollNumber,
      name: name ?? this.name,
      metadata: metadata ?? this.metadata,
    );
  }
}
