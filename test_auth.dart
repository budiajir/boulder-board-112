import 'dart:io';
import 'dart:convert';

void main() async {
  final url = 'https://ykhgdptnhbahvosfzhfd.supabase.co/auth/v1/signup';
  final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlraGdkcHRuaGJhaHZvc2Z6aGZkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkyODYzNzEsImV4cCI6MjA5NDg2MjM3MX0.nZ3CqW9QgtVfsmqX6JuKnXMj1l-s8HCoqF6646biQ0s';

  final request = await HttpClient().postUrl(Uri.parse(url));
  request.headers.add('apikey', anonKey);
  request.headers.add('Authorization', 'Bearer $anonKey');
  request.headers.add('Content-Type', 'application/json');

  final body = jsonEncode({
    'email': 'test_wiroboard_123@example.com',
    'password': 'password12345',
    'data': {'username': 'test_user'}
  });
  
  request.write(body);

  try {
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    print('Status Code: ${response.statusCode}');
    print('Response: $responseBody');
  } catch (e) {
    print('Error: $e');
  }
}
