/// Enum for summary size options
enum SummarySize {
  short,
  medium,
  long;

  /// Get display name for the summary size
  String get displayName {
    switch (this) {
      case SummarySize.short:
        return 'Short';
      case SummarySize.medium:
        return 'Medium';
      case SummarySize.long:
        return 'Long';
    }
  }

  /// Get description for the summary size
  String get description {
    switch (this) {
      case SummarySize.short:
        return '2-3 sentences (~100 words)';
      case SummarySize.medium:
        return '1-2 paragraphs (~250 words)';
      case SummarySize.long:
        return '3-4 paragraphs (~500 words)';
    }
  }

  /// Get word count estimate
  int get wordCount {
    switch (this) {
      case SummarySize.short:
        return 100;
      case SummarySize.medium:
        return 250;
      case SummarySize.long:
        return 500;
    }
  }
}
