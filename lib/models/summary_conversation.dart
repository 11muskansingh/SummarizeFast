import 'dart:io';
import 'conversation_message.dart';
import 'summary_version.dart';
import 'summary_size.dart';
import 'file_metadata.dart';

/// Configuration for summary generation
class SummaryConfig {
  final SummarySize size;
  final String? customPrompt;

  SummaryConfig({
    required this.size,
    this.customPrompt,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'size': size.name,
        'customPrompt': customPrompt,
      };

  /// Create from JSON
  factory SummaryConfig.fromJson(Map<String, dynamic> json) => SummaryConfig(
        size: SummarySize.values.firstWhere(
          (e) => e.name == json['size'],
        ),
        customPrompt: json['customPrompt'] as String?,
      );
}

/// Model for a complete summarization conversation
class SummaryConversation {
  final String conversationId;
  final File? originalFile;
  final FileMetadata? fileMetadata;
  final String? uploadedFileUri; // Gemini File API URI (valid 48 hours)
  final List<ConversationMessage> messages;
  final List<SummaryVersion> versions;
  final SummaryConfig config;
  final DateTime createdAt;

  SummaryConversation({
    required this.conversationId,
    this.originalFile,
    this.fileMetadata,
    this.uploadedFileUri,
    required this.messages,
    required this.versions,
    required this.config,
    required this.createdAt,
  });

  /// Create a new conversation
  factory SummaryConversation.create({
    required String conversationId,
    File? originalFile,
    FileMetadata? fileMetadata,
    String? uploadedFileUri,
    required SummaryConfig config,
  }) =>
      SummaryConversation(
        conversationId: conversationId,
        originalFile: originalFile,
        fileMetadata: fileMetadata,
        uploadedFileUri: uploadedFileUri,
        messages: [],
        versions: [],
        config: config,
        createdAt: DateTime.now(),
      );

  /// Get current summary (latest version)
  String? get currentSummary =>
      versions.isNotEmpty ? versions.last.content : null;

  /// Get current version number
  int get currentVersionNumber =>
      versions.isNotEmpty ? versions.last.versionNumber : 0;

  /// Get refinement count (versions - 1)
  int get refinementCount => versions.length > 0 ? versions.length - 1 : 0;

  /// Check if file URI is still valid (within 48 hours)
  bool get isFileUriValid {
    if (uploadedFileUri == null) return false;
    final expirationTime = createdAt.add(const Duration(hours: 48));
    return DateTime.now().isBefore(expirationTime);
  }

  /// Add a new message to the conversation
  SummaryConversation addMessage(ConversationMessage message) {
    return copyWith(
      messages: [...messages, message],
    );
  }

  /// Add a new summary version
  SummaryConversation addVersion(SummaryVersion version) {
    return copyWith(
      versions: [...versions, version],
    );
  }

  /// Create a copy with modifications
  SummaryConversation copyWith({
    String? conversationId,
    File? originalFile,
    FileMetadata? fileMetadata,
    String? uploadedFileUri,
    List<ConversationMessage>? messages,
    List<SummaryVersion>? versions,
    SummaryConfig? config,
    DateTime? createdAt,
  }) =>
      SummaryConversation(
        conversationId: conversationId ?? this.conversationId,
        originalFile: originalFile ?? this.originalFile,
        fileMetadata: fileMetadata ?? this.fileMetadata,
        uploadedFileUri: uploadedFileUri ?? this.uploadedFileUri,
        messages: messages ?? this.messages,
        versions: versions ?? this.versions,
        config: config ?? this.config,
        createdAt: createdAt ?? this.createdAt,
      );

  /// Convert to JSON (excluding File object)
  Map<String, dynamic> toJson() => {
        'conversationId': conversationId,
        'fileMetadata': fileMetadata?.toJson(),
        'uploadedFileUri': uploadedFileUri,
        'messages': messages.map((m) => m.toJson()).toList(),
        'versions': versions.map((v) => v.toJson()).toList(),
        'config': config.toJson(),
        'createdAt': createdAt.toIso8601String(),
      };

  /// Create from JSON
  factory SummaryConversation.fromJson(Map<String, dynamic> json) =>
      SummaryConversation(
        conversationId: json['conversationId'] as String,
        fileMetadata: json['fileMetadata'] != null
            ? FileMetadata.fromJson(json['fileMetadata'] as Map<String, dynamic>)
            : null,
        uploadedFileUri: json['uploadedFileUri'] as String?,
        messages: (json['messages'] as List)
            .map((m) => ConversationMessage.fromJson(m as Map<String, dynamic>))
            .toList(),
        versions: (json['versions'] as List)
            .map((v) => SummaryVersion.fromJson(v as Map<String, dynamic>))
            .toList(),
        config: SummaryConfig.fromJson(json['config'] as Map<String, dynamic>),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  @override
  String toString() => 'Conversation($conversationId, ${versions.length} versions, ${messages.length} messages)';
}
