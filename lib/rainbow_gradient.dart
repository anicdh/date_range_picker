import 'package:flutter/widgets.dart';

class RainbowGradient extends LinearGradient {
  RainbowGradient({
    @required List<Color> colors,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.topRight,
  }) : super(
          begin: begin,
          end: end,
          colors: _buildColors(colors),
          stops: _buildStops(colors),
        );

  static List<Color> _buildColors(List<Color> colors) {
    return colors.fold<List<Color>>(<Color>[],
        (List<Color> list, Color color) => list..addAll(<Color>[color, color]));
  }

  static List<double> _buildStops(List<Color> colors) {
    final List<double> stops = <double>[0.0];

    for (int i = 1, len = colors.length; i < len; i++) {
      stops.add(i / colors.length);
      stops.add(i / colors.length);
    }

    return stops..add(1.0);
  }
}