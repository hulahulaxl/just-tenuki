import 'board.dart';
import 'move.dart';

/// Represents a single moment/state in the game. Extremely lightweight.
class TreeNode {
  /// The move that resulted in this node. Null if this is the root/setup node.
  Move? move;

  /// The parent node to traverse backward.
  final TreeNode? parent;

  /// All possible continuations/variations from this point.
  final List<TreeNode> children = [];

  // --- Domain-Specific Properties ---
  String? comment;
  String? nodeName;

  // Board annotations (stored as 1D grid indices)
  List<int> setupBlackStones = [];
  List<int> setupWhiteStones = [];
  List<int> triangleMarks = [];
  List<int> squareMarks = [];
  List<int> circleMarks = [];
  List<int> crossMarks = [];

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

  /// Stores metadata like Player Names, Ranks, Date, etc.
  Map<String, String> gameInfo = {};

  GameSession() : currentBoard = Board() {
    rootNode = TreeNode();
    currentNode = rootNode;
  }

  /// Attempts to play a move on the physical board.
  /// If successful, adds the move to the tree and advances the timeline.
  bool play(int x, int y) {
    // We clone the board just to test if the move is physically legal right now
    Board testBoard = currentBoard.clone();
    if (testBoard.play(x, y)) {
      // 1. Physically apply the move
      currentBoard = testBoard;

      // 2. Create the new node and link it
      TreeNode newNode = TreeNode(
        move: Play(currentBoard.currentTurn, x, y),
        parent: currentNode,
      );
      currentNode.children.add(newNode);

      // 3. Advance timeline
      currentNode = newNode;
      return true;
    }
    return false; // Illegal move
  }

  /// Re-calculates the physical board state via Pure Event Sourcing.
  void jumpTo(TreeNode node) {
    // 1. Reset physical board to starting state
    currentBoard = Board();

    // 1.5 Apply setup stones from the root node
    _applySetupStones(1, rootNode.setupBlackStones);
    _applySetupStones(2, rootNode.setupWhiteStones);

    // 2. Find the chronological path from root to the target node
    var path = <TreeNode>[];
    TreeNode? curr = node;
    while (curr != null) {
      if (curr.move != null) path.insert(0, curr);
      curr = curr.parent;
    }

    // 3. Replay all moves sequentially
    for (var n in path) {
      if (n.move is Play) {
        final playMove = n.move as Play;
        currentBoard.play(playMove.x, playMove.y);
      } else if (n.move is Pass) {
        currentBoard.pass();
      }
    }

    // 4. Update the timeline pointer
    currentNode = node;
  }

  void _applySetupStones(int player, List<int> indices) {
    for (int index in indices) {
      int x = index % currentBoard.columns;
      int y = index ~/ currentBoard.columns;
      currentBoard.addStone(x, y, player);
    }
  }

  /// Traverses exactly one step backward using Event Sourcing.
  void undo() {
    if (currentNode.parent != null) {
      jumpTo(currentNode.parent!);
    }
  }

  /// Traverses to the next variation. Defaults to the main line (index 0).
  void next({int branchIndex = 0}) {
    if (currentNode.children.isNotEmpty &&
        branchIndex < currentNode.children.length) {
      jumpTo(currentNode.children[branchIndex]);
    }
  }

  /// Jumps to the absolute beginning of the game.
  void first() {
    jumpTo(rootNode);
  }

  /// Fast-forwards to the end of the current variation.
  void last() {
    TreeNode curr = currentNode;
    while (curr.children.isNotEmpty) {
      curr = curr.children[0];
    }
    jumpTo(curr);
  }
}
