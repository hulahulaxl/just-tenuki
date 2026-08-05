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

  bool isValid(Point point) {
    throw UnimplementedError();
  }

  List<Point> getNeighbors(Point point) {
    throw UnimplementedError();
  }

  Set<Point> getGroup(Point point, int playerId) {
    throw UnimplementedError();
  }

  int countLiberties(Set<Point> group) {
    throw UnimplementedError();
  }

  bool play(int x, int y) {
    throw UnimplementedError();
  }

  void pass() {
    throw UnimplementedError();
  }

  void resign() {
    throw UnimplementedError();
  }
}
