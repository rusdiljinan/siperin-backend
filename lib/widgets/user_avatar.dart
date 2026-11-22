import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final double size;

  const UserAvatar({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.paleGold.withValues(alpha: 0.24),
      child: Icon(
        Icons.person,
        size: size * 0.58,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
