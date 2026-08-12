import 'board.dart';
import 'move.dart';

enum MarkupType { triangle, square, circle, cross, letter, number }

/// Represents a single moment/state in the game. Extremely lightweight.
class TreeNode {
  /// The move that resulted in this node. Null if this is the root/setup node.
  Move? move;

  /// The parent node to traverse backward.
  final TreeNode? parent;

  /// All possible continuations/variations from this point.
  final List<TreeNode> children = [];

  // --- Domain-Specific Properties ---
  String comment = ''; // C property (node comment)
  String? nodeName;

  // Board annotations (stored as 1D grid indices)
  List<int> setupBlackStones = [];
  List<int> setupWhiteStones = [];
  List<int> setupEmptyStones = [];
  List<int> triangleMarks = [];
  List<int> squareMarks = [];
  List<int> circleMarks = [];
  List<int> crossMarks = [];
  Map<int, String> labels = {}; // LB property (letters, numbers, custom text)

  // Time management per node (Index 0 = Black, Index 1 = White)
  List<String?> timeLeft = List.filled(2, null);

  /// Explicitly dictates whose turn it is next (used for handicap and Tsumego)
  int? playerToPlay;

  TreeNode({this.move, this.parent});

  /// Adds a new variation (child node) based on a move.
  TreeNode addChild(Move newMove) {
    var child = TreeNode(move: newMove, parent: this);
    children.add(child);
    return child;
  }
}

class GameInfo {
  String blackName = 'Black';
  String whiteName = 'White';
  String? blackRank;
  String? whiteRank;
  String? date;
  String? result;
  String? event;
  String komi = '6.5';
  String rules = 'Japanese';
  String? baseTime;
  String? overtime;
}

/// The master controller that manages the timeline and physical board synchronization using Event Sourcing.
class GameSession {
  /// The physical state currently displayed on screen.
  Board currentBoard;

  /// The absolute start of the timeline.
  late final TreeNode rootNode;

  /// Where the user currently is in the timeline.
  late TreeNode currentNode;

  /// Strongly-typed metadata for the game
  GameInfo info = GameInfo();

  GameSession() : currentBoard = Board() {
    rootNode = TreeNode();
    currentNode = rootNode;
  }

