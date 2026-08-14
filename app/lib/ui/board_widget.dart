import 'package:flutter/material.dart';
import '../models/board.dart';
import '../models/tree.dart';
import '../api/protocol.dart';
import '../models/board_settings.dart';
import 'board_painter.dart';

class BoardWidget extends StatelessWidget {
  final Board board;
  final TreeNode currentNode;
  final void Function(int x, int y) onIntersectionTapped;
  final EngineResponse? analysis;
  final ValueNotifier<BoardSettings> settingsNotifier;

  const BoardWidget({
    super.key,
    required this.board,
    required this.currentNode,
    required this.onIntersectionTapped,
    required this.settingsNotifier,
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
            child: ValueListenableBuilder<BoardSettings>(
              valueListenable: settingsNotifier,
              builder: (context, settings, child) {
                return RepaintBoundary(
                  child: CustomPaint(
                    painter: BoardPainter(
                      board: board,
                      currentNode: currentNode,
                      settings: settings,
                      analysis: analysis,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _handleTap(Offset localPosition, Size size) {
    final settings = settingsNotifier.value;
    final int cols = board.columns;
    final int rows = board.rows;

    final double marginBlocks = settings.showCoordinates ? 2.2 : 1.0;
    final double cellWidth = size.width / (cols - 1 + marginBlocks);
    final double cellHeight = size.height / (rows - 1 + marginBlocks);
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
