import 'dart:io';
import '../models/summary_size.dart';
import '../models/file_metadata.dart';
import '../models/conversation_message.dart';
import '../models/summary_version.dart';
import 'gemini_service.dart';
import 'prompt_service.dart';

/// Service for generating summaries from files
class SummaryGenerationService {
  final GeminiService _geminiService = GeminiService.instance;

  /// Generate initial summary from file
  Future<SummaryGenerationResult> generateInitialSummary({
    required File file,
    required FileMetadata metadata,
    required SummarySize summarySize,
    String? customInstructions,
  }) async {
    try {
      // Ensure Gemini service is initialized
      if (!_geminiService.isInitialized) {
        await _geminiService.initialize();
      }

      // Read file content
      final fileContent = await _readFileContent(file, metadata);
      if (fileContent == null || fileContent.isEmpty) {
        return SummaryGenerationResult.error(
          'Unable to read file content. The file may be empty or corrupted.',
        );
      }

      // Build prompt
      final prompt = PromptService.buildSummaryPrompt(
        fileMetadata: metadata,
        summarySize: summarySize,
        customInstructions: customInstructions,
      );

      // Combine prompt with file content
      final fullPrompt = '$prompt\n\nDocument Content:\n$fileContent';

      // Generate summary using Gemini
      final result = await _geminiService.generateSummary(prompt: fullPrompt);

      if (result.hasError) {
        return SummaryGenerationResult.error(
          result.error ?? 'Failed to generate summary',
        );
      }

      // Create conversation messages
      final userMessage = ConversationMessage.user(
        prompt,
        fileUri: file.uri.toString(),
      );

      final modelMessage = ConversationMessage.model(
        result.content!,
      );

      // Create initial version
      final version = SummaryVersion.initial(result.content!);

      return SummaryGenerationResult.success(
        summary: result.content!,
        version: version,
        userMessage: userMessage,
        modelMessage: modelMessage,
      );
    } catch (e) {
      return SummaryGenerationResult.error(
        'Summary generation failed: ${e.toString()}',
      );
    }
  }

  /// Read content from file based on file type
  Future<String?> _readFileContent(File file, FileMetadata metadata) async {
    try {
      // For text-based files, read directly
      if (metadata.extension == 'txt' ||
          metadata.extension == 'md' ||
          metadata.extension == 'json' ||
          metadata.extension == 'csv') {
        return await file.readAsString();
      }

      // For PDFs and images, we'll need to extract text
      // In production, this would use PDF/OCR libraries
      // For now, we'll simulate by returning a message
      if (metadata.isPdf) {
        return _simulatePdfExtraction(file);
      }

      if (metadata.isImage) {
        return _simulateImageTextExtraction(file);
      }

      // For other document types, try to read as text
      // In production, you'd use specific document parsers
      try {
        return await file.readAsString();
      } catch (e) {
        return 'Binary document file: ${metadata.name}';
      }
    } catch (e) {
      return null;
    }
  }

  /// Simulate PDF text extraction
  /// In production, use packages like pdf_text or syncfusion_flutter_pdf
  Future<String> _simulatePdfExtraction(File file) async {
    // TODO: Implement actual PDF text extraction using pdf_text package
    return '''
[PDF Document Content]
This is a simulated PDF content extraction.
In production, this would contain the actual extracted text from the PDF file.

To implement real PDF extraction:
1. Add pdf_text package to pubspec.yaml
2. Use PDFDoc.fromFile(file) to load the PDF
3. Extract text from each page
4. Return combined text content

File: ${file.path}
''';
  }

  /// Simulate image text extraction (OCR)
  /// In production, use Google ML Kit or similar OCR solution
  Future<String> _simulateImageTextExtraction(File file) async {
    // TODO: Implement actual OCR using google_ml_kit or firebase_ml_vision
    return '''
[Image Text Content]
This is a simulated image text extraction.
In production, this would contain text recognized from the image using OCR.

To implement real OCR:
1. Add google_ml_kit package to pubspec.yaml
2. Use TextRecognizer() to process the image
3. Extract recognized text blocks
4. Return combined text content

File: ${file.path}
''';
  }

  /// Validate if file can be processed
  bool canProcessFile(FileMetadata metadata) {
    // Check file size
    if (metadata.sizeBytes > 10 * 1024 * 1024) {
      return false; // Over 10MB
    }

    // Check file type
    final supportedExtensions = [
      'txt', 'md', 'pdf', 'doc', 'docx',
      'jpg', 'jpeg', 'png', 'gif',
      'json', 'csv', 'xml',
    ];

    return supportedExtensions.contains(metadata.extension.toLowerCase());
  }

  /// Get estimated processing time based on file size
  Duration getEstimatedProcessingTime(FileMetadata metadata) {
    final sizeInMB = metadata.sizeBytes / (1024 * 1024);

    if (sizeInMB < 1) {
      return Duration(seconds: 10);
    } else if (sizeInMB < 5) {
      return Duration(seconds: 30);
    } else {
      return Duration(seconds: 60);
    }
  }
}

/// Result of summary generation
class SummaryGenerationResult {
  final String? summary;
  final SummaryVersion? version;
  final ConversationMessage? userMessage;
  final ConversationMessage? modelMessage;
  final String? error;

  SummaryGenerationResult._({
    this.summary,
    this.version,
    this.userMessage,
    this.modelMessage,
    this.error,
  });

  factory SummaryGenerationResult.success({
    required String summary,
    required SummaryVersion version,
    required ConversationMessage userMessage,
    required ConversationMessage modelMessage,
  }) =>
      SummaryGenerationResult._(
        summary: summary,
        version: version,
        userMessage: userMessage,
        modelMessage: modelMessage,
      );

  factory SummaryGenerationResult.error(String error) =>
      SummaryGenerationResult._(error: error);

  bool get isSuccess => summary != null && version != null;
  bool get hasError => error != null;
}
