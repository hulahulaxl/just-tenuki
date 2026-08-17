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
  static const double nodeSpacingX = 24.0;
  static const double nodeSpacingY = 24.0;

  /// Recalculates the entire layout starting from the given root node.
  void computeLayout(GameSession session) {
    positions.clear();
    _maxColumn = 0;
    _maxRow = 0;
    _traverse(session, session.rootNode, 0, 0);
  }

  void _traverse(GameSession session, TreeNode node, int col, int row) {
    // 60px initial padding to leave room for the move numbers on the left!
    positions[node] = Offset(col * nodeSpacingX + 60, row * nodeSpacingY + 20);

    if (col > _maxColumn) _maxColumn = col;
    if (row > _maxRow) _maxRow = row;

    if (node.childIds.isEmpty) return;

    List<TreeNode> children = session.getChildren(node);

    // The first child (Main line)
    if (children[0].move == null) {
      // Setup node on the main line shifts to the right (same row)
      _maxColumn++;
      _traverse(session, children[0], _maxColumn, row);
    } else {
      // Normal move goes straight down
      _traverse(session, children[0], col, row + 1);
    }

    // Any subsequent children (Variations) branch horizontally to the right.
    for (int i = 1; i < children.length; i++) {
      _maxColumn++;
      if (children[i].move == null) {
        _traverse(session, children[i], _maxColumn, row);
      } else {
        _traverse(session, children[i], _maxColumn, row + 1);
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
