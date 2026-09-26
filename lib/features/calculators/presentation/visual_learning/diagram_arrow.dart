import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Viewport geometry only. Zero/subpixel arrows become dots.
void paintDiagramArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
  final delta = end - start;
  if (delta.distance < 1) {
    canvas.drawCircle(start, 3, paint);
    return;
  }
  canvas.drawLine(start, end, paint);
  final direction = math.atan2(delta.dy, delta.dx);
  final head = math.min(9.0, delta.distance * .4);
  for (final turn in [-.5, .5]) {
    canvas.drawLine(
      end,
      end -
          Offset(math.cos(direction + turn), math.sin(direction + turn)) * head,
      paint,
    );
  }
}
