

import 'package:flutter_map/flutter_map.dart' as fm;

/// Wraps the tile coordinates to the "canonical" tile coordinates.
/// 
/// Meaning, the coordinates will be wrapped to the range [0, 2^z) for x and y.
fm.TileCoordinates wrapTileCoordinates(fm.TileCoordinates coordinates) {
  if (coordinates.z < 0) {
    return coordinates;
  }
  final modulo = 1 << coordinates.z;
  int x = coordinates.x;
  while (x < 0) {
    x += modulo;
  }
  while (x >= modulo) {
    x -= modulo;
  }
  int y = coordinates.y;
  while (y < 0) {
    y += modulo;
  }
  while (y >= modulo) {
    y -= modulo;
  }
  return fm.TileCoordinates(x, y, coordinates.z);
}
