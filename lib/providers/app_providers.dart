import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/file_metadata.dart';
import '../models/summary_size.dart';
import '../models/summary_conversation.dart';
import '../models/summary_version.dart';
import '../services/file_selection_service.dart';
import '../services/file_upload_service.dart';
import '../services/summary_generation_service.dart';
import '../services/refinement_service.dart';
import '../services/version_control_service.dart';

// ============================================================================
// FILE STATE PROVIDER
// ============================================================================

/// State for file selection and upload
class FileState {
  final File? selectedFile;
  final List<int>? fileBytes; // For web platform
  final FileMetadata? fileMetadata;
  final String? uploadedFileUri;
  final bool isUploading;
  final double uploadProgress;
  final String? error;

  FileState({
    this.selectedFile,
    this.fileBytes,
    this.fileMetadata,
    this.uploadedFileUri,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.error,
  });

  FileState copyWith({
    File? selectedFile,
    List<int>? fileBytes,
    FileMetadata? fileMetadata,
    String? uploadedFileUri,
    bool? isUploading,
    double? uploadProgress,
    String? error,
  }) {
    return FileState(
      selectedFile: selectedFile ?? this.selectedFile,
      fileBytes: fileBytes ?? this.fileBytes,
      fileMetadata: fileMetadata ?? this.fileMetadata,
      uploadedFileUri: uploadedFileUri ?? this.uploadedFileUri,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      error: error,
    );
  }

  FileState clearFile() {
    return FileState();
  }

  bool get hasFile => (selectedFile != null || fileBytes != null) && fileMetadata != null;
}

class FileStateNotifier extends StateNotifier<FileState> {
  final FileSelectionService _fileSelectionService = FileSelectionService();
  final FileUploadService _fileUploadService = FileUploadService.instance;

  FileStateNotifier() : super(FileState());

  /// Select a document file
  Future<void> selectDocument() async {
    print('📄 [FileStateNotifier] selectDocument() called');
    final result = await _fileSelectionService.pickDocument();
    print('📄 [FileStateNotifier] selectDocument() result: isSuccess=${result.isSuccess}, hasError=${result.hasError}');
    
    if (result.isSuccess) {
      print('✅ [FileStateNotifier] File selected successfully: ${result.metadata?.name}');
      print('✅ [FileStateNotifier] Has file: ${result.file != null}, Has bytes: ${result.bytes != null}');
      state = state.copyWith(
        selectedFile: result.file,
        fileBytes: result.bytes,
        fileMetadata: result.metadata,
        error: null,
      );
      print('✅ [FileStateNotifier] State updated: hasFile=${state.hasFile}');
    } else if (result.hasError) {
      print('❌ [FileStateNotifier] Error selecting document: ${result.error}');
      state = state.copyWith(error: result.error);
    }
  }

  /// Select an image from gallery
  Future<void> selectImage() async {
    print('🖼️ [FileStateNotifier] selectImage() called');
    final result = await _fileSelectionService.pickImageFromGallery();
    print('🖼️ [FileStateNotifier] selectImage() result: isSuccess=${result.isSuccess}, hasError=${result.hasError}');
    
    if (result.isSuccess) {
      print('✅ [FileStateNotifier] Image selected successfully: ${result.metadata?.name}');
      state = state.copyWith(
        selectedFile: result.file,
        fileBytes: result.bytes,
        fileMetadata: result.metadata,
        error: null,
      );
      print('✅ [FileStateNotifier] State updated: hasFile=${state.hasFile}');
    } else if (result.hasError) {
      print('❌ [FileStateNotifier] Error selecting image: ${result.error}');
      state = state.copyWith(error: result.error);
    }
  }

  /// Take a photo with camera
  Future<void> takePhoto() async {
    print('📸 [FileStateNotifier] takePhoto() called');
    final result = await _fileSelectionService.takePhoto();
    print('📸 [FileStateNotifier] takePhoto() result: isSuccess=${result.isSuccess}, hasError=${result.hasError}');
    
    if (result.isSuccess) {
      print('✅ [FileStateNotifier] Photo taken successfully: ${result.metadata?.name}');
      state = state.copyWith(
        selectedFile: result.file,
        fileBytes: result.bytes,
        fileMetadata: result.metadata,
        error: null,
      );
      print('✅ [FileStateNotifier] State updated: hasFile=${state.hasFile}');
    } else if (result.hasError) {
      print('❌ [FileStateNotifier] Error taking photo: ${result.error}');
      state = state.copyWith(error: result.error);
    }
  }

