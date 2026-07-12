import 'package:flutter/material.dart';

import '../models/card.dart';

class CardWidget extends StatelessWidget {
  final CardModel card;
  final bool selected;

  const CardWidget({super.key, required this.card, required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 80,
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          width: selected ? 3 : 2,
          color: selected ? Colors.blue : Colors.black,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: card.isJoker
          ? const Center(child: Text('🃏', style: TextStyle(fontSize: 36)))
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  card.displayRank,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(card.displaySuit, style: const TextStyle(fontSize: 24)),
              ],
            ),
    );
  }
}
