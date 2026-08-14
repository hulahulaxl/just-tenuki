import 'package:flutter/material.dart';

class BoardSettings {
  final Color boardColor;
  final Color blackStoneColor;
  final int blackStoneTextureIndex;
  final Color whiteStoneColor;
  final int whiteStoneTextureIndex;
  final Color lineColor;
  final bool showCoordinates;
  final bool highlightLastMove;
  final double stoneDropShadow;
  final double stoneOutlineThickness;
  final double stoneClickVolume;
  final double lineThickness;
  final double starPointThickness;
  final double stoneScale;

  const BoardSettings({
    required this.boardColor,
    required this.blackStoneColor,
    required this.blackStoneTextureIndex,
    required this.whiteStoneColor,
    required this.whiteStoneTextureIndex,
    required this.lineColor,
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
    : boardColor = const Color(0xFFDCB35C),
      blackStoneColor = const Color(0xFF101010),
      blackStoneTextureIndex = 3,
      whiteStoneColor = const Color(0xFFFFFFFF),
      whiteStoneTextureIndex = 5,
      lineColor = const Color(0xDD000000),
      showCoordinates = true,
      highlightLastMove = true,
      stoneDropShadow = 3.0,
      stoneOutlineThickness = 1.2,
      stoneClickVolume = 0.5,
      lineThickness = 0.5,
      starPointThickness = 2.5,
      stoneScale = 0.95;

  BoardSettings copyWith({
    Color? boardColor,
    Color? blackStoneColor,
    int? blackStoneTextureIndex,
    Color? whiteStoneColor,
    int? whiteStoneTextureIndex,
    Color? lineColor,
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
      boardColor: boardColor ?? this.boardColor,
      blackStoneColor: blackStoneColor ?? this.blackStoneColor,
      blackStoneTextureIndex: blackStoneTextureIndex ?? this.blackStoneTextureIndex,
      whiteStoneColor: whiteStoneColor ?? this.whiteStoneColor,
      whiteStoneTextureIndex: whiteStoneTextureIndex ?? this.whiteStoneTextureIndex,
      lineColor: lineColor ?? this.lineColor,
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
