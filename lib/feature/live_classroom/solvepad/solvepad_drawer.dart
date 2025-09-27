import 'package:flutter/material.dart';
import 'package:solve_tutor/feature/live_classroom/solvepad/solvepad_stroke_model.dart';

enum DrawingMode { drag, pen, eraser, laser, highlighter }

class SolvepadDrawerLive extends CustomPainter {
  SolvepadDrawerLive(
    this.penPoints,
    this.replayPoints,
    this.eraserPoint,
    this.laserPoints,
    this.highlighterPoints,
    this.hostPenPoints,
    this.hostLaserPoints,
    this.hostHighlighterPoints,
    this.hostEraserPoint,
  );

  List<Offset?> replayPoints;
  List<SolvepadStroke?> penPoints;
  List<SolvepadStroke?> laserPoints;
  List<SolvepadStroke?> highlighterPoints;
  Offset eraserPoint;
  List<SolvepadStroke?> hostPenPoints;
  List<SolvepadStroke?> hostLaserPoints;
  List<SolvepadStroke?> hostHighlighterPoints;
  Offset hostEraserPoint;

  Paint penPaint = Paint()..strokeCap = StrokeCap.round;
  Paint eraserPaint = Paint()
    ..color = Colors.green.withOpacity(0.1)
    ..strokeWidth = 10
    ..strokeCap = StrokeCap.round;
  Paint borderPaint = Paint()
    ..color = Colors.green
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round;
  Paint laserPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  Paint highlightLayer = Paint()
    ..color = Colors.white.withOpacity(0.5)
    ..strokeWidth = 25
    ..strokeCap = StrokeCap.round;
  Paint highlightPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  Paint hostPenPaint = Paint()..strokeCap = StrokeCap.round;
  Paint hostEraserPaint = Paint()
    ..color = Colors.green.withOpacity(0.1)
    ..strokeWidth = 10
    ..strokeCap = StrokeCap.round;
  Paint hostBorderPaint = Paint()
    ..color = Colors.green
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round;
  Paint hostLaserPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  Paint hostHighlightLayer = Paint()
    ..color = Colors.white.withOpacity(0.5)
    ..strokeWidth = 25
    ..strokeCap = StrokeCap.round;
  Paint hostHighlightPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < penPoints.length - 1; i++) {
      if (penPoints[i]?.offset != null && penPoints[i + 1]?.offset != null) {
        penPaint.color = penPoints[i]!.color;
        penPaint.strokeWidth = penPoints[i]!.width;
        canvas.drawLine(
            penPoints[i]!.offset, penPoints[i + 1]!.offset, penPaint);
      }
    }

    Path path = Path();
    bool newPath = true;
    int newStrokeIndex = 0;
    for (int i = 0; i < highlighterPoints.length - 1; i++) {
      if (highlighterPoints[i]?.offset == null) {
        canvas.drawPath(path, highlightPaint);
        path = Path();
        newPath = true;
        newStrokeIndex = i + 1;
        continue;
      }
      if (newPath) {
        path.moveTo(highlighterPoints[newStrokeIndex]!.offset.dx,
            highlighterPoints[newStrokeIndex]!.offset.dy);
        newPath = false;
      } else {
        path.lineTo(
            highlighterPoints[i]!.offset.dx, highlighterPoints[i]!.offset.dy);
      }
      highlightPaint.color =
          highlighterPoints[newStrokeIndex]!.color.withOpacity(0.4);
      highlightPaint.strokeWidth =
          (highlighterPoints[newStrokeIndex]!.width * 10) + 5;
    }
    canvas.drawPath(path, highlightPaint);

    for (int i = 0; i < replayPoints.length - 1; i++) {
      if (replayPoints[i] != null && replayPoints[i + 1] != null) {
        canvas.drawLine(replayPoints[i]!, replayPoints[i + 1]!, penPaint);
      }
    }
    for (int i = 0; i < laserPoints.length - 1; i++) {
      if (laserPoints[i] != null && laserPoints[i + 1] != null) {
        laserPaint.color = laserPoints[i]!.color.withOpacity(0.8);
        laserPaint.strokeWidth = laserPoints[i]!.width + 1;
        penPaint.strokeWidth = laserPoints[i]!.width;
        penPaint.color = laserPoints[i]!.color;
        canvas.drawLine(
            laserPoints[i]!.offset, laserPoints[i + 1]!.offset, laserPaint);
        canvas.drawLine(
            laserPoints[i]!.offset, laserPoints[i + 1]!.offset, penPaint);
      }
    }
    canvas.drawCircle(eraserPoint, 10, eraserPaint);
    canvas.drawCircle(eraserPoint, 10, borderPaint);

    for (int i = 0; i < hostPenPoints.length - 1; i++) {
      if (hostPenPoints[i]?.offset != null &&
          hostPenPoints[i + 1]?.offset != null) {
        hostPenPaint.color = hostPenPoints[i]!.color;
        hostPenPaint.strokeWidth = hostPenPoints[i]!.width;
        canvas.drawLine(hostPenPoints[i]!.offset, hostPenPoints[i + 1]!.offset,
            hostPenPaint);
      }
    }

    Path hostPath = Path();
    bool hostNewPath = true;
    int hostNewStrokeIndex = 0;
    for (int i = 0; i < hostHighlighterPoints.length - 1; i++) {
      if (hostHighlighterPoints[i]?.offset == null) {
        canvas.drawPath(hostPath, hostHighlightPaint);
        hostPath = Path();
        hostNewPath = true;
        hostNewStrokeIndex = i + 1;
        continue;
      }
      if (hostNewPath) {
        hostPath.moveTo(hostHighlighterPoints[hostNewStrokeIndex]!.offset.dx,
            hostHighlighterPoints[hostNewStrokeIndex]!.offset.dy);
        hostNewPath = false;
      } else {
        hostPath.lineTo(hostHighlighterPoints[i]!.offset.dx,
            hostHighlighterPoints[i]!.offset.dy);
      }
      hostHighlightPaint.color =
          hostHighlighterPoints[hostNewStrokeIndex]!.color.withOpacity(0.4);
      hostHighlightPaint.strokeWidth =
          (hostHighlighterPoints[hostNewStrokeIndex]!.width * 10) + 5;
    }
    canvas.drawPath(hostPath, hostHighlightPaint);

    for (int i = 0; i < hostLaserPoints.length - 1; i++) {
      if (hostLaserPoints[i] != null && hostLaserPoints[i + 1] != null) {
        hostLaserPaint.color = hostLaserPoints[i]!.color.withOpacity(0.8);
        hostLaserPaint.strokeWidth = hostLaserPoints[i]!.width + 1;
        hostPenPaint.strokeWidth = hostLaserPoints[i]!.width;
        hostPenPaint.color = hostLaserPoints[i]!.color;
        canvas.drawLine(hostLaserPoints[i]!.offset,
            hostLaserPoints[i + 1]!.offset, hostLaserPaint);
        canvas.drawLine(hostLaserPoints[i]!.offset,
            hostLaserPoints[i + 1]!.offset, hostPenPaint);
      }
    }
    canvas.drawCircle(hostEraserPoint, 10, hostEraserPaint);
    canvas.drawCircle(hostEraserPoint, 10, hostBorderPaint);
  }

  @override
  bool shouldRepaint(SolvepadDrawerLive oldDelegate) => true;
}

