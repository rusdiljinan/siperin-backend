/// Parser response JSON standar dari API Laravel SIPERIN.
class ApiResponseParser {
  /// Ambil token dari response (root atau nested di `data`).
  static String? extractToken(Map<String, dynamic> json) {
    final rootToken =
        json['token']?.toString() ?? json['access_token']?.toString();
    if (rootToken != null && rootToken.isNotEmpty) {
      return rootToken;
    }

    final data = json['data'];
    if (data is Map<String, dynamic>) {
      final nested =
          data['token']?.toString() ?? data['access_token']?.toString();
      if (nested != null && nested.isNotEmpty) {
        return nested;
      }
    }

    return null;
  }

  /// Ambil objek user dari response.
  static Map<String, dynamic>? extractUser(Map<String, dynamic> json) {
    if (json['user'] is Map<String, dynamic>) {
      return json['user'] as Map<String, dynamic>;
    }

    final data = json['data'];
    if (data is Map<String, dynamic>) {
      if (data['user'] is Map<String, dynamic>) {
        return data['user'] as Map<String, dynamic>;
      }
      if (data.containsKey('id') && data.containsKey('username')) {
        return data;
      }
    }

    if (json.containsKey('id') && json.containsKey('username')) {
      return json;
    }

    return null;
  }

  /// Ambil pesan error dari response atau Dio.
  static String extractErrorMessage(
    dynamic responseData, {
    String fallback = 'Terjadi kesalahan',
  }) {
    if (responseData is Map<String, dynamic>) {
      if (responseData['errors'] is Map) {
        final errors = responseData['errors'] as Map;
        final messages = <String>[];
        for (final entry in errors.entries) {
          final value = entry.value;
          final fieldMessage = value is List && value.isNotEmpty
              ? value.map((item) => item.toString()).join(', ')
              : value?.toString();
          if (fieldMessage != null && fieldMessage.isNotEmpty) {
            messages.add('${entry.key}: $fieldMessage');
          }
        }
        if (messages.isNotEmpty) return messages.join('\n');
      }
      if (responseData['message'] != null) {
        return responseData['message'].toString();
      }
    }
    return fallback;
  }

  static bool isSuccess(Map<String, dynamic> json) {
    return json['success'] == true;
  }

  /// Ambil list dari response API.
  /// Mendukung: data = [...], data = { data: [...] }, data = { items: [...] }
  static List<dynamic> extractList(Map<String, dynamic> json) {
    final payload = json['data'];

    if (payload is List) {
      return payload;
    }

    if (payload is Map) {
      final map = Map<String, dynamic>.from(payload);
      if (map['data'] is List) {
        return map['data'] as List;
      }
      if (map['items'] is List) {
        return map['items'] as List;
      }
    }

    return [];
  }

  /// Ambil satu objek dari field `data` (detail barang, dashboard, dll).
  static Map<String, dynamic> extractObject(Map<String, dynamic> json) {
    final payload = json['data'];
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    return json;
  }

  /// Meta pagination (current_page, last_page, total).
  static Map<String, dynamic>? extractMeta(Map<String, dynamic> json) {
    if (json['meta'] is Map) {
      return Map<String, dynamic>.from(json['meta'] as Map);
    }
    final payload = json['data'];
    if (payload is Map && payload['meta'] is Map) {
      return Map<String, dynamic>.from(payload['meta'] as Map);
    }
    return null;
  }
}
