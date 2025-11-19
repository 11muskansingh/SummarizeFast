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
    File? file,
    List<int>? fileBytes,
    required FileMetadata metadata,
    required SummarySize summarySize,
    String? customInstructions,
  }) async {
    try {
      print('📝 [SummaryGenerationService] generateInitialSummary() called');
      print('   - Has file: ${file != null}');
      print('   - Has bytes: ${fileBytes != null}');
      print('   - File type: ${metadata.extension}');
      print('   - MIME type: ${metadata.mimeType}');
      
      // Ensure Gemini service is initialized
      if (!_geminiService.isInitialized) {
        print('📝 [SummaryGenerationService] Initializing Gemini service...');
        await _geminiService.initialize();
      }

      // Build prompt
      print('📝 [SummaryGenerationService] Building prompt...');
      final prompt = PromptService.buildSummaryPrompt(
        fileMetadata: metadata,
        summarySize: summarySize,
        customInstructions: customInstructions,
      );
      print('✅ [SummaryGenerationService] Prompt built: ${prompt.length} characters');

      // Check if we can send the file directly to Gemini
      final canSendDirectly = _canSendFileDirectly(metadata);
      print('📝 [SummaryGenerationService] Can send file directly: $canSendDirectly');

      GeminiGenerationResult result;

      if (canSendDirectly && fileBytes != null) {
        // Send file bytes directly to Gemini (preferred method)
        print('📝 [SummaryGenerationService] Sending file directly to Gemini...');
        result = await _geminiService.generateSummaryFromFile(
          fileBytes: fileBytes,
          mimeType: metadata.mimeType ?? _getMimeType(metadata.extension),
          prompt: prompt,
        );
      } else if (canSendDirectly && file != null) {
        // Read file and send bytes
        print('📝 [SummaryGenerationService] Reading file to send to Gemini...');
        final bytes = await file.readAsBytes();
        result = await _geminiService.generateSummaryFromFile(
          fileBytes: bytes,
          mimeType: metadata.mimeType ?? _getMimeType(metadata.extension),
          prompt: prompt,
        );
      } else {
        // Fallback: Extract text content first (for unsupported formats)
        print('📝 [SummaryGenerationService] Extracting text content first...');
        final fileContent = await _readFileContent(file, fileBytes, metadata);
        if (fileContent == null || fileContent.isEmpty) {
          print('❌ [SummaryGenerationService] File content is empty');
          return SummaryGenerationResult.error(
            'Unable to read file content. The file may be empty or corrupted.',
          );
        }
        print('✅ [SummaryGenerationService] File content read: ${fileContent.length} characters');
        
        final fullPrompt = '$prompt\n\nDocument Content:\n$fileContent';
        result = await _geminiService.generateSummary(prompt: fullPrompt);
      }
      
      print('📝 [SummaryGenerationService] Gemini API call completed');

      if (result.hasError) {
        print('❌ [SummaryGenerationService] Gemini error: ${result.error}');
        return SummaryGenerationResult.error(
          result.error ?? 'Failed to generate summary',
        );
      }
      print('✅ [SummaryGenerationService] Summary generated: ${result.content?.length ?? 0} characters');

      // Create conversation messages
      print('📝 [SummaryGenerationService] Creating conversation messages...');
      final fileUri = file?.uri.toString() ?? 'web:///${metadata.name}';
      final userMessage = ConversationMessage.user(
        prompt,
        fileUri: fileUri,
      );

      final modelMessage = ConversationMessage.model(
        result.content!,
      );

      // Create initial version
      print('📝 [SummaryGenerationService] Creating summary version...');
      final version = SummaryVersion.initial(result.content!);

      print('✅ [SummaryGenerationService] Summary generation completed successfully');
      return SummaryGenerationResult.success(
        summary: result.content!,
        version: version,
        userMessage: userMessage,
        modelMessage: modelMessage,
      );
    } catch (e) {
      print('❌ [SummaryGenerationService] Exception in generateInitialSummary: $e');
      return SummaryGenerationResult.error(
        'Summary generation failed: ${e.toString()}',
      );
    }
  }

  /// Read content from file based on file type
  Future<String?> _readFileContent(File? file, List<int>? fileBytes, FileMetadata metadata) async {
    try {
      print('📝 [SummaryGenerationService] _readFileContent() called');
      print('   - File type: ${metadata.extension}');
      
      // For text-based files, read directly
      if (metadata.extension == 'txt' ||
          metadata.extension == 'md' ||
          metadata.extension == 'json' ||
          metadata.extension == 'csv') {
        print('📝 [SummaryGenerationService] Reading text-based file...');
        if (file != null) {
          return await file.readAsString();
        } else if (fileBytes != null) {
          print('🌐 [SummaryGenerationService] Reading from bytes (web platform)');
          return String.fromCharCodes(fileBytes);
        }
      }

      // For PDFs and images, we'll need to extract text
      // In production, this would use PDF/OCR libraries
      // For now, we'll simulate by returning a message
      if (metadata.isPdf) {
        print('📝 [SummaryGenerationService] Processing PDF file...');
        return _simulatePdfExtraction(file, fileBytes, metadata);
      }

      if (metadata.isImage) {
        print('📝 [SummaryGenerationService] Processing image file...');
        return _simulateImageTextExtraction(file, fileBytes, metadata);
      }

      // For other document types, try to read as text
      // In production, you'd use specific document parsers
      try {
        if (file != null) {
          return await file.readAsString();
        } else if (fileBytes != null) {
          print('🌐 [SummaryGenerationService] Reading binary from bytes (web platform)');
          return String.fromCharCodes(fileBytes);
        }
      } catch (e) {
        print('⚠️ [SummaryGenerationService] Could not read as text: $e');
        return 'Binary document file: ${metadata.name}';
      }
      
      print('❌ [SummaryGenerationService] No file data available');
      return null;
    } catch (e) {
      print('❌ [SummaryGenerationService] Error reading file content: $e');
      return null;
    }
  }

  /// Simulate PDF text extraction
  /// In production, use packages like pdf_text or syncfusion_flutter_pdf
  Future<String> _simulatePdfExtraction(File? file, List<int>? fileBytes, FileMetadata metadata) async {
    // TODO: Implement actual PDF text extraction using pdf_text package
    print('📝 [SummaryGenerationService] Simulating PDF extraction...');
    print('⚠️ [SummaryGenerationService] Using sample content for demonstration');
    
    // For demonstration, provide realistic sample content
    // In production, this would extract actual text from the PDF
    return '''
CHINMAY SHARMA
Full Stack Developer | AI/ML Enthusiast
Email: chinmay.sharma@email.com | Phone: +1 (555) 123-4567
LinkedIn: linkedin.com/in/chinmaysharma | GitHub: github.com/chinmaysharma

PROFESSIONAL SUMMARY
Experienced Full Stack Developer with 5+ years of expertise in building scalable web applications using modern technologies. Proficient in Flutter, React, Node.js, and Python. Strong background in AI/ML integration and cloud architecture. Passionate about creating efficient, user-friendly solutions.

TECHNICAL SKILLS
• Frontend: Flutter, React, Vue.js, HTML5, CSS3, JavaScript/TypeScript
• Backend: Node.js, Python (Django, Flask), Express.js, REST APIs, GraphQL
• Mobile: Flutter, React Native, Android (Kotlin), iOS (Swift)
• AI/ML: TensorFlow, PyTorch, Gemini AI, OpenAI APIs, Langchain
• Databases: PostgreSQL, MongoDB, Firebase, Redis, MySQL
• Cloud: AWS (EC2, S3, Lambda), Google Cloud Platform, Firebase, Docker
• Tools: Git, GitHub Actions, CI/CD, Jira, Figma, VS Code

PROFESSIONAL EXPERIENCE

Senior Full Stack Developer | Tech Solutions Inc. | Jan 2022 - Present
• Led development of AI-powered document processing system using Flutter and Gemini AI
• Architected microservices backend handling 1M+ daily requests with 99.9% uptime
• Implemented real-time collaboration features using WebSockets and Firebase
• Reduced application load time by 60% through code optimization and lazy loading
• Mentored team of 5 junior developers and conducted code reviews

Full Stack Developer | Digital Innovations Corp | Mar 2020 - Dec 2021
• Developed cross-platform mobile apps using Flutter reaching 100K+ downloads
• Built RESTful APIs using Node.js and Express serving 500K+ monthly users
• Integrated payment gateways (Stripe, PayPal) with 99.99% transaction success rate
• Implemented automated testing achieving 85% code coverage
• Collaborated with UX team to improve user retention by 40%

Software Developer | StartUp Ventures | Jun 2019 - Feb 2020
• Created responsive web applications using React and Material-UI
• Developed Python scripts for data processing and automation
• Implemented CI/CD pipeline reducing deployment time by 70%
• Worked in Agile environment with 2-week sprint cycles

EDUCATION
Bachelor of Science in Computer Science | State University | 2015 - 2019
• GPA: 3.8/4.0
• Relevant Coursework: Data Structures, Algorithms, Machine Learning, Database Systems
• Dean's List: 2017, 2018, 2019

PROJECTS

SummarizeFast - AI Document Summarization App
• Built Flutter web app with Gemini 2.5 Flash for instant document summarization
• Implemented multi-platform file handling (web/native) with 100% compatibility
• Added automatic retry logic for API reliability and error handling
• Technologies: Flutter, Dart, Gemini AI, Riverpod, Material Design

SmartChat - Real-time Messaging Platform
• Developed real-time chat application with end-to-end encryption
• Implemented WebRTC for video/audio calls supporting 10+ concurrent users
• Built using Flutter, Firebase, WebSockets
• 50K+ active users within 6 months of launch

EcoTracker - Environmental Impact Calculator
• Created mobile app to track and reduce carbon footprint
• Integrated ML model for personalized recommendations
• Technologies: Flutter, TensorFlow Lite, Firebase
• Featured in App Store "Apps We Love" section

CERTIFICATIONS
• AWS Certified Solutions Architect - Associate
• Google Cloud Professional Developer
• Flutter Development Bootcamp (Udemy)
• Machine Learning Specialization (Coursera)

ACHIEVEMENTS
• Winner - University Hackathon 2019 (Best Mobile App)
• Open Source Contributor - 500+ GitHub contributions
• Published 3 technical articles on Medium with 10K+ views
• Speaker at Flutter Forward 2023 Conference

LANGUAGES
• English (Native)
• Hindi (Fluent)
• Spanish (Intermediate)

NOTE: This is a demonstration using sample content. In production, actual PDF text would be extracted from the uploaded file using a PDF parsing library.
''';
  }

  /// Simulate image text extraction (OCR)
  /// In production, use Google ML Kit or similar OCR solution
  Future<String> _simulateImageTextExtraction(File? file, List<int>? fileBytes, FileMetadata metadata) async {
    // TODO: Implement actual OCR using google_ml_kit or firebase_ml_vision
    print('📝 [SummaryGenerationService] Simulating image OCR...');
    print('⚠️ [SummaryGenerationService] Using sample content for demonstration');
    
    // For demonstration, provide realistic sample text content
    // In production, this would use OCR to extract text from the image
    return '''
MEETING NOTES - Q4 Planning Session
Date: November 19, 2025
Attendees: Sarah Chen (PM), Mike Rodriguez (Tech Lead), Alex Kumar (Designer)

KEY DISCUSSION POINTS:

1. Product Roadmap Review
   - Launch new AI features by December 15th
   - Mobile app redesign scheduled for January
   - User feedback integration priority for Q1 2026

2. Technical Requirements
   - Implement real-time collaboration
   - Add offline mode support
   - Improve API response time by 30%
   - Scale infrastructure for 2x user growth

3. Design Updates
   - New color scheme approved
   - Accessibility improvements needed
   - Mobile-first approach for all features
   - User testing sessions scheduled weekly

4. Budget Allocation
   - Cloud infrastructure: \$15K/month
   - Third-party APIs: \$5K/month
   - Marketing: \$20K for Q4 campaign
   - Hiring: 2 developers, 1 designer

ACTION ITEMS:
• Sarah: Finalize feature specifications by Nov 25
• Mike: Set up staging environment by Nov 22
• Alex: Complete mockups for review by Nov 24
• Team: Daily standups at 10 AM starting Monday

NEXT MEETING: November 26, 2025 @ 2:00 PM

NOTE: This is demonstration content using sample text. In production, actual text would be extracted from the image using OCR technology.
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

  /// Check if file can be sent directly to Gemini
  bool _canSendFileDirectly(FileMetadata metadata) {
    // Gemini supports: PDF, images, audio, video, plain text
    final extension = metadata.extension.toLowerCase();
    return extension == 'pdf' || 
           metadata.isImage || 
           extension == 'txt' ||
           extension == 'md' ||
           extension == 'json' ||
           extension == 'csv';
  }

  /// Get MIME type from file extension
  String _getMimeType(String? extension) {
    if (extension == null) return 'application/octet-stream';
    
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'txt':
        return 'text/plain';
      case 'md':
        return 'text/markdown';
      case 'json':
        return 'application/json';
      case 'csv':
        return 'text/csv';
      default:
        return 'application/octet-stream';
    }
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
