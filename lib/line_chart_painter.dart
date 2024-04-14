import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_custom_line_chart/my_weight.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:touchable/touchable.dart';

class LineChartPainter extends CustomPainter {
  final List<MyWeight> myWeightProgress;
  final double heightView;
  final double minWeight;
  final double maxWeight;
  final BuildContext context;
  final Function(MyWeight myWeight) onPointClick;

  LineChartPainter({
    required this.myWeightProgress,
    required this.heightView,
    required this.minWeight,
    required this.maxWeight,
    required this.context,
    required this.onPointClick,
  });

  final _mainColor = const Color(0xff4259A4);
  final _backgroundColor = Colors.white;

  // range max min for Y axis
  late final ceilMax = maxWeight.ceil() + 1.0;
  late final floorMin = minWeight.floor() - 1.0;

  final qtyYLabels = 5;

  final paddingTop = 30.0;
  final paddingBottom = 30.0;
  final paddingLeft = 30.0;
  final paddingRight = 10.0;

  final tooltipLabelStyle = const TextStyle(color: Colors.white, fontSize: 12);
  final xAxisLabelStyle = const TextStyle(color: Color(0xff83808C), fontSize: 8);
  final yAxisLabelStyle = const TextStyle(color: Color(0xffAAA8B1), fontSize: 10);

  late final pointInnerPaint = Paint()
    ..color = _mainColor
    ..style = PaintingStyle.fill;

  final pointFocusingOuterPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  final pointOuterPaint = Paint()
    ..color = Colors.white.withOpacity(0.5)
    ..style = PaintingStyle.fill;

  late final tooltipPaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.fill;

  late final connectPathPaint = Paint()
    ..color = _mainColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  late final outlinePathPaint = Paint()
    ..style = PaintingStyle.fill
    ..shader = ui.Gradient.linear(
      Offset.zero,
      Offset(0, heightView),
      [
        _mainColor.withOpacity(0.32),
        _mainColor.withOpacity(0),
      ],
    );

