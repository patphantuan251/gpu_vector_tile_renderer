import 'dart:convert';

import 'package:gpu_vector_tile_renderer/_spec.dart' as spec;
import 'package:gpu_vector_tile_renderer/_tilejson.dart';
import 'package:gpu_vector_tile_renderer/_utils.dart';

/// A function that resolves a source.
///
/// Some sources may need to be resolved before they can be used (e.g. fetch the TileJSON spec).
typedef SourceResolverFn = Future<spec.Source> Function(spec.Source source);

/// The default source resolver.
///
/// Uses `package:http` to fetch the source.
Future<spec.Source> defaultSourceResolver(spec.Source source) async {
  return switch (source) {
    spec.SourceVector vector => _defaultVectorSourceResolver(vector),
    _ => source,
  };
}

/// Loads a TileJSON spec from a given [uri].
/// 
/// Used for resolving vector sources.
Future<TileJson> _loadTileJson(Uri uri) async {
  final response = await zonedHttpGet(uri);
  return TileJson.fromJson(jsonDecode(response.body));
}

Future<spec.SourceVector> _defaultVectorSourceResolver(spec.SourceVector source) async {
  if (source.tiles != null) return source;

  // If tiles are missing, try to load the TileJSON spec.
  if (source.url != null) {
    final tileJson = await _loadTileJson(Uri.parse(source.url!));
    return source.copyWith(tiles: tileJson.tiles, minzoom: tileJson.minzoom, maxzoom: tileJson.maxzoom);
  }

  // This means that the source doesn't have tiles.
  return source;
}
