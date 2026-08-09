import 'move.dart';

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

  List<Point> getNeighbors(Point point) {
    var neighbors = <Point>[];
    if (isOnBoard(point.x - 1, point.y)) {
      neighbors.add(Point(point.x - 1, point.y));
    }
    if (isOnBoard(point.x + 1, point.y)) {
      neighbors.add(Point(point.x + 1, point.y));
    }
    if (isOnBoard(point.x, point.y - 1)) {
      neighbors.add(Point(point.x, point.y - 1));
    }
    if (isOnBoard(point.x, point.y + 1)) {
      neighbors.add(Point(point.x, point.y + 1));
    }
    return neighbors;
  }

  Set<Point> getGroup(Point point) {
    var targetPlayer = grid[getIndex(point.x, point.y)];
    if (targetPlayer == 0) {
      return {};
    }

    var visited = <Point>{};
    var queue = [point];

    while (queue.isNotEmpty) {
      var current = queue.removeAt(0);
      if (visited.contains(current)) {
        continue;
      }

      visited.add(current);

      for (var neighbor in getNeighbors(current)) {
        if (grid[getIndex(neighbor.x, neighbor.y)] == targetPlayer &&
            !visited.contains(neighbor)) {
          queue.add(neighbor);
        }
      }
    }
    return visited;
  }

  int countLiberties(Set<Point> group) {
    var liberties = <Point>{};
    for (var stone in group) {
      for (var neighbor in getNeighbors(stone)) {
        if (grid[getIndex(neighbor.x, neighbor.y)] == 0) {
          liberties.add(neighbor);
        }
      }
    }
    return liberties.length;
  }

  bool isValidMove(Point point) {
    if (!isOnBoard(point.x, point.y) || grid[getIndex(point.x, point.y)] != 0) {
      return false;
    }

    var neighbors = getNeighbors(point);

    // 1. Has an empty adjacent point (instant liberty).
    for (var neighbor in neighbors) {
      if (grid[getIndex(neighbor.x, neighbor.y)] == 0) {
        return true;
      }
    }

    // 2. Complex checks
    for (var neighbor in neighbors) {
      var neighborPlayer = grid[getIndex(neighbor.x, neighbor.y)];
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

  bool play(Point point) {
    if (!isValidMove(point)) {
      return false;
    }

    grid[getIndex(point.x, point.y)] = currentTurn;
    var capturedStones = <Point>{};

    for (var neighbor in getNeighbors(point)) {
      var neighborPlayer = grid[getIndex(neighbor.x, neighbor.y)];
      if (neighborPlayer != 0 && neighborPlayer != currentTurn) {
        var opponentGroup = getGroup(neighbor);
        if (countLiberties(opponentGroup) == 0) {
          capturedStones.addAll(opponentGroup);
        }
      }
    }

    for (var captured in capturedStones) {
      grid[getIndex(captured.x, captured.y)] = 0;
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

  void resign() {
    // No-op for physical grid
  }
}
