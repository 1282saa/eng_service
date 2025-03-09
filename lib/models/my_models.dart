/// 모델, 데이터 클래스 등을 한 데 모아둔 예시 파일.
///
/// 예: DiagnosticQuestion, LearningContent, CategoryItem
/// (원하시면 더 많은 모델을 추가/분리할 수도 있음)

class DiagnosticQuestion {
  final int id;
  final String type;
  final String question;
  final List<String> options;

  DiagnosticQuestion({
    required this.id,
    required this.type,
    required this.question,
    required this.options,
  });
}

class LearningContent {
  final int id;
  final String title;
  final String duration;
  final String level;
  final String type;
  int progress;

  LearningContent({
    required this.id,
    required this.title,
    required this.duration,
    required this.level,
    required this.type,
    required this.progress,
  });
}

class CategoryItem {
  final String id;
  final String name;
  final String icon;
  final int count;

  CategoryItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.count,
  });
}
