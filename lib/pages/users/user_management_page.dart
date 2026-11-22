import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/managed_user_model.dart';
import '../../services/api_client.dart';
import '../../services/user_management_service.dart';
import '../../utils/responsive.dart';
import 'user_form_dialog.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  static const _roles = ['admin', 'user'];

  late final UserManagementService _service;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchTimer;
  List<ManagedUserModel> _users = [];
  String? _roleFilter;
  String? _error;
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;
  int _requestVersion = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _roleFilterHovered = false;
  bool _roleFilterFocused = false;

  @override
  void initState() {
    super.initState();
    _service = UserManagementService(context.read<ApiClient>());
    _searchController.addListener(_scheduleSearch);
    _loadUsers();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleSearch() {
    if (mounted) setState(() {});
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 350), _loadUsers);
  }

  Future<void> _loadUsers({bool nextPage = false}) async {
    if (_isLoadingMore || (nextPage && _currentPage >= _lastPage)) return;
    final page = nextPage ? _currentPage + 1 : 1;
    final requestVersion = nextPage ? _requestVersion : ++_requestVersion;
    setState(() {
      if (nextPage) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _error = null;
        _users = [];
        _currentPage = 1;
      }
    });

    try {
      final result = await _service.getUsers(
        search: _searchController.text,
        role: _roleFilter,
        page: page,
      );
      if (!mounted || requestVersion != _requestVersion) return;
      setState(() {
        _users = nextPage ? [..._users, ...result.users] : result.users;
        _currentPage = result.currentPage;
        _lastPage = result.lastPage;
        _total = result.total;
      });
    } catch (error) {
      if (!mounted || requestVersion != _requestVersion) return;
      setState(() => _error = _cleanError(error));
    } finally {
      if (mounted && requestVersion == _requestVersion) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _showUserForm({ManagedUserModel? user}) async {
    final values = await showDialog<UserFormValues>(
      context: context,
      builder: (_) => UserFormDialog(user: user),
    );

    if (values == null || !mounted) return;

    try {
      if (user == null) {
        await _service.createUser(
          name: values.name,
          role: values.role,
          username: values.username,
          password: values.password,
        );
        if (!mounted) return;
        await _loadUsers();
        if (!mounted) return;
        _showMessage('Pengguna berhasil ditambahkan');
      } else {
        await _service.updateUser(
          id: user.id,
          name: values.name,
          role: values.role,
          password: values.password,
        );
        if (!mounted) return;
        await _loadUsers();
        if (mounted) _showMessage('Perubahan pengguna berhasil disimpan');
      }
    } catch (error) {
      if (mounted) _showMessage(_cleanError(error), isError: true);
    }
  }

  Future<void> _toggleStatus(ManagedUserModel user) async {
    final activate = !user.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(activate ? 'Aktifkan pengguna?' : 'Nonaktifkan pengguna?'),
        content: Text(
          activate
              ? 'Akun ${user.name} dapat login kembali setelah diaktifkan.'
              : 'Akun ${user.name} tidak dapat login dan token aktifnya akan dicabut. Data terkait tetap disimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(activate ? 'Aktifkan' : 'Nonaktifkan'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _service.updateStatus(user.id, activate);
      if (!mounted) return;
      await _loadUsers();
      if (mounted) {
        _showMessage(
          activate ? 'Akun berhasil diaktifkan' : 'Akun berhasil dinonaktifkan',
        );
      }
    } catch (error) {
      if (mounted) _showMessage(_cleanError(error), isError: true);
    }
  }

  Future<void> _deleteUser(ManagedUserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus akun pengguna?'),
        content: Text(
          'Akun ${user.name} akan dihapus permanen. Riwayat aktivitas, '
          'laporan, dan notifikasi milik akun ini juga akan terhapus. '
          'Barang yang dibuat akun tetap disimpan. Tindakan ini tidak dapat '
          'dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Hapus Permanen'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _service.deleteUser(user.id);
      if (!mounted) return;
      await _loadUsers();
      if (mounted) _showMessage('Akun pengguna berhasil dihapus');
    } catch (error) {
      if (mounted) _showMessage(_cleanError(error), isError: true);
    }
  }

  String _cleanError(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        ),
      );
  }

  static String _roleLabel(String role) => switch (role) {
    'admin' => 'Admin',
    'user' => 'User',
    _ => role,
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '$_total pengguna',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = Responsive.isMobile(context);
                  final search = TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Cari nama pengguna',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Hapus pencarian',
                              onPressed: _searchController.clear,
                              icon: const Icon(Icons.clear),
                            ),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  );
                  final borderColor = _roleFilterFocused
                      ? colors.primary
                      : _roleFilterHovered
                      ? colors.primary.withValues(alpha: 0.65)
                      : colors.outlineVariant;
                  final roleFilter = MouseRegion(
                    onEnter: (_) => setState(() => _roleFilterHovered = true),
                    onExit: (_) => setState(() => _roleFilterHovered = false),
                    child: Focus(
                      onFocusChange: (focused) =>
                          setState(() => _roleFilterFocused = focused),
                      child: SizedBox(
                        width: isMobile ? null : 190,
                        height: 48,
                        child: DropdownButtonFormField<String?>(
                          initialValue: _roleFilter,
                          isExpanded: true,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: _roleFilterFocused
                                ? colors.primary
                                : colors.onSurfaceVariant,
                          ),
                          iconSize: 22,
                          dropdownColor: colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          menuMaxHeight: 320,
                          style: Theme.of(context).textTheme.bodyMedium,
                          decoration: InputDecoration(
                            labelText: 'Filter role',
                            filled: true,
                            fillColor: colors.surfaceContainerHighest
                                .withValues(alpha: 0.32),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 13,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colors.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Semua role'),
                            ),
                            ..._roles.map(
                              (role) => DropdownMenuItem<String?>(
                                value: role,
                                child: Text(_roleLabel(role)),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _roleFilter = value);
                            _loadUsers();
                          },
                        ),
                      ),
                    ),
                  );
                  final addButton = isMobile
                      ? SizedBox(
                          width: 48,
                          height: 48,
                          child: FilledButton(
                            onPressed: () => _showUserForm(),
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(48, 48),
                            ),
                            child: const Tooltip(
                              message: 'Tambah Pengguna',
                              child: Icon(Icons.person_add_alt_1),
                            ),
                          ),
                        )
                      : FilledButton.icon(
                          onPressed: () => _showUserForm(),
                          icon: const Icon(Icons.person_add_alt_1),
                          label: const Text('Tambah Pengguna'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                        );

                  if (isMobile) {
                    return Column(
                      children: [
                        search,
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: roleFilter),
                            const SizedBox(width: 12),
                            addButton,
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: search),
                      const SizedBox(width: 12),
                      roleFilter,
                      const SizedBox(width: 12),
                      addButton,
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null && _users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cloud_off_outlined,
                              size: 40,
                              color: colors.error,
                            ),
                            const SizedBox(height: 12),
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _loadUsers,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      )
                    : _users.isEmpty
                    ? const Center(
                        child: Text('Tidak ada pengguna yang cocok.'),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        child: ListView.separated(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 12),
                          itemCount:
                              _users.length +
                              (_currentPage < _lastPage ? 1 : 0),
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            if (index == _users.length) {
                              return Center(
                                child: TextButton.icon(
                                  onPressed: _isLoadingMore
                                      ? null
                                      : () => _loadUsers(nextPage: true),
                                  icon: _isLoadingMore
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.expand_more),
                                  label: Text(
                                    _isLoadingMore
                                        ? 'Memuat...'
                                        : 'Muat pengguna berikutnya',
                                  ),
                                ),
                              );
                            }
                            return _userTile(_users[index]);
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _userTile(ManagedUserModel user) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colors.primaryContainer,
          child: Text(
            user.name.trim().isEmpty ? '?' : user.name.trim()[0].toUpperCase(),
            style: TextStyle(color: colors.onPrimaryContainer),
          ),
        ),
        title: Text(user.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(
                label: Text(_roleLabel(user.role)),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
              Text(
                user.isActive ? 'Aktif' : 'Nonaktif',
                style: TextStyle(
                  color: user.isActive ? colors.primary : colors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        trailing: Wrap(
          spacing: 0,
          children: [
            IconButton(
              tooltip: 'Edit pengguna',
              onPressed: () => _showUserForm(user: user),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Hapus pengguna',
              onPressed: () => _deleteUser(user),
              icon: Icon(Icons.delete_outline, color: colors.error),
            ),
            IconButton(
              tooltip: user.isActive
                  ? 'Nonaktifkan pengguna'
                  : 'Aktifkan pengguna',
              onPressed: () => _toggleStatus(user),
              icon: Icon(
                user.isActive
                    ? Icons.person_off_outlined
                    : Icons.person_outline,
                color: user.isActive ? colors.error : colors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
