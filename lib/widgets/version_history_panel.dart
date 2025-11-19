import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import '../models/summary_version.dart';
import '../widgets/common_widgets.dart';

/// A panel that displays version history with expansion tile
class VersionHistoryPanel extends ConsumerWidget {
  final List<SummaryVersion> versions;
  final int currentVersionIndex;
  final Function(int index) onVersionSelected;
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;

  const VersionHistoryPanel({
    super.key,
    required this.versions,
    required this.currentVersionIndex,
    required this.onVersionSelected,
    this.isExpanded = false,
    this.onToggleExpanded,
  });

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(timestamp);
    }
  }

  String _getRefinementPromptSummary(String? prompt) {
    if (prompt == null || prompt.isEmpty) {
      return 'Initial summary';
    }
    if (prompt.length <= 50) {
      return prompt;
    }
    return '${prompt.substring(0, 47)}...';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (versions.isEmpty) {
      return const SizedBox.shrink();
    }

    return GlassCard(
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: AppColors.primary.withOpacity(0.1),
          highlightColor: AppColors.primary.withOpacity(0.05),
        ),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          onExpansionChanged: (_) => onToggleExpanded?.call(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.3),
                  AppColors.secondary.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.history,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          title: Text(
            'Version History',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            '${versions.length} ${versions.length == 1 ? 'version' : 'versions'}',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          trailing: Icon(
            isExpanded ? Icons.expand_less : Icons.expand_more,
            color: AppColors.textSecondary,
          ),
          children: [
            _buildVersionList(),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionList() {
    // Show versions in reverse chronological order (newest first)
    final reversedVersions = versions.reversed.toList();

    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: reversedVersions.length,
        separatorBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Divider(
            height: 1,
            color: AppColors.border.withOpacity(0.3),
          ),
        ),
        itemBuilder: (context, index) {
          final version = reversedVersions[index];
          final originalIndex = versions.length - 1 - index;
          final isCurrent = originalIndex == currentVersionIndex;

          return _buildVersionItem(
            version: version,
            versionIndex: originalIndex,
            isCurrent: isCurrent,
          );
        },
      ),
    );
  }

  Widget _buildVersionItem({
    required SummaryVersion version,
    required int versionIndex,
    required bool isCurrent,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isCurrent ? null : () => onVersionSelected(versionIndex),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: isCurrent
              ? BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.secondary.withOpacity(0.1),
                    ],
                  ),
                )
              : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Version indicator
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppColors.primary
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isCurrent
                        ? AppColors.primary
                        : AppColors.border,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    'v${version.versionNumber}',
                    style: TextStyle(
                      color: isCurrent
                          ? Colors.white
                          : AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Version details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _getRefinementPromptSummary(version.refinementPrompt),
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Current',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimestamp(version.timestamp),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.text_fields,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${version.content.split(' ').length} words',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Navigation icon
              if (!isCurrent)
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact version history indicator
class CompactVersionIndicator extends StatelessWidget {
  final int currentVersion;
  final int totalVersions;
  final VoidCallback? onTap;

  const CompactVersionIndicator({
    super.key,
    required this.currentVersion,
    required this.totalVersions,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
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
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'v$currentVersion of $totalVersions',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
