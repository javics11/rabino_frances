import 'package:flutter/material.dart';

import '../models/meld.dart';
import 'meld_widget.dart';

class MeldAreaWidget extends StatelessWidget {
  final List<Meld> melds;
  final String emptyText;
  final Color borderColor;

  /// Allows GameScreen to know where this widget is.
  final GlobalKey? areaKey;
  final List<GlobalKey>? meldKeys;
  final Function(int)? onMeldTapped;
  final VoidCallback? onAreaTapped;

  const MeldAreaWidget({
    super.key,
    required this.melds,
    required this.emptyText,
    this.borderColor = Colors.white54,
    this.areaKey,
    this.meldKeys,
    this.onMeldTapped,
    this.onAreaTapped,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: areaKey,
      behavior: HitTestBehavior.deferToChild,
      onTap: onAreaTapped,
      child: SizedBox(
        height: 120,
        width: double.infinity,
        child: Stack(
          children: [
            // Background of the meld area
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            if (melds.isEmpty)
              Center(
                child: Text(
                  emptyText,
                  style: TextStyle(
                    color: borderColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: IntrinsicWidth(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...melds.asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: MeldWidget(
                              key: meldKeys != null
                                  ? meldKeys![entry.key]
                                  : null,
                              meld: entry.value,
                              onTap: onMeldTapped == null
                                  ? null
                                  : () => onMeldTapped!(entry.key),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
