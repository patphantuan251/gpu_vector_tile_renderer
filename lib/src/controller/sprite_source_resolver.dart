import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:gpu_vector_tile_renderer/_spec.dart' as spec;
import 'package:gpu_vector_tile_renderer/_utils.dart';

/// A function that provides a way to load a sprite source.
///
/// For a default (network) implementation, see [defaultSpriteSourceResolver].
typedef SpriteSourceResolverFn = Future<ResolvedSpriteSource> Function(spec.SpriteSource source, {bool isHighDpi});

/// Uses `dart:http` to load a sprite source.
Future<ResolvedSpriteSource> defaultSpriteSourceResolver(spec.SpriteSource source, {bool isHighDpi = false}) async {
  final [indexResponse, imageResponse] =
      await [
        zonedHttpGet(source.getIndexUri(isHighDpi: isHighDpi)),
        zonedHttpGet(source.getImageUri(isHighDpi: isHighDpi)),
      ].wait;

  final index = spec.SpriteIndex.fromJson(jsonDecode(indexResponse.body));
  final image = await decodeImageFromListAsync(imageResponse.bodyBytes);

  return ResolvedSpriteSource(id: source.id, index: index, image: image);
}

/// An object that contains a downloaded sprite source.
class ResolvedSpriteSource {
  const ResolvedSpriteSource({this.id, required this.index, required this.image});

  /// The id of the sprite source. Can be `null`
  final String? id;

  /// The sprite index, which contains the mapping of sprite names to their metrics.
  final spec.SpriteIndex index;

  /// The atlas image containing all the sprites.
  final ui.Image image;

  void dispose() {
    image.dispose();
  }
}
