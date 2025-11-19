import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../utils/app_colors.dart';
import '../services/prompt_service.dart';

/// A widget that displays quick refinement action chips
class QuickRefinementActions extends ConsumerStatefulWidget {
  final Function(String action, String prompt) onRefine;
  final bool isEnabled;

  const QuickRefinementActions({
    super.key,
    required this.onRefine,
    this.isEnabled = true,
  });

  @override
  ConsumerState<QuickRefinementActions> createState() =>
      _QuickRefinementActionsState();
}

class _QuickRefinementActionsState
    extends ConsumerState<QuickRefinementActions> {
  String? _loadingAction;

  void _handleAction(String action, String prompt) async {
    if (!widget.isEnabled || _loadingAction != null) return;

    // Haptic feedback
    HapticFeedback.lightImpact();

    setState(() => _loadingAction = action);

    try {
      await widget.onRefine(action, prompt);
    } finally {
      if (mounted) {
        setState(() => _loadingAction = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quickActions = PromptService.getQuickActions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_fix_high,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Quick Refinements',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quickActions.map((action) {
            final isLoading = _loadingAction == action.id;
            final isDisabled = !widget.isEnabled || (_loadingAction != null && !isLoading);

            return _buildActionChip(
              label: action.label,
              icon: _getIconForAction(action.id),
              action: action.id,
              description: action.description,
              isLoading: isLoading,
              isDisabled: isDisabled,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionChip({
    required String label,
    required IconData icon,
    required String action,
    required String description,
    required bool isLoading,
    required bool isDisabled,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: ActionChip(
        avatar: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : Icon(
                icon,
                size: 16,
                color: isDisabled
                    ? AppColors.textSecondary.withOpacity(0.5)
                    : AppColors.primary,
              ),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDisabled
                ? AppColors.textSecondary.withOpacity(0.5)
                : AppColors.textPrimary,
          ),
        ),
        onPressed: isDisabled
            ? null
            : () => _handleAction(action, description),
        backgroundColor: AppColors.surface,
        side: BorderSide(
          color: isLoading
              ? AppColors.primary.withOpacity(0.5)
              : AppColors.border,
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        elevation: 0,
        pressElevation: 2,
      ),
    );
  }

  IconData _getIconForAction(String action) {
    switch (action) {
      case 'shorter':
        return Icons.compress;
      case 'longer':
        return Icons.expand;
      case 'simpler':
        return Icons.lightbulb_outline;
      case 'technical':
        return Icons.science;
      case 'bullet_points':
        return Icons.format_list_bulleted;
      case 'add_details':
        return Icons.add_circle_outline;
      default:
        return Icons.edit;
    }
  }
}

/// A compact version of quick refinement actions for smaller spaces
class CompactQuickActions extends ConsumerStatefulWidget {
  final Function(String action, String prompt) onRefine;
  final bool isEnabled;

  const CompactQuickActions({
    super.key,
    required this.onRefine,
    this.isEnabled = true,
  });

  @override
  ConsumerState<CompactQuickActions> createState() =>
      _CompactQuickActionsState();
}

class _CompactQuickActionsState extends ConsumerState<CompactQuickActions> {
  String? _loadingAction;

  void _handleAction(String action, String prompt) async {
    if (!widget.isEnabled || _loadingAction != null) return;

    HapticFeedback.lightImpact();

    setState(() => _loadingAction = action);

    try {
      await widget.onRefine(action, prompt);
    } finally {
      if (mounted) {
        setState(() => _loadingAction = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quickActions = PromptService.getQuickActions();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: quickActions.map((action) {
          final isLoading = _loadingAction == action.id;
          final isDisabled = !widget.isEnabled || (_loadingAction != null && !isLoading);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildCompactChip(
              label: action.label,
              icon: _getIconForAction(action.id),
              action: action.id,
              description: action.description,
              isLoading: isLoading,
              isDisabled: isDisabled,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCompactChip({
    required String label,
    required IconData icon,
    required String action,
    required String description,
    required bool isLoading,
    required bool isDisabled,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLoading
              ? AppColors.primary.withOpacity(0.5)
              : AppColors.border,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled
              ? null
              : () => _handleAction(action, description),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                else
                  Icon(
                    icon,
                    size: 14,
                    color: isDisabled
                        ? AppColors.textSecondary.withOpacity(0.5)
                        : AppColors.primary,
                  ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDisabled
                        ? AppColors.textSecondary.withOpacity(0.5)
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForAction(String action) {
    switch (action) {
      case 'shorter':
        return Icons.compress;
      case 'longer':
        return Icons.expand;
      case 'simpler':
        return Icons.lightbulb_outline;
      case 'technical':
        return Icons.science;
      case 'bullet_points':
        return Icons.format_list_bulleted;
      case 'add_details':
        return Icons.add_circle_outline;
      default:
        return Icons.edit;
    }
  }
}
