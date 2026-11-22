import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/responsive.dart';
import '../../widgets/user_avatar.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final theme = context.watch<ThemeProvider>();

    return Center(
      child: SingleChildScrollView(
        padding: Responsive.adaptivePadding(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Card(
            child: Padding(
              padding: Responsive.adaptivePadding(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const UserAvatar(size: 104),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? 'Pengguna',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '@${user?.username ?? '-'}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Chip(label: Text(user?.role.toUpperCase() ?? 'USER')),
                  const Divider(height: 32),
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Email'),
                    subtitle: Text(user?.email ?? '-'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.account_balance),
                    title: const Text('Instansi'),
                    subtitle: Text(AppConstants.instansiName),
                  ),
                  ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: const Text('Tema Aplikasi'),
                    trailing: DropdownButton<ThemeMode>(
                      value: theme.themeMode,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text('Sistem'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text('Terang'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text('Gelap'),
                        ),
                      ],
                      onChanged: (mode) {
                        if (mode != null) theme.setTheme(mode);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
