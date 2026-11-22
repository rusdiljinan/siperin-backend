import 'package:flutter/material.dart';

import '../../models/managed_user_model.dart';

typedef UserFormValues = ({
  String name,
  String role,
  String username,
  String password,
});

class UserFormDialog extends StatefulWidget {
  final ManagedUserModel? user;

  const UserFormDialog({super.key, this.user});

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  static const _roles = ['admin', 'user'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  late String _selectedRole;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _selectedRole = widget.user?.role ?? 'user';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop((
      name: _nameController.text.trim(),
      role: _selectedRole,
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    ));
  }

  String? _validateUsername(String? value) {
    final username = (value ?? '').trim();
    if (username.isEmpty) {
      return 'Username wajib diisi';
    }
    if (username.length < 3 || username.length > 50) {
      return 'Username 3-50 karakter';
    }
    if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(username)) {
      return 'Username hanya boleh berisi huruf, angka, titik, garis bawah, dan hubung';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return null;
    if (password.length < 8 || password.length > 72) {
      return 'Password harus 8-72 karakter';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password)) {
      return 'Password harus mengandung huruf dan angka';
    }
    return null;
  }

  String _roleLabel(String role) => switch (role) {
    'admin' => 'Admin',
    'user' => 'User',
    _ => role,
  };

  @override
  Widget build(BuildContext context) {
    final isCreating = widget.user == null;

    return AlertDialog(
      title: Text(isCreating ? 'Tambah Pengguna' : 'Edit Pengguna'),
      scrollable: true,
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                maxLength: 100,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama Pengguna',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nama pengguna wajib diisi'
                    : null,
              ),
              if (isCreating) ...[
                TextFormField(
                  controller: _usernameController,
                  maxLength: 50,
                  decoration: const InputDecoration(
                    labelText: 'Username Login',
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                  validator: _validateUsername,
                ),
                const SizedBox(height: 12),
              ],
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: _roles
                    .map(
                      (role) => DropdownMenuItem(
                        value: role,
                        child: Text(_roleLabel(role)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedRole = value);
                },
                validator: (value) => value == null || !_roles.contains(value)
                    ? 'Role wajib dipilih'
                    : null,
              ),
              if (!isCreating) ...[
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Kata sandi lama disimpan secara aman dan tidak dapat '
                    'ditampilkan. Isi kata sandi baru hanya jika ingin '
                    'menggantinya.',
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Kata sandi awal dapat ditentukan sekarang. Jika dikosongkan, '
                    'sistem akan membuat kata sandi acak.',
                  ),
                ),
              ],
              if (isCreating) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  maxLength: 72,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Password Awal (opsional)',
                    helperText: 'Kosongkan untuk menggunakan password acak',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Tampilkan password'
                          : 'Sembunyikan password',
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: _validatePassword,
                  onFieldSubmitted: (_) => _submit(),
                ),
              ] else ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  maxLength: 72,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Password Baru',
                    helperText: 'Kosongkan jika tidak ingin mengubah password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Tampilkan password'
                          : 'Sembunyikan password',
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: _validatePassword,
                  onFieldSubmitted: (_) => _submit(),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save_outlined),
          label: Text(isCreating ? 'Simpan' : 'Simpan Perubahan'),
        ),
      ],
    );
  }
}
