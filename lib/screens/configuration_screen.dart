import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../widgets/common_widgets.dart';
import '../models/summary_size.dart';
import '../providers/app_providers.dart';
import '../services/prompt_service.dart';
import 'summary_display_screen.dart';

/// Screen for configuring summary generation options
class ConfigurationScreen extends ConsumerStatefulWidget {
  const ConfigurationScreen({super.key});

  @override
  ConsumerState<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends ConsumerState<ConfigurationScreen> {
  final TextEditingController _customPromptController = TextEditingController();
  bool _isGenerating = false;

  @override
  void dispose() {
    _customPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summarySize = ref.watch(summaryConfigProvider);
    final fileState = ref.watch(fileStateProvider);
    final summaryState = ref.watch(summaryStateProvider);

    // Check if already generating
    if (summaryState.isGenerating && !_isGenerating) {
      _isGenerating = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGenerationDialog(context);
      });
    }

    return Scaffold(
      appBar: GlassAppBar(
        title: 'Configure Summary',
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.surfaceGradient,
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.paddingLG,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: AppSpacing.md),

                    // Summary Size Selection
                    _buildSectionTitle(context, 'Summary Length'),
                    SizedBox(height: AppSpacing.md),
                    _buildSizeSelectorCards(summarySize),

                    SizedBox(height: AppSpacing.xl),

                    // Custom Prompt Section
                    _buildSectionTitle(context, 'Custom Instructions (Optional)'),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'Add specific instructions to customize your summary',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    SizedBox(height: AppSpacing.md),
                    _buildCustomPromptField(),

                    SizedBox(height: AppSpacing.md),

                    // Example Prompts
                    _buildExamplePrompts(),

                    SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),

            // Generate Button
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
                child: GradientButton(
                  onPressed: _isGenerating || !fileState.hasFile
                      ? null
                      : () => _generateSummary(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white),
                      SizedBox(width: AppSpacing.sm),
                      Text(
                        'Generate Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildSizeSelectorCards(SummarySize selectedSize) {
    return Column(
      children: SummarySize.values.map((size) {
        final isSelected = size == selectedSize;
        return Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: GlassCard(
            child: InkWell(
              onTap: () {
                ref.read(summaryConfigProvider.notifier).setSummarySize(size);
              },
              borderRadius: AppSpacing.borderRadiusMD,
              child: Container(
                padding: AppSpacing.paddingMD,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                  borderRadius: AppSpacing.borderRadiusMD,
                ),
                child: Row(
                  children: [
                    // Radio indicator
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : null,
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            size.displayName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            size.description,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCustomPromptField() {
    return GlassCard(
      child: TextField(
        controller: _customPromptController,
        maxLines: 4,
        maxLength: 1000,
        decoration: InputDecoration(
          hintText: 'e.g., Focus on the financial implications...',
          hintStyle: TextStyle(color: AppColors.textTertiary),
          border: InputBorder.none,
          counterStyle: TextStyle(color: AppColors.textSecondary),
        ),
        style: TextStyle(color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildExamplePrompts() {
    final examples = PromptService.getExamplePrompts();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick suggestions:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
        SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: examples.take(4).map((example) {
            return ActionChip(
              label: Text(
                example,
                style: TextStyle(fontSize: 12),
              ),
              backgroundColor: AppColors.glassLight,
              side: BorderSide(color: AppColors.glassMedium),
              onPressed: () {
                _customPromptController.text = example;
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _generateSummary(BuildContext context) async {
    print('⚙️ [ConfigurationScreen] _generateSummary() called');
    final fileState = ref.read(fileStateProvider);
    final summarySize = ref.read(summaryConfigProvider);
    final customPrompt = _customPromptController.text.trim();

    print('⚙️ [ConfigurationScreen] FileState check:');
    print('   - Has file: ${fileState.selectedFile != null}');
    print('   - Has bytes: ${fileState.fileBytes != null}');
    print('   - Has metadata: ${fileState.fileMetadata != null}');
    print('   - Summary size: ${summarySize.name}');

    // Validate we have file data
    if (!fileState.hasFile) {
      print('❌ [ConfigurationScreen] No file data available');
      _showError(context, 'No file selected');
      return;
    }

    // Validate custom prompt if provided
    if (customPrompt.isNotEmpty) {
      print('⚙️ [ConfigurationScreen] Validating custom prompt');
      final validation = PromptService.validateCustomPrompt(customPrompt);
      if (!validation.isValid) {
        print('❌ [ConfigurationScreen] Invalid custom prompt: ${validation.error}');
        _showError(context, validation.error ?? 'Invalid prompt');
        return;
      }
    }

    print('✅ [ConfigurationScreen] Starting summary generation');
    // Start generation
    await ref.read(summaryStateProvider.notifier).generateSummary(
          file: fileState.selectedFile,
          fileBytes: fileState.fileBytes,
          metadata: fileState.fileMetadata!,
          summarySize: summarySize,
          customInstructions: customPrompt.isEmpty ? null : customPrompt,
        );
    print('⚙️ [ConfigurationScreen] Summary generation completed');

    // Check result
    final summaryState = ref.read(summaryStateProvider);
    print('⚙️ [ConfigurationScreen] Summary state check:');
    print('   - Has versions: ${summaryState.hasVersions}');
    print('   - Has error: ${summaryState.error != null}');
    print('   - Error message: ${summaryState.error}');
    print('   - Is generating: ${summaryState.isGenerating}');
    
    if (mounted) {
      print('⚙️ [ConfigurationScreen] Closing generation dialog');
      Navigator.pop(context); // Close generation dialog

      if (summaryState.hasVersions) {
        // Success - show summary
        print('✅ [ConfigurationScreen] Summary generated successfully!');
        setState(() => _isGenerating = false);
        
        // Show the generated summary
        final currentVersion = summaryState.currentVersion;
        if (currentVersion != null) {
          print('📄 [ConfigurationScreen] Displaying summary: ${currentVersion.content.substring(0, 50)}...');
          _showSummaryDialog(context, currentVersion.content);
        } else {
          _showSuccess(context, 'Summary generated successfully!');
        }
      } else if (summaryState.error != null) {
        print('❌ [ConfigurationScreen] Generation error: ${summaryState.error}');
        _showError(context, summaryState.error!);
        setState(() => _isGenerating = false);
      } else {
        print('⚠️ [ConfigurationScreen] No versions and no error - unexpected state');
      }
    }
  }

  void _showGenerationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassCard(
            child: Padding(
              padding: AppSpacing.paddingXL,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    'Generating Summary...',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'This may take a few moments',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSummaryDialog(BuildContext context, String summary) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassCard(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: 600,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: AppSpacing.paddingLG,
                    child: Row(
                      children: [
                        Icon(Icons.description, color: AppColors.primary, size: 28),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'Generated Summary',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1),
                  
                  // Summary Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: AppSpacing.paddingXL,
                      child: SelectableText(
                        summary,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                              fontSize: 16,
                            ),
                      ),
                    ),
                  ),
                  
                  Divider(height: 1),
                  
                  // Actions
                  Padding(
                    padding: AppSpacing.paddingLG,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Close'),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context); // Close dialog first
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SummaryDisplayScreen(),
                              ),
                            );
                          },
                          icon: Icon(Icons.open_in_new),
                          label: Text('View Full Details'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.accentError,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
