import 'dart:ui';
import '../../models/tree.dart';

/// Traverses the GameTree and assigns an (x, y) logical coordinate to every node.
class TreeLayout {
  final Map<TreeNode, Offset> positions = {};
  int _maxColumn = 0;
  int _maxRow = 0;

  int get maxColumn => _maxColumn;
  int get maxRow => _maxRow;

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
    // 60px initial padding to leave room for the move numbers on the left!
    positions[node] = Offset(col * nodeSpacingX + 60, row * nodeSpacingY + 20);

    if (col > _maxColumn) _maxColumn = col;
    if (row > _maxRow) _maxRow = row;

    if (node.children.isEmpty) return;

    // The first child (Main line)
    if (node.children[0].move == null) {
      // Setup node on the main line shifts to the right (same row)
      _maxColumn++;
      _traverse(node.children[0], _maxColumn, row);
    } else {
      // Normal move goes straight down
      _traverse(node.children[0], col, row + 1);
    }

    // Any subsequent children (Variations) branch horizontally to the right.
    for (int i = 1; i < node.children.length; i++) {
      _maxColumn++;
      if (node.children[i].move == null) {
        _traverse(node.children[i], _maxColumn, row);
      } else {
        _traverse(node.children[i], _maxColumn, row + 1);
      }
    }
  }

  /// The total pixel size required to draw the entire tree
  Size get totalSize {
    return Size(
      (_maxColumn + 1) * nodeSpacingX + 80, // +80 to account for move numbers
      (_maxRow + 1) * nodeSpacingY + 40,
    );
  }
}
