import 'dart:io';

/// Model for file metadata
class FileMetadata {
  final String name;
  final String path;
  final int sizeBytes;
  final String extension;
  final DateTime selectedAt;
  final String? mimeType;

  FileMetadata({
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.extension,
    required this.selectedAt,
    this.mimeType,
  });

  /// Create from File object
  factory FileMetadata.fromFile(File file) {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';
    
    return FileMetadata(
      name: fileName,
      path: file.path,
      sizeBytes: file.lengthSync(),
      extension: extension,
      selectedAt: DateTime.now(),
    );
  }

  /// Get human-readable file size
  String get formattedSize {
    if (sizeBytes < 1024) {
      return '$sizeBytes B';
    } else if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(2)} KB';
    } else if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// Check if file is an image
  bool get isImage {
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg'];
    return imageExtensions.contains(extension);
  }

  /// Check if file is a PDF
  bool get isPdf => extension == 'pdf';

  /// Check if file is a document
  bool get isDocument {
    const docExtensions = ['doc', 'docx', 'txt', 'md', 'rtf', 'csv', 'json', 'xml'];
    return docExtensions.contains(extension);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'name': name,
        'path': path,
        'sizeBytes': sizeBytes,
        'extension': extension,
        'selectedAt': selectedAt.toIso8601String(),
        'mimeType': mimeType,
      };

  /// Create from JSON
  factory FileMetadata.fromJson(Map<String, dynamic> json) => FileMetadata(
        name: json['name'] as String,
        path: json['path'] as String,
        sizeBytes: json['sizeBytes'] as int,
        extension: json['extension'] as String,
        selectedAt: DateTime.parse(json['selectedAt'] as String),
        mimeType: json['mimeType'] as String?,
      );

  @override
  String toString() => 'FileMetadata(name: $name, size: $formattedSize)';
}
