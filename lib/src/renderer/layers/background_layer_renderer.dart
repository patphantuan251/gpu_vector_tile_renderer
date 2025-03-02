import 'dart:ui' as ui;

import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:gpu_vector_tile_renderer/_renderer.dart';
import 'package:gpu_vector_tile_renderer/_spec.dart' as spec;
import 'package:gpu_vector_tile_renderer/src/shaders/bindings/shader_bindings.dart';
import 'package:vector_math/vector_math_64.dart';

abstract class $BackgroundLayerRenderer extends SingleTileLayerRenderer<spec.LayerBackground> {
  $BackgroundLayerRenderer({
    required super.coordinates,
    required super.container,
    required super.specLayer,
    required super.vtLayer,
  });

  RenderPipelineBindings get pipeline;

  void setVertices();

  @override
  void prepare(PrepareContext context) {
    pipeline.vertex.allocateVertices(gpu.gpuContext, 4);
    pipeline.vertex.allocateIndices(gpu.gpuContext, [0, 1, 2, 0, 2, 3]);
    setVertices();
    pipeline.upload(gpu.gpuContext);
  }

  void setUniforms(
    RenderContext context,
    Matrix4 cameraWorldToGl,
    double cameraZoom,
    double pixelRatio,
    Matrix4 tileLocalToWorld,
    double tileSize,
    double tileExtent,
    double tileOpacity,
  );

  @override
  void draw(RenderContext context) {
    if (!pipeline.isReady) return;

    final tileSize = context.getScaledTileSize(coordinates);
    final origin = ui.Offset(coordinates.x * tileSize, coordinates.y * tileSize);
    final tileLocalToWorld = Matrix4.identity()..translate(origin.dx, origin.dy);

    setUniforms(
      context,
      context.worldToGl,
      context.camera.zoom,
      context.pixelRatio,
      tileLocalToWorld,
      tileSize,
      vtLayer.extent.toDouble(),
      container.opacityAnimation.value,
    );

    context.setTileScissor(context.pass, coordinates);
    pipeline.bind(gpu.gpuContext, context.pass);

    context.pass.draw();
    context.pass.clearBindings();
  }
}
