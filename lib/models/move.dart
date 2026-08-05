class Point {
  final int x;
  final int y;
  const Point(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

enum StoneColor { black, white }

sealed class Move {
  final StoneColor color;
  const Move({required this.color});
}

class Play extends Move {
  final Point point;
  const Play({required super.color, required this.point});
}

class Pass extends Move {
  const Pass({required super.color});
}

class Resign extends Move {
  const Resign({required super.color});
}
