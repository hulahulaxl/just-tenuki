class BoardSettings {
  final int boardStyleIndex;
  final int blackStoneStyleIndex;
  final int whiteStoneStyleIndex;
  final int lineStyleIndex;
  final bool showCoordinates;
  final bool highlightLastMove;
  final double stoneDropShadow;
  final double stoneOutlineThickness;
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
    required this.stoneDropShadow,
    required this.stoneOutlineThickness,
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
      showCoordinates = false,
      highlightLastMove = true,
      stoneDropShadow = 2.0,
      stoneOutlineThickness = 0.0,
      stoneClickVolume = 0.5,
      lineThickness = 0.5,
      starPointThickness = 3.0,
      stoneScale = 0.95;

  BoardSettings copyWith({
    int? boardStyleIndex,
    int? blackStoneStyleIndex,
    int? whiteStoneStyleIndex,
    int? lineStyleIndex,
    bool? showCoordinates,
    bool? highlightLastMove,
    double? stoneDropShadow,
    double? stoneOutlineThickness,
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
      stoneDropShadow: stoneDropShadow ?? this.stoneDropShadow,
      stoneOutlineThickness:
          stoneOutlineThickness ?? this.stoneOutlineThickness,
      stoneClickVolume: stoneClickVolume ?? this.stoneClickVolume,
      lineThickness: lineThickness ?? this.lineThickness,
      starPointThickness: starPointThickness ?? this.starPointThickness,
      stoneScale: stoneScale ?? this.stoneScale,
    );
  }
}
