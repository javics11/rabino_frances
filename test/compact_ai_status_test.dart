import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rabino_frances/widgets/compact_ai_status.dart';
import 'package:rabino_frances/widgets/card_back_widget.dart';

void main() {
  testWidgets('compact AI status shows name and current card count', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CompactAiStatus(playerName: 'AI 2', cardCount: 14),
        ),
      ),
    );

    expect(find.text('AI 2'), findsOneWidget);
    expect(find.text('\u00D7 14'), findsOneWidget);
    expect(find.byKey(const ValueKey('compact-ai-status-cards')), findsOneWidget);
    expect(find.byKey(const ValueKey('compact-ai-status-mini-card-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('compact-ai-status-mini-card-1')), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CompactAiStatus(playerName: 'AI 2', cardCount: 9),
        ),
      ),
    );
    expect(find.text('\u00D7 9'), findsOneWidget);
  });

  testWidgets('compact AI status remains a fixed-size indicator', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CompactAiStatus(playerName: 'AI 1', cardCount: 40),
        ),
      ),
    );

    final status = tester.getSize(find.byType(CompactAiStatus));
    expect(status.width, lessThan(180));
    expect(status.height, lessThan(48));
    expect(find.byKey(const ValueKey('compact-ai-status-mini-card-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('compact-ai-status-mini-card-1')), findsOneWidget);
    expect(find.byType(CardBackWidget), findsNothing);
  });
}
