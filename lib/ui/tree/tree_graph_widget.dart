import 'package:flutter/material.dart';
import '../../models/tree.dart';
import 'tree_layout.dart';
import 'tree_painter.dart';

class TreeGraphWidget extends StatefulWidget {
  final GameSession session;
  final VoidCallback onNodeSelected;

  const TreeGraphWidget({
    super.key,
    required this.session,
    required this.onNodeSelected,
  });

  @override
  State<TreeGraphWidget> createState() => _TreeGraphWidgetState();
}

class _TreeGraphWidgetState extends State<TreeGraphWidget> {
  final TreeLayout _layoutEngine = TreeLayout();

  @override
  Widget build(BuildContext context) {
    // Recompute layout just in case nodes were added
    _layoutEngine.computeLayout(widget.session.rootNode);

    return InteractiveViewer(
      constrained: false, // Allow unbounded canvas size
      boundaryMargin: const EdgeInsets.all(40),
      minScale: 0.5,
      maxScale: 2.0,
      child: GestureDetector(
        onTapUp: (details) {
          // Hit test: Find the node closest to the tap coordinate
          final touch = details.localPosition;
          TreeNode? closestNode;
          double closestDistSq = double.infinity;

          for (var entry in _layoutEngine.positions.entries) {
            final node = entry.key;
            final offset = entry.value;

            // Distance squared
            final distSq =
                (offset.dx - touch.dx) * (offset.dx - touch.dx) +
                (offset.dy - touch.dy) * (offset.dy - touch.dy);

            if (distSq < 400 && distSq < closestDistSq) {
              // 20px hit radius
              closestNode = node;
              closestDistSq = distSq;
            }
          }

          if (closestNode != null) {
            widget.session.jumpTo(closestNode); // Teleport via Event Sourcing!
            widget.onNodeSelected(); // Notify UI to redraw the board
          }
        },
        child: CustomPaint(
          size: _layoutEngine.totalSize,
          painter: TreePainter(
            layout: _layoutEngine.positions,
            currentNode: widget.session.currentNode,
            maxRow: _layoutEngine.maxRow,
          ),
        ),
      ),
    );
  }
}
