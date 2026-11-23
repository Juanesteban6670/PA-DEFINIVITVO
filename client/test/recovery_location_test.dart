import 'package:cartagena_segura/app/router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const route = '/ResetPassword?token=qa%2Btoken%26a';
  test('recovers current and legacy email link formats', () {
    expect(
      recoveryLocationFromUri(Uri.parse('https://example.test/#$route')),
      route,
    );
    expect(
      recoveryLocationFromUri(Uri.parse('https://example.test$route')),
      route,
    );
  });

  test('a missing recovery token opens the request form', () {
    expect(
      recoveryLocationFromUri(Uri.parse('https://example.test/ResetPassword')),
      '/ForgotPassword',
    );
    expect(
      recoveryLocationFromUri(Uri.parse('https://example.test/#/App')),
      isNull,
    );
  });

  test('opens direct web routes and preserves the selected incident', () {
    expect(
      startupLocationFromUri(Uri.parse('https://example.test/Login')),
      '/Login',
    );
    for (final prefix in ['', '/#']) {
      expect(
        startupLocationFromUri(
          Uri.parse('https://example.test$prefix/App/Incidents?id=qa'),
        ),
        '/App/Incidents?id=qa',
      );
    }
    expect(
      startupLocationFromUri(
        Uri.parse('https://example.test/#//other.test/App'),
      ),
      isNull,
    );
  });
}
