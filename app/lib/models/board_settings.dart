class BoardSettings {
  final int boardStyleIndex;
  final int blackStoneStyleIndex;
  final int whiteStoneStyleIndex;
  final int lineStyleIndex;
  final bool showCoordinates;
  final bool highlightLastMove;
  final bool showShadows;
  final double stoneClickVolume;
  final double lineThickness;
  final double starPointThickness;
  final double stoneScale;

  const BoardSettings({
    required this.boardStyleIndex,
    required this.blackStoneStyleIndex,
    required this.whiteStoneStyleIndex,
    required this.lineStyleIndex,
    required this.showCoordinates,
    required this.highlightLastMove,
    required this.showShadows,
    required this.stoneClickVolume,
    required this.lineThickness,
    required this.starPointThickness,
    required this.stoneScale,
  });

  const BoardSettings.defaults()
    : boardStyleIndex = 0,
      blackStoneStyleIndex = 0,
      whiteStoneStyleIndex = 0,
      lineStyleIndex = 0,
      showCoordinates = true,
      highlightLastMove = true,
      showShadows = true,
      stoneClickVolume = 0.5,
      lineThickness = 1.0,
      starPointThickness = 3.0,
      stoneScale = 0.95;

  BoardSettings copyWith({
    int? boardStyleIndex,
    int? blackStoneStyleIndex,
    int? whiteStoneStyleIndex,
    int? lineStyleIndex,
    bool? showCoordinates,
    bool? highlightLastMove,
    bool? showShadows,
    double? stoneClickVolume,
    double? lineThickness,
    double? starPointThickness,
    double? stoneScale,
  }) {
    return BoardSettings(
      boardStyleIndex: boardStyleIndex ?? this.boardStyleIndex,
      blackStoneStyleIndex: blackStoneStyleIndex ?? this.blackStoneStyleIndex,
      whiteStoneStyleIndex: whiteStoneStyleIndex ?? this.whiteStoneStyleIndex,
      lineStyleIndex: lineStyleIndex ?? this.lineStyleIndex,
      showCoordinates: showCoordinates ?? this.showCoordinates,
      highlightLastMove: highlightLastMove ?? this.highlightLastMove,
      showShadows: showShadows ?? this.showShadows,
      stoneClickVolume: stoneClickVolume ?? this.stoneClickVolume,
      lineThickness: lineThickness ?? this.lineThickness,
      starPointThickness: starPointThickness ?? this.starPointThickness,
      stoneScale: stoneScale ?? this.stoneScale,
    );
  }
}
