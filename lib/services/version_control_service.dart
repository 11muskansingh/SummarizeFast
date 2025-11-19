import '../models/summary_version.dart';

/// Service for managing version history and navigation
class VersionControlService {
  /// Navigate to a specific version by index
  VersionNavigationResult navigateToVersion({
    required List<SummaryVersion> versions,
    required int currentIndex,
    required int targetIndex,
  }) {
    // Validate target index
    if (targetIndex < 0 || targetIndex >= versions.length) {
      return VersionNavigationResult.error('Invalid version index');
    }

    if (targetIndex == currentIndex) {
      return VersionNavigationResult.noChange();
    }

    return VersionNavigationResult.success(
      version: versions[targetIndex],
      newIndex: targetIndex,
    );
  }

  /// Undo to previous version
  VersionNavigationResult undo({
    required List<SummaryVersion> versions,
    required int currentIndex,
  }) {
    if (!canUndo(currentIndex)) {
      return VersionNavigationResult.error('Cannot undo - already at first version');
    }

    final newIndex = currentIndex - 1;
    return VersionNavigationResult.success(
      version: versions[newIndex],
      newIndex: newIndex,
    );
  }

  /// Redo to next version
  VersionNavigationResult redo({
    required List<SummaryVersion> versions,
    required int currentIndex,
  }) {
    if (!canRedo(currentIndex, versions.length)) {
      return VersionNavigationResult.error('Cannot redo - already at latest version');
    }

    final newIndex = currentIndex + 1;
    return VersionNavigationResult.success(
      version: versions[newIndex],
      newIndex: newIndex,
    );
  }

  /// Check if undo is possible
  bool canUndo(int currentIndex) {
    return currentIndex > 0;
  }

  /// Check if redo is possible
  bool canRedo(int currentIndex, int versionsCount) {
    return currentIndex < versionsCount - 1;
  }

