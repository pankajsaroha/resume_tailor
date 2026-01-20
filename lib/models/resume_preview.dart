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
    final sections = (map['sections'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ResumeSection.fromMap)
        .toList();
    return ResumePreview(
      name: map['name'] as String? ?? '',
      role: map['role'] as String? ?? '',
      keywordMatch: (map['keywordMatch'] as int?) ?? 0,
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
