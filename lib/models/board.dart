import 'move.dart';

class Board {
  final int columns;
  final int rows;
  final int playerCount;
  final Map<Point, int> grid;
  int currentTurn;

  Board({this.columns = 19, this.rows = 19, this.playerCount = 2})
    : grid = {},
      currentTurn = 1;

  Board._clone(
    this.columns,
    this.rows,
    this.playerCount,
    this.currentTurn,
    Map<Point, int> existingGrid,
  ) : grid = Map.from(existingGrid);

  Board clone() => Board._clone(columns, rows, playerCount, currentTurn, grid);

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

  bool play(int x, int y) {
    var point = Point(x, y);
    if (!isOnBoard(point) || grid.containsKey(point)) return false;

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

    var myGroup = getGroup(point);
    if (countLiberties(myGroup) == 0) {
      grid.remove(point);
      return false; // Suicide is illegal
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
