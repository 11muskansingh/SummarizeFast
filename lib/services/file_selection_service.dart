import 'dart:io';
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
      final result = await _filePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: AppConstants.supportedDocumentExtensions,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return FileSelectionResult.cancelled();
      }

      final pickedFile = result.files.first;
      
      // Validate file path exists
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
  final String? error;
  final bool isCancelled;

  FileSelectionResult._({
    this.file,
    this.metadata,
    this.error,
    this.isCancelled = false,
  });

  /// Success result
  factory FileSelectionResult.success(File file, FileMetadata metadata) =>
      FileSelectionResult._(
        file: file,
        metadata: metadata,
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
  bool get isSuccess => file != null && metadata != null;

  /// Check if there was an error
  bool get hasError => error != null;
}
