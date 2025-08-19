class CodeFile {
  final String filename;
  final String content;
  final String language;

  CodeFile({
    required this.filename,
    required this.content,
    required this.language,
  });

  factory CodeFile.fromJson(Map<String, dynamic> json) {
    return CodeFile(
      filename: json['filename'] ?? '',
      content: json['content'] ?? '',
      language: json['language'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'content': content,
      'language': language,
    };
  }

  CodeFile copyWith({
    String? filename,
    String? content,
    String? language,
  }) {
    return CodeFile(
      filename: filename ?? this.filename,
      content: content ?? this.content,
      language: language ?? this.language,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CodeFile &&
        other.filename == filename &&
        other.content == content &&
        other.language == language;
  }

  @override
  int get hashCode => filename.hashCode ^ content.hashCode ^ language.hashCode;

  @override
  String toString() => 'CodeFile(filename: $filename, language: $language)';
}