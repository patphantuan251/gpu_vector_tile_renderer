import 'package:flutter_map/flutter_map.dart';
import 'package:gpu_vector_tile_renderer/gpu_vector_tile_renderer.dart';

// TODO: Actually get this working

class TileCache {
  TileCache({this.maxSize = 100});

  final int maxSize;
  final Map<TileCoordinates, TileContainer> _cache = {};

  void put(TileCoordinates coordinates, TileContainer tile) {
    if (_cache.length >= maxSize) {
      _cache.remove(_cache.keys.first)?.dispose();
    }

    _cache[coordinates] = tile;
  }

  bool contains(TileCoordinates coordinates) {
    return _cache.containsKey(coordinates);
  }

  TileContainer? get(TileCoordinates coordinates) {
    return _cache[coordinates];
  }

  TileContainer? getUnderzoomFor(TileCoordinates coordinates) {
    var x = coordinates.x;
    var y = coordinates.y;

    for (var z = coordinates.z - 1; z >= 0; z--) {
      x ~/= 2;
      y ~/= 2;

      final tile = _cache[TileCoordinates(x, y, z)];
      if (tile != null && tile.isReadyToDisplay) return tile;
    }

    return null;
  }

  List<TileContainer>? getOverzoomFor(TileCoordinates coordinates) {
    final _overzoomCoordinates = [
      TileCoordinates(coordinates.x * 2, coordinates.y * 2, coordinates.z + 1),
      TileCoordinates(coordinates.x * 2 + 1, coordinates.y * 2, coordinates.z + 1),
      TileCoordinates(coordinates.x * 2, coordinates.y * 2 + 1, coordinates.z + 1),
      TileCoordinates(coordinates.x * 2 + 1, coordinates.y * 2 + 1, coordinates.z + 1),
    ];

    final result = <TileContainer>[];
    for (final overzoomCoordinate in _overzoomCoordinates) {
      final tile = _cache[overzoomCoordinate];
      if (tile != null && tile.isReadyToDisplay) {
        result.add(tile);
      }
    }

    if (result.length != 4) return null;
    return result;
  }

  void dispose() {
    for (final tile in _cache.values) {
      tile.dispose();
    }

    _cache.clear();
  }
}
