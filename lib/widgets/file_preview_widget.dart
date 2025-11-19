import 'dart:io';
import 'package:flutter/material.dart';
import '../models/file_metadata.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import 'common_widgets.dart';

/// Widget to preview selected files
class FilePreviewWidget extends StatelessWidget {
  final File file;
  final FileMetadata metadata;
  final VoidCallback? onRemove;

  const FilePreviewWidget({
    super.key,
    required this.file,
    required this.metadata,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with file info and remove button
          Row(
            children: [
              // File icon
              Container(
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: AppSpacing.borderRadiusMD,
                ),
                child: Icon(
                  _getFileIcon(),
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              
              // File info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metadata.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      '${metadata.formattedSize} • ${metadata.extension.toUpperCase()}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              
              // Remove button
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: Icon(
                    Icons.close,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: 'Remove file',
                ),
            ],
          ),
          
          SizedBox(height: AppSpacing.lg),
          
          // Preview content
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.surfaceDark.withOpacity(0.5),
              borderRadius: AppSpacing.borderRadiusMD,
              border: Border.all(
                color: AppColors.glassMedium,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: AppSpacing.borderRadiusMD,
              child: _buildPreviewContent(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewContent(BuildContext context) {
    if (metadata.isImage) {
      return _buildImagePreview();
    } else if (metadata.isPdf) {
      return _buildPdfPreview(context);
    } else if (metadata.isDocument) {
      return _buildDocumentPreview(context);
    } else {
      return _buildGenericPreview(context);
    }
  }

  Widget _buildImagePreview() {
    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Icon(
            Icons.broken_image,
            size: 64,
            color: AppColors.textSecondary,
          ),
        );
      },
    );
  }

  Widget _buildPdfPreview(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf,
            size: 64,
            color: AppColors.accentError,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'PDF Document',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Ready to summarize',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentPreview(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description,
            size: 64,
            color: AppColors.accent,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            '${metadata.extension.toUpperCase()} Document',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Ready to summarize',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericPreview(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_drive_file,
            size: 64,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'File Preview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            metadata.name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon() {
    if (metadata.isImage) {
      return Icons.image;
    } else if (metadata.isPdf) {
      return Icons.picture_as_pdf;
    } else if (metadata.isDocument) {
      return Icons.description;
    } else {
      return Icons.insert_drive_file;
    }
  }
}

/// Compact file chip widget for displaying selected file
class FileChip extends StatelessWidget {
  final FileMetadata metadata;
  final VoidCallback? onRemove;

  const FileChip({
    super.key,
    required this.metadata,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.glassGradient,
        borderRadius: AppSpacing.borderRadiusLG,
        border: Border.all(
          color: AppColors.glassMedium,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getFileIcon(),
            size: 16,
            color: AppColors.primary,
          ),
          SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              metadata.name,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onRemove != null) ...[
            SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: onRemove,
              child: Icon(
                Icons.close,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getFileIcon() {
    if (metadata.isImage) {
      return Icons.image;
    } else if (metadata.isPdf) {
      return Icons.picture_as_pdf;
    } else if (metadata.isDocument) {
      return Icons.description;
    } else {
      return Icons.insert_drive_file;
    }
  }
}
