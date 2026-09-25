import 'package:flutter/material.dart';

/// Short diagram symbols only. Full values and explanations use ordinary text
/// outside the canvas, so they can wrap without altering the diagram geometry.
void paintDiagramLabel(
  Canvas canvas,
  String text,
  Offset center,
  Color color,
  TextScaler scaler,
  TextStyle labelStyle,
) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: labelStyle.copyWith(color: color, fontSize: 13),
    ),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
  )..layout();
  painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
  painter.dispose();
}
