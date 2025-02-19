import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:gpu_vector_tile_renderer/_controller.dart';
import 'package:gpu_vector_tile_renderer/_renderer.dart';
import 'package:gpu_vector_tile_renderer/_spec.dart';
import 'package:gpu_vector_tile_renderer/src/utils/flutter_map/tile_scale_calculator.dart';
import 'package:vector_math/vector_math.dart' as vm32;

class VectorTileLayerRenderOrchestrator with ChangeNotifier {
  VectorTileLayerRenderOrchestrator({required this.controller}) {
    controller.addListener(_onControllerChanged);
    controller.addTileUpdateListener(_onTilesChanged);
  }

  /// The controller that this renderer is attached to.
  final VectorTileLayerController controller;

  List<LayerRenderer>? _layers;

  void _onControllerChanged() {
    if (_layers != null) return;

    // Convert the style layers to layer renderers.
    _layers = createLayerRenderers(this, controller.style);

    for (final layer in _layers!) {
      layer.prepare(PrepareContext(eval: EvaluationContext.empty()));
    }
  }

  void onReassemble() {
    if (_layers == null) return;

    for (final layer in _layers!) {
      final result = layer.prepare(PrepareContext(eval: EvaluationContext.empty()));

      if (result is Future) {
        result.then((_) => notifyListeners());
      }
    }
  }

  void _onTilesChanged() {
    notifyListeners();
  }

  fm.MapCamera? _lastCamera;
  double? _lastTileSize;
  TileScaleCalculator? _tileScaleCalculator;

  void onCameraChanged(fm.MapCamera camera, double tileSize) {
    if (_tileScaleCalculator == null || tileSize != _lastTileSize) {
      _tileScaleCalculator = TileScaleCalculator(crs: camera.crs, tileSize: tileSize);
    }

    _lastCamera = camera;
    _lastTileSize = tileSize;
    _tileScaleCalculator!.clearCacheUnlessZoomMatches(camera.zoom);
  }

  gpu.Texture? _texture;
  gpu.Texture? _resolveTexture;

  void _setupTextures(ui.Size size, double pixelRatio) {
    final width = (size.width * pixelRatio).ceil();
    final height = (size.height * pixelRatio).ceil();

    if (_texture != null && _texture!.width == width && _texture!.height == height) return;

    if (gpu.gpuContext.doesSupportOffscreenMSAA) {
      _texture = gpu.gpuContext.createTexture(
        gpu.StorageMode.hostVisible,
        width,
        height,
        sampleCount: 4,
        format: gpu.PixelFormat.r8g8b8a8UNormIntSRGB,
      );

      _resolveTexture = gpu.gpuContext.createTexture(
        gpu.StorageMode.hostVisible,
        width,
        height,
        sampleCount: 1,
        format: gpu.PixelFormat.r8g8b8a8UNormIntSRGB,
      );
    } else {
      _texture = gpu.gpuContext.createTexture(
        gpu.StorageMode.hostVisible,
        width,
        height,
        format: gpu.PixelFormat.r8g8b8a8UNormIntSRGB,
      );
      _resolveTexture = null;
    }
  }

  ui.Image? draw({
    required ui.Size size,
    required double pixelRatio,
    required fm.MapCamera camera,
    required double tileSize,
  }) {
    if (_layers == null) return null;
    _setupTextures(size, pixelRatio);

    final commandBuffer = gpu.gpuContext.createCommandBuffer();

    final renderTarget = gpu.RenderTarget.singleColor(
      gpu.ColorAttachment(
        texture: _texture!,
        resolveTexture: _resolveTexture,
        clearValue: vm32.Vector4(0, 0, 0, 0),
        storeAction: _resolveTexture != null ? gpu.StoreAction.storeAndMultisampleResolve : gpu.StoreAction.store,
        loadAction: gpu.LoadAction.clear,
      ),
    );

    final pass = commandBuffer.createRenderPass(renderTarget);
    pass.setColorBlendEnable(true);
    pass.setColorBlendEquation(
      gpu.ColorBlendEquation(
        colorBlendOperation: gpu.BlendOperation.add,
        sourceColorBlendFactor: gpu.BlendFactor.one,
        destinationColorBlendFactor: gpu.BlendFactor.oneMinusSourceAlpha,
        alphaBlendOperation: gpu.BlendOperation.add,
        sourceAlphaBlendFactor: gpu.BlendFactor.one,
        destinationAlphaBlendFactor: gpu.BlendFactor.oneMinusSourceAlpha,
      ),
    );

    final renderContext = RenderContext(
      pass: pass,
      size: size,
      pixelRatio: pixelRatio,
      camera: camera,
      unscaledTileSize: tileSize,
      tileScaleCalculator: _tileScaleCalculator!,
      eval: EvaluationContext(geometryType: '', zoom: camera.zoom, locale: Locale(languageCode: 'en')),
    );

    final zoom = camera.zoom;
    for (final layer in _layers!) {
      final specLayer = layer.specLayer;

      if (specLayer.minzoom != null && zoom < specLayer.minzoom!) continue;
      if (specLayer.maxzoom != null && zoom > specLayer.maxzoom!) continue;

      layer.draw(renderContext);
    }

    commandBuffer.submit();
    return (_resolveTexture ?? _texture)!.asImage();
  }
}
