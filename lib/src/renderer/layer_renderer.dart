import 'dart:async';

import 'package:flutter_map/flutter_map.dart';
import 'package:gpu_vector_tile_renderer/_controller.dart';
import 'package:gpu_vector_tile_renderer/_renderer.dart';
import 'package:gpu_vector_tile_renderer/_spec.dart' as spec;
import 'package:gpu_vector_tile_renderer/_vector_tile.dart' as vt;

List<LayerRenderer> createLayerRenderers(VectorTileLayerRenderOrchestrator orchestrator, spec.Style style) {
  final layers = style.layers.where((layer) => supportedLayerTypes.contains(layer.type)).toList();

  return layers
      .map(
        (layer) => switch (layer.type) {
          spec.Layer$Type.fill => TiledLayerRenderer<spec.LayerFill>(
            orchestrator: orchestrator,
            specLayer: layer as spec.LayerFill,
          ),
          _ => throw UnimplementedError('Unsupported layer type: ${layer.type}'),
        },
      )
      .cast<LayerRenderer>()
      .toList();
}

abstract class LayerRenderer<T extends spec.Layer> {
  LayerRenderer({required this.orchestrator, required this.specLayer});

  final VectorTileLayerRenderOrchestrator orchestrator;
  final T specLayer;

  FutureOr<void> prepare(PrepareContext context) {}
  void draw(RenderContext context);
}

class TiledLayerRenderer<T extends spec.Layer> extends LayerRenderer<T> {
  TiledLayerRenderer({required super.orchestrator, required super.specLayer});

  @override
  Future<void> prepare(PrepareContext context) async {
    final tiles = orchestrator.controller.tiles;
    final futures = <Future<void>>[];

    for (final tile in tiles) {
      final renderer = tile.renderers[specLayer.id];
      if (renderer == null) continue;

      final futureOr = renderer.prepare(context);
      if (futureOr is Future) futures.add(futureOr);
    }

    await futures.wait;
  }

  @override
  void draw(RenderContext context) {
    final tiles = orchestrator.controller.tiles;

    for (final tile in tiles) {
      if (!tile.isReadyToDisplay) continue;

      final renderer = tile.renderers[specLayer.id];
      if (renderer == null) continue;

      renderer.draw(context);
    }
  }
}

abstract class SingleTileLayerRenderer<T extends spec.Layer> {
  SingleTileLayerRenderer({
    required this.coordinates,
    required this.container,
    required this.specLayer,
    required this.vtLayer,
  });

  final TileCoordinates coordinates;
  final TileContainer container;
  final T specLayer;
  final vt.Layer vtLayer;

  FutureOr<void> prepare(PrepareContext context);
  void draw(RenderContext context);
}
