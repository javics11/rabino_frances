import 'package:flutter/material.dart';

class CardBackWidget extends StatelessWidget {
  const CardBackWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 90,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.indigo,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: const Center(
        child: Text('🂠', style: TextStyle(fontSize: 24, color: Colors.white)),
      ),
    );
  }
}