  /// Attempts to play a move on the physical board.
  /// If successful, adds the move to the tree and advances the timeline.
  bool play(int x, int y) {
    // We clone the board just to test if the move is physically legal right now
    Board testBoard = currentBoard.clone();

    // Save the turn BEFORE playing, because play() will advance it!
    int playedTurn = currentBoard.currentTurn;

    if (testBoard.play(x, y)) {
      // 1. Physically apply the move
      currentBoard = testBoard;

      // 2. Create the new node and link it
      TreeNode newNode = TreeNode(
        move: Play(playedTurn, x, y),
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

    // 1.5 Determine initial turn based on PL tag or handicap stones
    if (rootNode.playerToPlay != null) {
      currentBoard.currentTurn = rootNode.playerToPlay!;
    } else if (rootNode.setupBlackStones.isNotEmpty &&
        rootNode.setupWhiteStones.isEmpty) {
      // Standard Go rule: If Black has handicap stones, White plays first.
      currentBoard.currentTurn = 2;
    }

    // 2. Find the chronological path from root to the target node
    var path = <TreeNode>[];
    TreeNode? curr = node;
    while (curr != null) {
      path.insert(0, curr);
      curr = curr.parent;
    }

    // 3. Replay all moves sequentially
    for (var n in path) {
      // Setup stones apply before the move in a node
      _applySetupStones(1, n.setupBlackStones);
      _applySetupStones(2, n.setupWhiteStones);
      _applySetupStones(0, n.setupEmptyStones); // 0 = empty

      if (n.move is Play) {
        final playMove = n.move as Play;
        // Sync the board's turn directly to the SGF move.
        // This handles SGF files that skip turns or have implicit passes.
        currentBoard.currentTurn = playMove.playerId;
        currentBoard.play(playMove.x, playMove.y);
      } else if (n.move is Pass) {
        final passMove = n.move as Pass;
        currentBoard.currentTurn = passMove.playerId;
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

  /// Adds a setup stone to the current node. If the current node already
  /// has a regular move, a new child node is created.
  /// [player] 1=Black, 2=White, 0=Empty
  bool addSetupStone(int x, int y, int player) {
    if (!currentBoard.isOnBoard(x, y)) return false;

    // Standard editor behavior: if the current node has a regular move,
    // OR if it's a setup node that already has children (to avoid altering history),
    // placing setup stones branches into a new "setup node".
    if (currentNode.move != null || currentNode.children.isNotEmpty) {
      TreeNode newNode = TreeNode(parent: currentNode);
      currentNode.children.add(newNode);
      currentNode = newNode;
    }

    int index = currentBoard.getIndex(x, y);

    // Remove from all setup lists to avoid conflicts
    currentNode.setupBlackStones.remove(index);
    currentNode.setupWhiteStones.remove(index);
    currentNode.setupEmptyStones.remove(index);

    // Add to the appropriate list
    if (player == 1) {
      currentNode.setupBlackStones.add(index);
    } else if (player == 2) {
      currentNode.setupWhiteStones.add(index);
    } else if (player == 0) {
      currentNode.setupEmptyStones.add(index);
    }

    // Physically apply the change so the UI updates instantly
    currentBoard.addStone(x, y, player);
    return true;
  }

  /// Toggles a markup (Triangle, Square, Circle, Cross, Letter, Number) on the current node.
  /// Markup properties modify the current node directly without branching!
  bool toggleMarkup(int x, int y, MarkupType type) {
    if (!currentBoard.isOnBoard(x, y)) return false;
    int index = currentBoard.getIndex(x, y);

    // 1. Check if the exact mark already exists
    bool exists = false;
    if (type == MarkupType.triangle &&
        currentNode.triangleMarks.contains(index)) {
      exists = true;
    }
    if (type == MarkupType.square && currentNode.squareMarks.contains(index)) {
      exists = true;
    }
    if (type == MarkupType.circle && currentNode.circleMarks.contains(index)) {
      exists = true;
    }
    if (type == MarkupType.cross && currentNode.crossMarks.contains(index)) {
      exists = true;
    }
    if ((type == MarkupType.letter || type == MarkupType.number) &&
        currentNode.labels.containsKey(index)) {
      exists = true;
    }

    // 2. Remove from all markup lists (clears intersection)
    currentNode.triangleMarks.remove(index);
    currentNode.squareMarks.remove(index);
    currentNode.circleMarks.remove(index);
    currentNode.crossMarks.remove(index);
    currentNode.labels.remove(index);

    // 3. If it didn't already exist, add it
    if (!exists) {
      if (type == MarkupType.triangle) {
        currentNode.triangleMarks.add(index);
      }
      if (type == MarkupType.square) {
        currentNode.squareMarks.add(index);
      }
      if (type == MarkupType.circle) {
        currentNode.circleMarks.add(index);
      }
      if (type == MarkupType.cross) {
        currentNode.crossMarks.add(index);
      }
      if (type == MarkupType.letter) {
        currentNode.labels[index] = _getNextAvailableLetter();
      }
      if (type == MarkupType.number) {
        currentNode.labels[index] = _getNextAvailableNumber();
      }
    }

    return true; // Indicates the tree changed and UI should redraw
  }

  String _getNextAvailableLetter() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    final used = currentNode.labels.values.toSet();
    for (int i = 0; i < chars.length; i++) {
      if (!used.contains(chars[i])) return chars[i];
    }
    return 'A'; // Fallback if all 52 are used
  }

  String _getNextAvailableNumber() {
    final used = currentNode.labels.values.toSet();
    int i = 1;
    while (true) {
      if (!used.contains(i.toString())) return i.toString();
      i++;
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
