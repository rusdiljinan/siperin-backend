import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/barang_service.dart';

class BarangFoto extends StatelessWidget {
  final int barangId;
  final String? fotoUrl;
  final BarangService service;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData placeholderIcon;

  const BarangFoto({
    super.key,
    required this.barangId,
    required this.fotoUrl,
    required this.service,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Icons.inventory_2_outlined,
  });

  @override
  Widget build(BuildContext context) {
    if (fotoUrl == null || fotoUrl!.isEmpty) {
      return _placeholder(context);
    }

    return FutureBuilder<Uint8List?>(
      future: service.getFoto(barangId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          if (kDebugMode) {
            debugPrint(
              '[BarangFoto] Failed to load photo $barangId: ${snapshot.error}',
            );
          }
          return _placeholder(context, icon: Icons.broken_image_outlined);
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return _placeholder(context, loading: true);
        }
        return Image.memory(
          snapshot.data!,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              _placeholder(context, icon: Icons.broken_image_outlined),
        );
      },
    );
  }

  Widget _placeholder(
    BuildContext context, {
    bool loading = false,
    IconData? icon,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  icon ?? placeholderIcon,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
        ),
      ),
    );
  }
}
