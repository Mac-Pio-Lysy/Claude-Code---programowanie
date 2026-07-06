/// Kategorie checklisty na dzień ślubu (CHECKLIST_CATEGORIES w wersji web).
const List<String> kChecklistCategories = [
  'Co zabrać',
  'Kto co przynosi',
  'Przed ceremonią',
  'Po ceremonii',
];

/// Pozycja checklisty — nakładka na surową mapę `{id, category, text, done}`.
class ChecklistItem {
  ChecklistItem(this.raw);
  final Map<String, dynamic> raw;

  int? get id => (raw['id'] as num?)?.toInt();
  String get category => (raw['category'] as String?) ?? kChecklistCategories.first;
  String get text => (raw['text'] as String?) ?? '';
  bool get done => raw['done'] == true;
}
