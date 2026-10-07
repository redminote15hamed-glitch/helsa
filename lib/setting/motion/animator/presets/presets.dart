import 'package:flutter/material.dart';
import '../core/speeds.dart';
import '../extensions/entrance.dart';

abstract class AnimatorPresets {
  static Widget homeScreen({
    required Widget appBar,
    required Widget banner,
    required List<Widget> cards,
    required Widget bottomBar,
    Duration speed = AS.balanced,
    int intervalMs = 60,
  }) {
    return Column(
      children: [
        appBar.enSlideDown(s: speed, d: 0),
        banner.enHero(s: speed, d: intervalMs),
        Expanded(
          child: ListView.builder(
            itemCount: cards.length,
            itemBuilder: (context, index) {
              return cards[index].enSlideUp(
                s: speed,
                d: (intervalMs * 2) + (index * intervalMs),
              );
            },
          ),
        ),
        bottomBar.enSlideUp(
          s: speed,
          d: (intervalMs * 3) + (cards.length * intervalMs),
        ),
      ],
    );
  }

  static Widget cascadeColumn({
    required List<Widget> children,
    Duration speed = AS.balanced,
    int intervalMs = 50,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < children.length; i++)
          children[i].enSlideUp(s: speed, d: i * intervalMs),
      ],
    );
  }

  static Widget modalSheet({required Widget child}) {
    return child.enGlass(s: AS.slow);
  }

  static Widget animatedList({
    required List<Widget> children,
    int intervalMs = 40,
  }) {
    return ListView.builder(
      itemCount: children.length,
      itemBuilder: (context, index) {
        return children[index].enPop(d: index * intervalMs);
      },
    );
  }
}
