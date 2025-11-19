import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../widgets/common_widgets.dart';
import '../widgets/file_preview_widget.dart';
import '../providers/app_providers.dart';
import 'configuration_screen.dart';

/// Screen for selecting and previewing files
class UploadScreen extends ConsumerWidget {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(fileStateProvider);

    return Scaffold(
      appBar: GlassAppBar(
        title: 'Select Document',
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.surfaceGradient,
        ),
        child: SafeArea(
          child: fileState.hasFile
              ? _buildFilePreview(context, ref, fileState)
              : _buildFilePicker(context, ref),
        ),
      ),
    );
  }

  Widget _buildFilePicker(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: AppSpacing.xxl),
            
            // Illustration
            Container(
              padding: EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                gradient: AppColors.glassGradient,
                borderRadius: AppSpacing.borderRadiusXL,
                border: Border.all(
                  color: AppColors.glassMedium,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.cloud_upload_outlined,
                size: 80,
                color: AppColors.primary,
              ),
            ),
            
            SizedBox(height: AppSpacing.xl),

            Text(
              'Choose a file to summarize',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: AppSpacing.sm),

            Text(
              'Support for PDF, images, and documents up to 10MB',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: AppSpacing.xxl),

            // File selection buttons
            GradientButton(
              onPressed: () {
                print('📁 [UploadScreen] Choose Document button pressed');
                ref.read(fileStateProvider.notifier).selectDocument();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description, color: Colors.white),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'Choose Document',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSpacing.md),

            GlassCard(
              child: InkWell(
                onTap: () {
                  print('🖼️ [UploadScreen] Choose from Gallery button pressed');
                  ref.read(fileStateProvider.notifier).selectImage();
                },
                borderRadius: AppSpacing.borderRadiusMD,
                child: Padding(
                  padding: AppSpacing.paddingMD,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library, color: AppColors.primary),
                      SizedBox(width: AppSpacing.sm),
                      Text(
                        'Choose from Gallery',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: AppSpacing.md),

            GlassCard(
              child: InkWell(
                onTap: () {
                  print('📸 [UploadScreen] Take Photo button pressed');
                  ref.read(fileStateProvider.notifier).takePhoto();
                },
                borderRadius: AppSpacing.borderRadiusMD,
                child: Padding(
                  padding: AppSpacing.paddingMD,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, color: AppColors.primary),
                      SizedBox(width: AppSpacing.sm),
                      Text(
                        'Take Photo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview(BuildContext context, WidgetRef ref, FileState fileState) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: AppSpacing.paddingLG,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: AppSpacing.md),

                // Success message
                Container(
                  padding: AppSpacing.paddingMD,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: AppSpacing.borderRadiusMD,
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.accent,
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'File selected successfully!',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppSpacing.lg),

                // File preview
                FilePreviewWidget(
                  file: fileState.selectedFile,
                  metadata: fileState.fileMetadata!,
                  onRemove: () {
                    ref.read(fileStateProvider.notifier).clearFile();
                  },
                ),

                SizedBox(height: AppSpacing.md),

                // File info chips
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _buildInfoChip(
                      context,
                      Icons.insert_drive_file,
                      fileState.fileMetadata!.extension.toUpperCase(),
                    ),
                    _buildInfoChip(
                      context,
                      Icons.data_usage,
                      fileState.fileMetadata!.formattedSize,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Bottom action bar
        Container(
          padding: AppSpacing.paddingLG,
          decoration: BoxDecoration(
            gradient: AppColors.glassGradient,
            border: Border(
              top: BorderSide(
                color: AppColors.glassMedium,
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(fileStateProvider.notifier).clearFile();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      side: BorderSide(color: AppColors.border),
                    ),
                    child: Text('Replace File'),
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: GradientButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ConfigurationScreen(),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Icon(Icons.arrow_forward, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
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
          Icon(icon, size: 16, color: AppColors.primary),
          SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
