import 'board.dart';
import 'move.dart';

/// Represents a single moment/state in the game.
class TreeNode {
  /// The move that resulted in this node. Null if this is the root/setup node.
  final Move? move;

  /// A cached snapshot of the physical board state at this exact node.
  final Board boardState;

  /// The parent node to traverse backward.
  final TreeNode? parent;

  /// All variations/branches diverging from this state.
  final List<TreeNode> children = [];

  /// Flexible storage for annotations, comments, time remaining, etc.
  final Map<String, dynamic> properties = {};

  TreeNode({this.move, required this.boardState, this.parent});

  /// Adds a new variation (child node) based on a move.
  TreeNode addChild(Move newMove, Board resultingBoard) {
    var child = TreeNode(
      move: newMove,
      boardState: resultingBoard,
      parent: this,
    );
    children.add(child);
    return child;
  }
}

/// The master controller that manages the timeline and physical board synchronization.
class GameSession {
  /// The physical state currently displayed on screen.
  Board currentBoard;

  /// The absolute start of the timeline.
  late final TreeNode rootNode;

  /// Where the user currently is in the timeline.
  late TreeNode currentNode;

  GameSession() : currentBoard = Board() {
    rootNode = TreeNode(boardState: currentBoard.clone());
    currentNode = rootNode;
  }

  /// Attempts to play a move on the physical board.
  /// If successful, caches the state into a new TreeNode and advances the timeline.
  bool play(Point point) {
    if (currentBoard.play(point)) {
      // The move was physically valid, so we record it in the tree
      var move = Play(
        currentBoard.currentTurn == 1 ? 2 : 1,
        point,
      ); // the turn just advanced

      // Spawn a new node branching from currentNode
      var newNode = currentNode.addChild(move, currentBoard.clone());

      // Advance timeline
      currentNode = newNode;
      return true;
    }
    return false;
  }

  /// Instantly teleports the physical board and timeline to a specific node.
  void jumpTo(TreeNode node) {
    currentNode = node;
    currentBoard = node.boardState.clone();
  }

  /// Traverses exactly one step backward, if possible.
  void undo() {
    if (currentNode.parent != null) {
      jumpTo(currentNode.parent!);
    }
  }
}
