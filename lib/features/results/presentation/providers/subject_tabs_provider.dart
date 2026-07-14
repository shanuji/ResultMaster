import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/result_workbook.dart';

final draftSubjectTabsProvider = StateProvider<List<SubjectTab>>((ref) {
  return const [
    SubjectTab(id: 'summary', name: 'Summary', position: 0),
    SubjectTab(id: 'mathematics', name: 'Mathematics', position: 1),
    SubjectTab(id: 'english', name: 'English', position: 2),
  ];
});
