class CodeFile {
  final String filename;
  final String content; // Now provided by backend
  final String language; // Inferred by backend from extension
  final String? fileExtension; // Extracted by backend
  final String? mimeType; // From API response
  final int? fileSize; // From API response
  final String? fileUrl; // Original file URL

  CodeFile({
    required this.filename,
    required this.content,
    required this.language,
    this.fileExtension,
    this.mimeType,
    this.fileSize,
    this.fileUrl,
  });

  factory CodeFile.fromJson(Map<String, dynamic> json) {
    return CodeFile(
      filename: json['filename'] ?? '',
      content: json['content'] ?? '',
      language: json['language'] ?? '',
      fileExtension: json['fileExtension'],
      mimeType: json['mimeType'],
      fileSize: json['fileSize'],
      fileUrl: json['fileUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'content': content,
      'language': language,
      'fileExtension': fileExtension,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'fileUrl': fileUrl,
    };
  }
}