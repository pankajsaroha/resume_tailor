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

  factory ResumePreview.mock() {
    return ResumePreview(
      name: 'John Doe',
      role: 'Senior Software Engineer',
      keywordMatch: 82,
      sections: [
        ResumeSection(
          title: 'Professional Summary',
          content:
              'Experienced software engineer with 5+ years of expertise in mobile and web development. '
              'Proven track record of delivering high-quality applications using Flutter, React, and Node.js.',
        ),
        ResumeSection(
          title: 'Experience',
          content:
              'Senior Software Engineer | Tech Corp\n'
              '2020 - Present\n'
              '• Led development of mobile applications\n'
              '• Implemented scalable backend solutions\n'
              '• Collaborated with cross-functional teams',
        ),
        ResumeSection(
          title: 'Education',
          content:
              'Bachelor of Science in Computer Science\n'
              'University Name | 2016 - 2020',
        ),
        ResumeSection(
          title: 'Skills',
          content:
              'Flutter, Dart, React, Node.js, JavaScript, TypeScript, Python, AWS, Git',
        ),
      ],
    );
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
