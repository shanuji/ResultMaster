
import 'package:flutter/material.dart';

class SubjectComponent {
  String name;
  double maxMarks;
  double passingMarks;
  SubjectComponent({required this.name, required this.maxMarks, this.passingMarks = 0.0});
}

class SubjectSetup {
  String name;
  double maxMarks;
  double passingMarks;
  bool includeInPassFail;
  bool requirePassPerComponent;
  Color themeColor;
  List<SubjectComponent> components;

  SubjectSetup({
    required this.name,
    this.maxMarks = 100.0,
    this.passingMarks = 33.0,
    this.includeInPassFail = true,
    this.requirePassPerComponent = false,
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

  StudentRow({
    required this.rollNo,
    required this.name,
    required this.marks,
    this.remarks = "",
  });

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
        if (val.isEmpty || (double.tryParse(val) == null && val != "A" && val != "AB")) return false;
      }
      return true;
    }
  }

  bool isSubjectPassed(SubjectSetup sub) {
    if (sub.requirePassPerComponent && sub.components.isNotEmpty) {
      for (var c in sub.components) {
        double cScore = double.tryParse(marks['${sub.name}_${c.name}'] ?? "") ?? 0.0;
        if (cScore < c.passingMarks) return false;
      }
      return true; 
    }
    return getSubjectScore(sub) >= sub.passingMarks;
  }
}
