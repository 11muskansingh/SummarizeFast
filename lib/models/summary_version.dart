/// Model for a summary version in the version history
class SummaryVersion {
  final String content;
  final DateTime timestamp;
  final String? refinementPrompt; // What user asked for this version
  final int versionNumber;

  SummaryVersion({
    required this.content,
    required this.timestamp,
    this.refinementPrompt,
    required this.versionNumber,
  });

  /// Create initial version (version 1)
  factory SummaryVersion.initial(String content) => SummaryVersion(
        content: content,
        timestamp: DateTime.now(),
        refinementPrompt: null,
        versionNumber: 1,
      );

  /// Create refined version
  factory SummaryVersion.refined({
    required String content,
    required String refinementPrompt,
    required int versionNumber,
  }) =>
      SummaryVersion(
        content: content,
        timestamp: DateTime.now(),
        refinementPrompt: refinementPrompt,
        versionNumber: versionNumber,
      );

  /// Get formatted timestamp
  String get formattedTime {
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

  /// Get word count
  int get wordCount => content.split(RegExp(r'\s+')).length;

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'refinementPrompt': refinementPrompt,
        'versionNumber': versionNumber,
      };

  /// Create from JSON
  factory SummaryVersion.fromJson(Map<String, dynamic> json) => SummaryVersion(
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        refinementPrompt: json['refinementPrompt'] as String?,
        versionNumber: json['versionNumber'] as int,
      );

  /// Create a copy with modifications
  SummaryVersion copyWith({
    String? content,
    DateTime? timestamp,
    String? refinementPrompt,
    int? versionNumber,
  }) =>
      SummaryVersion(
        content: content ?? this.content,
        timestamp: timestamp ?? this.timestamp,
        refinementPrompt: refinementPrompt ?? this.refinementPrompt,
        versionNumber: versionNumber ?? this.versionNumber,
      );

  @override
  String toString() => 'Version $versionNumber (${wordCount} words) - $formattedTime';
}
