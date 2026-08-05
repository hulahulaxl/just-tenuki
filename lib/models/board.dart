import 'move.dart';

class Board {
  final int size;
  final Map<Point, StoneColor> grid;

  Board({this.size = 19}) : grid = {};

  // Constructor for cloning
  Board._clone(this.size, Map<Point, StoneColor> existingGrid)
    : grid = Map.from(existingGrid);

  Board clone() {
    return Board._clone(size, grid);
  }

  bool isValid(Point p) {
    throw UnimplementedError("Check if point is within bounds");
  }

  List<Point> getNeighbors(Point p) {
    throw UnimplementedError("Return adjacent valid points");
  }

  Set<Point> getGroup(Point p, StoneColor color) {
    throw UnimplementedError("Find all connected stones of the same color");
  }

  int countLiberties(Set<Point> group) {
    throw UnimplementedError(
      "Count empty adjacent points for a group of stones",
    );
  }

  bool move(Move move) {
    throw UnimplementedError("Place a stone, handle captures, check suicide");
  }
}
