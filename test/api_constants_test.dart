import 'package:flutter_test/flutter_test.dart';
import 'package:inventaris_instansi/core/constants/api_constants.dart';

const configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

void main() {
  test('uses the configured API URL or the local web and desktop default', () {
    expect(
      ApiConstants.baseUrl,
      configuredBaseUrl.isEmpty
          ? 'http://127.0.0.1:8000/api'
          : configuredBaseUrl,
    );
  });
}
