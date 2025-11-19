import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_colors.dart';
import '../widgets/common_widgets.dart';

/// A widget that displays the generated summary with various actions
class SummaryDisplayWidget extends StatefulWidget {
  final String summary;
  final int? versionNumber;
  final bool isLoading;
  final VoidCallback? onCopy;
  final VoidCallback? onFullScreen;

  const SummaryDisplayWidget({
    super.key,
    required this.summary,
    this.versionNumber,
    this.isLoading = false,
    this.onCopy,
    this.onFullScreen,
  });

  @override
  State<SummaryDisplayWidget> createState() => _SummaryDisplayWidgetState();
}

class _SummaryDisplayWidgetState extends State<SummaryDisplayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _showCopiedFeedback = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(SummaryDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.summary != widget.summary && widget.summary.isNotEmpty) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleCopy() {
    Clipboard.setData(ClipboardData(text: widget.summary));
    setState(() => _showCopiedFeedback = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showCopiedFeedback = false);
      }
    });
    widget.onCopy?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingSkeleton();
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          _buildSummaryContent(context),
          const SizedBox(height: 16),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.3),
                    AppColors.secondary.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Summary',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.versionNumber != null) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.border,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'v${widget.versionNumber}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        IconButton(
          onPressed: widget.onFullScreen,
          icon: Icon(
            Icons.fullscreen,
            color: AppColors.textSecondary,
          ),
          tooltip: 'Full Screen',
        ),
      ],
    );
  }

  Widget _buildSummaryContent(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: SelectableText(
          widget.summary.isEmpty ? 'Your summary will appear here...' : widget.summary,
          style: TextStyle(
            color: widget.summary.isEmpty
                ? AppColors.textSecondary
                : AppColors.textPrimary,
            fontSize: 15,
            height: 1.6,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.summary.isEmpty ? null : _handleCopy,
            icon: Icon(
              _showCopiedFeedback ? Icons.check : Icons.copy,
              size: 18,
            ),
            label: Text(_showCopiedFeedback ? 'Copied!' : 'Copy to Clipboard'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _showCopiedFeedback ? Colors.green : AppColors.primary,
              side: BorderSide(
                color: _showCopiedFeedback
                    ? Colors.green.withOpacity(0.5)
                    : AppColors.border,
                width: 1,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
          ),
          child: IconButton(
            onPressed: widget.summary.isEmpty ? null : () {
              // TODO: Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share functionality coming soon')),
              );
            },
            icon: Icon(
              Icons.share,
              color: AppColors.textSecondary,
            ),
            tooltip: 'Share',
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          Row(
            children: [
              ShimmerLoader(
                width: 120,
                height: 32,
                borderRadius: BorderRadius.circular(20),
              ),
              const SizedBox(width: 12),
              ShimmerLoader(
                width: 60,
                height: 32,
                borderRadius: BorderRadius.circular(16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Content skeleton
          Container(
            width: double.infinity,
            height: 250,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoader(
                  width: double.infinity,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 12),
                ShimmerLoader(
                  width: double.infinity,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 12),
                ShimmerLoader(
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 20),
                ShimmerLoader(
                  width: double.infinity,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 12),
                ShimmerLoader(
                  width: double.infinity,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 12),
                ShimmerLoader(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Actions skeleton
          Row(
            children: [
              Expanded(
                child: ShimmerLoader(
                  height: 44,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              ShimmerLoader(
                width: 44,
                height: 44,
                borderRadius: BorderRadius.circular(12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A shimmer loading effect widget
class ShimmerLoader extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  const ShimmerLoader({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<ShimmerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((v) => v.clamp(0.0, 1.0)).toList(),
              colors: [
                AppColors.surface,
                AppColors.surfaceDark,
                AppColors.surface,
              ],
            ),
          ),
        );
      },
    );
  }
}
