import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../utils/constants.dart';

/// Service for interacting with Google Gemini API
class GeminiService {
  static GeminiService? _instance;
  late final GenerativeModel _model;
  late final String _apiKey;
  bool _isInitialized = false;

  GeminiService._internal();

  /// Get singleton instance
  static GeminiService get instance {
    _instance ??= GeminiService._internal();
    return _instance!;
  }

  /// Initialize the Gemini service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load environment variables
      await dotenv.load(fileName: ".env");

      // Get API key
      _apiKey = dotenv.env['GOOGLE_AI_API_KEY'] ?? '';
      if (_apiKey.isEmpty) {
        throw GeminiServiceException(
          'GOOGLE_AI_API_KEY not found in .env file',
        );
      }

      // Initialize Generative Model with safety settings
      _model = GenerativeModel(
        model: AppConstants.geminiModel,
        apiKey: _apiKey,
        safetySettings: [
          SafetySetting(
            HarmCategory.harassment,
            HarmBlockThreshold.low,
          ),
          SafetySetting(
            HarmCategory.hateSpeech,
            HarmBlockThreshold.low,
          ),
          SafetySetting(
            HarmCategory.sexuallyExplicit,
            HarmBlockThreshold.low,
          ),
          SafetySetting(
            HarmCategory.dangerousContent,
            HarmBlockThreshold.low,
          ),
        ],
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 8192,
        ),
      );

      _isInitialized = true;
    } catch (e) {
      throw GeminiServiceException(
        'Failed to initialize Gemini service: ${e.toString()}',
      );
    }
  }

  /// Upload a file to Gemini API (currently uses local file path)
  /// Note: File API upload will be implemented when needed
  Future<GeminiFileUploadResult> uploadFile(
    File file, {
    String? displayName,
    String? mimeType,
  }) async {
    _ensureInitialized();

    try {
      // For now, return the local file path as URI
      // TODO: Implement actual file upload when google_generative_ai adds support
      return GeminiFileUploadResult.success(
        uri: file.uri.toString(),
        name: displayName ?? file.path.split(Platform.pathSeparator).last,
        mimeType: mimeType ?? 'application/pdf',
      );
    } catch (e) {
      return GeminiFileUploadResult.error(
        'Failed to process file: ${e.toString()}',
      );
    }
  }

  /// Generate summary from text content
  Future<GeminiGenerationResult> generateSummary({
    required String prompt,
  }) async {
    _ensureInitialized();

    try {
      final content = [Content.text(prompt)];

      final response = await _model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        return GeminiGenerationResult.error(
          'No content generated. Please try again.',
        );
      }

      return GeminiGenerationResult.success(response.text!);
    } catch (e) {
      return GeminiGenerationResult.error(
        'Failed to generate summary: ${e.toString()}',
      );
    }
  }

  /// Generate refined summary based on conversation history
  Future<GeminiGenerationResult> generateRefinedSummary({
    required List<Content> conversationHistory,
    required String refinementPrompt,
  }) async {
    _ensureInitialized();

    try {
      // Create chat session with history
      final chat = _model.startChat(history: conversationHistory);

      // Send refinement prompt
      final response = await chat.sendMessage(
        Content.text(refinementPrompt),
      );

      if (response.text == null || response.text!.isEmpty) {
        return GeminiGenerationResult.error(
          'No content generated. Please try again.',
        );
      }

      return GeminiGenerationResult.success(response.text!);
    } catch (e) {
      return GeminiGenerationResult.error(
        'Failed to refine summary: ${e.toString()}',
      );
    }
  }

  /// Generate chat response (for follow-up questions)
  Future<GeminiGenerationResult> generateChatResponse({
    required List<Content> conversationHistory,
    required String message,
  }) async {
    _ensureInitialized();

    try {
      final chat = _model.startChat(history: conversationHistory);

      final response = await chat.sendMessage(Content.text(message));

      if (response.text == null || response.text!.isEmpty) {
        return GeminiGenerationResult.error(
          'No response generated. Please try again.',
        );
      }

      return GeminiGenerationResult.success(response.text!);
    } catch (e) {
      return GeminiGenerationResult.error(
        'Failed to generate response: ${e.toString()}',
      );
    }
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Ensure service is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw GeminiServiceException(
        'GeminiService not initialized. Call initialize() first.',
      );
    }
  }
}

/// Result of file upload operation
class GeminiFileUploadResult {
  final String? uri;
  final String? name;
  final String? mimeType;
  final String? error;

  GeminiFileUploadResult._({
    this.uri,
    this.name,
    this.mimeType,
    this.error,
  });

  factory GeminiFileUploadResult.success({
    required String uri,
    required String name,
    required String mimeType,
  }) =>
      GeminiFileUploadResult._(
        uri: uri,
        name: name,
        mimeType: mimeType,
      );

  factory GeminiFileUploadResult.error(String error) =>
      GeminiFileUploadResult._(error: error);

  bool get isSuccess => uri != null;
  bool get hasError => error != null;
}

/// Result of generation operation
class GeminiGenerationResult {
  final String? content;
  final String? error;

  GeminiGenerationResult._({
    this.content,
    this.error,
  });

  factory GeminiGenerationResult.success(String content) =>
      GeminiGenerationResult._(content: content);

  factory GeminiGenerationResult.error(String error) =>
      GeminiGenerationResult._(error: error);

  bool get isSuccess => content != null;
  bool get hasError => error != null;
}

/// Custom exception for Gemini service errors
class GeminiServiceException implements Exception {
  final String message;

  GeminiServiceException(this.message);

  @override
  String toString() => 'GeminiServiceException: $message';
}
