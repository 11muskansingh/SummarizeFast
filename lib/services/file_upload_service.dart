import 'dart:io';
import 'dart:async';
import '../models/file_metadata.dart';

/// Service for handling file upload operations with progress tracking
class FileUploadService {
  static FileUploadService? _instance;

  FileUploadService._internal();

  /// Get singleton instance
  static FileUploadService get instance {
    _instance ??= FileUploadService._internal();
    return _instance!;
  }

  /// Upload file with progress tracking
  /// Note: For now, this simulates upload. In production with Gemini File API,
  /// this would handle actual file upload to Google's servers
  Future<FileUploadResult> uploadFile(
    File file,
    FileMetadata metadata, {
    Function(double)? onProgress,
    CancellationToken? cancellationToken,
  }) async {
    try {
      // Validate file exists
      if (!await file.exists()) {
        return FileUploadResult.error('File does not exist');
      }

      // Simulate upload progress (in real implementation, this would track actual upload)
      final steps = 10;
      for (int i = 0; i <= steps; i++) {
        // Check for cancellation
        if (cancellationToken?.isCancelled ?? false) {
          return FileUploadResult.cancelled();
        }

        // Report progress
        final progress = i / steps;
        onProgress?.call(progress);

        // Simulate network delay
        await Future.delayed(Duration(milliseconds: 200));
      }

      // Generate URI (48-hour validity)
      final uploadedUri = _generateFileUri(file.path);
      final expiresAt = DateTime.now().add(Duration(hours: 48));

      return FileUploadResult.success(
        uri: uploadedUri,
        expiresAt: expiresAt,
      );
    } catch (e) {
      return FileUploadResult.error('Upload failed: ${e.toString()}');
    }
  }

  /// Upload with retry logic
  Future<FileUploadResult> uploadFileWithRetry(
    File file,
    FileMetadata metadata, {
    int maxRetries = 3,
    Function(double)? onProgress,
    CancellationToken? cancellationToken,
  }) async {
    int attempts = 0;
    Duration delay = Duration(seconds: 1);

    while (attempts < maxRetries) {
      attempts++;

      final result = await uploadFile(
        file,
        metadata,
        onProgress: onProgress,
        cancellationToken: cancellationToken,
      );

      if (result.isSuccess || result.isCancelled) {
        return result;
      }

      // Don't retry if this was the last attempt
      if (attempts >= maxRetries) {
        return result;
      }

      // Wait before retry with exponential backoff
      await Future.delayed(delay);
      delay *= 2; // Double the delay for next retry
    }

    return FileUploadResult.error('Upload failed after $maxRetries attempts');
  }

  /// Check if uploaded file URI is still valid (within 48 hours)
  bool isFileUriValid(DateTime uploadedAt) {
    final now = DateTime.now();
    final expiresAt = uploadedAt.add(Duration(hours: 48));
    return now.isBefore(expiresAt);
  }

  /// Get time remaining until URI expires
  Duration getTimeRemaining(DateTime uploadedAt) {
    final now = DateTime.now();
    final expiresAt = uploadedAt.add(Duration(hours: 48));
    return expiresAt.difference(now);
  }

  /// Generate file URI (in production, this would come from Gemini File API)
  String _generateFileUri(String filePath) {
    // For now, use file:// URI. In production, this would be gs:// or similar
    return 'file://$filePath';
  }
}

/// Token for cancelling upload operations
class CancellationToken {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }
}

/// Result of file upload operation
class FileUploadResult {
  final String? uri;
  final DateTime? expiresAt;
  final String? error;
  final bool isCancelled;

  FileUploadResult._({
    this.uri,
    this.expiresAt,
    this.error,
    this.isCancelled = false,
  });

  factory FileUploadResult.success({
    required String uri,
    required DateTime expiresAt,
  }) =>
      FileUploadResult._(
        uri: uri,
        expiresAt: expiresAt,
      );

  factory FileUploadResult.error(String error) =>
      FileUploadResult._(error: error);

  factory FileUploadResult.cancelled() =>
      FileUploadResult._(isCancelled: true);

  bool get isSuccess => uri != null && expiresAt != null;
  bool get hasError => error != null;

  /// Check if URI is still valid
  bool get isValid {
    if (!isSuccess || expiresAt == null) return false;
    return DateTime.now().isBefore(expiresAt!);
  }

  /// Get time remaining until expiration
  Duration? get timeRemaining {
    if (!isSuccess || expiresAt == null) return null;
    final remaining = expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Get formatted expiration time
  String get expirationInfo {
    if (!isSuccess || expiresAt == null) return '';
    
    final remaining = timeRemaining;
    if (remaining == null || remaining == Duration.zero) {
      return 'Expired';
    }

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);

    if (hours > 0) {
      return 'Valid for ${hours}h ${minutes}m';
    } else {
      return 'Valid for ${minutes}m';
    }
  }
}
