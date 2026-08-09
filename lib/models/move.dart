sealed class Move {
  final int playerId;
  const Move(this.playerId);
}

class Play extends Move {
  final int x;
  final int y;
  const Play(super.playerId, this.x, this.y);
}

class Pass extends Move {
  const Pass(super.playerId);
}

class Resign extends Move {
  const Resign(super.playerId);
}