  /// Upload selected file
  Future<void> uploadFile() async {
    if (!state.hasFile) {
      state = state.copyWith(error: 'No file selected');
      return;
    }

    state = state.copyWith(isUploading: true, uploadProgress: 0.0, error: null);

    final result = await _fileUploadService.uploadFileWithRetry(
      state.selectedFile!,
      state.fileMetadata!,
      onProgress: (progress) {
        state = state.copyWith(uploadProgress: progress);
      },
    );

    if (result.isSuccess) {
      state = state.copyWith(
        isUploading: false,
        uploadedFileUri: result.uri,
        uploadProgress: 1.0,
      );
    } else {
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
        error: result.error ?? 'Upload failed',
      );
    }
  }

  /// Clear selected file
  void clearFile() {
    state = state.clearFile();
  }
}

final fileStateProvider = StateNotifierProvider<FileStateNotifier, FileState>(
  (ref) => FileStateNotifier(),
);

// ============================================================================
// SUMMARY CONFIG PROVIDER
// ============================================================================

class SummaryConfigNotifier extends StateNotifier<SummarySize> {
  SummaryConfigNotifier() : super(SummarySize.medium);

  void setSummarySize(SummarySize size) {
    state = size;
  }

  void reset() {
    state = SummarySize.medium;
  }
}

final summaryConfigProvider =
    StateNotifierProvider<SummaryConfigNotifier, SummarySize>(
  (ref) => SummaryConfigNotifier(),
);

// Custom prompt provider (separate from size)
final customPromptProvider = StateProvider<String?>((ref) => null);

// ============================================================================
// SUMMARY STATE PROVIDER
// ============================================================================

/// State for summary generation and refinement
class SummaryState {
  final SummaryConversation? conversation;
  final List<SummaryVersion> versions;
  final int currentVersionIndex;
  final bool isGenerating;
  final bool isRefining;
  final String? error;

  SummaryState({
    this.conversation,
    this.versions = const [],
    this.currentVersionIndex = 0,
    this.isGenerating = false,
    this.isRefining = false,
    this.error,
  });

  SummaryState copyWith({
    SummaryConversation? conversation,
    List<SummaryVersion>? versions,
    int? currentVersionIndex,
    bool? isGenerating,
    bool? isRefining,
    String? error,
  }) {
    return SummaryState(
      conversation: conversation ?? this.conversation,
      versions: versions ?? this.versions,
      currentVersionIndex: currentVersionIndex ?? this.currentVersionIndex,
      isGenerating: isGenerating ?? this.isGenerating,
      isRefining: isRefining ?? this.isRefining,
      error: error,
    );
  }

  SummaryVersion? get currentVersion {
    if (versions.isEmpty || currentVersionIndex >= versions.length) {
      return null;
    }
    return versions[currentVersionIndex];
  }

  String? get currentSummary => currentVersion?.content;

  bool get hasVersions => versions.isNotEmpty;
  bool get canUndo => currentVersionIndex > 0;
  bool get canRedo => currentVersionIndex < versions.length - 1;
  int get refinementCount => versions.length - 1;
}

class SummaryStateNotifier extends StateNotifier<SummaryState> {
  final SummaryGenerationService _generationService = SummaryGenerationService();
  final RefinementService _refinementService = RefinementService();
  final VersionControlService _versionControl = VersionControlService();

  SummaryStateNotifier() : super(SummaryState());

  /// Generate initial summary
  Future<void> generateSummary({
    File? file,
    List<int>? fileBytes,
    required FileMetadata metadata,
    required SummarySize summarySize,
    String? customInstructions,
  }) async {
    print('📊 [SummaryStateNotifier] generateSummary() called');
    print('   - Has file: ${file != null}');
    print('   - Has bytes: ${fileBytes != null}');
    print('   - Metadata: ${metadata.name}');
    
    state = state.copyWith(isGenerating: true, error: null);

    print('📊 [SummaryStateNotifier] Calling generation service...');
    final result = await _generationService.generateInitialSummary(
      file: file,
      fileBytes: fileBytes,
      metadata: metadata,
      summarySize: summarySize,
      customInstructions: customInstructions,
    );
    print('📊 [SummaryStateNotifier] Service returned: isSuccess=${result.isSuccess}');

    if (result.isSuccess) {
      print('✅ [SummaryStateNotifier] Creating conversation...');
      final config = SummaryConfig(
        size: summarySize,
        customPrompt: customInstructions,
      );

      final conversation = SummaryConversation.create(
        conversationId: DateTime.now().millisecondsSinceEpoch.toString(),
        originalFile: file ?? File('web:///${metadata.name}'), // Use virtual path for web
        fileMetadata: metadata,
        config: config,
      );

      print('📊 [SummaryStateNotifier] Updating conversation with messages and version...');
      final updatedConversation = conversation.copyWith(
        messages: [result.userMessage!, result.modelMessage!],
        versions: [result.version!],
      );

      print('📊 [SummaryStateNotifier] Updating state...');
      state = state.copyWith(
        conversation: updatedConversation,
        versions: [result.version!],
        currentVersionIndex: 0,
        isGenerating: false,
      );
      print('✅ [SummaryStateNotifier] State updated successfully');
      print('   - Has versions: ${state.hasVersions}');
      print('   - Version count: ${state.versions.length}');
    } else {
      print('❌ [SummaryStateNotifier] Generation failed: ${result.error}');
      state = state.copyWith(
        isGenerating: false,
        error: result.error,
      );
    }
  }

