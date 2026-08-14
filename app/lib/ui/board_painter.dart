import 'package:flutter/material.dart';
import '../models/board.dart';
import '../api/protocol.dart';

import '../../models/tree.dart';
import '../../models/move.dart';
import '../models/board_settings.dart';
import '../models/board_styles.dart';

class BoardPainter extends CustomPainter {
  final Board board;
  final TreeNode currentNode;
  final EngineResponse? analysis;
  final BoardSettings settings;

  BoardPainter({
    required this.board,
    required this.currentNode,
    required this.settings,
    this.analysis,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw board background
    final Paint bgPaint = Paint()
      ..color = settings.boardColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8.0),
      ),
      bgPaint,
    );

    final int cols = board.columns;
    final int rows = board.rows;

    // We allocate space for (cols - 1) grid squares PLUS margin blocks
    final double marginBlocks = settings.showCoordinates ? 2.2 : 1.0;
    final double cellWidth = size.width / (cols - 1 + marginBlocks);
    final double cellHeight = size.height / (rows - 1 + marginBlocks);
    final double cellSize = cellWidth < cellHeight ? cellWidth : cellHeight;

    // Center the grid
    final double gridWidth = cellSize * (cols - 1);
    final double gridHeight = cellSize * (rows - 1);
    final double offsetX = (size.width - gridWidth) / 2;
    final double offsetY = (size.height - gridHeight) / 2;

    // Scale line thickness based on cell size (between 0.5 and 4.0 pixels)
    final double lineThickness = (cellSize * 0.04 * settings.lineThickness)
        .clamp(0.5, 4.0);
    final linePaint = Paint()
      ..color = BoardStyles.lineColors[settings.lineStyleIndex]
      ..strokeWidth = lineThickness;

    // 2. Draw vertical lines
    for (int i = 0; i < cols; i++) {
      double x = offsetX + i * cellSize;
      canvas.drawLine(
        Offset(x, offsetY),
        Offset(x, offsetY + gridHeight),
        linePaint,
      );
    }

    // Draw horizontal lines
    for (int i = 0; i < rows; i++) {
      double y = offsetY + i * cellSize;
      canvas.drawLine(
        Offset(offsetX, y),
        Offset(offsetX + gridWidth, y),
        linePaint,
      );
    }

    // 2.5 Draw Coordinates
    if (settings.showCoordinates) {
      _drawCoordinates(canvas, offsetX, offsetY, cellSize, cols, rows);
    }

    // 3. Draw star points (hoshi) if 19x19 board
    if (cols == 19 && rows == 19) {
      final hoshiPaint = Paint()
        ..color = BoardStyles.lineColors[settings.lineStyleIndex];
      final List<int> hoshiPoints = [3, 9, 15]; // 4th, 10th, and 16th lines
      final double hoshiRadius =
          cellSize *
          0.1 *
          (settings.starPointThickness / 3.0); // Scale hoshi proportionally

      for (int x in hoshiPoints) {
        for (int y in hoshiPoints) {
          canvas.drawCircle(
            Offset(offsetX + x * cellSize, offsetY + y * cellSize),
            hoshiRadius,
            hoshiPaint,
          );
        }
      }
    }

    // 4. Draw stones
    final double stoneRadius = cellSize * 0.5 * settings.stoneScale;

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        final int player = board.grid[y * cols + x];
        if (player == 0) continue;

        final Offset center = Offset(
          offsetX + x * cellSize,
          offsetY + y * cellSize,
        );
        final Rect stoneRect = Rect.fromCircle(
          center: center,
          radius: stoneRadius,
        );

        final Paint stonePaint = Paint();

        // Draw drop shadow
        if (settings.stoneDropShadow > 0) {
          final shadowPaint = Paint()
            ..color = Colors.black.withValues(alpha: 0.3)
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              settings.stoneDropShadow,
            );
          canvas.drawCircle(
            Offset(
              center.dx + settings.stoneDropShadow * 0.5,
              center.dy + settings.stoneDropShadow * 0.5,
            ),
            stoneRadius,
            shadowPaint,
          );
        }

        if (player == 1) {
          stonePaint.shader = BoardStyles
              .blackStones[settings.blackStoneStyleIndex]
              .createShader(stoneRect);
        } else if (player == 2) {
          stonePaint.shader = BoardStyles
              .whiteStones[settings.whiteStoneStyleIndex]
              .createShader(stoneRect);
        } else {
          stonePaint.color = Colors.red;
        }

        canvas.drawCircle(center, stoneRadius, stonePaint);

        // Draw base outline
        if (settings.stoneOutlineThickness > 0) {
          final outlineBasePaint = Paint()
            ..color = Colors.black87
            ..style = PaintingStyle.stroke
            ..strokeWidth = settings.stoneOutlineThickness;
          canvas.drawCircle(center, stoneRadius, outlineBasePaint);
        }

        int? latestMoveX = currentNode.move is Play
            ? (currentNode.move as Play).x
            : null;
        int? latestMoveY = currentNode.move is Play
            ? (currentNode.move as Play).y
            : null;

        bool isLatest =
            settings.highlightLastMove &&
            (latestMoveX != null &&
                latestMoveY != null &&
                x == latestMoveX &&
                y == latestMoveY);

        if (isLatest) {
          final Paint highlightPaint = Paint()
            ..color = Colors.blue.shade500
            ..style = PaintingStyle.stroke
            ..strokeWidth = (cellSize * 0.12).clamp(2.5, 4.5);
          canvas.drawCircle(center, stoneRadius, highlightPaint);
        }
      }
    }

    // 4.5 Draw Markups
    _drawMarkups(canvas, offsetX, offsetY, cellSize, stoneRadius);

    // 5. Draw Analysis Overlays (Move Options)
    EngineResponse? activeAnalysis = analysis;

    if (activeAnalysis == null) {
      return; // Nothing to draw
    }

    for (int i = 0; i < activeAnalysis.moveOptions.length; i++) {
      if (i > 4) break; // Only show top 5

      final option = activeAnalysis.moveOptions[i];

      // Skip pass moves or invalid indices
      if (option.moveIndex >= cols * rows) continue;

      int x = option.moveIndex % cols;
      int y = option.moveIndex ~/ cols;

      // Calculate point difference (relative to the player to move)
      double pointDiff = option.scoreLead - activeAnalysis.rootScoreLead;

      Color boxColor;
      if (i == 0) {
        boxColor = Colors.blue.shade800.withValues(
          alpha: 0.85,
        ); // Top 1: Dark Blue
      } else if (pointDiff >= 0) {
        boxColor = Colors.green.shade800.withValues(
          alpha: 0.85,
        ); // Good/Equal: Dark Green
      } else if (pointDiff >= -2.0) {
        boxColor = Colors.amber.shade900.withValues(
          alpha: 0.85,
        ); // Suboptimal: Dark Amber/Yellow
      } else {
        boxColor = Colors.red.shade800.withValues(
          alpha: 0.85,
        ); // Blunder: Dark Red
      }

      final Offset center = Offset(
        offsetX + x * cellSize,
        offsetY + y * cellSize,
      );

      final Rect boxRect = Rect.fromCenter(
        center: center,
        width: cellSize * 0.8,
        height: cellSize * 0.8,
      );

      final Paint boxPaint = Paint()
        ..color = boxColor
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(boxRect, const Radius.circular(4.0)),
        boxPaint,
      );

      // Draw point difference text
      String scoreText =
          (pointDiff > 0 ? '+' : '') + pointDiff.toStringAsFixed(1);
      // Prevent "-0.0" display
      if (scoreText == "-0.0") scoreText = "0.0";

      final textSpan = TextSpan(
        text: scoreText,
        style: TextStyle(
          color: Colors.white, // White text on the colored boxes
          fontSize: cellSize * 0.28,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();

      // Center the text in the box
      final Offset textOffset = Offset(
        center.dx - (textPainter.width / 2),
        center.dy - (textPainter.height / 2),
      );
      textPainter.paint(canvas, textOffset);
    }
  }

  void _drawMarkups(
    Canvas canvas,
    double offsetX,
    double offsetY,
    double cellSize,
    double stoneRadius,
  ) {
    final int cols = board.columns;

    // Helper to get color contrasting with the stone (or board) beneath
    Color getContrastingColor(int index) {
      int player = board.grid[index];
      if (player == 1) return Colors.white; // On black stone
      if (player == 2) return Colors.black; // On white stone
      return Colors.black; // On empty board
    }

    // Helper to draw a background circle on empty intersections to obscure grid lines
    void drawBackgroundCircleIfEmpty(Canvas c, Offset center, int index) {
      if (board.grid[index] == 0) {
        c.drawCircle(
          center,
          stoneRadius *
              0.7, // Reduce the background circle size a bit since marks are smaller
          Paint()
            ..color =
                const Color(0xFFDCB35C) // Fully opaque board color
            ..style = PaintingStyle.fill,
        );
      }
    }

    void drawShape(
      int index,
      void Function(Canvas c, Offset center, Paint p, double size) drawFunc,
    ) {
      int x = index % cols;
      int y = index ~/ cols;
      Offset center = Offset(offsetX + x * cellSize, offsetY + y * cellSize);

      drawBackgroundCircleIfEmpty(canvas, center, index);

      Paint paint = Paint()
        ..color = getContrastingColor(index)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (cellSize * 0.1).clamp(1.5, 3.0);
      drawFunc(
        canvas,
        center,
        paint,
        stoneRadius * 0.60,
      ); // Shape is 60% size of a stone
    }

    // Triangle
    for (int index in currentNode.triangleMarks) {
      drawShape(index, (c, center, p, size) {
        Path path = Path();
        path.moveTo(center.dx, center.dy - size);
        path.lineTo(
          center.dx - size * 0.866,
          center.dy + size * 0.5,
        ); // 0.866 is approx sqrt(3)/2
        path.lineTo(center.dx + size * 0.866, center.dy + size * 0.5);
        path.close();
        c.drawPath(path, p);
      });
    }

    // Square
    for (int index in currentNode.squareMarks) {
      drawShape(index, (c, center, p, size) {
        c.drawRect(
          Rect.fromCenter(
            center: center,
            width: size * 1.5,
            height: size * 1.5,
          ),
          p,
        );
      });
    }

    // Circle
    for (int index in currentNode.circleMarks) {
      drawShape(index, (c, center, p, size) {
        c.drawCircle(center, size * 0.8, p);
      });
    }

    // Cross (X)
    for (int index in currentNode.crossMarks) {
      drawShape(index, (c, center, p, size) {
        double offset = size * 0.6;
        c.drawLine(
          Offset(center.dx - offset, center.dy - offset),
          Offset(center.dx + offset, center.dy + offset),
          p,
        );
        c.drawLine(
          Offset(center.dx - offset, center.dy + offset),
          Offset(center.dx + offset, center.dy - offset),
          p,
        );
      });
    }

    // Labels (Letters/Numbers)
    for (var entry in currentNode.labels.entries) {
      int index = entry.key;
      String text = entry.value;

      int x = index % cols;
      int y = index ~/ cols;
      Offset center = Offset(offsetX + x * cellSize, offsetY + y * cellSize);

      drawBackgroundCircleIfEmpty(canvas, center, index);

      final textSpan = TextSpan(
        text: text,
        style: TextStyle(
          color: getContrastingColor(index),
          fontSize: cellSize * 0.55, // Slightly smaller text
          fontWeight: FontWeight.w900, // Extra bold to match thick shape lines
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          center.dx - textPainter.width / 2,
          center.dy - textPainter.height / 2,
        ),
      );
    }
  }

  void _drawCoordinates(
    Canvas canvas,
    double offsetX,
    double offsetY,
    double cellSize,
    int cols,
    int rows,
  ) {
    final textStyle = TextStyle(
      color: Colors.black87,
      fontSize: cellSize * 0.4, // Scale font with cell size
      fontWeight: FontWeight.w600,
    );

    // Draw Column Labels (A, B, C...) at Top and Bottom
    for (int i = 0; i < cols; i++) {
      // Skip 'I' (index 8)
      String letter = String.fromCharCode(
        'A'.codeUnitAt(0) + i + (i >= 8 ? 1 : 0),
      );
      final textSpan = TextSpan(text: letter, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();

      double x = offsetX + i * cellSize;

      // Top label
      textPainter.paint(
        canvas,
        Offset(
          x - textPainter.width / 2,
          offsetY - cellSize * 0.8 - textPainter.height / 2,
        ),
      );
      // Bottom label
      textPainter.paint(
        canvas,
        Offset(
          x - textPainter.width / 2,
          offsetY +
              (rows - 1) * cellSize +
              cellSize * 0.8 -
              textPainter.height / 2,
        ),
      );
    }

    // Draw Row Labels (19, 18...) at Left and Right
    for (int i = 0; i < rows; i++) {
      String number = (rows - i).toString();
      final textSpan = TextSpan(text: number, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();

      double y = offsetY + i * cellSize;

      // Left label
      textPainter.paint(
        canvas,
        Offset(
          offsetX - cellSize * 0.8 - textPainter.width / 2,
          y - textPainter.height / 2,
        ),
      );
      // Right label
      textPainter.paint(
        canvas,
        Offset(
          offsetX +
              (cols - 1) * cellSize +
              cellSize * 0.8 -
              textPainter.width / 2,
          y - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    // For now, always repaint when called
    return true;
  }
}
