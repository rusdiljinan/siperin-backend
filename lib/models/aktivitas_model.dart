import 'package:flutter/material.dart';

class AktivitasModel {
  final int id;
  final String deskripsi;
  final String userName;
  final String role;
  final String tipe;
  final DateTime waktu;

  AktivitasModel({
    required this.id,
    required this.deskripsi,
    required this.userName,
    required this.role,
    required this.tipe,
    required this.waktu,
  });

  factory AktivitasModel.fromJson(Map<String, dynamic> json) {
    return AktivitasModel(
      id: json['id'] as int? ?? 0,
      deskripsi:
          json['deskripsi']?.toString() ?? json['keterangan']?.toString() ?? '',
      userName:
          json['user']?.toString() ??
          json['user_name']?.toString() ??
          'Pengguna',
      role: json['role']?.toString() ?? '-',
      tipe:
          json['tipe']?.toString() ??
          json['aktivitas']?.toString() ??
          json['aksi']?.toString() ??
          'update',
      waktu:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  IconData get icon {
    switch (tipe.toLowerCase()) {
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      case 'create':
      case 'tambah':
        return Icons.add_circle_outline;
      case 'delete':
      case 'hapus':
        return Icons.delete_outline;
      case 'update':
      case 'edit':
        return Icons.edit_outlined;
      case 'upload':
        return Icons.cloud_upload_outlined;
      case 'ubah_kondisi':
        return Icons.build_outlined;
      case 'verifikasi':
        return Icons.verified_outlined;
      case 'export_pdf':
        return Icons.picture_as_pdf;
      case 'export_excel':
        return Icons.table_chart;
      case 'print':
        return Icons.print;
      default:
        return Icons.history;
    }
  }
}
