/// Utility functions for the app
library;

/// Format file size in bytes to human-readable format
String formatFileSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  } else if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(2)} KB';
  } else if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  } else {
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// Get file extension from filename
String getFileExtension(String filename) {
  final parts = filename.split('.');
  return parts.length > 1 ? parts.last.toLowerCase() : '';
}

/// Check if file is an image based on extension
bool isImageFile(String filename) {
  const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg'];
  final ext = getFileExtension(filename);
  return imageExtensions.contains(ext);
}

/// Check if file is a PDF
bool isPdfFile(String filename) {
  return getFileExtension(filename) == 'pdf';
}

/// Check if file is a document
bool isDocumentFile(String filename) {
  const docExtensions = ['doc', 'docx', 'txt', 'md', 'rtf', 'csv', 'json', 'xml'];
  final ext = getFileExtension(filename);
  return docExtensions.contains(ext);
}

/// Format timestamp to readable string
String formatTimestamp(DateTime timestamp) {
  final now = DateTime.now();
  final difference = now.difference(timestamp);

  if (difference.inMinutes < 1) {
    return 'Just now';
  } else if (difference.inHours < 1) {
    return '${difference.inMinutes} min ago';
  } else if (difference.inDays < 1) {
    return '${difference.inHours} hr ago';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
  } else {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}
