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
    double? lineThickness,
    double? starPointThickness,
    double? stoneScale,
  }) {
    return BoardSettings(
      boardColor: boardColor ?? this.boardColor,
      blackStoneColor: blackStoneColor ?? this.blackStoneColor,
      blackStoneTextureIndex:
          blackStoneTextureIndex ?? this.blackStoneTextureIndex,
      whiteStoneColor: whiteStoneColor ?? this.whiteStoneColor,
      whiteStoneTextureIndex:
          whiteStoneTextureIndex ?? this.whiteStoneTextureIndex,
      lineColor: lineColor ?? this.lineColor,
      showCoordinates: showCoordinates ?? this.showCoordinates,
      highlightLastMove: highlightLastMove ?? this.highlightLastMove,
      stoneDropShadow: stoneDropShadow ?? this.stoneDropShadow,
      stoneOutlineThickness:
          stoneOutlineThickness ?? this.stoneOutlineThickness,
      lineThickness: lineThickness ?? this.lineThickness,
      starPointThickness: starPointThickness ?? this.starPointThickness,
      stoneScale: stoneScale ?? this.stoneScale,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'boardColor': boardColor.toARGB32(),
      'blackStoneColor': blackStoneColor.toARGB32(),
      'blackStoneTextureIndex': blackStoneTextureIndex,
      'whiteStoneColor': whiteStoneColor.toARGB32(),
      'whiteStoneTextureIndex': whiteStoneTextureIndex,
      'lineColor': lineColor.toARGB32(),
      'showCoordinates': showCoordinates,
      'highlightLastMove': highlightLastMove,
      'stoneDropShadow': stoneDropShadow,
      'stoneOutlineThickness': stoneOutlineThickness,
      'lineThickness': lineThickness,
      'starPointThickness': starPointThickness,
      'stoneScale': stoneScale,
    };
  }

  factory BoardSettings.fromJson(Map<dynamic, dynamic> json) {
    const defaults = BoardSettings.defaults();
    return BoardSettings(
      boardColor: json['boardColor'] != null
          ? Color(json['boardColor'] as int)
          : defaults.boardColor,
      blackStoneColor: json['blackStoneColor'] != null
          ? Color(json['blackStoneColor'] as int)
          : defaults.blackStoneColor,
      blackStoneTextureIndex:
          json['blackStoneTextureIndex'] as int? ??
          defaults.blackStoneTextureIndex,
      whiteStoneColor: json['whiteStoneColor'] != null
          ? Color(json['whiteStoneColor'] as int)
          : defaults.whiteStoneColor,
      whiteStoneTextureIndex:
          json['whiteStoneTextureIndex'] as int? ??
          defaults.whiteStoneTextureIndex,
      lineColor: json['lineColor'] != null
          ? Color(json['lineColor'] as int)
          : defaults.lineColor,
      showCoordinates:
          json['showCoordinates'] as bool? ?? defaults.showCoordinates,
      highlightLastMove:
          json['highlightLastMove'] as bool? ?? defaults.highlightLastMove,
      stoneDropShadow:
          (json['stoneDropShadow'] as num?)?.toDouble() ??
          defaults.stoneDropShadow,
      stoneOutlineThickness:
          (json['stoneOutlineThickness'] as num?)?.toDouble() ??
          defaults.stoneOutlineThickness,
      lineThickness:
          (json['lineThickness'] as num?)?.toDouble() ?? defaults.lineThickness,
      starPointThickness:
          (json['starPointThickness'] as num?)?.toDouble() ??
          defaults.starPointThickness,
      stoneScale:
          (json['stoneScale'] as num?)?.toDouble() ?? defaults.stoneScale,
    );
  }
}
