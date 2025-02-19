import 'dart:ui' hide Color;

import 'package:vector_math/vector_math_64.dart';

extension ToVector2 on Offset {
  Vector2 get vec2 => Vector2(dx, dy);
}
