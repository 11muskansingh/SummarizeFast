import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_colors.dart';
import '../services/prompt_service.dart';
import '../widgets/common_widgets.dart';

/// A widget for custom refinement input with suggestions
class CustomRefinementInput extends ConsumerStatefulWidget {
  final Function(String prompt) onRefine;
  final bool isEnabled;
  final int? maxLength;

  const CustomRefinementInput({
    super.key,
    required this.onRefine,
    this.isEnabled = true,
    this.maxLength = 500,
  });

  @override
  ConsumerState<CustomRefinementInput> createState() =>
      _CustomRefinementInputState();
}

class _CustomRefinementInputState
    extends ConsumerState<CustomRefinementInput> {
  late TextEditingController _controller;
  bool _isRefining = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(() {
      if (_errorMessage != null) {
        setState(() => _errorMessage = null);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleRefine() async {
    final prompt = _controller.text.trim();

    // Validate
    final validationResult = PromptService.validateCustomPrompt(prompt);
    if (!validationResult.isValid) {
      setState(() => _errorMessage = validationResult.error);
      return;
    }

    setState(() {
      _isRefining = true;
      _errorMessage = null;
    });

    try {
      await widget.onRefine(prompt);
      _controller.clear();
    } catch (e) {
      setState(() => _errorMessage = 'Failed to refine summary: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isRefining = false);
      }
    }
  }

  void _insertSuggestion(String suggestion) {
    final currentText = _controller.text;
    final newText = currentText.isEmpty ? suggestion : '$currentText $suggestion';
    _controller.text = newText;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: newText.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildTextField(),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            _buildErrorMessage(),
          ],
          const SizedBox(height: 16),
          _buildSuggestionChips(),
          const SizedBox(height: 16),
          _buildRefineButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.edit_note,
          size: 20,
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        Text(
          'Custom Refinement',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        if (widget.maxLength != null && _controller.text.isNotEmpty)
          Text(
            '${_controller.text.length}/${widget.maxLength}',
            style: TextStyle(
              color: _controller.text.length > widget.maxLength!
                  ? AppColors.accentError
                  : AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
      ],
    );
  }

  Widget _buildTextField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _errorMessage != null
              ? AppColors.accentError.withOpacity(0.5)
              : AppColors.border.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _controller,
        enabled: widget.isEnabled && !_isRefining,
        maxLines: 4,
        maxLength: widget.maxLength,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText: 'Tell me how to improve the summary...\n\nExamples:\n- Focus more on the methodology\n- Add specific examples\n- Remove technical jargon',
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.7),
            fontSize: 14,
            height: 1.5,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          counterText: '', // Hide default counter
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accentError.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.accentError.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 16,
            color: AppColors.accentError,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: AppColors.accentError,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips() {
    final suggestions = [
      'Focus on...',
      'Add more about...',
      'Remove details about...',
      'Emphasize...',
      'Clarify...',
      'Include examples',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Suggestions',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions.map((suggestion) {
            return ActionChip(
              label: Text(
                suggestion,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
              ),
              avatar: Icon(
                Icons.add,
                size: 14,
                color: AppColors.primary,
              ),
              onPressed: widget.isEnabled && !_isRefining
                  ? () => _insertSuggestion(suggestion)
                  : null,
              backgroundColor: AppColors.surface,
              side: BorderSide(
                color: AppColors.border,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRefineButton() {
    return SizedBox(
      width: double.infinity,
      child: GradientButton(
        onPressed: widget.isEnabled && !_isRefining && _controller.text.trim().isNotEmpty
            ? _handleRefine
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isRefining)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
              const SizedBox(width: 8),
              Text(
                _isRefining ? 'Refining...' : 'Refine Summary',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact version of custom refinement input
class CompactCustomRefinementInput extends ConsumerStatefulWidget {
  final Function(String prompt) onRefine;
  final bool isEnabled;

  const CompactCustomRefinementInput({
    super.key,
    required this.onRefine,
    this.isEnabled = true,
  });

  @override
  ConsumerState<CompactCustomRefinementInput> createState() =>
      _CompactCustomRefinementInputState();
}

class _CompactCustomRefinementInputState
    extends ConsumerState<CompactCustomRefinementInput> {
  late TextEditingController _controller;
  bool _isRefining = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleRefine() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    // Validate
    final validationResult = PromptService.validateCustomPrompt(prompt);
    if (!validationResult.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationResult.error ?? 'Invalid prompt'),
          backgroundColor: AppColors.accentError,
        ),
      );
      return;
    }

    setState(() => _isRefining = true);

    try {
      await widget.onRefine(prompt);
      _controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refine: ${e.toString()}'),
            backgroundColor: AppColors.accentError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefining = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: widget.isEnabled && !_isRefining,
              maxLines: 1,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'How should I refine this?',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onSubmitted: widget.isEnabled && !_isRefining ? (_) => _handleRefine() : null,
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: widget.isEnabled && !_isRefining && _controller.text.trim().isNotEmpty
                ? _handleRefine
                : null,
            icon: _isRefining
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                : Icon(
                    Icons.send,
                    color: _controller.text.trim().isEmpty
                        ? AppColors.textSecondary
                        : AppColors.primary,
                  ),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
