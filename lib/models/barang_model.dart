class BarangModel {
  final int id;
  final String nama;
  final String kode;
  final String? merek;
  final String? nomorSeri;
  final String? ukuran;
  final String? bahan;
  final int tahunPembelian;
  final int jumlah;
  final double hargaBeli;
  final String kondisi;
  final String? keterangan;
  final String ruangan;
  final String kategori;
  final int? kategoriId;
  final String status;
  final String? fotoUrl;
  final bool hasFoto;

  BarangModel({
    required this.id,
    required this.nama,
    required this.kode,
    this.merek,
    this.nomorSeri,
    this.ukuran,
    this.bahan,
    required this.tahunPembelian,
    required this.jumlah,
    required this.hargaBeli,
    required this.kondisi,
    this.keterangan,
    required this.ruangan,
    required this.kategori,
    this.kategoriId,
    required this.status,
    this.fotoUrl,
    this.hasFoto = false,
  });

  factory BarangModel.fromJson(Map<String, dynamic> json) {
    return BarangModel(
      id: json['id'] as int? ?? 0,
      nama: json['nama']?.toString() ?? json['nama_barang']?.toString() ?? '',
      kode: json['kode']?.toString() ?? json['kode_barang']?.toString() ?? '',
      merek: json['merek']?.toString(),
      nomorSeri: json['nomor_seri']?.toString(),
      ukuran: json['ukuran']?.toString(),
      bahan: json['bahan']?.toString(),
      tahunPembelian: json['tahun_pembelian'] as int? ?? 0,
      jumlah: json['jumlah'] as int? ?? 1,
      hargaBeli: (json['harga_beli'] as num?)?.toDouble() ?? 0,
      kondisi: json['kondisi']?.toString() ?? 'Baik',
      keterangan: json['keterangan']?.toString(),
      ruangan: json['ruangan']?.toString() ?? '-',
      kategori: json['kategori']?.toString() ?? 'Lainnya',
      kategoriId: json['kategori_id'] is int
          ? json['kategori_id'] as int
          : int.tryParse(json['kategori_id']?.toString() ?? ''),
      status: json['status']?.toString() ?? 'Aktif',
      fotoUrl: json['foto']?.toString() ?? json['foto_url']?.toString(),
      hasFoto:
          json['has_foto'] as bool? ??
          (json['foto'] != null || json['foto_url'] != null),
    );
  }

  Map<String, dynamic> toJson() => {
    'nama': nama,
    'kode': kode,
    'merek': merek,
    'nomor_seri': nomorSeri,
    'ukuran': ukuran,
    'bahan': bahan,
    'tahun_pembelian': tahunPembelian,
    'jumlah': jumlah,
    'harga_beli': hargaBeli,
    'kondisi': kondisi,
    'keterangan': keterangan,
    'ruangan': ruangan,
    'kategori': kategori,
    'kategori_id': kategoriId,
    'status': status,
  };

  BarangModel copyWith({
    int? id,
    String? nama,
    String? kode,
    int? kategoriId,
    String? kondisi,
    String? status,
    String? fotoUrl,
    bool? hasFoto,
  }) {
    return BarangModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      kode: kode ?? this.kode,
      merek: merek,
      nomorSeri: nomorSeri,
      ukuran: ukuran,
      bahan: bahan,
      tahunPembelian: tahunPembelian,
      jumlah: jumlah,
      hargaBeli: hargaBeli,
      kondisi: kondisi ?? this.kondisi,
      keterangan: keterangan,
      ruangan: ruangan,
      kategori: kategori,
      kategoriId: kategoriId ?? this.kategoriId,
      status: status ?? this.status,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      hasFoto: hasFoto ?? this.hasFoto,
    );
  }
}