class SolvepadDrawerMarketplace extends CustomPainter {
  SolvepadDrawerMarketplace(
    this.penPoints,
    this.replayPoints,
    this.eraserPoint,
    this.laserPoints,
    this.highlighterPoints,
  );

  List<Offset?> replayPoints;
  List<SolvepadStroke?> penPoints;
  List<SolvepadStroke?> laserPoints;
  List<SolvepadStroke?> highlighterPoints;
  Offset eraserPoint;

  Paint penPaint = Paint()..strokeCap = StrokeCap.round;
  Paint eraserPaint = Paint()
    ..color = Colors.green.withOpacity(0.1)
    ..strokeWidth = 10
    ..strokeCap = StrokeCap.round;
  Paint borderPaint = Paint()
    ..color = Colors.green
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round;
  Paint laserPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  Paint highlightLayer = Paint()
    ..color = Colors.white.withOpacity(0.5)
    ..strokeWidth = 25
    ..strokeCap = StrokeCap.round;
  Paint highlightPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final smoothedPen = chaikinSmoothSolvepad(penPoints, iterations: 2);
    for (int i = 0; i < smoothedPen.length - 1; i++) {
      final a = smoothedPen[i];
      final b = smoothedPen[i + 1];
      if (a?.offset != null && b?.offset != null) {
        penPaint
          ..color = a!.color
          ..strokeWidth = a.width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        canvas.drawLine(a.offset, b!.offset, penPaint);
      }
    }

