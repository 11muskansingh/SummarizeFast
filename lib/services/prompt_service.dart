import '../models/summary_size.dart';
import '../models/file_metadata.dart';

/// Service for building and managing prompts for Gemini API
class PromptService {
  /// Build initial summary generation prompt
  static String buildSummaryPrompt({
    required FileMetadata fileMetadata,
    required SummarySize summarySize,
    String? customInstructions,
  }) {
    final basePrompt = _getBasePrompt(summarySize);
    final fileTypeContext = _getFileTypeContext(fileMetadata);
    final customSection = customInstructions != null && customInstructions.isNotEmpty
        ? '\n\nAdditional Instructions:\n$customInstructions'
        : '';

    return '''
$fileTypeContext

Task: Create a comprehensive summary of this document.

Requirements:
- Length: ${summarySize.description}
- Target word count: Approximately ${summarySize.wordCount} words
- Style: Clear, concise, and well-structured
- Focus: Key points, main ideas, and important details
- Format: Use paragraphs for readability

$basePrompt$customSection

Please provide the summary now:
''';
  }

  /// Build refinement prompt based on user feedback
  static String buildRefinementPrompt({
    required String refinementType,
    String? customFeedback,
  }) {
    switch (refinementType.toLowerCase()) {
      case 'shorter':
        return '''
Please make this summary shorter and more concise.
- Remove less important details
- Keep only the most essential information
- Maintain clarity and coherence
- Aim for about 30-40% reduction in length
''';

      case 'longer':
        return '''
Please expand this summary with more details.
- Add more context and explanation
- Include additional relevant information
- Elaborate on key points
- Maintain the same clear structure
- Aim for about 30-40% increase in length
''';

      case 'simpler':
        return '''
Please simplify this summary for easier understanding.
- Use simpler language and shorter sentences
- Avoid technical jargon where possible
- Explain complex concepts in plain terms
- Make it accessible to a general audience
''';

      case 'technical':
        return '''
Please make this summary more technical and detailed.
- Include technical terminology where appropriate
- Add specific details and data points
- Use industry-standard language
- Provide deeper technical insights
''';

      case 'bullet_points':
        return '''
Please reformat this summary as bullet points.
- Convert paragraphs into clear bullet points
- Each point should be concise and focused
- Organize by main topics or themes
- Maintain logical flow and hierarchy
- Use sub-bullets for details if needed
''';

      case 'add_details':
        return '''
Please add more details and depth to this summary.
- Expand on the main points with specific information
- Include relevant examples or data
- Provide more context and background
- Maintain clear organization
''';

      case 'custom':
        return customFeedback ?? 'Please refine the summary based on my feedback.';

      default:
        return customFeedback ?? 'Please improve this summary.';
    }
  }

  /// Build prompt for follow-up questions
  static String buildQuestionPrompt(String question) {
    return '''
Based on the document we've been discussing, please answer this question:

$question

Please provide a clear and detailed answer based on the document content.
''';
  }

  /// Get base prompt for summary size
  static String _getBasePrompt(SummarySize size) {
    switch (size) {
      case SummarySize.short:
        return '''
Create a brief summary that:
- Captures the main point or thesis in 2-3 sentences
- Highlights only the most critical information
- Is concise and to-the-point
- Provides a quick overview for readers
''';

      case SummarySize.medium:
        return '''
Create a balanced summary that:
- Covers the main ideas in 1-2 paragraphs
- Includes key supporting details
- Provides sufficient context
- Balances brevity with completeness
''';

      case SummarySize.long:
        return '''
Create a comprehensive summary that:
- Explores main ideas in depth across 3-4 paragraphs
- Includes important details and examples
- Provides thorough context and background
- Covers multiple aspects of the content
- Maintains clear structure and flow
''';
    }
  }

