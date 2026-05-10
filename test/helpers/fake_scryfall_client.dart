import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

class FakeUri extends Fake implements Uri {}

void registerHttpFallbacks() {
  registerFallbackValue(FakeUri());
}

/// Helper to stub a successful 200 response from the mock client.
http.Response okJson(String body) => http.Response(body, 200);

http.Response status(int code, [String body = '']) => http.Response(body, code);
