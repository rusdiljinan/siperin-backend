import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class KondisiBadge extends StatelessWidget {
  final String kondisi;

  const KondisiBadge({super.key, required this.kondisi});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = kondisi == 'Perlu Perbaikan'
        ? (isDark ? AppColors.darkWarning : AppColors.warning)
        : AppColors.kondisiColor(kondisi, dark: isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        kondisi,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
