// ignore_for_file: deprecated_member_use
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

class _TreeGraphWidgetState extends State<TreeGraphWidget>
    with SingleTickerProviderStateMixin {
  final TreeLayout _layoutEngine = TreeLayout();
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  Size _viewportSize = Size.zero;

  TreeNode? _lastNode;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _lastNode = widget.session.currentNode;
    _layoutEngine.computeLayout(widget.session);

    // Jump to initial node immediately (no animation)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_viewportSize != Size.zero) {
        _scrollIntoView(
          widget.session.currentNode,
          _viewportSize,
          animate: false,
        );
      }
    });
  }

  @override
  void didUpdateWidget(TreeGraphWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Always recompute in case nodes were added/removed
    _layoutEngine.computeLayout(widget.session);

    if (_lastNode != widget.session.currentNode && _viewportSize != Size.zero) {
      _lastNode = widget.session.currentNode;
      _scrollIntoView(widget.session.currentNode, _viewportSize, animate: true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _scrollIntoView(
    TreeNode node,
    Size viewportSize, {
    bool animate = true,
  }) {
    final offset = _layoutEngine.positions[node];
    if (offset == null) return;

    final double scale = _transformationController.value.getMaxScaleOnAxis();
    final double tx = _transformationController.value.getTranslation().x;
    final double ty = _transformationController.value.getTranslation().y;

    // Node bounding box in child space (with some padding)
    final double nodeLeft = offset.dx - 30;
    final double nodeRight = offset.dx + 30;
    final double nodeTop = offset.dy - 30;
    final double nodeBottom = offset.dy + 30;

    // Position in screen/viewport space
    final double screenLeft = nodeLeft * scale + tx;
    final double screenRight = nodeRight * scale + tx;
    final double screenTop = nodeTop * scale + ty;
    final double screenBottom = nodeBottom * scale + ty;

    double dx = 0;
    double dy = 0;

    if (screenLeft < 0) {
      dx = -screenLeft;
    } else if (screenRight > viewportSize.width) {
      dx = viewportSize.width - screenRight;
    }

    if (screenTop < 0) {
      dy = -screenTop;
    } else if (screenBottom > viewportSize.height) {
      dy = viewportSize.height - screenBottom;
    }

    // If it's already fully visible, do nothing
    if (dx == 0 && dy == 0) return;

    final targetMatrix = _transformationController.value.clone()
      ..setTranslationRaw(tx + dx, ty + dy, 0.0);

    if (!animate) {
      _transformationController.value = targetMatrix;
      return;
    }

    _animation?.removeListener(_onAnimate);
    _animationController.reset();

    _animation =
        Matrix4Tween(
          begin: _transformationController.value,
          end: targetMatrix,
        ).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animation!.addListener(_onAnimate);
    _animationController.forward();
  }

  void _onAnimate() {
    _transformationController.value = _animation!.value;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);

        return InteractiveViewer(
          transformationController: _transformationController,
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

                final distSq =
                    (offset.dx - touch.dx) * (offset.dx - touch.dx) +
                    (offset.dy - touch.dy) * (offset.dy - touch.dy);

                if (distSq < 400 && distSq < closestDistSq) {
                  closestNode = node;
                  closestDistSq = distSq;
                }
              }

              if (closestNode != null) {
                widget.session.jumpTo(closestNode);
                widget.onNodeSelected();
              }
            },
            child: CustomPaint(
              size: _layoutEngine.totalSize,
              painter: TreePainter(
                layout: _layoutEngine.positions,
                session: widget.session,
                currentNode: widget.session.currentNode,
                maxRow: _layoutEngine.maxRow,
              ),
            ),
          ),
        );
      },
    );
  }
}
