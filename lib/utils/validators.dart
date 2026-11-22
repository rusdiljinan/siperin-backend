class Validators {
  static String? required(String? value, {String field = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field wajib diisi';
    }
    return null;
  }

  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username wajib diisi';
    }
    if (value.length < 3) {
      return 'Username minimal 3 karakter';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password wajib diisi';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  static String? number(String? value, {String field = 'Nilai'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field wajib diisi';
    }
    if (int.tryParse(value) == null && double.tryParse(value) == null) {
      return '$field harus berupa angka';
    }
    return null;
  }

  static String? year(String? value) {
    final err = number(value, field: 'Tahun pembelian');
    if (err != null) return err;
    final y = int.parse(value!);
    if (y < 1900 || y > DateTime.now().year + 1) {
      return 'Tahun tidak valid';
    }
    return null;
  }
}
