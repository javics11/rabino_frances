// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:rabino_frances/models/deck.dart';
import 'package:rabino_frances/models/player.dart';

void main() {
  test('A new deck contains 108 cards', () {
    final deck = Deck();

    expect(deck.cards.length, 108);
  });

  test('A new player starts with an empty hand', () {
    final player = Player('Test Player');

    expect(player.hand, isEmpty);
  });
}