  /// Get context based on file type
  static String _getFileTypeContext(FileMetadata metadata) {
    if (metadata.isPdf) {
      return 'Analyze the following PDF document:';
    } else if (metadata.isImage) {
      return 'Analyze the text content in the following image:';
    } else if (metadata.extension == 'txt' || metadata.extension == 'md') {
      return 'Analyze the following text document:';
    } else if (metadata.extension == 'doc' || metadata.extension == 'docx') {
      return 'Analyze the following Word document:';
    } else {
      return 'Analyze the following document:';
    }
  }

  /// Build prompt for extracting text from file
  static String buildTextExtractionPrompt(FileMetadata metadata) {
    if (metadata.isImage) {
      return '''
Please extract all text content from this image.
- Preserve formatting where possible
- Maintain original structure
- Include all visible text
''';
    } else if (metadata.isPdf) {
      return '''
Please extract all text content from this PDF document.
- Preserve the document structure
- Include all textual content
- Maintain heading hierarchy
''';
    } else {
      return 'Please extract and read all text content from this document.';
    }
  }

  /// Validate custom prompt
  static PromptValidationResult validateCustomPrompt(String? prompt) {
    if (prompt == null || prompt.trim().isEmpty) {
      return PromptValidationResult.valid();
    }

    final trimmedPrompt = prompt.trim();

    // Check minimum length
    if (trimmedPrompt.length < 10) {
      return PromptValidationResult.invalid(
        'Custom instructions should be at least 10 characters',
      );
    }

    // Check maximum length
    if (trimmedPrompt.length > 1000) {
      return PromptValidationResult.invalid(
        'Custom instructions should not exceed 1000 characters',
      );
    }

    // Check for potentially harmful content patterns
    final harmfulPatterns = [
      'ignore previous',
      'ignore all',
      'disregard',
      'forget everything',
    ];

    final lowerPrompt = trimmedPrompt.toLowerCase();
    for (final pattern in harmfulPatterns) {
      if (lowerPrompt.contains(pattern)) {
        return PromptValidationResult.invalid(
          'Instructions contain potentially problematic phrases',
        );
      }
    }

    return PromptValidationResult.valid();
  }

  /// Get prompt suggestions for quick actions
  static List<QuickRefinementAction> getQuickActions() {
    return [
      QuickRefinementAction(
        id: 'shorter',
        label: 'Shorter',
        icon: '📉',
        description: 'Make it more concise',
      ),
      QuickRefinementAction(
        id: 'longer',
        label: 'Longer',
        icon: '📈',
        description: 'Add more details',
      ),
      QuickRefinementAction(
        id: 'simpler',
        label: 'Simpler',
        icon: '💡',
        description: 'Use simpler language',
      ),
      QuickRefinementAction(
        id: 'technical',
        label: 'Technical',
        icon: '🔬',
        description: 'More technical depth',
      ),
      QuickRefinementAction(
        id: 'bullet_points',
        label: 'Bullet Points',
        icon: '📝',
        description: 'Format as bullets',
      ),
      QuickRefinementAction(
        id: 'add_details',
        label: 'Add Details',
        icon: '➕',
        description: 'Include more information',
      ),
    ];
  }

  /// Get example custom prompts
  static List<String> getExamplePrompts() {
    return [
      'Focus on the financial implications',
      'Emphasize the technical implementation details',
      'Highlight the key challenges and solutions',
      'Summarize from a business perspective',
      'Focus on the methodology and approach',
      'Emphasize the results and outcomes',
      'Highlight the main arguments and conclusions',
      'Focus on the timeline and chronology',
    ];
  }
}

/// Quick refinement action configuration
class QuickRefinementAction {
  final String id;
  final String label;
  final String icon;
  final String description;

  QuickRefinementAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.description,
  });
}

/// Result of prompt validation
class PromptValidationResult {
  final bool isValid;
  final String? error;

  PromptValidationResult._({
    required this.isValid,
    this.error,
  });

  factory PromptValidationResult.valid() => PromptValidationResult._(isValid: true);

  factory PromptValidationResult.invalid(String error) =>
      PromptValidationResult._(
        isValid: false,
        error: error,
      );
}
