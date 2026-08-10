import 'package:flutter/material.dart';
import '../models/board.dart';
import '../api/protocol.dart';

class BoardPainter extends CustomPainter {
  final Board board;
  final int? latestMoveX;
  final int? latestMoveY;
  final EngineResponse? analysis;

  BoardPainter({
    required this.board,
    this.latestMoveX,
    this.latestMoveY,
    this.analysis,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw flat wooden color background
    final bgPaint = Paint()..color = const Color(0xFFDCB35C);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8.0),
      ),
      bgPaint,
    );

    final int cols = board.columns;
    final int rows = board.rows;

    // We allocate space for (cols - 1) grid squares PLUS 1 full square for margins (0.5 left, 0.5 right)
    final double cellWidth = size.width / cols;
    final double cellHeight = size.height / rows;
    final double cellSize = cellWidth < cellHeight ? cellWidth : cellHeight;

    // Center the grid
    final double gridWidth = cellSize * (cols - 1);
    final double gridHeight = cellSize * (rows - 1);
    final double offsetX = (size.width - gridWidth) / 2;
    final double offsetY = (size.height - gridHeight) / 2;

    // Scale line thickness based on cell size (between 0.5 and 2.0 pixels)
    final double lineThickness = (cellSize * 0.04).clamp(0.5, 2.0);
    final linePaint = Paint()
      ..color = Colors.black
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

    // 3. Draw star points (hoshi) if 19x19 board
    if (cols == 19 && rows == 19) {
      final hoshiPaint = Paint()..color = Colors.black;
      final List<int> hoshiPoints = [3, 9, 15]; // 4th, 10th, and 16th lines
      final double hoshiRadius = cellSize * 0.1; // Scale hoshi proportionally

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
    final double stoneRadius =
        cellSize * 0.48; // Leaves a tiny gap between adjacent stones

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        final int player = board.grid[y * cols + x];
        if (player == 0) continue;

        Color stoneColor;
        if (player == 1) {
          stoneColor = Colors.black;
        } else if (player == 2) {
          stoneColor = Colors.white;
        } else {
          stoneColor = Colors.red;
        }

        final Paint stonePaint = Paint()..color = stoneColor;
        final Paint outlinePaint = Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = (cellSize * 0.05).clamp(0.5, 1.5);

        final Offset center = Offset(
          offsetX + x * cellSize,
          offsetY + y * cellSize,
        );

        canvas.drawCircle(center, stoneRadius, stonePaint);
        canvas.drawCircle(center, stoneRadius, outlinePaint);

        // Draw the latest move indicator (a contrasting inner ring)
        if (latestMoveX != null &&
            latestMoveY != null &&
            x == latestMoveX &&
            y == latestMoveY) {
          final indicatorRadius = stoneRadius * 0.45;
          final Paint indicatorPaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = (cellSize * 0.08).clamp(1.0, 3.0)
            ..color = (player == 1) ? Colors.white : Colors.black87;

          canvas.drawCircle(center, indicatorRadius, indicatorPaint);
        }
      }
    }

    // 5. Draw Analysis Overlays (Move Options)
    if (analysis != null) {
      for (int i = 0; i < analysis!.moveOptions.length; i++) {
        if (i > 4) break; // Only show top 5

        final option = analysis!.moveOptions[i];

        // Skip pass moves or invalid indices
        if (option.moveIndex >= cols * rows) continue;

        int x = option.moveIndex % cols;
        int y = option.moveIndex ~/ cols;

        Color boxColor;
        if (i == 0) {
          boxColor = Colors.blue.withValues(alpha: 0.6); // Top 1: Blue
        } else if (i == 1) {
          boxColor = Colors.green.withValues(alpha: 0.6); // High: Green
        } else if (i == 2) {
          boxColor = Colors.yellow.withValues(alpha: 0.6); // Medium: Yellow
        } else {
          boxColor = Colors.red.withValues(alpha: 0.6); // Low: Red
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
      }
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    // For now, always repaint when called
    return true;
  }
}
