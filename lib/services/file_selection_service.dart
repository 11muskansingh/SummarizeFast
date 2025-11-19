import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../models/file_metadata.dart';
import '../utils/constants.dart';

/// Service for file selection operations
class FileSelectionService {
  final FilePicker _filePicker = FilePicker.platform;
  final ImagePicker _imagePicker = ImagePicker();

  /// Pick a document file
  Future<FileSelectionResult> pickDocument() async {
    try {
      print('📄 [FileSelectionService] pickDocument() called (Platform: ${kIsWeb ? "Web" : "Native"})');
      final result = await _filePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: AppConstants.supportedDocumentExtensions,
        allowMultiple: false,
        withData: kIsWeb, // Load bytes for web platform
      );
      print('📄 [FileSelectionService] FilePicker result: ${result != null ? "success" : "cancelled"}');

      if (result == null || result.files.isEmpty) {
        print('⚠️ [FileSelectionService] User cancelled file picker');
        return FileSelectionResult.cancelled();
      }

      final pickedFile = result.files.first;
      print('📄 [FileSelectionService] Selected file: ${pickedFile.name}, size: ${pickedFile.size} bytes');
      
      // Validate file size
      if (pickedFile.size > AppConstants.maxFileSizeBytes) {
        print('❌ [FileSelectionService] File too large: ${pickedFile.size} > ${AppConstants.maxFileSizeBytes}');
        return FileSelectionResult.error(
          'File size exceeds ${AppConstants.maxFileSizeDisplay} limit',
        );
      }

      // Handle web platform differently
      if (kIsWeb) {
        print('🌐 [FileSelectionService] Web platform - using bytes instead of path');
        // For web, we use PlatformFile directly with bytes
        if (pickedFile.bytes == null) {
          print('❌ [FileSelectionService] File bytes are null');
          return FileSelectionResult.error('Unable to read file content');
        }
        
        print('🌐 [FileSelectionService] Creating metadata for web (avoiding path property)');
        // Create metadata from PlatformFile (isWeb=true avoids accessing path property)
        final metadata = FileMetadata.fromPlatformFile(pickedFile, isWeb: true);
        print('✅ [FileSelectionService] File metadata created: ${metadata.name}');
        
        return FileSelectionResult.success(null, metadata, bytes: pickedFile.bytes);
      } else {
        // For native platforms, use File
        if (pickedFile.path == null) {
          print('❌ [FileSelectionService] File path is null');
          return FileSelectionResult.error('Unable to access file path');
        }

        final file = File(pickedFile.path!);
        print('📄 [FileSelectionService] File path: ${pickedFile.path}');

        // Create metadata
        final metadata = FileMetadata.fromFile(file);
        print('✅ [FileSelectionService] File metadata created: ${metadata.name}');

        return FileSelectionResult.success(file, metadata);
      }
    } catch (e) {
      print('❌ [FileSelectionService] Error picking document: $e');
      return FileSelectionResult.error(
        'Failed to pick document: ${e.toString()}',
      );
    }
  }

  /// Pick an image from gallery
  Future<FileSelectionResult> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 4096,
        maxHeight: 4096,
      );

      if (pickedFile == null) {
        return FileSelectionResult.cancelled();
      }

      final file = File(pickedFile.path);

      // Validate file size
      final sizeBytes = await file.length();
      if (sizeBytes > AppConstants.maxFileSizeBytes) {
        return FileSelectionResult.error(
          'Image size exceeds ${AppConstants.maxFileSizeDisplay} limit',
        );
      }

      // Create metadata
      final metadata = FileMetadata.fromFile(file);

      return FileSelectionResult.success(file, metadata);
    } catch (e) {
      return FileSelectionResult.error(
        'Failed to pick image: ${e.toString()}',
      );
    }
  }

  /// Take a photo with camera
  Future<FileSelectionResult> takePhoto() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 4096,
        maxHeight: 4096,
      );

      if (pickedFile == null) {
        return FileSelectionResult.cancelled();
      }

      final file = File(pickedFile.path);

      // Validate file size
      final sizeBytes = await file.length();
      if (sizeBytes > AppConstants.maxFileSizeBytes) {
        return FileSelectionResult.error(
          'Photo size exceeds ${AppConstants.maxFileSizeDisplay} limit',
        );
      }

      // Create metadata
      final metadata = FileMetadata.fromFile(file);

      return FileSelectionResult.success(file, metadata);
    } catch (e) {
      return FileSelectionResult.error(
        'Failed to take photo: ${e.toString()}',
      );
    }
  }

  /// Pick any file (all supported types)
  Future<FileSelectionResult> pickAnyFile() async {
    try {
      final result = await _filePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          ...AppConstants.supportedDocumentExtensions,
          ...AppConstants.supportedImageExtensions,
        ],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return FileSelectionResult.cancelled();
      }

      final pickedFile = result.files.first;
      
      if (pickedFile.path == null) {
        return FileSelectionResult.error('Unable to access file path');
      }

      final file = File(pickedFile.path!);

      // Validate file size
      final sizeBytes = await file.length();
      if (sizeBytes > AppConstants.maxFileSizeBytes) {
        return FileSelectionResult.error(
          'File size exceeds ${AppConstants.maxFileSizeDisplay} limit',
        );
      }

      // Create metadata
      final metadata = FileMetadata.fromFile(file);

      return FileSelectionResult.success(file, metadata);
    } catch (e) {
      return FileSelectionResult.error(
        'Failed to pick file: ${e.toString()}',
      );
    }
  }

  /// Validate if file type is supported
  bool isFileTypeSupported(String extension) {
    return AppConstants.supportedDocumentExtensions.contains(extension) ||
        AppConstants.supportedImageExtensions.contains(extension);
  }

  /// Validate file size
  bool isFileSizeValid(int sizeBytes) {
    return sizeBytes <= AppConstants.maxFileSizeBytes;
  }
}

/// Result of file selection operation
class FileSelectionResult {
  final File? file;
  final FileMetadata? metadata;
  final List<int>? bytes; // For web platform
  final String? error;
  final bool isCancelled;

  FileSelectionResult._({
    this.file,
    this.metadata,
    this.bytes,
    this.error,
    this.isCancelled = false,
  });

  /// Success result (for native platforms with File)
  factory FileSelectionResult.success(File? file, FileMetadata metadata, {List<int>? bytes}) =>
      FileSelectionResult._(
        file: file,
        metadata: metadata,
        bytes: bytes,
      );

  /// Error result
  factory FileSelectionResult.error(String error) => FileSelectionResult._(
        error: error,
      );

  /// Cancelled result
  factory FileSelectionResult.cancelled() => FileSelectionResult._(
        isCancelled: true,
      );

  /// Check if selection was successful
  bool get isSuccess => metadata != null && (file != null || bytes != null);

  /// Check if there was an error
  bool get hasError => error != null;
}
