import 'dart:ui' as ui;

import 'package:flutter_gpu/gpu.dart';
import 'package:gpu_vector_tile_renderer/_renderer.dart';
import 'package:gpu_vector_tile_renderer/_spec.dart' as spec;
import 'package:gpu_vector_tile_renderer/_utils.dart';
import 'package:gpu_vector_tile_renderer/_vector_tile.dart' as vt;
import 'package:gpu_vector_tile_renderer/src/shaders/bindings/shader_bindings.dart';
import 'package:gpu_vector_tile_renderer/src/spec/spec.dart';
import 'package:vector_math/vector_math_64.dart';

abstract class FillLayerRenderer extends SingleTileLayerRenderer<spec.LayerFill> {
  FillLayerRenderer({
    required super.coordinates,
    required super.container,
    required super.specLayer,
    required super.vtLayer,
  });

  RenderPipelineBindings get pipeline;

  int setFeatureVertices(EvaluationContext eval, vt.PolygonFeature feature, int vertexIndex);
  void setUniforms(
    RenderContext context,
    Matrix4 cameraWorldToGl,
    double cameraZoom,
    Matrix4 tileLocalToWorld,
    double tileSize,
    double tileExtent,
    double tileOpacity,
  );

  @override
  void prepare(PrepareContext context) {
    final features = filterFeatures<vt.PolygonFeature>(vtLayer, specLayer, context.eval);
    if (features.isEmpty) return;

    var vertexCount = 0;
    final indicesList = <int>[];

    for (final feature in features) {
      for (final polygon in feature.polygons) vertexCount += polygon.vertexCount;
    }

    // Allocate vertices
    pipeline.vertex.allocateVertices(gpuContext, vertexCount);

    var vertexIndex = 0;
    for (final feature in features) {
      final featureEval = context.eval.extendWith(properties: feature.attributes);
      final polygons = feature.polygons;

      for (final polygon in polygons) {
        final indices = Tessellator.tessellatePolygon(polygon);
        indicesList.addAll(indices);
      }

      vertexIndex = setFeatureVertices(featureEval, feature, vertexIndex);
    }

    pipeline.vertex.allocateIndices(gpuContext, indicesList);
    pipeline.upload(gpuContext);
  }

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
      tileLocalToWorld,
      tileSize,
      vtLayer.extent.toDouble(),
      container.opacityAnimation.value,
    );

    context.setTileScissor(context.pass, coordinates);
    pipeline.bind(gpuContext, context.pass);

    context.pass.draw();
    context.pass.clearBindings();
  }
}
