import 'package:flutter/material.dart';

class BoardStyles {
  static const List<Color> boardColors = [
    Color(0xFFDCB35C),
    Color(0xFFE6D0A7),
    Color(0xFFE1D0AB),
    Color(0xFFECD2B2),
    Color(0xFFDFC49C),
    Color(0xFFE8E0C0),
    Color(0xFFDED3BC),
    Color(0xFFBFA192),
    Color(0xFFC0C3C2),
    Color(0xFF909392),
    Color(0xFF9CF0FF),
    Color(0xFF75818C),
    Color(0xFFFFFFFF),
    Color(0xFFB9C2C5),
  ];

  static const List<Gradient> whiteStones = [
    RadialGradient(colors: [Color(0xFFFFFFFF), Color(0xFFD0D0D0)]),
    RadialGradient(colors: [Color(0xFFFFFFFF), Color(0xFFE0E0E0)]),
    RadialGradient(colors: [Color(0xFFFFFFFF), Color(0xFFF0F0F0)]),
    LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFDDDDDD)]),
    RadialGradient(colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)]),
    RadialGradient(colors: [Color(0xFFE0E0E0), Color(0xFFB0B0B0)]),
    RadialGradient(colors: [Color(0xFFF5FFE8), Color(0xFFD0E0D0)]),
  ];

  static const List<Gradient> blackStones = [
    RadialGradient(colors: [Color(0xFF404040), Color(0xFF101010)]),
    RadialGradient(colors: [Color(0xFF606060), Color(0xFF303030)]),
    RadialGradient(colors: [Color(0xFF707070), Color(0xFF404040)]),
    RadialGradient(colors: [Color(0xFF505050), Color(0xFF505050)]),
    RadialGradient(colors: [Color(0xFF555555), Color(0xFF222222)]),
    RadialGradient(colors: [Color(0xFF454545), Color(0xFF252525)]),
    RadialGradient(colors: [Color(0xFF353535), Color(0xFF151515)]),
  ];

  static final List<Color> lineColors = [
    Colors.black87,
    Colors.black54,
    Colors.brown.shade800,
    Colors.brown.shade600,
    Colors.blueGrey.shade800,
    Colors.grey.shade400,
    Colors.white70,
  ];
}
