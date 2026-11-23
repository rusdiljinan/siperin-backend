import 'package:flutter_test/flutter_test.dart';
import 'package:inventaris_instansi/core/constants/api_constants.dart';

void main() {
  test('uses the production Railway HTTPS API URL', () {
    expect(
      ApiConstants.baseUrl,
      'https://siperin-backend-production.up.railway.app/api',
    );
  });
}
