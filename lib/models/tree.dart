import 'board.dart';
import 'move.dart';

/// Represents a single moment/state in the game. Extremely lightweight.
class TreeNode {
  /// The move that resulted in this node. Null if this is the root/setup node.
  final Move? move;

  /// The parent node to traverse backward.
  final TreeNode? parent;

  /// All variations/branches diverging from this state.
  final List<TreeNode> children = [];

  /// Flexible storage for annotations, comments, time remaining, etc.
  final Map<String, dynamic> properties = {};

  TreeNode({this.move, this.parent});

  /// Adds a new variation (child node) based on a move.
  TreeNode addChild(Move newMove) {
    var child = TreeNode(move: newMove, parent: this);
    children.add(child);
    return child;
  }
}

/// The master controller that manages the timeline and physical board synchronization using Event Sourcing.
class GameSession {
  /// The physical state currently displayed on screen.
  Board currentBoard;

  /// The absolute start of the timeline.
  late final TreeNode rootNode;

  /// Where the user currently is in the timeline.
  late TreeNode currentNode;

  GameSession() : currentBoard = Board() {
    rootNode = TreeNode();
    currentNode = rootNode;
  }

  /// Attempts to play a move on the physical board.
  /// If successful, adds the move to the tree and advances the timeline.
  bool play(Point point) {
    // Determine whose turn it is before playing (play() advances the turn)
    int player = currentBoard.currentTurn;

    if (currentBoard.play(point)) {
      var move = Play(player, point);

      // Spawn a new node branching from currentNode
      var newNode = currentNode.addChild(move);

      // Advance timeline
      currentNode = newNode;
      return true;
    }
    return false;
  }

  /// Re-calculates the physical board state via Pure Event Sourcing.
  void jumpTo(TreeNode node) {
    // 1. Reset physical board to starting state (TODO: Handle custom handicap/sizes later)
    currentBoard = Board();

    // 2. Find the chronological path from root to the target node
    var path = <TreeNode>[];
    TreeNode? curr = node;
    while (curr != null) {
      path.insert(0, curr);
      curr = curr.parent;
    }

    // 3. Replay all moves sequentially
    for (var n in path) {
      if (n.move is Play) {
        // We inject the move into the physical grid
        currentBoard.play((n.move as Play).point);
      } else if (n.move is Pass) {
        currentBoard.pass();
      }
    }

    // 4. Update the timeline pointer
    currentNode = node;
  }

  /// Traverses exactly one step backward using Event Sourcing.
  void undo() {
    if (currentNode.parent != null) {
      jumpTo(currentNode.parent!);
    }
  }
}
