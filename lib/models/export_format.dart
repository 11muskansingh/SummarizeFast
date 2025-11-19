/// Enum for export format options
enum ExportFormat {
  pdf,
  markdown,
  html;

  /// Get display name for the export format
  String get displayName {
    switch (this) {
      case ExportFormat.pdf:
        return 'PDF';
      case ExportFormat.markdown:
        return 'Markdown';
      case ExportFormat.html:
        return 'HTML';
    }
  }

  /// Get file extension
  String get extension {
    switch (this) {
      case ExportFormat.pdf:
        return 'pdf';
      case ExportFormat.markdown:
        return 'md';
      case ExportFormat.html:
        return 'html';
    }
  }

  /// Get MIME type
  String get mimeType {
    switch (this) {
      case ExportFormat.pdf:
        return 'application/pdf';
      case ExportFormat.markdown:
        return 'text/markdown';
      case ExportFormat.html:
        return 'text/html';
    }
  }

  /// Get icon for the format
  String get icon {
    switch (this) {
      case ExportFormat.pdf:
        return '📄';
      case ExportFormat.markdown:
        return '📝';
      case ExportFormat.html:
        return '🌐';
    }
  }
}
