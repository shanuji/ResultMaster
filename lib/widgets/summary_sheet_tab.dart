import 'package:flutter/material.dart';
import '../models/data_models.dart';

class SummarySheetTabWidget extends StatelessWidget {
  final int termId;
  final List<SubjectSetup> subjects; 
  final List<StudentRow> students;
  const SummarySheetTabWidget({super.key, required this.termId, required this.subjects, required this.students});

  @override
  Widget build(BuildContext context) {
    int grandAppeared = 0; int grandPassed = 0; int grandDistinction = 0;
    Map<String, int> grandBrackets = {'0-20': 0, '21-32.9': 0, '33-40': 0, '41-50': 0, '51-59.9': 0, '60': 0, '61-70': 0, '71-74.9': 0, '75-80': 0, '81-90': 0, '90': 0, '91-94.9': 0, '95-100': 0};
    final subjectRows = subjects.asMap().entries.map((entry) {
      int index = entry.key; var sub = entry.value;
      int appeared = 0; int passed = 0; int distinction = 0; double sumMarks = 0.0; Map<String, int> distribution = {'0-20': 0, '21-32.9': 0, '33-40': 0, '41-50': 0, '51-59.9': 0, '60': 0, '61-70': 0, '71-74.9': 0, '75-80': 0, '81-90': 0, '90': 0, '91-94.9': 0, '95-100': 0};
      for (var row in students) {
        if (!row.isSubjectAttempted(termId, sub)) continue;
        double score = row.getSubjectScore(termId, sub); appeared++; sumMarks += score;
        if (row.isSubjectPassed(termId, sub)) passed++; if (score >= (sub.maxMarks * 0.75)) distinction++;
        if (score >= 0 && score < 21) distribution['0-20'] = distribution['0-20']! + 1; else if (score >= 21 && score < 32.9) distribution['21-32.9'] = distribution['21-32.9']! + 1; else if (score >= 33 && score < 40) distribution['33-40'] = distribution['33-40']! + 1; else if (score >= 41 && score < 50) distribution['41-50'] = distribution['41-50']! + 1; else if (score >= 51 && score < 59.9) distribution['51-59.9'] = distribution['51-59.9']! + 1; else if (score == 60) distribution['60'] = distribution['60']! + 1; else if (score >= 61 && score < 70) distribution['61-70'] = distribution['61-70']! + 1; else if (score >= 71 && score < 74.9) distribution['71-74.9'] = distribution['71-74.9']! + 1; else if (score >= 75 && score < 80) distribution['75-80'] = distribution['75-80']! + 1; else if (score >= 81 && score < 90) distribution['81-90'] = distribution['81-90']! + 1; else if (score == 90) distribution['90'] = distribution['90']! + 1; else if (score >= 91 && score < 94.9) distribution['91-94.9'] = distribution['91-94.9']! + 1; else if (score >= 95 && score <= 100) distribution['95-100'] = distribution['95-100']! + 1;
      }
      double passPct = appeared > 0 ? (passed / appeared) * 100 : 0.0; double qi = appeared > 0 ? (sumMarks / appeared) : 0.0;
      grandAppeared += appeared; grandPassed += passed; grandDistinction += distinction; distribution.forEach((key, val) => grandBrackets[key] = grandBrackets[key]! + val);
      return DataRow(color: MaterialStateProperty.all(index.isEven ? Colors.grey[50] : Colors.white), cells: [DataCell(Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold))), DataCell(Text(appeared.toString())), DataCell(Text(passed.toString())), DataCell(Text('${passPct.toStringAsFixed(2)}%')), DataCell(Text(distinction.toString())), DataCell(Text(qi.toStringAsFixed(2))), DataCell(Text(distribution['0-20'].toString())), DataCell(Text(distribution['21-32.9'].toString())), DataCell(Text(distribution['33-40'].toString())), DataCell(Text(distribution['41-50'].toString())), DataCell(Text(distribution['51-59.9'].toString())), DataCell(Text(distribution['60'].toString())), DataCell(Text(distribution['61-70'].toString())), DataCell(Text(distribution['71-74.9'].toString())), DataCell(Text(distribution['75-80'].toString())), DataCell(Text(distribution['81-90'].toString())), DataCell(Text(distribution['90'].toString())), DataCell(Text(distribution['91-94.9'].toString())), DataCell(Text(distribution['95-100'].toString()))]);
    }).toList();
    final sumRow = DataRow(color: MaterialStateProperty.all(Colors.orange[100]), cells: [const DataCell(Text('SUM', style: TextStyle(fontWeight: FontWeight.bold))), DataCell(Text(grandAppeared.toString(), style: const TextStyle(fontWeight: FontWeight.bold))), DataCell(Text(grandPassed.toString(), style: const TextStyle(fontWeight: FontWeight.bold))), const DataCell(Text('-')), DataCell(Text(grandDistinction.toString(), style: const TextStyle(fontWeight: FontWeight.bold))), const DataCell(Text('-')), DataCell(Text(grandBrackets['0-20'].toString())), DataCell(Text(grandBrackets['21-32.9'].toString())), DataCell(Text(grandBrackets['33-40'].toString())), DataCell(Text(grandBrackets['41-50'].toString())), DataCell(Text(grandBrackets['51-59.9'].toString())), DataCell(Text(grandBrackets['60'].toString())), DataCell(Text(grandBrackets['61-70'].toString())), DataCell(Text(grandBrackets['71-74.9'].toString())), DataCell(Text(grandBrackets['75-80'].toString())), DataCell(Text(grandBrackets['81-90'].toString())), DataCell(Text(grandBrackets['90'].toString())), DataCell(Text(grandBrackets['91-94.9'].toString())), DataCell(Text(grandBrackets['95-100'].toString()))]);
    return Expanded(
      child: SingleChildScrollView(scrollDirection: Axis.vertical, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Padding(padding: const EdgeInsets.all(8.0), child: DataTable(headingRowColor: MaterialStateProperty.all(Colors.yellow[100]), border: TableBorder.all(color: Colors.grey[300]!), columns: const [DataColumn(label: Text('SUBJECT', style: TextStyle(fontWeight: FontWeight.bold))), DataColumn(label: Text('APP')), DataColumn(label: Text('PASS')), DataColumn(label: Text('PASS %')), DataColumn(label: Text('DISTT')), DataColumn(label: Text('QI (AVG)')), DataColumn(label: Text('0-20')), DataColumn(label: Text('21-32.9')), DataColumn(label: Text('33-40')), DataColumn(label: Text('41-50')), DataColumn(label: Text('51-59.9')), DataColumn(label: Text('60')), DataColumn(label: Text('61-70')), DataColumn(label: Text('71-74.9')), DataColumn(label: Text('75-80')), DataColumn(label: Text('81-90')), DataColumn(label: Text('90')), DataColumn(label: Text('91-94.9')), DataColumn(label: Text('95-100'))], rows: [...subjectRows, sumRow])))),
    );
  }
}
