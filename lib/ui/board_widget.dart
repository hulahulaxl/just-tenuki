import 'package:flutter/material.dart';
import '../models/board.dart';
import 'board_painter.dart';

class BoardWidget extends StatelessWidget {
  final Board board;

  const BoardWidget({super.key, required this.board});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: CustomPaint(painter: BoardPainter(board: board)),
    );
  }
}
