import 'board.dart';
import 'move.dart';
import 'package:flutter/foundation.dart';

enum MarkupType { triangle, square, circle, cross, letter, number }

/// Represents a single moment/state in the game. Extremely lightweight.
class TreeNode {
  final int id;
  final int? parentId;
  final List<int> childIds = [];

  /// The move that resulted in this node. Null if this is the root/setup node.
  Move? move;

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
  List<String?> overtimeLeft = List.filled(2, null);

  /// Explicitly dictates whose turn it is next (used for handicap and Tsumego)
  int? playerToPlay;

  TreeNode({required this.id, this.parentId, this.move});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentId': parentId,
      'childIds': childIds,
      'move': move != null
          ? {
              'type': move is Play ? 'Play' : 'Pass',
              'player': move!.playerId,
              'x': move is Play ? (move as Play).x : null,
              'y': move is Play ? (move as Play).y : null,
            }
          : null,
      'comment': comment,
      'nodeName': nodeName,
      'setupBlackStones': setupBlackStones,
      'setupWhiteStones': setupWhiteStones,
      'setupEmptyStones': setupEmptyStones,
      'triangleMarks': triangleMarks,
      'squareMarks': squareMarks,
      'circleMarks': circleMarks,
      'crossMarks': crossMarks,
      'labels': labels.map((k, v) => MapEntry(k.toString(), v)),
      'timeLeft': timeLeft,
      'overtimeLeft': overtimeLeft,
      'playerToPlay': playerToPlay,
    };
  }

  factory TreeNode.fromJson(Map<dynamic, dynamic> json) {
    TreeNode node = TreeNode(
      id: json['id'] as int,
      parentId: json['parentId'] as int?,
      move: json['move'] != null
          ? (json['move']['type'] == 'Play'
                ? Play(
                    json['move']['player'],
                    json['move']['x'],
                    json['move']['y'],
                  )
                : Pass(json['move']['player']))
          : null,
    );

    if (json['childIds'] != null) {
      node.childIds.addAll((json['childIds'] as List).cast<int>());
    }

    node.comment = json['comment'] ?? '';
    node.nodeName = json['nodeName'];
    node.setupBlackStones =
        (json['setupBlackStones'] as List?)?.cast<int>() ?? [];
    node.setupWhiteStones =
        (json['setupWhiteStones'] as List?)?.cast<int>() ?? [];
    node.setupEmptyStones =
        (json['setupEmptyStones'] as List?)?.cast<int>() ?? [];
    node.triangleMarks = (json['triangleMarks'] as List?)?.cast<int>() ?? [];
    node.squareMarks = (json['squareMarks'] as List?)?.cast<int>() ?? [];
    node.circleMarks = (json['circleMarks'] as List?)?.cast<int>() ?? [];
    node.crossMarks = (json['crossMarks'] as List?)?.cast<int>() ?? [];

    if (json['labels'] != null) {
      (json['labels'] as Map).forEach((k, v) {
        node.labels[int.parse(k.toString())] = v.toString();
      });
    }

    if (json['timeLeft'] != null) {
      node.timeLeft = (json['timeLeft'] as List)
          .map((e) => e as String?)
          .toList();
    }
    if (json['overtimeLeft'] != null) {
      node.overtimeLeft = (json['overtimeLeft'] as List)
          .map((e) => e as String?)
          .toList();
    }

    node.playerToPlay = json['playerToPlay'] as int?;

    return node;
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

  /// The centralized normalized map of all nodes.
  Map<int, TreeNode> nodes = {};

  int nextNodeId = 0;

  /// The absolute start of the timeline.
  late int rootNodeId;

  /// Where the user currently is in the timeline.
  late int currentNodeId;

  /// Strongly-typed metadata for the game
  GameInfo info = GameInfo();

  /// Callback fired when the session state changes
  VoidCallback? onStateChanged;

  GameSession() : currentBoard = Board() {
    TreeNode rootNode = TreeNode(id: nextNodeId++);
    nodes[rootNode.id] = rootNode;
    rootNodeId = rootNode.id;
    currentNodeId = rootNode.id;
  }

  TreeNode get rootNode => nodes[rootNodeId]!;
  TreeNode get currentNode => nodes[currentNodeId]!;
  set currentNode(TreeNode node) => currentNodeId = node.id;

  TreeNode? getParent(TreeNode node) =>
      node.parentId != null ? nodes[node.parentId!] : null;
  List<TreeNode> getChildren(TreeNode node) =>
      node.childIds.map((id) => nodes[id]!).toList();

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
        id: nextNodeId++,
        parentId: currentNodeId,
        move: Play(playedTurn, x, y),
      );
      nodes[newNode.id] = newNode;
      currentNode.childIds.add(newNode.id);

      // 3. Advance timeline
      currentNodeId = newNode.id;
      onStateChanged?.call();
      return true;
    }
    return false; // Illegal move
  }

  /// Deletes the current node (and all its descendants) and jumps to its parent.
  /// The root node cannot be deleted.
  void deleteCurrentNode() {
    if (currentNodeId == rootNodeId) return; // Cannot delete root node

    TreeNode? parent = getParent(currentNode);
    if (parent == null) return;

    // Remove from parent's children
    parent.childIds.remove(currentNodeId);

    // Recursively remove from nodes map
    void deleteSubtree(int id) {
      final node = nodes[id];
      if (node == null) return;
      for (int childId in node.childIds.toList()) {
        deleteSubtree(childId);
      }
      nodes.remove(id);
    }

    deleteSubtree(currentNodeId);
    jumpTo(
      parent,
    ); // This updates currentNode, board state, and fires onStateChanged
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
      curr = getParent(curr);
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
    onStateChanged?.call();
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
    if (currentNode.move != null || currentNode.childIds.isNotEmpty) {
      TreeNode newNode = TreeNode(id: nextNodeId++, parentId: currentNodeId);
      nodes[newNode.id] = newNode;
      currentNode.childIds.add(newNode.id);
      currentNodeId = newNode.id;
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
    if (currentNode.parentId != null) {
      jumpTo(getParent(currentNode)!);
      onStateChanged?.call();
    }
  }

  /// Traverses to the next variation. Defaults to the main line (index 0).
  void next({int branchIndex = 0}) {
    if (currentNode.childIds.isNotEmpty &&
        branchIndex < currentNode.childIds.length) {
      jumpTo(nodes[currentNode.childIds[branchIndex]]!);
      onStateChanged?.call();
    }
  }

  /// Jumps to the latest setup node in the current variation.
  void first() {
    TreeNode curr = currentNode;
    if (curr.parentId != null) {
      curr = getParent(curr)!;
    }
    while (curr.parentId != null && curr.move != null) {
      curr = getParent(curr)!;
    }
    jumpTo(curr);
  }

  /// Fast-forwards to the end of the current variation.
  void last() {
    TreeNode curr = currentNode;
    while (curr.childIds.isNotEmpty) {
      curr = nodes[curr.childIds[0]]!;
    }
    jumpTo(curr);
  }

  /// Traverses backward to find the most recent time left for a given player.
  /// [player] 0 for Black, 1 for White.
  String? getTimeLeft(int player) {
    TreeNode? curr = currentNode;
    while (curr != null) {
      if (curr.timeLeft[player] != null) {
        return curr.timeLeft[player];
      }
      curr = getParent(curr);
    }
    return null;
  }

  /// Traverses backward to find the most recent overtime left for a given player.
  String? getOvertimeLeft(int player) {
    TreeNode? curr = currentNode;
    while (curr != null) {
      if (curr.overtimeLeft[player] != null) {
        return curr.overtimeLeft[player];
      }
      curr = getParent(curr);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'rootNodeId': rootNodeId,
      'currentNodeId': currentNodeId,
      'nextNodeId': nextNodeId,
      'info': {
        'blackName': info.blackName,
        'whiteName': info.whiteName,
        'blackRank': info.blackRank,
        'whiteRank': info.whiteRank,
        'date': info.date,
        'result': info.result,
        'event': info.event,
        'komi': info.komi,
        'rules': info.rules,
        'baseTime': info.baseTime,
        'overtime': info.overtime,
      },
      'nodes': nodes.map((k, v) => MapEntry(k.toString(), v.toJson())),
    };
  }

  factory GameSession.fromJson(Map<dynamic, dynamic> json) {
    GameSession session = GameSession();
    session.rootNodeId = json['rootNodeId'] as int;
    session.currentNodeId = json['currentNodeId'] as int;
    session.nextNodeId = json['nextNodeId'] as int;

    if (json['info'] != null) {
      session.info.blackName = json['info']['blackName'] ?? 'Black';
      session.info.whiteName = json['info']['whiteName'] ?? 'White';
      session.info.blackRank = json['info']['blackRank'];
      session.info.whiteRank = json['info']['whiteRank'];
      session.info.date = json['info']['date'];
      session.info.result = json['info']['result'];
      session.info.event = json['info']['event'];
      session.info.komi = json['info']['komi'] ?? '6.5';
      session.info.rules = json['info']['rules'] ?? 'Japanese';
      session.info.baseTime = json['info']['baseTime'];
      session.info.overtime = json['info']['overtime'];
    }

    if (json['nodes'] != null) {
      session.nodes.clear();
      (json['nodes'] as Map).forEach((k, v) {
        int id = int.parse(k.toString());
        session.nodes[id] = TreeNode.fromJson(v as Map<dynamic, dynamic>);
      });
    }

    if (session.nodes.containsKey(session.currentNodeId)) {
      session.jumpTo(session.nodes[session.currentNodeId]!);
    }

    return session;
  }
}
