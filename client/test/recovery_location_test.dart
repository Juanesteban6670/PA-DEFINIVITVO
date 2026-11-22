import 'package:cartagena_segura/app/router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const route = '/ResetPassword?token=qa%2Btoken%26a';
  test('recovers current and legacy email link formats', () {
    expect(recoveryLocationFromUri(Uri.parse('https://example.test/#$route')), route);
    expect(recoveryLocationFromUri(Uri.parse('https://example.test$route')), route);
  });

  test('a missing recovery token opens the request form', () {
    expect(
      recoveryLocationFromUri(Uri.parse('https://example.test/ResetPassword')),
      '/ForgotPassword',
    );
    expect(recoveryLocationFromUri(Uri.parse('https://example.test/#/App')), isNull);
  });
}
