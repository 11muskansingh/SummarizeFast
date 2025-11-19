/// App-wide constants and configuration values
class AppConstants {
  // App Information
  static const String appName = 'SummarizeFast';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'AI-powered document & image summarization';

  // File Constraints
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10MB
  static const String maxFileSizeDisplay = '10MB';

  // Supported File Types
  static const List<String> supportedDocumentExtensions = [
    'pdf',
    'doc',
    'docx',
    'txt',
    'md',
    'rtf',
    'csv',
    'json',
    'xml',
  ];

  static const List<String> supportedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'svg',
  ];

  // Gemini API Configuration
  static const String geminiModel = 'gemini-2.5-flash';
  static const Duration apiTimeout = Duration(seconds: 60);
  static const int maxRetries = 3;

  // Summary Size Descriptions
  static const Map<String, String> summarySizeDescriptions = {
    'short': '2-3 concise sentences (~100 words)',
    'medium': '1-2 well-structured paragraphs (~250 words)',
    'long': '3-4 detailed paragraphs (~500 words)',
  };

  // UI Constants
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const double borderRadius = 16.0;
  static const double cardElevation = 4.0;
}
