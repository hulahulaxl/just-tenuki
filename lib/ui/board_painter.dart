import 'package:flutter/material.dart';
import '../models/board.dart';
import '../models/move.dart';

class BoardPainter extends CustomPainter {
  final Board board;

  BoardPainter({required this.board});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw flat wooden color background (as requested, no images yet)
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
    // This ensures stones placed on the very edge lines are never clipped.
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

    for (var entry in board.grid.entries) {
      final Point pt = entry.key;
      final int player = entry.value;

      Color stoneColor;
      if (player == 1) {
        stoneColor = Colors.black;
      } else if (player == 2) {
        stoneColor = Colors.white;
      } else {
        // Fallback for N-player variations
        stoneColor = Colors.red;
      }

      final Paint stonePaint = Paint()..color = stoneColor;
      final Paint outlinePaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = (cellSize * 0.05).clamp(0.5, 1.5);

      final Offset center = Offset(
        offsetX + pt.x * cellSize,
        offsetY + pt.y * cellSize,
      );

      canvas.drawCircle(center, stoneRadius, stonePaint);
      canvas.drawCircle(center, stoneRadius, outlinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    // For now, always repaint when called
    return true;
  }
}
