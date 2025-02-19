import 'dart:typed_data';

import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:gpu_vector_tile_renderer/_spec.dart' as spec;
import 'package:gpu_vector_tile_renderer/_utils.dart';

/// A function that resolves a vector tile.
///
/// The function should return the raw vector tile data (protobuf) as a [Uint8List].
///
/// See [defaultVectorTileResolver] for a default implementation.
typedef VectorTileResolverFn = Future<Uint8List> Function(spec.SourceVector source, fm.TileCoordinates coordinates);

/// A default implementation of [VectorTileResolverFn].
Future<Uint8List> defaultVectorTileResolver(spec.SourceVector source, fm.TileCoordinates coordinates) async {
  final uri = Uri.parse(
    source.tiles!.first
        .replaceFirst('{x}', coordinates.x.toString())
        .replaceFirst('{y}', coordinates.y.toString())
        .replaceFirst('{z}', coordinates.z.toString()),
  );

  final response = await zonedHttpGet(uri);
  return response.bodyBytes;
}
