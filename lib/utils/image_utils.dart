import 'package:image_picker/image_picker.dart';

/// Memilih dan mengompresi gambar sebelum dikirim sebagai multipart ke Laravel.
class ImageUtils {
  static final ImagePicker _picker = ImagePicker();

  /// Kompresi via image_picker: max 800px, kualitas 65% (~100–300 KB).
  static Future<XFile?> pickCompressed(ImageSource source) {
    return _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 65,
    );
  }
}
