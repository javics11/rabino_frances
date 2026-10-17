import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabino_frances/services/drag_drop_service.dart';

void main() {
  testWidgets('recognizes the physical gap between melds', (tester) async {
    final areaKey = GlobalKey();
    final leftKey = GlobalKey();
    final rightKey = GlobalKey();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          key: areaKey,
          height: 120,
          child: Row(
            children: [
              SizedBox(key: leftKey, width: 100, height: 100),
              const SizedBox(width: 24),
              SizedBox(key: rightKey, width: 100, height: 100),
            ],
          ),
        ),
      ),
    ));

    final left = DragDropService.getGlobalRect(leftKey)!;
    final right = DragDropService.getGlobalRect(rightKey)!;
    final result = DragDropService.findDropTarget(
      position: Offset((left.right + right.left) / 2, left.center.dy),
      discardPileKey: GlobalKey(),
      meldAreaKey: areaKey,
      meldKeys: [leftKey, rightKey],
      meldCardKeys: [[], []],
    );

    expect(result.type, DropTargetType.meldArea);
  });

  testWidgets('keeps meld bounds and card targets higher priority', (tester) async {
    final areaKey = GlobalKey();
    final leftKey = GlobalKey();
    final rightKey = GlobalKey();
    final leftCardKey = GlobalKey();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          key: areaKey,
          height: 120,
          child: Row(
            children: [
              SizedBox(
                key: leftKey,
                width: 100,
                height: 100,
                child: SizedBox(key: leftCardKey, width: 40, height: 80),
              ),
              const SizedBox(width: 24),
              SizedBox(key: rightKey, width: 100, height: 100),
            ],
          ),
        ),
      ),
    ));

    final left = DragDropService.getGlobalRect(leftKey)!;
    final right = DragDropService.getGlobalRect(rightKey)!;
    final card = DragDropService.getGlobalRect(leftCardKey)!;

    DropResult find(Offset position) => DragDropService.findDropTarget(
          position: position,
          discardPileKey: GlobalKey(),
          meldAreaKey: areaKey,
          meldKeys: [leftKey, rightKey],
          meldCardKeys: [
            [leftCardKey],
            [],
          ],
        );

    expect(find(left.center).type, DropTargetType.existingMeld);
    expect(find(right.center).type, DropTargetType.existingMeld);
    expect(find(Offset(card.center.dx, card.center.dy)).type,
        DropTargetType.existingMeld);
    expect(
      find(Offset(left.left - 2, left.center.dy)).type,
      DropTargetType.existingMeld,
    );
  });
}
