import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:gpu_vector_tile_renderer/_controller.dart';
import 'package:gpu_vector_tile_renderer/_renderer.dart';
import 'package:gpu_vector_tile_renderer/_spec.dart' as spec;
import 'package:gpu_vector_tile_renderer/_vector_tile.dart' as vt;
import 'package:gpu_vector_tile_renderer/src/vector_tile/proto/vector_tile.pb.dart' as pb;

/// A class that holds a tile on the map.
class TileContainer with ChangeNotifier {
  TileContainer({required this.controller, required this.coordinates, required this.sourceKeys}) {
    _load();

    _opacityAnimationController = AnimationController(
      vsync: controller.tickerProvider,
      duration: const Duration(milliseconds: 150),
    );

    _opacityAnimationController.addListener(notifyListeners);
  }

  /// The controller that owns this tile.
  final VectorTileLayerController controller;

  /// The coordinates of the tile.
  final fm.TileCoordinates coordinates;

  /// List of source keys that should be loaded for this tile.
  final List<Object> sourceKeys;

  late final AnimationController _opacityAnimationController;
  Animation<double> get opacityAnimation => _opacityAnimationController.view;

  Map<Object, vt.Tile>? _vectorTiles;
  Map<Object, SingleTileLayerRenderer>? _renderers;

  /// The vector tiles that have been loaded.
  ///
  /// Make sure that [isLoaded] is `true` before accessing this property.
  Map<Object, vt.Tile> get vectorTiles => _vectorTiles!;

  /// The renderers that will be used to render this tile.
  ///
  /// Make sure that [isReadyToDisplay] is `true` before accessing this property.
  Map<Object, SingleTileLayerRenderer> get renderers => _renderers!;

  /// Whether the tile data has been loaded.
  bool get isLoaded => _vectorTiles != null;

  /// Whether the renderers are ready to display.
  bool get isReadyToDisplay => _renderers != null;

  Future<void> _load() async {
    final futures = <Future>[];
    final result = <Object, vt.Tile>{};

    // Load all source tiles in parallel.
    for (final sourceKey in sourceKeys) {
      final source = controller.style.sources[sourceKey]! as spec.SourceVector;
      final future = controller.vectorTileResolver(source, coordinates).then((data) {
        final pbTile = pb.Tile.fromBuffer(data);
        final vtTile = vt.decodeTile(pbTile);
        result[sourceKey] = vtTile;
      });

      futures.add(future);
    }

    await futures.wait;
    if (_disposed) return;

    _vectorTiles = result;
    notifyListeners();

    _setupRenderers();
  }

  Future<void> _setupRenderers() async {
    return await SchedulerBinding.instance.scheduleTask(() async {
      final result = <Object, SingleTileLayerRenderer>{};

      final prepareFutures = <Future>[];

      for (final layer in controller.style.layers) {
        // Check if this layer type is even supported
        if (!supportedLayerTypes.contains(layer.type)) continue;

        // Check the source key and check if we have that source
        final sourceKey = layer.source;
        if (sourceKey == null) continue;
        if (!sourceKeys.contains(sourceKey)) continue;

        // Check the source layer name
        final sourceLayerName = layer.sourceLayer;
        if (sourceLayerName == null) continue;

        // Get the vector tile layer
        final vectorTile = _vectorTiles![sourceKey]!;
        final vtLayer = vectorTile.layers.firstWhereOrNull((data) => data.name == sourceLayerName);
        if (vtLayer == null) continue;

        // Create the renderer
        final renderer = controller.renderOrchestrator.createSingleTileLayerRenderer(coordinates, this, layer, vtLayer);
        if (renderer == null) continue;

        result[layer.id] = renderer;
        final futureOr = renderer.prepare(
          PrepareContext(eval: spec.EvaluationContext.empty().copyWithZoom(coordinates.z.toDouble())),
        );
        if (futureOr is Future) prepareFutures.add(futureOr);
      }

      await prepareFutures.wait;
      if (_disposed) return;

      _renderers = result;
      notifyListeners();

      _opacityAnimationController.forward();
    }, Priority.animation);
  }

  bool _disposed = false;

  Future<void> animatedDispose() async {
    await _opacityAnimationController.reverse();
    dispose();
  }

  @override
  void dispose() {
    _disposed = true;
    _opacityAnimationController.dispose();

    super.dispose();
  }
}
