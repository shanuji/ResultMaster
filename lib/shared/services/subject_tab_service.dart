import '../models/subject_tab.dart';

class SubjectTabService {
  const SubjectTabService();

  List<SubjectTab> getInitialTabs() {
    return const [
      SubjectTab(id: 1, name: 'Summary', sortOrder: 0),
      SubjectTab(id: 2, name: 'Subject 1', sortOrder: 1),
      SubjectTab(id: 3, name: 'Subject 2', sortOrder: 2),
    ];
  }
}
