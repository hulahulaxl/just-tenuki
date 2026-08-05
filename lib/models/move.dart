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

sealed class Move {
  final int playerId;
  const Move(this.playerId);
}

class Play extends Move {
  final Point point;
  const Play(super.playerId, this.point);
}

class Pass extends Move {
  const Pass(super.playerId);
}

class Resign extends Move {
  const Resign(super.playerId);
}
