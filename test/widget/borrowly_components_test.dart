import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:borrowly/app/theme/app_theme.dart';
import 'package:borrowly/core/widgets/borrowly_badge.dart';
import 'package:borrowly/core/widgets/borrowly_button.dart';
import 'package:borrowly/core/widgets/borrowly_card.dart';

void main() {
  group('Borrowly Design System Widget Tests', () {
    testWidgets('BorrowlyButton renders label and responds to tap', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: BorrowlyButton(
              label: 'Borrow Now',
              onPressed: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Borrow Now'), findsOneWidget);
      await tester.tap(find.byType(BorrowlyButton));
      expect(tapped, isTrue);
    });

    testWidgets('BorrowlyBadge renders label correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: BorrowlyBadge(
              label: '1.2 km away',
              variant: BorrowlyBadgeVariant.primary,
            ),
          ),
        ),
      );

      expect(find.text('1.2 km away'), findsOneWidget);
    });

    testWidgets('BorrowlyCard renders child content', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: BorrowlyCard(
              child: Text('Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
    });
  });
}
