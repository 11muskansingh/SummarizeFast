import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_colors.dart';

/// A widget that provides undo/redo buttons with keyboard shortcuts
class UndoRedoControls extends ConsumerWidget {
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool canUndo;
  final bool canRedo;
  final bool showLabels;

  const UndoRedoControls({
    super.key,
    required this.onUndo,
    required this.onRedo,
    required this.canUndo,
    required this.canRedo,
    this.showLabels = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildUndoButton(context),
        const SizedBox(width: 8),
        _buildRedoButton(context),
      ],
    );
  }

  Widget _buildUndoButton(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: showLabels
          ? _buildLabeledButton(
              icon: Icons.undo,
              label: 'Undo',
              onPressed: canUndo ? onUndo : null,
              tooltip: 'Undo (Ctrl+Z)',
            )
          : _buildIconButton(
              icon: Icons.undo,
              onPressed: canUndo ? onUndo : null,
              tooltip: 'Undo (Ctrl+Z)',
            ),
    );
  }

  Widget _buildRedoButton(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: showLabels
          ? _buildLabeledButton(
              icon: Icons.redo,
              label: 'Redo',
              onPressed: canRedo ? onRedo : null,
              tooltip: 'Redo (Ctrl+Y)',
            )
          : _buildIconButton(
              icon: Icons.redo,
              onPressed: canRedo ? onRedo : null,
              tooltip: 'Redo (Ctrl+Y)',
            ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: onPressed != null ? AppColors.surface : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: onPressed != null
              ? AppColors.border
              : AppColors.border.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: onPressed != null
              ? AppColors.primary
              : AppColors.textSecondary.withOpacity(0.3),
        ),
        tooltip: tooltip,
        iconSize: 20,
      ),
    );
  }

  Widget _buildLabeledButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: onPressed != null ? AppColors.surface : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: onPressed != null
              ? AppColors.border
              : AppColors.border.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: onPressed != null
                      ? AppColors.primary
                      : AppColors.textSecondary.withOpacity(0.3),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: onPressed != null
                        ? AppColors.textPrimary
                        : AppColors.textSecondary.withOpacity(0.3),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A widget that handles keyboard shortcuts for undo/redo
class UndoRedoShortcuts extends ConsumerWidget {
  final Widget child;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool canUndo;
  final bool canRedo;

  const UndoRedoShortcuts({
    super.key,
    required this.child,
    required this.onUndo,
    required this.onRedo,
    required this.canUndo,
    required this.canRedo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CallbackShortcuts(
      bindings: {
        // Ctrl+Z for Undo
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ): () {
          if (canUndo) {
            onUndo();
          }
        },
        // Ctrl+Y for Redo
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY): () {
          if (canRedo) {
            onRedo();
          }
        },
        // Ctrl+Shift+Z for Redo (alternative)
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyZ,
        ): () {
          if (canRedo) {
            onRedo();
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: child,
      ),
    );
  }
}

/// A widget that displays undo/redo controls with version navigation
class UndoRedoNavigator extends ConsumerStatefulWidget {
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool canUndo;
  final bool canRedo;
  final int currentVersion;
  final int totalVersions;

  const UndoRedoNavigator({
    super.key,
    required this.onUndo,
    required this.onRedo,
    required this.canUndo,
    required this.canRedo,
    required this.currentVersion,
    required this.totalVersions,
  });

  @override
  ConsumerState<UndoRedoNavigator> createState() => _UndoRedoNavigatorState();
}

class _UndoRedoNavigatorState extends ConsumerState<UndoRedoNavigator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleUndo() {
    _controller.forward().then((_) => _controller.reverse());
    widget.onUndo();
  }

  void _handleRedo() {
    _controller.forward().then((_) => _controller.reverse());
    widget.onRedo();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Version indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.2),
                  AppColors.secondary.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.layers,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'v${widget.currentVersion} / ${widget.totalVersions}',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Divider
          Container(
            width: 1,
            height: 24,
            color: AppColors.border,
          ),
          const SizedBox(width: 16),
          // Undo button
          ScaleTransition(
            scale: _scaleAnimation,
            child: IconButton(
              onPressed: widget.canUndo ? _handleUndo : null,
              icon: Icon(
                Icons.undo,
                color: widget.canUndo
                    ? AppColors.primary
                    : AppColors.textSecondary.withOpacity(0.3),
              ),
              tooltip: 'Undo (Ctrl+Z)',
              iconSize: 22,
            ),
          ),
          const SizedBox(width: 4),
          // Redo button
          ScaleTransition(
            scale: _scaleAnimation,
            child: IconButton(
              onPressed: widget.canRedo ? _handleRedo : null,
              icon: Icon(
                Icons.redo,
                color: widget.canRedo
                    ? AppColors.primary
                    : AppColors.textSecondary.withOpacity(0.3),
              ),
              tooltip: 'Redo (Ctrl+Y)',
              iconSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}
