class Board {
  final int columns;
  final int rows;
  final int playerCount;

  /// A flat 1D array representing the board. 0 means empty.
  /// Index is calculated as: y * columns + x
  final List<int> grid;

  int currentTurn;
  List<int> captures;

  Board({this.columns = 19, this.rows = 19, this.playerCount = 2})
    : grid = List.filled(columns * rows, 0),
      currentTurn = 1,
      captures = List.filled(playerCount, 0);

  Board._clone(
    this.columns,
    this.rows,
    this.playerCount,
    this.currentTurn,
    List<int> existingGrid,
    List<int> existingCaptures,
  ) : grid = List.from(existingGrid),
      captures = List.from(existingCaptures);

  Board clone() =>
      Board._clone(columns, rows, playerCount, currentTurn, grid, captures);

  int getIndex(int x, int y) => y * columns + x;

  void advance() {
    currentTurn = (currentTurn % playerCount) + 1;
  }

  bool isOnBoard(int x, int y) {
    return x >= 0 && x < columns && y >= 0 && y < rows;
  }

  /// Returns 1D indices of all valid adjacent intersections
  List<int> getNeighbors(int index) {
    int x = index % columns;
    int y = index ~/ columns;

    var neighbors = <int>[];
    if (isOnBoard(x - 1, y)) {
      neighbors.add(getIndex(x - 1, y));
    }
    if (isOnBoard(x + 1, y)) {
      neighbors.add(getIndex(x + 1, y));
    }
    if (isOnBoard(x, y - 1)) {
      neighbors.add(getIndex(x, y - 1));
    }
    if (isOnBoard(x, y + 1)) {
      neighbors.add(getIndex(x, y + 1));
    }
    return neighbors;
  }

  /// Returns a set of 1D indices representing the connected string of stones
  Set<int> getGroup(int index) {
    var targetPlayer = grid[index];
    if (targetPlayer == 0) {
      return {};
    }

    var visited = <int>{};
    var queue = [index];

    while (queue.isNotEmpty) {
      var current = queue.removeAt(0);
      if (visited.contains(current)) {
        continue;
      }

      visited.add(current);

      for (var neighbor in getNeighbors(current)) {
        if (grid[neighbor] == targetPlayer && !visited.contains(neighbor)) {
          queue.add(neighbor);
        }
      }
    }
    return visited;
  }

  /// Counts the liberties of a given string of stones
  int countLiberties(Set<int> group) {
    var liberties = <int>{};
    for (var stoneIdx in group) {
      for (var neighbor in getNeighbors(stoneIdx)) {
        if (grid[neighbor] == 0) {
          liberties.add(neighbor);
        }
      }
    }
    return liberties.length;
  }

  bool isValidMove(int x, int y) {
    if (!isOnBoard(x, y)) {
      return false;
    }

    int index = getIndex(x, y);
    if (grid[index] != 0) {
      return false;
    }

    var neighbors = getNeighbors(index);

    // 1. Has an empty adjacent point (instant liberty).
    for (var neighbor in neighbors) {
      if (grid[neighbor] == 0) {
        return true;
      }
    }

    // 2. Complex checks
    for (var neighbor in neighbors) {
      var neighborPlayer = grid[neighbor];
      var neighborGroup = getGroup(neighbor);
      var liberties = countLiberties(neighborGroup);

      // Connects to a friendly group that has > 1 liberty
      if (neighborPlayer == currentTurn && liberties > 1) {
        return true;
      }

      // Captures an enemy group (they have exactly 1 liberty left)
      if (neighborPlayer != 0 &&
          neighborPlayer != currentTurn &&
          liberties == 1) {
        return true;
      }
    }

    return false; // Suicide
  }

  bool play(int x, int y) {
    if (!isValidMove(x, y)) {
      return false;
    }

    int index = getIndex(x, y);
    grid[index] = currentTurn;
    var capturedStones = <int>{};

    for (var neighbor in getNeighbors(index)) {
      var neighborPlayer = grid[neighbor];
      if (neighborPlayer != 0 && neighborPlayer != currentTurn) {
        var opponentGroup = getGroup(neighbor);
        if (countLiberties(opponentGroup) == 0) {
          capturedStones.addAll(opponentGroup);
        }
      }
    }

    for (var capturedIdx in capturedStones) {
      grid[capturedIdx] = 0;
    }

    if (capturedStones.isNotEmpty) {
      // currentTurn is 1-indexed (1, 2, ...), so index is currentTurn - 1
      captures[currentTurn - 1] += capturedStones.length;
    }

    advance();
    return true;
  }

  void pass() {
    advance();
  }

  /// Directly places a stone without validating captures, suicide, or advancing the turn.
  /// This is used exclusively for loading SGF setup stones (AB / AW / AE).
  void addSetupStone(int x, int y, int player) {
    if (isOnBoard(x, y)) {
      grid[getIndex(x, y)] = player;
    }
  }

  void resign() {
    // No-op for physical grid
  }
}
