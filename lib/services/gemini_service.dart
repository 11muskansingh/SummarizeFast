import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../utils/constants.dart';

/// Service for interacting with Google Gemini API
class GeminiService {
  /// Convert technical API errors to user-friendly messages
  static String _getUserFriendlyError(String technicalError) {
    if (technicalError.contains('503') || technicalError.contains('overloaded')) {
      return 'The AI service is currently busy. Retrying automatically...';
    } else if (technicalError.contains('429')) {
      return 'Rate limit reached. Please wait a moment...';
    } else if (technicalError.contains('401') || technicalError.contains('API key')) {
      return 'API key is invalid. Please check your configuration.';
    } else if (technicalError.contains('404')) {
      return 'AI model not found. Please check your configuration.';
    } else if (technicalError.contains('timeout') || technicalError.contains('SocketException')) {
      return 'Network connection issue. Retrying...';
    } else if (technicalError.contains('400')) {
      return 'Invalid request. Please try a different file or smaller content.';
    }
    return technicalError;
  }

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

  /// Upload a file to Gemini API using File API
  Future<GeminiFileUploadResult> uploadFile(
    File file, {
    String? displayName,
    String? mimeType,
  }) async {
    _ensureInitialized();

    try {
      print('🤖 [GeminiService] Uploading file to Gemini API...');
      print('   - File path: ${file.path}');
      print('   - MIME type: $mimeType');
      
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

  /// Upload file bytes to Gemini API (for web platform)
  Future<GeminiFileUploadResult> uploadFileBytes(
    List<int> bytes, {
    required String fileName,
    String? mimeType,
  }) async {
    _ensureInitialized();

    try {
      print('🤖 [GeminiService] Uploading file bytes to Gemini API...');
      print('   - File name: $fileName');
      print('   - Bytes length: ${bytes.length}');
      print('   - MIME type: $mimeType');
      
      // Create a DataPart from bytes for Gemini API
      // Gemini can process files directly as inline data
      return GeminiFileUploadResult.success(
        uri: 'data://$fileName',
        name: fileName,
        mimeType: mimeType ?? 'application/pdf',
      );
    } catch (e) {
      print('❌ [GeminiService] Upload failed: $e');
      return GeminiFileUploadResult.error(
        'Failed to upload file: ${e.toString()}',
      );
    }
  }

  /// Generate summary from file bytes (for PDFs, images, documents)
  Future<GeminiGenerationResult> generateSummaryFromFile({
    required List<int> fileBytes,
    required String mimeType,
    required String prompt,
    int maxRetries = 3,
  }) async {
    print('🤖 [GeminiService] generateSummaryFromFile() called');
    print('   - File bytes: ${fileBytes.length}');
    print('   - MIME type: $mimeType');
    print('   - Prompt length: ${prompt.length} characters');
    print('   - Max retries: $maxRetries');
    
    _ensureInitialized();
    print('✅ [GeminiService] Service initialized');

    int attempt = 0;
    Duration waitTime = Duration(seconds: 2);

    while (attempt < maxRetries) {
      attempt++;
      print('🤖 [GeminiService] Attempt $attempt of $maxRetries');

      try {
        print('🤖 [GeminiService] Creating file data part...');
        
        // Convert List<int> to Uint8List if needed
        final uint8FileBytes = fileBytes is Uint8List 
            ? fileBytes 
            : Uint8List.fromList(fileBytes);
        
        // Create DataPart from file bytes
        final filePart = DataPart(mimeType, uint8FileBytes);
        
        print('🤖 [GeminiService] Creating content with file and prompt...');
        final content = [
          Content.multi([
            filePart,
            TextPart(prompt),
          ])
        ];

        print('🤖 [GeminiService] Calling _model.generateContent()...');
        final response = await _model.generateContent(content);
        print('✅ [GeminiService] API response received');

        if (response.text == null || response.text!.isEmpty) {
          print('❌ [GeminiService] Response text is null or empty');
          return GeminiGenerationResult.error(
            'No content generated. Please try again.',
          );
        }

        print('✅ [GeminiService] Response text: ${response.text!.length} characters');
        return GeminiGenerationResult.success(response.text!);
      } catch (e) {
        final errorString = e.toString();
        print('❌ [GeminiService] Exception caught: $e');
        
        // Check if it's a retryable error
        final isRetryable = errorString.contains('503') || 
                           errorString.contains('429') || 
                           errorString.contains('overloaded') ||
                           errorString.contains('timeout') ||
                           errorString.contains('SocketException');

        if (isRetryable && attempt < maxRetries) {
          print('⚠️ [GeminiService] Retryable error detected. Waiting ${waitTime.inSeconds}s before retry...');
          await Future.delayed(waitTime);
          waitTime = waitTime * 2;
          continue;
        }

        // Non-retryable error or max retries reached
        print('❌ [GeminiService] Giving up after $attempt attempt(s)');
        final userFriendlyError = _getUserFriendlyError(errorString);
        return GeminiGenerationResult.error(
          attempt > 1 
            ? 'Failed after $attempt attempts: $userFriendlyError'
            : userFriendlyError,
        );
      }
    }

    return GeminiGenerationResult.error(
      'AI service is currently unavailable after $maxRetries attempts. Please try again in a few moments.',
    );
  }

  /// Generate summary from text content with retry logic
  Future<GeminiGenerationResult> generateSummary({
    required String prompt,
    int maxRetries = 3,
  }) async {
    print('🤖 [GeminiService] generateSummary() called');
    print('   - Prompt length: ${prompt.length} characters');
    print('   - Max retries: $maxRetries');
    
    _ensureInitialized();
    print('✅ [GeminiService] Service initialized');

    int attempt = 0;
    Duration waitTime = Duration(seconds: 2);

    while (attempt < maxRetries) {
      attempt++;
      print('🤖 [GeminiService] Attempt $attempt of $maxRetries');

      try {
        print('🤖 [GeminiService] Creating content...');
        final content = [Content.text(prompt)];

        print('🤖 [GeminiService] Calling _model.generateContent()...');
        final response = await _model.generateContent(content);
        print('✅ [GeminiService] API response received');

        if (response.text == null || response.text!.isEmpty) {
          print('❌ [GeminiService] Response text is null or empty');
          return GeminiGenerationResult.error(
            'No content generated. Please try again.',
          );
        }

        print('✅ [GeminiService] Response text: ${response.text!.length} characters');
        return GeminiGenerationResult.success(response.text!);
      } catch (e) {
        final errorString = e.toString();
        print('❌ [GeminiService] Exception caught: $e');
        
        // Check if it's a retryable error (503, 429, network errors)
        final isRetryable = errorString.contains('503') || 
                           errorString.contains('429') || 
                           errorString.contains('overloaded') ||
                           errorString.contains('timeout') ||
                           errorString.contains('SocketException');

        if (isRetryable && attempt < maxRetries) {
          print('⚠️ [GeminiService] Retryable error detected. Waiting ${waitTime.inSeconds}s before retry...');
          await Future.delayed(waitTime);
          waitTime = waitTime * 2; // Exponential backoff
          continue;
        }

        // Non-retryable error or max retries reached
        print('❌ [GeminiService] Giving up after $attempt attempt(s)');
        final userFriendlyError = _getUserFriendlyError(errorString);
        return GeminiGenerationResult.error(
          attempt > 1 
            ? 'Failed after $attempt attempts: $userFriendlyError'
            : userFriendlyError,
        );
      }
    }

    return GeminiGenerationResult.error(
      'AI service is currently unavailable after $maxRetries attempts. Please try again in a few moments.',
    );
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
