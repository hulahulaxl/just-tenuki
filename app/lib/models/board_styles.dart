import 'package:flutter/material.dart';

typedef StoneTextureFactory = Paint Function(Rect rect, Color baseColor);

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

  static const List<Color> whiteStoneColorPresets = [
    Color(0xFFFFFFFF),
    Color(0xFFF0F0F0),
    Color(0xFFE0E0E0),
    Color(0xFFD0D0D0),
    Color(0xFFC0C0C0),
    Color(0xFFF5FFE8),
    Color(0xFFFFE8E8),
    Color(0xFFE8F5FF),
    Color(0xFFFFF0D0),
  ];

  static const List<Color> blackStoneColorPresets = [
    Color(0xFF101010),
    Color(0xFF202020),
    Color(0xFF303030),
    Color(0xFF404040),
    Color(0xFF505050),
    Color(0xFF2A2A2A),
    Color(0xFF1A2530),
    Color(0xFF301A1A),
    Color(0xFF1A301A),
  ];

  static Color _darken(Color color, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  static Color _lighten(Color color, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return hslLight.toColor();
  }

  static final List<StoneTextureFactory> stoneTextures = [
    // 0: Matte/Flat
    (Rect rect, Color baseColor) {
      return Paint()..color = baseColor;
    },
    // 1: Subtle Gradient (current default)
    (Rect rect, Color baseColor) {
      return Paint()
        ..shader = RadialGradient(
          colors: [
            baseColor.computeLuminance() > 0.5
                ? Colors.white
                : _lighten(baseColor, 0.2),
            _darken(baseColor, 0.2),
          ],
        ).createShader(rect);
    },
    // 2: Strong Gradient
    (Rect rect, Color baseColor) {
      return Paint()
        ..shader = RadialGradient(
          colors: [_lighten(baseColor, 0.4), _darken(baseColor, 0.4)],
        ).createShader(rect);
    },
    // 3: Linear Gradient
    (Rect rect, Color baseColor) {
      return Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_lighten(baseColor, 0.3), _darken(baseColor, 0.3)],
        ).createShader(rect);
    },
    // 4: Edge Highlight
    (Rect rect, Color baseColor) {
      return Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0),
          colors: [_darken(baseColor, 0.1), _lighten(baseColor, 0.3)],
        ).createShader(rect);
    },
    // 5: Glossy
    (Rect rect, Color baseColor) {
      return Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 0.8,
          colors: [
            _lighten(baseColor, 0.5),
            baseColor,
            _darken(baseColor, 0.3),
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(rect);
    },
    // 6: Deep Shadow
    (Rect rect, Color baseColor) {
      return Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.2, -0.2),
          radius: 1.2,
          colors: [baseColor, _darken(baseColor, 0.5)],
        ).createShader(rect);
    },
  ];

  static final List<Color> lineColorPresets = [
    const Color(0xDD000000), // Default black
    Colors.black87,
    Colors.black54,
    Colors.brown.shade800,
    Colors.brown.shade600,
    Colors.blueGrey.shade800,
    Colors.grey.shade400,
    Colors.white70,
    Colors.white54,
  ];
}
