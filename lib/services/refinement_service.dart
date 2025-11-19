import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/conversation_message.dart';
import '../models/summary_version.dart';
import 'gemini_service.dart';
import 'prompt_service.dart';

/// Service for handling conversational refinement of summaries
class RefinementService {
  final GeminiService _geminiService = GeminiService.instance;

  /// Refine summary based on user feedback
  Future<RefinementResult> refineSummary({
    required List<ConversationMessage> conversationHistory,
    required String refinementType,
    String? customFeedback,
    required int currentVersionNumber,
  }) async {
    try {
      // Ensure Gemini service is initialized
      if (!_geminiService.isInitialized) {
        await _geminiService.initialize();
      }

      // Build refinement prompt
      final refinementPrompt = PromptService.buildRefinementPrompt(
        refinementType: refinementType,
        customFeedback: customFeedback,
      );

      // Convert conversation history to Gemini Content format
      final geminiHistory = _convertToGeminiHistory(conversationHistory);

      // Generate refined summary
      final result = await _geminiService.generateRefinedSummary(
        conversationHistory: geminiHistory,
        refinementPrompt: refinementPrompt,
      );

      if (result.hasError) {
        return RefinementResult.error(
          result.error ?? 'Failed to refine summary',
        );
      }

      // Create new messages
      final userMessage = ConversationMessage.user(refinementPrompt);
      final modelMessage = ConversationMessage.model(result.content!);

      // Create new version
      final newVersion = SummaryVersion.refined(
        content: result.content!,
        refinementPrompt: refinementPrompt,
        versionNumber: currentVersionNumber + 1,
      );

      return RefinementResult.success(
        refinedSummary: result.content!,
        version: newVersion,
        userMessage: userMessage,
        modelMessage: modelMessage,
      );
    } catch (e) {
      return RefinementResult.error(
        'Refinement failed: ${e.toString()}',
      );
    }
  }

  /// Ask a follow-up question about the document
  Future<RefinementResult> askQuestion({
    required List<ConversationMessage> conversationHistory,
    required String question,
  }) async {
    try {
      // Ensure Gemini service is initialized
      if (!_geminiService.isInitialized) {
        await _geminiService.initialize();
      }

      // Build question prompt
      final questionPrompt = PromptService.buildQuestionPrompt(question);

      // Convert conversation history to Gemini Content format
      final geminiHistory = _convertToGeminiHistory(conversationHistory);

      // Generate answer
      final result = await _geminiService.generateChatResponse(
        conversationHistory: geminiHistory,
        message: questionPrompt,
      );

      if (result.hasError) {
        return RefinementResult.error(
          result.error ?? 'Failed to answer question',
        );
      }

      // Create new messages
      final userMessage = ConversationMessage.user(question);
      final modelMessage = ConversationMessage.model(result.content!);

      return RefinementResult.success(
        refinedSummary: result.content!,
        version: null, // Questions don't create versions
        userMessage: userMessage,
        modelMessage: modelMessage,
      );
    } catch (e) {
      return RefinementResult.error(
        'Question failed: ${e.toString()}',
      );
    }
  }

  /// Quick refinement using predefined action
  Future<RefinementResult> quickRefine({
    required List<ConversationMessage> conversationHistory,
    required String actionId,
    required int currentVersionNumber,
  }) async {
    return refineSummary(
      conversationHistory: conversationHistory,
      refinementType: actionId,
      currentVersionNumber: currentVersionNumber,
    );
  }

  /// Convert app conversation messages to Gemini Content format
  List<Content> _convertToGeminiHistory(
    List<ConversationMessage> messages,
  ) {
    return messages.map((message) {
      final role = message.role == MessageRole.user ? 'user' : 'model';
      return Content(role, [TextPart(message.content)]);
    }).toList();
  }

  /// Build context-aware refinement prompt
  String buildContextualRefinement({
    required String currentSummary,
    required String userFeedback,
  }) {
    return '''
Current Summary:
$currentSummary

User Feedback:
$userFeedback

Please refine the summary based on the user's feedback while maintaining accuracy and completeness.
''';
  }

  /// Validate refinement request
  RefinementValidationResult validateRefinementRequest({
    required List<ConversationMessage> conversationHistory,
    String? customFeedback,
  }) {
    // Check if we have conversation history
    if (conversationHistory.isEmpty) {
      return RefinementValidationResult.invalid(
        'No conversation history available',
      );
    }

    // Check if we have at least one summary (model message)
    final hasSummary = conversationHistory.any(
      (msg) => msg.role == MessageRole.model,
    );

    if (!hasSummary) {
      return RefinementValidationResult.invalid(
        'No summary available to refine',
      );
    }

    // Validate custom feedback if provided
    if (customFeedback != null && customFeedback.isNotEmpty) {
      if (customFeedback.length < 3) {
        return RefinementValidationResult.invalid(
          'Feedback must be at least 3 characters',
        );
      }

      if (customFeedback.length > 500) {
        return RefinementValidationResult.invalid(
          'Feedback must not exceed 500 characters',
        );
      }
    }

    return RefinementValidationResult.valid();
  }

  /// Check if refinement limit reached (optional, for free tier protection)
  bool hasReachedRefinementLimit(int refinementCount, {int limit = 50}) {
    return refinementCount >= limit;
  }

  /// Get estimated tokens for refinement
  int estimateTokens(List<ConversationMessage> history) {
    // Rough estimation: ~4 characters per token
    int totalChars = 0;
    for (final message in history) {
      totalChars += message.content.length;
    }
    return (totalChars / 4).ceil();
  }
}

/// Result of refinement operation
class RefinementResult {
  final String? refinedSummary;
  final SummaryVersion? version;
  final ConversationMessage? userMessage;
  final ConversationMessage? modelMessage;
  final String? error;

  RefinementResult._({
    this.refinedSummary,
    this.version,
    this.userMessage,
    this.modelMessage,
    this.error,
  });

  factory RefinementResult.success({
    required String refinedSummary,
    SummaryVersion? version,
    required ConversationMessage userMessage,
    required ConversationMessage modelMessage,
  }) =>
      RefinementResult._(
        refinedSummary: refinedSummary,
        version: version,
        userMessage: userMessage,
        modelMessage: modelMessage,
      );

  factory RefinementResult.error(String error) =>
      RefinementResult._(error: error);

  bool get isSuccess => refinedSummary != null;
  bool get hasError => error != null;
  bool get isVersionUpdate => version != null;
}

/// Result of refinement validation
class RefinementValidationResult {
  final bool isValid;
  final String? error;

  RefinementValidationResult._({
    required this.isValid,
    this.error,
  });

  factory RefinementValidationResult.valid() =>
      RefinementValidationResult._(isValid: true);

  factory RefinementValidationResult.invalid(String error) =>
      RefinementValidationResult._(
        isValid: false,
        error: error,
      );
}
