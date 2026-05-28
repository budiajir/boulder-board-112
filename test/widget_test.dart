import 'package:flutter_test/flutter_test.dart';
import 'package:wiroboard/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wiroboard/features/auth/presentation/providers/auth_notifier.dart';

class FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() {
    return const AuthState(user: null);
  }
}

void main() {
  testWidgets('Boulder Board 112 app launches', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => FakeAuthNotifier()),
        ],
        child: const BoulderBoardApp(),
      ),
    );
    expect(find.text('Boulder Board 112'), findsWidgets);
  });
}
