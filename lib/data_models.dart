import 'package:flutter/material.dart';

// ==========================================
// DATA MODELS (Supports Bifurcation & Pass/Fail toggle)
// ==========================================
class SubjectComponent {
  String name;
  double maxMarks;
  SubjectComponent({required this.name, required this.maxMarks});
}

class SubjectSetup {
  String name;
  double maxMarks;
  double passingMarks;
  bool includeInPassFail;
  bool includeInPercentage;
  Color themeColor;
  List<SubjectComponent> components;

  SubjectSetup({
    required this.name,
    this.maxMarks = 100.0,
    this.passingMarks = 33.0,
    this.includeInPassFail = true,
    this.includeInPercentage = true,
    this.themeColor = Colors.blue,
    List<SubjectComponent>? components,
  }) : components = components ?? [];

  void recalculateMaxMarks() {
    if (components.isNotEmpty) {
      maxMarks = components.fold(0.0, (sum, c) => sum + c.maxMarks);
    }
  }
}

class StudentRow {
  String rollNo;
  String name;
  Map<String, String> marks;
  String remarks;
  Set<String> pinnedSubjects;

  StudentRow({
    required this.rollNo,
    required this.name,
    required this.marks,
    this.remarks = "",
    Set<String>? pinnedSubjects,
  }) : pinnedSubjects = pinnedSubjects ?? {};

  double getSubjectScore(SubjectSetup sub) {
    if (sub.components.isEmpty) {
      String val = marks[sub.name] ?? "";
      return double.tryParse(val) ?? 0.0;
    } else {
      double total = 0.0;
      for (var c in sub.components) {
        String val = marks["${sub.name}_${c.name}"] ?? "";
        total += double.tryParse(val) ?? 0.0;
      }
      return total;
    }
  }

  bool isSubjectAttempted(SubjectSetup sub) {
    if (sub.components.isEmpty) {
      String val = (marks[sub.name] ?? "").trim().toUpperCase();
      return val.isNotEmpty && (double.tryParse(val) != null || val == "A" || val == "AB");
    } else {
      for (var c in sub.components) {
        String val = (marks["${sub.name}_${c.name}"] ?? "").trim().toUpperCase();
        if (val.isNotEmpty && (double.tryParse(val) != null || val == "A" || val == "AB")) return true;
      }
      return false;
    }
  }
}
