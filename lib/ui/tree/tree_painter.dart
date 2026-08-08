import 'package:flutter/material.dart';
import '../../models/tree.dart';
import '../../models/move.dart';

class TreePainter extends CustomPainter {
  final Map<TreeNode, Offset> layout;
  final TreeNode currentNode;

  TreePainter({required this.layout, required this.currentNode});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final blackPaint = Paint()..color = Colors.black87;
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final whiteBorderPaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final highlightPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    // 1. Draw connecting lines between parents and children
    for (var entry in layout.entries) {
      final node = entry.key;
      final start = entry.value;

      for (var child in node.children) {
        final end = layout[child];
        if (end != null) {
          canvas.drawLine(start, end, linePaint);
        }
      }
    }

    // 2. Draw the nodes
    for (var entry in layout.entries) {
      final node = entry.key;
      final center = entry.value;

      // Highlight the currently active timeline node
      if (node == currentNode) {
        canvas.drawCircle(center, 12, highlightPaint);
      }

      // Root node is a simple gray dot
      if (node.move == null) {
        canvas.drawCircle(center, 6, Paint()..color = Colors.grey);
        continue;
      }

      // Play moves are colored based on the player ID
      if (node.move is Play) {
        final playerId = node.move!.playerId;
        if (playerId == 1) {
          canvas.drawCircle(center, 8, blackPaint); // Black
        } else {
          canvas.drawCircle(center, 8, whitePaint); // White
          canvas.drawCircle(center, 8, whiteBorderPaint);
        }
      } else if (node.move is Pass) {
        // Pass moves are drawn as small squares
        canvas.drawRect(
          Rect.fromCenter(center: center, width: 12, height: 12),
          Paint()..color = Colors.grey,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant TreePainter oldDelegate) {
    return oldDelegate.layout != layout ||
        oldDelegate.currentNode != currentNode;
  }
}
