import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/subject_tab.dart';
import '../../../shared/services/subject_tab_service.dart';

final subjectTabServiceProvider = Provider<SubjectTabService>((ref) {
  return const SubjectTabService();
});

final subjectTabsProvider = Provider<List<SubjectTab>>((ref) {
  return ref.watch(subjectTabServiceProvider).getInitialTabs();
});
