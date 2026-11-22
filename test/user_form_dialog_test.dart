import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventaris_instansi/models/managed_user_model.dart';
import 'package:inventaris_instansi/pages/users/user_form_dialog.dart';

void main() {
  testWidgets('creates an account form and returns validated values', (
    tester,
  ) async {
    UserFormValues? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showDialog<UserFormValues>(
                  context: context,
                  builder: (_) => const UserFormDialog(),
                );
              },
              child: const Text('Tambah akun'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Tambah akun'));
    await tester.pumpAndSettle();
    expect(find.text('Tambah Pengguna'), findsOneWidget);
    expect(find.textContaining('Email'), findsNothing);

    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Nama pengguna wajib diisi'), findsOneWidget);
    expect(find.text('Username wajib diisi'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Petugas Baru');
    await tester.enterText(find.byType(TextFormField).at(1), 'petugas-baru');
    await tester.enterText(find.byType(TextFormField).at(2), 'Petugas123');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(result, (
      name: 'Petugas Baru',
      role: 'user',
      username: 'petugas-baru',
      password: 'Petugas123',
    ));
  });

  testWidgets('edits an account without exposing its stored password', (
    tester,
  ) async {
    UserFormValues? result;
    const user = ManagedUserModel(
      id: 7,
      name: 'Petugas Lama',
      role: 'user',
      isActive: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showDialog<UserFormValues>(
                  context: context,
                  builder: (_) => const UserFormDialog(user: user),
                );
              },
              child: const Text('Edit akun'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Edit akun'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Pengguna'), findsOneWidget);
    expect(
      find.textContaining('Kata sandi lama disimpan secara aman'),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('User').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Petugas Baru');
    await tester.enterText(find.byType(TextFormField).at(1), 'salah');
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();
    expect(find.text('Password harus 8-72 karakter'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(1), 'Petugas456');
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();

    expect(result, (
      name: 'Petugas Baru',
      role: 'user',
      username: '',
      password: 'Petugas456',
    ));
    expect(tester.takeException(), isNull);
  });
}