  final columnFocusingPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xffE6EAF6).withOpacity(0.5);

  final tappableColumnPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.transparent;

  final outlinePaint = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke
    ..color = const Color(0xffF4F4F4);

  final dottedLinePaint = Paint()
    ..color = const Color(0xff83808C)
    ..strokeWidth = 1;

  @override
  void paint(Canvas canvas, Size size) {
    final touchyCanvas = TouchyCanvas(context, canvas);

    // frame
    final clipRRect = RRect.fromLTRBR(0, 0, size.width, size.height, const Radius.circular(4));
    canvas.clipRRect(clipRRect);

    // fill background color
    final paint = Paint()..color = _backgroundColor;
    canvas.drawPaint(paint);

    // compute the drawable chart width and height
    final drawableHeight = size.height - paddingTop - paddingBottom;
    final drawableWidth = size.width - paddingLeft - paddingRight;
    final widthColumn = (drawableWidth / myWeightProgress.length).toDouble();
    final heightColumn = drawableHeight;

    // escape if invalid
    if (heightColumn <= 0 || widthColumn <= 0) return;
    if (maxWeight - minWeight <= 0) return;

    // height ratio between max - min
    final heightRatio = heightColumn / (ceilMax - floorMin);

    final center = Offset(paddingLeft + widthColumn / 2, paddingTop + heightColumn / 2);

    final points = _computePoints(center, widthColumn, heightColumn, heightRatio);

    final yPositions = _computeYPositions(
      paddingTop: paddingTop,
      heightRatio: heightColumn / (qtyYLabels - 1),
      qty: qtyYLabels,
    );

    // draw horizontal outline
    _drawHorizontalOutline(
      canvas: canvas,
      positions: yPositions,
      startDx: paddingLeft,
      endDx: size.width - paddingRight,
    );

    // draw vertical outline
    _drawVerticalOutline(
      canvas,
      center,
      widthColumn,
      heightColumn,
    );

    // draw connect path
    final connectPath = _computeConnectPath(
      points: points,
      paddingLeft: paddingLeft,
      widthColumn: widthColumn,
      maxDx: size.width - paddingRight - widthColumn / 2,
      maxDy: size.height,
    );
    canvas.drawPath(connectPath, connectPathPaint);

    // draw border path
    final borderPath = _computeBorderPath(
      points: points,
      paddingLeft: paddingLeft,
      widthColumn: widthColumn,
      maxDy: size.height,
    );
    canvas.drawPath(borderPath, outlinePathPaint);

    // draw X axis labels
    final xLabels = _computeXLabels(myWeightProgress);
    _drawXAxisLabels(
      canvas: canvas,
      center: center,
      labels: xLabels,
      points: points,
      labelMaxWidth: widthColumn,
      labelMarginTop: drawableHeight + paddingTop + 8,
    );

    // draw Y axis labels
    final yLabels = _computeYLabels(qtyYLabels);
    _drawYAxisLabels(
      canvas: canvas,
      center: center,
      labels: yLabels,
      positions: yPositions,
      labelMaxWidth: paddingLeft,
    );

    // draw points
    _drawPoints(
      points: points,
      touchyCanvas: touchyCanvas,
      canvas: canvas,
      maxDy: size.height,
      drawableHeight: drawableHeight,
      widthFocusingColumn: widthColumn,
    );

    // draw tooltip
    final tooltipLabels = _computeTooltipLabels(myWeightProgress);
    _drawTooltip(
      canvas: canvas,
      center: center,
      labels: tooltipLabels,
      points: points,
      labelMaxWidth: 62,
    );
  }

  void _drawHorizontalOutline({
    required Canvas canvas,
    required List<Offset> positions,
    required double startDx,
    required double endDx,
  }) {
    for (var position in positions) {
      final path = Path();
      path.moveTo(startDx, position.dy);
      path.lineTo(endDx, position.dy);
      canvas.drawPath(path, outlinePaint);
    }
  }

  void _drawVerticalOutline(
    Canvas canvas,
    Offset center,
    double width,
    double height,
  ) {
    for (var _ in myWeightProgress) {
      final rect = Rect.fromCenter(center: center, width: width, height: height);
      canvas.drawRect(rect, outlinePaint);
      center += Offset(width, 0);
    }
  }

  void _drawYAxisLabels({
    required Canvas canvas,
    required Offset center,
    required List<String> labels,
    required List<Offset> positions,
    required double labelMaxWidth,
  }) {
    for (var i = 0; i < labels.length; i++) {
      final label = labels[i];
      final yPoint = positions[i];
      final textPainter = _getTextPainter(label, yAxisLabelStyle, labelMaxWidth);
      final position = Offset(0, yPoint.dy - textPainter.height / 2);
      textPainter.paint(canvas, position);
      center += Offset(labelMaxWidth, 0);
    }
  }

  void _drawXAxisLabels({
    required Canvas canvas,
    required Offset center,
    required List<String> labels,
    required List<Offset> points,
    required double labelMaxWidth,
    required double labelMarginTop,
  }) {
    for (var i = 0; i < labels.length; i++) {
      final label = labels[i];
      final point = points[i];
      final textPainter = _getTextPainter(label, xAxisLabelStyle, labelMaxWidth);
      final position = Offset(point.dx - textPainter.width / 2, labelMarginTop);
      textPainter.paint(canvas, position);
      center += Offset(labelMaxWidth, 0);
    }
  }

  void _drawTooltip({
    required Canvas canvas,
    required Offset center,
    required List<String> labels,
    required List<Offset> points,
    required double labelMaxWidth,
  }) {
    // labels and points must be the same length
    for (var i = 0; i < labels.length; i++) {
      const spaceBetweenPointAndTooltip = 12.0;
      final label = labels[i];
      final point = points[i];

      final textPainter = _getTextPainter(label, tooltipLabelStyle, labelMaxWidth);
      final myWeight = myWeightProgress[i];
      final position = point +
          Offset(-textPainter.width / 2, -textPainter.height / 2) +
          const Offset(0, -12 - spaceBetweenPointAndTooltip);

      // draw tooltip
      if (myWeight.isFocusing) {
        // draw rounded rectangle
        const widthTooltip = 63.0;
        const heightTooltip = 26.0;
        canvas.drawRRect(
          RRect.fromLTRBR(
            point.dx - widthTooltip / 2,
            point.dy - heightTooltip - spaceBetweenPointAndTooltip,
            point.dx + widthTooltip / 2,
            point.dy - spaceBetweenPointAndTooltip,
            const Radius.circular(12),
          ),
          tooltipPaint,
        );

        // draw triangle
        const triangleW = 10;
        const triangleH = 5;
        final Path trianglePath = Path()
          ..moveTo(point.dx - triangleW / 2, point.dy - spaceBetweenPointAndTooltip)
          ..lineTo(point.dx, point.dy - spaceBetweenPointAndTooltip + triangleH)
          ..lineTo(point.dx + triangleW / 2, point.dy - spaceBetweenPointAndTooltip)
          ..lineTo(point.dx - triangleW / 2, point.dy - spaceBetweenPointAndTooltip);
        canvas.drawPath(trianglePath, tooltipPaint);

        // draw text label
        textPainter.paint(canvas, position);
      }
      center += Offset(labelMaxWidth, 0);
    }
  }

  void _drawPoints({
    required List<Offset> points,
    required TouchyCanvas touchyCanvas,
    required Canvas canvas,
    required double maxDy,
    required double drawableHeight,
    required double widthFocusingColumn,
  }) {
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final myWeight = myWeightProgress[i];
      const radiusOuterCircle = 8.0;
      const radiusInnerCircle = 4.0;
      // draw column focusing
      final columnFocusing = RRect.fromLTRBR(
        point.dx - widthFocusingColumn / 2,
        paddingTop,
        point.dx + widthFocusingColumn / 2,
        maxDy,
        const Radius.circular(8),
      );
      touchyCanvas.drawRRect(
        columnFocusing,
        myWeight.isFocusing ? columnFocusingPaint : tappableColumnPaint,
        onTapDown: (_) => onPointClick(myWeight),
      );
      // draw dotted line
      if (myWeight.isFocusing) {
        double startY = paddingTop;
        const dashHeight = 3, dashSpace = 3;
        while (startY < drawableHeight + paddingTop) {
          canvas.drawLine(Offset(point.dx, startY), Offset(point.dx, startY + 2), dottedLinePaint);
          startY += dashHeight + dashSpace;
        }
      }
      // draw outer circle
      touchyCanvas.drawCircle(
        point,
        radiusOuterCircle,
        myWeight.isFocusing ? pointFocusingOuterPaint : pointOuterPaint,
        onTapDown: (_) => onPointClick(myWeight),
      );
      // draw inner circle
      touchyCanvas.drawCircle(
        point,
        radiusInnerCircle,
        pointInnerPaint,
        onTapDown: (_) => onPointClick(myWeight),
      );
    }
  }

  TextPainter _getTextPainter(String text, TextStyle style, double maxWidth) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(text: textSpan, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
    textPainter.layout(minWidth: 0, maxWidth: maxWidth);
    return textPainter;
  }

  List<String> _computeTooltipLabels(List<MyWeight> myWeightProgress) {
    return myWeightProgress.map((e) => "${e.weight.toStringAsFixed(1)} kg").toList();
  }

  List<String> _computeXLabels(List<MyWeight> myWeightProgress) {
    return myWeightProgress
        .map((e) => "${DateFormat.d().format(e.dateTime)}\n ${DateFormat.MMM().format(e.dateTime)}")
        .toList();
  }

  List<String> _computeYLabels(int qty) {
    final result = <String>[];
    final ratio = (ceilMax - floorMin) / (qty - 1);
    var value = ceilMax;
    for (var i = 1; i <= qty; i++) {
      result.add(value.toStringAsFixed(1));
      value -= ratio;
    }
    return result;
  }

  List<Offset> _computeYPositions({required double paddingTop, required double heightRatio, required int qty}) {
    final points = <Offset>[];
    for (var i = 1; i <= qty; i++) {
      final dp = Offset(0, paddingTop);
      points.add(dp);
      paddingTop += heightRatio;
    }
    return points;
  }

  List<Offset> _computePoints(
    Offset center,
    double widthColumn,
    double heightColumn,
    double heightRatio,
  ) {
    final points = <Offset>[];
    for (var myWeight in myWeightProgress) {
      final yy = heightColumn - (myWeight.weight - floorMin) * heightRatio;
      final dp = Offset(center.dx, center.dy - heightColumn / 2 + yy);
      points.add(dp);
      center += Offset(widthColumn, 0);
    }
    return points;
  }

  Path _computeConnectPath({
    required List<Offset> points,
    required double paddingLeft,
    required double widthColumn,
    required double maxDx,
    required double maxDy,
  }) {
    final path = Path();
    // separate width column into 3 parts (for control points of cubicTo)
    final segWidth = widthColumn / 3;
    for (var i = 0; i < points.length; i++) {
      final currentPoint = points[i];
      if (i == 0) {
        path.moveTo(currentPoint.dx, currentPoint.dy);
      } else {
        // draw straight line
        // path.lineTo(p.dx, p.dy);

        // draw curved line
        final previousPoint = points[i - 1];
        final initialPaddingLeft = paddingLeft + widthColumn / 2;
        // use cubicTo instead of lineTo to make curved line
        path.cubicTo(
          initialPaddingLeft + (widthColumn * (i - 1)) + segWidth,
          previousPoint.dy,
          initialPaddingLeft + (widthColumn * (i - 1)) + segWidth * 2,
          currentPoint.dy,
          currentPoint.dx,
          currentPoint.dy,
        );
      }
    }
    return path;
  }

  Path _computeBorderPath({
    required List<Offset> points,
    required double paddingLeft,
    required double widthColumn,
    required double maxDy,
  }) {
    final path = Path();
    // separate width column into 3 parts (for control points of cubicTo)
    final segWidth = widthColumn / 3;
    for (var i = 0; i < points.length; i++) {
      final currentPoint = points[i];
      if (i == 0) {
        path.moveTo(currentPoint.dx, currentPoint.dy);
      } else {
        // draw straight line
        // path.lineTo(p.dx, p.dy);

        // draw curved line
        final previousPoint = points[i - 1];
        final initialPaddingLeft = paddingLeft + widthColumn / 2;
        // use cubicTo instead of lineTo to make curved line
        path.cubicTo(
          initialPaddingLeft + (widthColumn * (i - 1)) + segWidth,
          previousPoint.dy,
          initialPaddingLeft + (widthColumn * (i - 1)) + segWidth * 2,
          currentPoint.dy,
          currentPoint.dx,
          currentPoint.dy,
        );
      }
    }

    // close path to fill out color from path to bottom
    if (points.isNotEmpty) {
      path.lineTo(points.last.dx, maxDy);
      path.lineTo(points.first.dx, maxDy);
      path.lineTo(points.first.dx, points.first.dy);
    }

    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
