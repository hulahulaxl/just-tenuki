import 'package:flutter/material.dart';
import '../models/board.dart';
import '../models/tree.dart';
import '../api/protocol.dart';
import 'board_painter.dart';

class BoardWidget extends StatelessWidget {
  final Board board;
  final TreeNode currentNode;
  final void Function(int x, int y) onIntersectionTapped;
  final EngineResponse? analysis;

  const BoardWidget({
    super.key,
    required this.board,
    required this.currentNode,
    required this.onIntersectionTapped,
    this.analysis,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);

          return GestureDetector(
            onTapUp: (details) => _handleTap(details.localPosition, size),
            child: CustomPaint(
              painter: BoardPainter(
                board: board,
                currentNode: currentNode,
                analysis: analysis,
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleTap(Offset localPosition, Size size) {
    final int cols = board.columns;
    final int rows = board.rows;

    final double cellWidth = size.width / cols;
    final double cellHeight = size.height / rows;
    final double cellSize = cellWidth < cellHeight ? cellWidth : cellHeight;

    final double gridWidth = cellSize * (cols - 1);
    final double gridHeight = cellSize * (rows - 1);

    final double offsetX = (size.width - gridWidth) / 2;
    final double offsetY = (size.height - gridHeight) / 2;

    // Convert tap pixel coordinates back into grid coordinates
    int x = ((localPosition.dx - offsetX) / cellSize).round();
    int y = ((localPosition.dy - offsetY) / cellSize).round();

    // Ensure the tap is actually on the board before firing the callback
    if (x >= 0 && x < cols && y >= 0 && y < rows) {
      onIntersectionTapped(x, y);
    }
  }
}
