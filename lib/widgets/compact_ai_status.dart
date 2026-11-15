import 'package:flutter/material.dart';

class CompactAiStatus extends StatelessWidget {
  final String playerName;
  final int cardCount;

  const CompactAiStatus({
    super.key,
    required this.playerName,
    required this.cardCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            playerName,
            key: const ValueKey('compact-ai-status-name'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          const SizedBox(
            key: ValueKey('compact-ai-status-cards'),
            width: 14,
            height: 12,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  top: 2,
                  child: _MiniCardBack(
                    key: ValueKey('compact-ai-status-mini-card-0'),
                  ),
                ),
                Positioned(
                  left: 3,
                  top: 0,
                  child: _MiniCardBack(
                    key: ValueKey('compact-ai-status-mini-card-1'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 3),
          Text(
            '\u00D7 $cardCount',
            key: const ValueKey('compact-ai-status-count'),
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _MiniCardBack extends StatelessWidget {
  const _MiniCardBack({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.indigo,
        border: Border.all(color: Colors.white, width: .5),
        borderRadius: BorderRadius.circular(1),
      ),
      child: const SizedBox(width: 7, height: 10),
    );
  }
}
