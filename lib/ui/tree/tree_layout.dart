import 'dart:ui';
import '../../models/tree.dart';

/// Traverses the GameTree and assigns an (x, y) logical coordinate to every node.
class TreeLayout {
  final Map<TreeNode, Offset> positions = {};
  int _maxColumn = 0;
  int _maxRow = 0;

  // Visual config
  static const double nodeSpacingX = 40.0;
  static const double nodeSpacingY = 40.0;

  /// Recalculates the entire layout starting from the given root node.
  void computeLayout(TreeNode root) {
    positions.clear();
    _maxColumn = 0;
    _maxRow = 0;
    _traverse(root, 0, 0);
  }

  void _traverse(TreeNode node, int col, int row) {
    // 20px initial padding
    positions[node] = Offset(col * nodeSpacingX + 20, row * nodeSpacingY + 20);

    if (col > _maxColumn) _maxColumn = col;
    if (row > _maxRow) _maxRow = row;

    if (node.children.isEmpty) return;

    // The first child (Main line) continues straight down the same column
    _traverse(node.children[0], col, row + 1);

    // Any subsequent children (Variations) branch horizontally to the right.
    // We increment a global column counter to guarantee branches never overlap!
    for (int i = 1; i < node.children.length; i++) {
      _maxColumn++;
      _traverse(node.children[i], _maxColumn, row + 1);
    }
  }

  /// The total pixel size required to draw the entire tree
  Size get totalSize {
    return Size(
      (_maxColumn + 1) * nodeSpacingX + 40,
      (_maxRow + 1) * nodeSpacingY + 40,
    );
  }
}
