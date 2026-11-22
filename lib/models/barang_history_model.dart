class BarangHistoryModel {
  final int id;
  final String perubahan;
  final String userName;
  final DateTime waktu;

  BarangHistoryModel({
    required this.id,
    required this.perubahan,
    required this.userName,
    required this.waktu,
  });

  factory BarangHistoryModel.fromJson(Map<String, dynamic> json) {
    return BarangHistoryModel(
      id: json['id'] as int? ?? 0,
      perubahan:
          json['perubahan']?.toString() ?? json['deskripsi']?.toString() ?? '',
      userName: json['user']?.toString() ?? 'Sistem',
      waktu:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  static List<BarangHistoryModel> mockForBarang(int barangId) => [
    BarangHistoryModel(
      id: 1,
      perubahan: 'Data barang dibuat',
      userName: 'Admin',
      waktu: DateTime(2024, 3, 10),
    ),
    BarangHistoryModel(
      id: 2,
      perubahan: 'Kondisi diperbarui menjadi Baik',
      userName: 'User',
      waktu: DateTime(2024, 8, 15),
    ),
  ];
}
