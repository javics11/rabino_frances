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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final nameWidth = _textWidth(context, playerName, _nameStyle);
          final countWidth = _textWidth(
            context,
            '\u00D7 $cardCount',
            _countStyle,
          );
          final wideWidth = nameWidth + 4 + 14 + 3 + countWidth;
          final fanCountWidth = 14 + 2 + countWidth;
          final content = !constraints.hasBoundedWidth ||
                  availableWidth >= wideWidth
              ? _wideContent
              : availableWidth >= fanCountWidth
                  ? _mediumContent
                  : _narrowContent;
          return Align(
            alignment: Alignment.center,
            widthFactor: 1,
            heightFactor: 1,
            child: content,
          );
        },
      ),
    );
  }

  Widget get _wideContent => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _nameText,
          const SizedBox(width: 4),
          _cardBacks,
          const SizedBox(width: 3),
          _countText,
        ],
      );

  Widget get _mediumContent => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _nameText,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _cardBacks,
              const SizedBox(width: 2),
              _countText,
            ],
          ),
        ],
      );

  Widget get _narrowContent => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _cardBacks,
              const SizedBox(width: 2),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _nameText,
                  _countText,
                ],
              ),
            ],
          ),
        ],
      );

  double _textWidth(BuildContext context, String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  static const _nameStyle = TextStyle(
    color: Colors.white,
    fontSize: 11,
    fontWeight: FontWeight.bold,
  );

  static const _countStyle = TextStyle(color: Colors.white, fontSize: 11);

  Widget get _nameText => Text(
        playerName,
        key: const ValueKey('compact-ai-status-name'),
        style: _nameStyle,
      );

  Widget get _countText => Text(
        '\u00D7 $cardCount',
        key: const ValueKey('compact-ai-status-count'),
        style: _countStyle,
      );

  Widget get _cardBacks => const SizedBox(
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
      );
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
