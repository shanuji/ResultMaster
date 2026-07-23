import 'package:flutter/material.dart';

class SubjectComponent {
  String name;
  double maxMarks;
  double passingMarks;
  SubjectComponent({required this.name, required this.maxMarks, this.passingMarks = 0.0});
}

class SubjectSetup {
  int? id;
  int? workbookId;
  String name;
  double maxMarks;
  double passingMarks;
  bool includeInPassFail;
  Color themeColor;
  List<SubjectComponent> components;

  SubjectSetup({
    this.id,
    this.workbookId,
    required this.name,
    this.maxMarks = 100.0,
    this.passingMarks = 33.0,
    this.includeInPassFail = true,
    this.themeColor = Colors.blue,
    List<SubjectComponent>? components,
  }) : components = components ?? [];

  void recalculateMaxMarks() {
    if (components.isNotEmpty) {
      maxMarks = components.fold(0.0, (sum, c) => sum + c.maxMarks);
    }
  }
}

class TermSetup {
  int id;
  int workbookId;
  String name;
  TermSetup({required this.id, required this.workbookId, required this.name});
}

class StudentRow {
  String rollNo;
  String name;
  bool isPromotedOverall;
  Map<int, Map<String, String>> termMarks; 
  Map<int, Map<String, bool>> termPromotions; 

  StudentRow({
    required this.rollNo,
    required this.name,
    this.isPromotedOverall = false,
    Map<int, Map<String, String>>? termMarks,
    Map<int, Map<String, bool>>? termPromotions,
  })  : termMarks = termMarks ?? {},
        termPromotions = termPromotions ?? {};

  double getSubjectScore(int termId, SubjectSetup sub) {
    if (!termMarks.containsKey(termId)) return 0.0;
    if (sub.components.isEmpty) {
      return double.tryParse(termMarks[termId]![sub.name] ?? "") ?? 0.0;
    } else {
      double total = 0.0;
      for (var c in sub.components) {
        total += double.tryParse(termMarks[termId]!["${sub.name}_${c.name}"] ?? "") ?? 0.0;
      }
      return total;
    }
  }

  bool isSubjectAttempted(int termId, SubjectSetup sub) {
    if (!termMarks.containsKey(termId)) return false;
    if (sub.components.isEmpty) {
      String val = (termMarks[termId]![sub.name] ?? "").trim().toUpperCase();
      return val.isNotEmpty && (double.tryParse(val) != null || val == "A" || val == "AB");
    } else {
      for (var c in sub.components) {
        String val = (termMarks[termId]!["${sub.name}_${c.name}"] ?? "").trim().toUpperCase();
        if (val.isEmpty || (double.tryParse(val) == null && val != "A" && val != "AB")) return false;
      }
      return true;
    }
  }

  bool isSubjectPassed(int termId, SubjectSetup sub) {
    // 1. Check for manual override
    if (termPromotions[termId]?[sub.name] == true) return true;
    
    // 2. Check individual components dynamically (If pass marks > 0, it's mandatory)
    if (sub.components.isNotEmpty) {
      for (var c in sub.components) {
        if (c.passingMarks > 0) {
          double cScore = double.tryParse(termMarks[termId]?['${sub.name}_${c.name}'] ?? "") ?? 0.0;
          if (cScore < c.passingMarks) return false;
        }
      }
    }
    
    // 3. Check overall subject total
    return getSubjectScore(termId, sub) >= sub.passingMarks;
  }
}
