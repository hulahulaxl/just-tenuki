import 'package:flutter/material.dart';
import '../../models/tree.dart';
import '../../models/move.dart';

class TreePainter extends CustomPainter {
  final Map<TreeNode, Offset> layout;
  final TreeNode currentNode;
  final int maxRow;

  TreePainter({
    required this.layout,
    required this.currentNode,
    required this.maxRow,
  });

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

    // 0. Get the visible bounds for frustum culling
    // We inflate by 100px to ensure we don't accidentally cull things right on the edge,
    // since nodes are at most ~56px apart (diagonal).
    final Rect visibleBounds = canvas.getLocalClipBounds();
    final Rect cullRect = visibleBounds.inflate(100.0);

    // 1. Draw chronological move numbers down the left side
    final textStyle = TextStyle(
      color: Colors.grey[400],
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );
    
    for (int r = 0; r <= maxRow; r++) {
      // Node centers are at (r * 40.0 + 20) vertically
      final nodeCenterY = r * 40.0 + 20.0;
      
      // CULLING: Skip if this row is completely off-screen
      if (nodeCenterY < cullRect.top || nodeCenterY > cullRect.bottom) {
        continue;
      }

      final textSpan = TextSpan(text: r.toString(), style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
      );
      textPainter.layout(minWidth: 30, maxWidth: 30);

      final yPos = nodeCenterY - (textPainter.height / 2);
      textPainter.paint(canvas, Offset(10, yPos));
    }

    // 2. Draw connecting lines between parents and children
    for (var entry in layout.entries) {
      final node = entry.key;
      final start = entry.value;

      // CULLING: Skip if start node is completely off-screen
      if (!cullRect.contains(start)) continue;

      for (var child in node.children) {
        final end = layout[child];
        if (end != null) {
          canvas.drawLine(start, end, linePaint);
        }
      }
    }

    // 3. Draw the nodes
    for (var entry in layout.entries) {
      final node = entry.key;
      final center = entry.value;

      // CULLING: Skip if node is completely off-screen
      if (!cullRect.contains(center)) continue;

      // Highlight the currently active timeline node
      if (node == currentNode) {
        canvas.drawCircle(center, 12, highlightPaint);
      }

      // Setup/Root nodes are drawn as small gray squares
      if (node.move == null) {
        canvas.drawRect(
          Rect.fromCenter(center: center, width: 10, height: 10),
          Paint()..color = Colors.grey,
        );
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