    Path path = Path();
    bool newPath = true;
    int newStrokeIndex = 0;
    for (int i = 0; i < highlighterPoints.length - 1; i++) {
      if (highlighterPoints[i]?.offset == null) {
        canvas.drawPath(path, highlightPaint);
        path = Path();
        newPath = true;
        newStrokeIndex = i + 1;
        continue;
      }
      if (newPath) {
        path.moveTo(highlighterPoints[newStrokeIndex]!.offset.dx,
            highlighterPoints[newStrokeIndex]!.offset.dy);
        newPath = false;
      } else {
        path.lineTo(
            highlighterPoints[i]!.offset.dx, highlighterPoints[i]!.offset.dy);
      }
      highlightPaint.color =
          highlighterPoints[newStrokeIndex]!.color.withOpacity(0.4);
      highlightPaint.strokeWidth =
          (highlighterPoints[newStrokeIndex]!.width * 10) + 5;
    }
    canvas.drawPath(path, highlightPaint);

    for (int i = 0; i < replayPoints.length - 1; i++) {
      if (replayPoints[i] != null && replayPoints[i + 1] != null) {
        canvas.drawLine(replayPoints[i]!, replayPoints[i + 1]!, penPaint);
      }
    }
    for (int i = 0; i < laserPoints.length - 1; i++) {
      if (laserPoints[i] != null && laserPoints[i + 1] != null) {
        laserPaint.color = laserPoints[i]!.color.withOpacity(0.8);
        laserPaint.strokeWidth = laserPoints[i]!.width + 1;
        penPaint.strokeWidth = laserPoints[i]!.width;
        penPaint.color = laserPoints[i]!.color;
        canvas.drawLine(
            laserPoints[i]!.offset, laserPoints[i + 1]!.offset, laserPaint);
        canvas.drawLine(
            laserPoints[i]!.offset, laserPoints[i + 1]!.offset, penPaint);
      }
    }
    canvas.drawCircle(eraserPoint, 10, eraserPaint);
    canvas.drawCircle(eraserPoint, 10, borderPaint);
  }

  List<SolvepadStroke?> chaikinSmoothSolvepad(
      List<SolvepadStroke?> pts, {
        int iterations = 1,
      }) {
    List<SolvepadStroke?> current = pts;

    for (int k = 0; k < iterations; k++) {
      final next = <SolvepadStroke?>[];
      int i = 0;

      while (i < current.length) {
        // 1) Preserve separators
        while (i < current.length && current[i]?.offset == null) {
          next.add(null);
          i++;
        }
        if (i >= current.length) break;

        // 2) Collect one stroke (until next null)
        final stroke = <SolvepadStroke>[];
        while (i < current.length && current[i]?.offset != null) {
          stroke.add(current[i]!);
          i++;
        }

        // 3) Short strokes: pass through
        if (stroke.length <= 2) {
          next.addAll(stroke);
          continue;
        }

        // 4) Chaikin corner cutting on this stroke
        next.add(stroke.first); // keep first endpoint
        for (int j = 0; j < stroke.length - 1; j++) {
          final a = stroke[j];
          final b = stroke[j + 1];
          final p = a.offset;
          final q = b.offset;

          // New points between a and b
          final q1 = Offset(0.75 * p.dx + 0.25 * q.dx, 0.75 * p.dy + 0.25 * q.dy);
          final r1 = Offset(0.25 * p.dx + 0.75 * q.dx, 0.25 * p.dy + 0.75 * q.dy);

          // Policy: inherit color/width from 'a'.
          // (Or interpolate if you let color/width vary mid-stroke.)
          next.add(SolvepadStroke(q1, a.color, a.width));
          next.add(SolvepadStroke(r1, a.color, a.width));
        }
        next.add(stroke.last); // keep last endpoint
      }

      current = next;
    }

    return current;
  }

  @override
  bool shouldRepaint(SolvepadDrawerMarketplace oldDelegate) => true;
}