  /// Get version by number
  SummaryVersion? getVersionByNumber({
    required List<SummaryVersion> versions,
    required int versionNumber,
  }) {
    try {
      return versions.firstWhere(
        (version) => version.versionNumber == versionNumber,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get latest version
  SummaryVersion? getLatestVersion(List<SummaryVersion> versions) {
    if (versions.isEmpty) return null;
    return versions.last;
  }

  /// Get first version
  SummaryVersion? getFirstVersion(List<SummaryVersion> versions) {
    if (versions.isEmpty) return null;
    return versions.first;
  }

  /// Compare two versions and get differences
  VersionComparison compareVersions({
    required SummaryVersion version1,
    required SummaryVersion version2,
  }) {
    final content1 = version1.content;
    final content2 = version2.content;

    // Calculate basic metrics
    final wordCount1 = _countWords(content1);
    final wordCount2 = _countWords(content2);
    final charCount1 = content1.length;
    final charCount2 = content2.length;

    final wordDifference = wordCount2 - wordCount1;
    final charDifference = charCount2 - charCount1;

    return VersionComparison(
      version1: version1,
      version2: version2,
      wordCount1: wordCount1,
      wordCount2: wordCount2,
      wordDifference: wordDifference,
      charCount1: charCount1,
      charCount2: charCount2,
      charDifference: charDifference,
    );
  }

  /// Get version statistics
  VersionStatistics getStatistics(List<SummaryVersion> versions) {
    if (versions.isEmpty) {
      return VersionStatistics(
        totalVersions: 0,
        totalRefinements: 0,
        averageWordCount: 0,
        shortestVersion: null,
        longestVersion: null,
      );
    }

    final wordCounts = versions.map((v) => _countWords(v.content)).toList();
    final averageWordCount =
        wordCounts.reduce((a, b) => a + b) / wordCounts.length;

    // Find shortest and longest versions
    var shortestVersion = versions.first;
    var longestVersion = versions.first;
    var shortestCount = _countWords(shortestVersion.content);
    var longestCount = _countWords(longestVersion.content);

    for (final version in versions) {
      final wordCount = _countWords(version.content);
      if (wordCount < shortestCount) {
        shortestVersion = version;
        shortestCount = wordCount;
      }
      if (wordCount > longestCount) {
        longestVersion = version;
        longestCount = wordCount;
      }
    }

    return VersionStatistics(
      totalVersions: versions.length,
      totalRefinements: versions.length - 1,
      averageWordCount: averageWordCount.round(),
      shortestVersion: shortestVersion,
      longestVersion: longestVersion,
    );
  }

  /// Create a rollback to a previous version
  SummaryVersion rollbackToVersion({
    required SummaryVersion targetVersion,
    required int newVersionNumber,
  }) {
    return SummaryVersion.refined(
      content: targetVersion.content,
      refinementPrompt: 'Rolled back to version ${targetVersion.versionNumber}',
      versionNumber: newVersionNumber,
    );
  }

  /// Get version history summary for display
  List<VersionHistoryItem> getVersionHistory(List<SummaryVersion> versions) {
    return versions.map((version) {
      return VersionHistoryItem(
        version: version,
        wordCount: _countWords(version.content),
      );
    }).toList();
  }

  /// Count words in text
  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  /// Get time difference between versions
  Duration getTimeBetweenVersions({
    required SummaryVersion version1,
    required SummaryVersion version2,
  }) {
    return version2.timestamp.difference(version1.timestamp);
  }

  /// Check if version history has unsaved changes
  bool hasUnsavedChanges({
    required List<SummaryVersion> versions,
    required int currentIndex,
  }) {
    // If we're not at the latest version, we have "unsaved" navigation
    return currentIndex < versions.length - 1;
  }
}

/// Result of version navigation
class VersionNavigationResult {
  final SummaryVersion? version;
  final int? newIndex;
  final String? error;
  final bool isNoChange;

  VersionNavigationResult._({
    this.version,
    this.newIndex,
    this.error,
    this.isNoChange = false,
  });

  factory VersionNavigationResult.success({
    required SummaryVersion version,
    required int newIndex,
  }) =>
      VersionNavigationResult._(
        version: version,
        newIndex: newIndex,
      );

  factory VersionNavigationResult.error(String error) =>
      VersionNavigationResult._(error: error);

  factory VersionNavigationResult.noChange() =>
      VersionNavigationResult._(isNoChange: true);

  bool get isSuccess => version != null && newIndex != null;
  bool get hasError => error != null;
}

/// Version comparison result
class VersionComparison {
  final SummaryVersion version1;
  final SummaryVersion version2;
  final int wordCount1;
  final int wordCount2;
  final int wordDifference;
  final int charCount1;
  final int charCount2;
  final int charDifference;

  VersionComparison({
    required this.version1,
    required this.version2,
    required this.wordCount1,
    required this.wordCount2,
    required this.wordDifference,
    required this.charCount1,
    required this.charCount2,
    required this.charDifference,
  });

  bool get isLonger => wordDifference > 0;
  bool get isShorter => wordDifference < 0;
  bool get isSameLength => wordDifference == 0;

  double get percentageChange {
    if (wordCount1 == 0) return 0;
    return (wordDifference / wordCount1) * 100;
  }

  String get changeDescription {
    if (isSameLength) return 'Same length';
    if (isLonger) {
      return '+${wordDifference.abs()} words (${percentageChange.abs().toStringAsFixed(1)}% longer)';
    } else {
      return '-${wordDifference.abs()} words (${percentageChange.abs().toStringAsFixed(1)}% shorter)';
    }
  }
}

/// Version statistics
class VersionStatistics {
  final int totalVersions;
  final int totalRefinements;
  final int averageWordCount;
  final SummaryVersion? shortestVersion;
  final SummaryVersion? longestVersion;

  VersionStatistics({
    required this.totalVersions,
    required this.totalRefinements,
    required this.averageWordCount,
    this.shortestVersion,
    this.longestVersion,
  });
}

/// Version history item for display
class VersionHistoryItem {
  final SummaryVersion version;
  final int wordCount;

  VersionHistoryItem({
    required this.version,
    required this.wordCount,
  });
}
