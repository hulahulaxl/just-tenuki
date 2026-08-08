import 'move.dart';

class Board {
  final int columns;
  final int rows;
  final int playerCount;
  final Map<Point, int> grid;
  int currentTurn;
  List<int> captures;

  Board({this.columns = 19, this.rows = 19, this.playerCount = 2})
    : grid = {},
      currentTurn = 1,
      captures = List.filled(playerCount, 0);

  Board._clone(
    this.columns,
    this.rows,
    this.playerCount,
    this.currentTurn,
    Map<Point, int> existingGrid,
    List<int> existingCaptures,
  ) : grid = Map.from(existingGrid),
      captures = List.from(existingCaptures);

  Board clone() =>
      Board._clone(columns, rows, playerCount, currentTurn, grid, captures);

  void advance() {
    currentTurn = (currentTurn % playerCount) + 1;
  }

  bool isOnBoard(Point point) {
    return point.x >= 0 && point.x < columns && point.y >= 0 && point.y < rows;
  }

  List<Point> getNeighbors(Point point) {
    return [
      Point(point.x - 1, point.y),
      Point(point.x + 1, point.y),
      Point(point.x, point.y - 1),
      Point(point.x, point.y + 1),
    ].where(isOnBoard).toList();
  }

  Set<Point> getGroup(Point point) {
    var targetPlayer = grid[point];
    var visited = <Point>{};
    var queue = [point];

    while (queue.isNotEmpty) {
      var current = queue.removeAt(0);
      if (visited.contains(current)) continue;

      visited.add(current);

      for (var neighbor in getNeighbors(current)) {
        if (grid[neighbor] == targetPlayer && !visited.contains(neighbor)) {
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
        if (!grid.containsKey(neighbor)) {
          liberties.add(neighbor);
        }
      }
    }
    return liberties.length;
  }

  bool isValidMove(Point point) {
    if (!isOnBoard(point) || grid.containsKey(point)) return false;

    var neighbors = getNeighbors(point);

    // 1. Has an empty adjacent point (instant liberty).
    // We check all neighbors first because this is an O(1) check!
    for (var neighbor in neighbors) {
      if (grid[neighbor] == null) return true;
    }

    // If all neighbors are occupied, we must do the more expensive group checks
    for (var neighbor in neighbors) {
      var neighborPlayer = grid[neighbor];
      var neighborGroup = getGroup(neighbor);
      var liberties = countLiberties(neighborGroup);

      // 2. Connects to a friendly group that has > 1 liberty
      if (neighborPlayer == currentTurn && liberties > 1) return true;

      // 3. Captures an enemy group (they have exactly 1 liberty left)
      if (neighborPlayer != currentTurn && liberties == 1) return true;
    }

    return false; // None of the survival conditions met, it's suicide
  }

  bool play(Point point) {
    if (!isValidMove(point)) return false;

    grid[point] = currentTurn;
    var capturedStones = <Point>{};

    for (var neighbor in getNeighbors(point)) {
      var neighborPlayer = grid[neighbor];
      if (neighborPlayer != null && neighborPlayer != currentTurn) {
        var opponentGroup = getGroup(neighbor);
        if (countLiberties(opponentGroup) == 0) {
          capturedStones.addAll(opponentGroup);
        }
      }
    }

    for (var captured in capturedStones) {
      grid.remove(captured);
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
    // Usually recorded in the Game Tree. For the physical board state,
    // resign doesn't change stones, so this is a no-op here.
  }
}
