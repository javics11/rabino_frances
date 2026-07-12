import 'package:flutter/material.dart';

import '../models/meld.dart';
import 'card_widget.dart';

class MeldWidget extends StatelessWidget {
  final Meld meld;

  final VoidCallback? onTap;
  final GlobalKey? meldKey;

  const MeldWidget({super.key, required this.meld, this.onTap, this.meldKey});

  @override
  Widget build(BuildContext context) {
    const double overlap = 60;

    return GestureDetector(
      key: meldKey,
      onTap: onTap,
      child: SizedBox(
        width: 80 + (meld.cards.length - 1) * overlap,
        height: 110,
        child: Stack(
          children: List.generate(
            meld.cards.length,
            (index) => Positioned(
              left: index * overlap,
              child: SizedBox(
                width: 80,
                child: CardWidget(card: meld.cards[index], selected: false),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
