import 'dart:async';

import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:gpu_vector_tile_renderer/_renderer.dart';
import 'package:gpu_vector_tile_renderer/_spec.dart' as spec;
import 'package:gpu_vector_tile_renderer/src/shaders/bindings/shader_bindings.dart';
import 'package:gpu_vector_tile_renderer/src/shaders/bindings/shader_bindings_utils.dart';
import 'package:vector_math/vector_math_64.dart';

/// Generated UBO bindings for `BackgroundUbo`
class BackgroundUbo extends UniformBufferObjectBindings {
  BackgroundUbo(gpu.Shader shader)
    : super(slot: shader.getUniformSlot('BackgroundUbo'));

  void set({required Vector4 color, required double opacity}) {
    set_vec4(get_member_offset(slot, 'color'), data, color);
    set_float(get_member_offset(slot, 'opacity'), data, opacity);
    needsFlush = true;
  }
}

/// Generated bindings for the vertex shader `background`
class BackgroundVertexShaderBindings extends VertexShaderBindings {
  BackgroundVertexShaderBindings(gpu.ShaderLibrary shaderLibrary)
    : super(bytesPerVertex: 8, shader: shaderLibrary['background_vert']!);

  /// Sets attributes for a vertex at [index].
  ///
  /// Ensure that [allocateVertices] has been called before calling this method.
  void setVertex(int index, {required Vector2 position}) {
    final offset = index * bytesPerVertex;

    set_vec2(offset + 0, vertexData!, position);
  }
}

/// Generated bindings for the fragment shader `background`
class BackgroundFragmentShaderBindings extends FragmentShaderBindings {
  BackgroundFragmentShaderBindings(gpu.ShaderLibrary shaderLibrary)
    : super(shader: shaderLibrary['background_frag']!);
}

/// Generated bindings for the render pipeline `background`
class BackgroundRenderPipelineBindings
    extends
        RenderPipelineBindings<
          BackgroundVertexShaderBindings,
          BackgroundFragmentShaderBindings
        > {
  BackgroundRenderPipelineBindings(gpu.ShaderLibrary shaderLibrary)
    : super(
        vertex: BackgroundVertexShaderBindings(shaderLibrary),
        fragment: BackgroundFragmentShaderBindings(shaderLibrary),
        ubos: [BackgroundUbo(shaderLibrary['background_vert']!)],
      );

  late final BackgroundUbo backgroundUbo = ubos[0] as BackgroundUbo;

  /// Sets the UBOs for this shader.
  void setUbos({
    required Vector4 backgroundUboColor,
    required double backgroundUboOpacity,
  }) {
    backgroundUbo.set(color: backgroundUboColor, opacity: backgroundUboOpacity);
  }
}

class BackgroundLayerRenderer extends LayerRenderer<spec.LayerBackground> {
  BackgroundLayerRenderer({
    required gpu.ShaderLibrary shaderLibrary,
    required super.orchestrator,
    required super.specLayer,
  }): pipeline = BackgroundRenderPipelineBindings(shaderLibrary);

  final BackgroundRenderPipelineBindings pipeline;

  @override
  void prepare(PrepareContext context) {
    pipeline.vertex.allocateVertices(gpu.gpuContext, 4);
    pipeline.vertex.allocateIndices(gpu.gpuContext, [0, 1, 2, 0, 2, 3]);

    pipeline.vertex.setVertex(0, position: Vector2(-1, -1));
    pipeline.vertex.setVertex(1, position: Vector2(1, -1));
    pipeline.vertex.setVertex(2, position: Vector2(1, 1));
    pipeline.vertex.setVertex(3, position: Vector2(-1, 1));

    pipeline.upload(gpu.gpuContext);
  }

  @override
  void draw(RenderContext context) {
    if (!pipeline.isReady) return;

    final paint = specLayer.paint;

    final color = paint.backgroundColor.evaluate(context.eval);
    final opacity = paint.backgroundOpacity.evaluate(context.eval);

    pipeline.setUbos(
      backgroundUboColor: color.vec,
      backgroundUboOpacity: opacity.toDouble(),
    );

    pipeline.bind(gpu.gpuContext, context.pass);
    context.pass.draw();
    context.pass.clearBindings();
  }
}
