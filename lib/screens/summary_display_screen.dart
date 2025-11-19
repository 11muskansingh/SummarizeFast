import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../providers/app_providers.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../widgets/common_widgets.dart';

/// Screen to display generated summary with full details
class SummaryDisplayScreen extends ConsumerWidget {
  const SummaryDisplayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryState = ref.watch(summaryStateProvider);
    final fileState = ref.watch(fileStateProvider);

    if (!summaryState.hasVersions) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Summary'),
        ),
        body: const Center(
          child: Text('No summary available'),
        ),
      );
    }

    final currentVersion = summaryState.currentVersion!;
    final metadata = fileState.fileMetadata!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Summary Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white),
            onPressed: () => _copyToClipboard(context, ref),
            tooltip: 'Copy',
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => _showSnackbar(context, 'Share coming soon!'),
            tooltip: 'Share',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingXL,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File info card
            GlassCard(
              child: Padding(
                padding: AppSpacing.paddingLG,
                child: Row(
                  children: [
                    const Icon(
                      Icons.description,
                      color: AppColors.primary,
                      size: 40,
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            metadata.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            '${metadata.formattedSize} • ${metadata.extension.toUpperCase()}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: Text(
                        'v${currentVersion.versionNumber}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: AppSpacing.xl),

            // Summary content
            GlassCard(
              child: Padding(
                padding: AppSpacing.paddingXL,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: AppColors.primary),
                        SizedBox(width: AppSpacing.sm),
                        Text(
                          'Generated Summary',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.md),
                    const Divider(),
                    SizedBox(height: AppSpacing.lg),
                    SelectableText(
                      currentVersion.content,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.8,
                            fontSize: 16,
                          ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: AppSpacing.xl),

            // Metadata section
            GlassCard(
              child: Padding(
                padding: AppSpacing.paddingLG,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Summary Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(height: AppSpacing.md),
                    _buildDetailRow(
                      context,
                      Icons.schedule,
                      'Generated',
                      currentVersion.formattedTime,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    _buildDetailRow(
                      context,
                      Icons.text_fields,
                      'Word Count',
                      '~${_estimateWordCount(currentVersion.content)} words',
                    ),
                    SizedBox(height: AppSpacing.sm),
                    _buildDetailRow(
                      context,
                      Icons.format_size,
                      'Character Count',
                      '${currentVersion.content.length} characters',
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: AppSpacing.paddingLG,
        decoration: const BoxDecoration(
          color: AppColors.surfaceDark,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showSnackbar(context, 'Refine feature coming in Task 23-50!'),
                icon: const Icon(Icons.edit),
                label: const Text('Refine Summary'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                ),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showSnackbar(context, 'PDF export coming in Task 22!'),
                icon: const Icon(Icons.file_download),
                label: const Text('Export PDF'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        SizedBox(width: AppSpacing.sm),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }

  int _estimateWordCount(String text) {
    return text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  void _copyToClipboard(BuildContext context, WidgetRef ref) {
    final summaryState = ref.read(summaryStateProvider);
    if (summaryState.currentVersion != null) {
      Clipboard.setData(ClipboardData(text: summaryState.currentVersion!.content));
      _showSnackbar(context, 'Summary copied to clipboard!', isSuccess: true);
    }
  }

  void _showSnackbar(BuildContext context, String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppColors.accent : AppColors.primary,
      ),
    );
  }
}
