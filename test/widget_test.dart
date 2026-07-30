import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:borrowly/app/app.dart';

void main() {
  testWidgets('Borrowly App renders successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: BorrowlyApp(),
      ),
    );

    expect(find.byType(BorrowlyApp), findsOneWidget);
  });
}