  /// Refine current summary
  Future<void> refineSummary({
    required String refinementType,
    String? customFeedback,
  }) async {
    if (state.conversation == null || !state.hasVersions) {
      state = state.copyWith(error: 'No summary to refine');
      return;
    }

    state = state.copyWith(isRefining: true, error: null);

    final result = await _refinementService.refineSummary(
      conversationHistory: state.conversation!.messages,
      refinementType: refinementType,
      customFeedback: customFeedback,
      currentVersionNumber: state.versions.length,
    );

    if (result.isSuccess) {
      final updatedMessages = [
        ...state.conversation!.messages,
        result.userMessage!,
        result.modelMessage!,
      ];

      final updatedVersions = [...state.versions, result.version!];

      final updatedConversation = state.conversation!.copyWith(
        messages: updatedMessages,
        versions: updatedVersions,
      );

      state = state.copyWith(
        conversation: updatedConversation,
        versions: updatedVersions,
        currentVersionIndex: updatedVersions.length - 1,
        isRefining: false,
      );
    } else {
      state = state.copyWith(
        isRefining: false,
        error: result.error,
      );
    }
  }

  /// Undo to previous version
  void undo() {
    final result = _versionControl.undo(
      versions: state.versions,
      currentIndex: state.currentVersionIndex,
    );

    if (result.isSuccess) {
      state = state.copyWith(currentVersionIndex: result.newIndex);
    }
  }

  /// Redo to next version
  void redo() {
    final result = _versionControl.redo(
      versions: state.versions,
      currentIndex: state.currentVersionIndex,
    );

    if (result.isSuccess) {
      state = state.copyWith(currentVersionIndex: result.newIndex);
    }
  }

  /// Navigate to specific version
  void goToVersion(int index) {
    final result = _versionControl.navigateToVersion(
      versions: state.versions,
      currentIndex: state.currentVersionIndex,
      targetIndex: index,
    );

    if (result.isSuccess) {
      state = state.copyWith(currentVersionIndex: result.newIndex);
    }
  }

  /// Reset state
  void reset() {
    state = SummaryState();
  }
}

final summaryStateProvider =
    StateNotifierProvider<SummaryStateNotifier, SummaryState>(
  (ref) => SummaryStateNotifier(),
);

// ============================================================================
// EXPORT STATE PROVIDER
// ============================================================================

/// State for export operations
class ExportState {
  final bool isExporting;
  final double progress;
  final Map<String, String> savedPaths; // format -> path
  final String? error;

  ExportState({
    this.isExporting = false,
    this.progress = 0.0,
    this.savedPaths = const {},
    this.error,
  });

  ExportState copyWith({
    bool? isExporting,
    double? progress,
    Map<String, String>? savedPaths,
    String? error,
  }) {
    return ExportState(
      isExporting: isExporting ?? this.isExporting,
      progress: progress ?? this.progress,
      savedPaths: savedPaths ?? this.savedPaths,
      error: error,
    );
  }

  ExportState addSavedPath(String format, String path) {
    final updatedPaths = Map<String, String>.from(savedPaths);
    updatedPaths[format] = path;
    return copyWith(savedPaths: updatedPaths);
  }
}

class ExportStateNotifier extends StateNotifier<ExportState> {
  ExportStateNotifier() : super(ExportState());

  void startExport() {
    state = state.copyWith(isExporting: true, progress: 0.0, error: null);
  }

  void updateProgress(double progress) {
    state = state.copyWith(progress: progress);
  }

  void addExportedFile(String format, String path) {
    state = state.addSavedPath(format, path);
  }

  void completeExport() {
    state = state.copyWith(isExporting: false, progress: 1.0);
  }

  void setError(String error) {
    state = state.copyWith(isExporting: false, error: error);
  }

  void reset() {
    state = ExportState();
  }
}

final exportStateProvider =
    StateNotifierProvider<ExportStateNotifier, ExportState>(
  (ref) => ExportStateNotifier(),
);
