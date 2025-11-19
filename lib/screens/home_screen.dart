import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../widgets/common_widgets.dart';
import 'upload_screen.dart';

/// Home/Welcome screen with app branding and features
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              AppColors.surfaceDark,
              AppColors.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.paddingLG,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: AppSpacing.xl),
                      // Logo/Branding
                      _buildLogo(context),
                      SizedBox(height: AppSpacing.md),
                      // Tagline
                      _buildTagline(context),
                    ],
                  ),
                ),
              ),

              // Feature Highlights
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.paddingLG,
                  child: Column(
                    children: [
                      SizedBox(height: AppSpacing.xxl),
                      _buildFeaturesList(context),
                      SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),

              // CTA Button
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: AppSpacing.paddingLG,
                      child: _buildCTAButton(context),
                    ),
                    SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: AppSpacing.borderRadiusLG,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.auto_awesome,
            size: 40,
            color: Colors.white,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SummarizeFast',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            Text(
              'AI-Powered Summaries',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTagline(BuildContext context) {
    return Text(
      'Transform any document into a concise, intelligent summary in seconds',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
    );
  }

  Widget _buildFeaturesList(BuildContext context) {
    final features = [
      _Feature(
        icon: Icons.upload_file,
        title: 'Multi-Format Support',
        description: 'PDFs, images, documents, and more',
        color: AppColors.primary,
      ),
      _Feature(
        icon: Icons.tune,
        title: 'Customizable Length',
        description: 'Choose from short, medium, or long summaries',
        color: AppColors.accent,
      ),
      _Feature(
        icon: Icons.auto_fix_high,
        title: 'Smart Refinement',
        description: 'Refine your summary unlimited times with AI',
        color: AppColors.secondary,
      ),
      _Feature(
        icon: Icons.history,
        title: 'Version History',
        description: 'Track all changes with undo/redo support',
        color: AppColors.accentWarning,
      ),
      _Feature(
        icon: Icons.download,
        title: 'Multiple Exports',
        description: 'Save as PDF, Markdown, or HTML',
        color: AppColors.primary,
      ),
      _Feature(
        icon: Icons.flash_on,
        title: 'Lightning Fast',
        description: 'Powered by Google Gemini 2.5 Flash',
        color: AppColors.accent,
      ),
    ];

    return Column(
      children: features.map((feature) {
        return Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: _buildFeatureCard(context, feature),
        );
      }).toList(),
    );
  }

  Widget _buildFeatureCard(BuildContext context, _Feature feature) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: feature.color.withOpacity(0.1),
              borderRadius: AppSpacing.borderRadiusMD,
            ),
            child: Icon(
              feature.icon,
              color: feature.color,
              size: 28,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  feature.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTAButton(BuildContext context) {
    return GradientButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UploadScreen()),
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Get Started',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(width: AppSpacing.sm),
          Icon(
            Icons.arrow_forward,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _Feature {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  _Feature({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
