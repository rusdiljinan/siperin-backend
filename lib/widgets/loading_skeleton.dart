import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme/app_colors.dart';

class LoadingSkeleton extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const LoadingSkeleton({
    super.key,
    this.height = 16,
    this.width,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkSecondary : AppColors.silk,
      highlightColor: isDark ? AppColors.darkBorder : AppColors.paper,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: LoadingSkeleton(
                  height: 100,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LoadingSkeleton(
                  height: 100,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LoadingSkeleton(
                  height: 100,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LoadingSkeleton(
                  height: 100,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LoadingSkeleton(height: 220, borderRadius: BorderRadius.circular(12)),
        ],
      ),
    );
  }
}
