class ResumePreview {
  ResumePreview({
    required this.name,
    required this.role,
    required this.keywordMatch,
    required this.sections,
  });

  final String name;
  final String role;
  final int keywordMatch;
  final List<ResumeSection> sections;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'keywordMatch': keywordMatch,
      'sections': sections.map((section) => section.toMap()).toList(),
    };
  }

  factory ResumePreview.fromMap(Map<String, dynamic> map) {
    final rawSections = map['sections'];
    final sections = (rawSections is List ? rawSections : const [])
        .whereType<Map>()
        .map((section) =>
            ResumeSection.fromMap(Map<String, dynamic>.from(section)))
        .toList();
    final keywordMatchValue = map['keywordMatch'];
    final keywordMatch = keywordMatchValue is num
        ? keywordMatchValue.toInt()
        : int.tryParse(keywordMatchValue?.toString() ?? '') ?? 0;
    return ResumePreview(
      name: map['name'] as String? ?? '',
      role: map['role'] as String? ?? '',
      keywordMatch: keywordMatch,
      sections: sections,
    );
  }
}

class ResumeSection {
  ResumeSection({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  factory ResumeSection.fromMap(Map<String, dynamic> map) {
    return ResumeSection(
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
    };
  }
}
