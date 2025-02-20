import 'package:flutter/foundation.dart';
import 'package:flutter_gpu/gpu.dart' as gpu;

/// An abstract class that contains bindings for a shader.
///
/// The bindings are automatically generated from the shader source code using the script in
/// `tool/generate_shaders.dart`.
abstract class ShaderBindings {
  ShaderBindings({required this.shader});

  /// The shader that these bindings are for.
  final gpu.Shader shader;

  /// Uploads the bindings to the GPU.
  void upload(gpu.GpuContext context) {}

  /// Binds the shader to the current pass.
  void bind(gpu.GpuContext context, gpu.RenderPass pass);
}

/// An abstract class that contains bindings for a uniform buffer object.
///
/// The bindings are automatically generated from the shader source code using the script in
/// `tool/generate_shaders.dart`.
abstract class UniformBufferObjectBindings {
  UniformBufferObjectBindings({required this.slot}) : data = ByteData(slot.sizeInBytes!);

  /// The slot in the shader that this UBO is bound to.
  final gpu.UniformSlot slot;

  /// The data that will be uploaded to the GPU.
  final ByteData data;

  /// The length of the UBO data in bytes.
  int get lengthInBytes => data.lengthInBytes;

  /// Whether the data needs to be flushed to the GPU.
  ///
  /// Do not modify this value directly. The [upload] method in the bindings will handle this automatically.
  bool needsFlush = true;
}

/// An abstract class that contains bindings for a vertex shader.
///
/// To upload a vertex shader:
/// - Allocate vertices using `allocateVertices`, passing the number of vertices.
/// - Populate each vertex using the `setVertex` method.
/// - Optionally, allocate indices using `allocateIndices` (or `allocateIndicesDirect`), passing the list of indices.
/// - Upload the vertices to the GPU using the `upload` method.
///
/// When binding the shader, you can use the `setUbos` method to set values for UBOs.
///
/// Vertex and index buffers (and transient UBO buffers) are automatically managed by the bindings.
abstract class VertexShaderBindings extends ShaderBindings {
  VertexShaderBindings({required this.bytesPerVertex, required super.shader});

  /// Number of bytes per vertex.
  final int bytesPerVertex;

  int? vertexCount;
  int? _indexCount;

  ByteData? vertexData;
  ByteData? _indexData;

  gpu.DeviceBuffer? _vertexBuffer;
  gpu.DeviceBuffer? _indexBuffer;

  gpu.BufferView? _vertexBufferView;
  gpu.BufferView? _indexBufferView;

  /// Allocates [vertexCount] vertices for the shader.
  ///
  /// Resets the existing buffer if necessary.
  void allocateVertices(gpu.GpuContext context, int vertexCount) {
    if (vertexCount == this.vertexCount) return;

    this.vertexCount = vertexCount;
    vertexData = ByteData(vertexCount * bytesPerVertex);
    _vertexBuffer = null;
    _vertexBufferView = null;
  }

  /// Allocates the index buffer for the shader using a list of indices.
  ///
  /// This method will always reset the existing index buffer.
  void allocateIndices(gpu.GpuContext context, List<int> indices) {
    allocateIndicesDirect(context, Int32List.fromList(indices));
  }

  /// Allocates the index buffer for the shader using a [Int32List].
  void allocateIndicesDirect(gpu.GpuContext context, Int32List indices) {
    _indexCount = indices.length;
    _indexData = indices.buffer.asByteData();
    _indexBuffer = null;
    _indexBufferView = null;
  }

  @override
  @mustCallSuper
  void upload(gpu.GpuContext context) {
    if (vertexData != null) {
      _vertexBuffer ??= context.createDeviceBuffer(gpu.StorageMode.hostVisible, vertexData!.lengthInBytes);
      _vertexBufferView = gpu.BufferView(_vertexBuffer!, offsetInBytes: 0, lengthInBytes: vertexData!.lengthInBytes);
      _vertexBuffer!.overwrite(vertexData!);
      _vertexBuffer!.flush();
    }

    if (_indexData != null) {
      _indexBuffer ??= context.createDeviceBuffer(gpu.StorageMode.hostVisible, _indexData!.lengthInBytes);
      _indexBufferView = gpu.BufferView(_indexBuffer!, offsetInBytes: 0, lengthInBytes: _indexData!.lengthInBytes);
      _indexBuffer!.overwrite(_indexData!);
      _indexBuffer!.flush();
    }
  }

  @override
  @mustCallSuper
  void bind(gpu.GpuContext context, gpu.RenderPass pass) {
    if (_vertexBufferView != null) {
      pass.bindVertexBuffer(_vertexBufferView!, vertexCount!);
    }

    if (_indexBufferView != null) {
      pass.bindIndexBuffer(_indexBufferView!, gpu.IndexType.int32, _indexCount!);
    }
  }
}

/// An abstract class that contains bindings for a fragment shader.
abstract class FragmentShaderBindings extends ShaderBindings {
  FragmentShaderBindings({required super.shader});

  @override
  void bind(gpu.GpuContext context, gpu.RenderPass pass) {}
}

/// An abstract class that contains bindings for a render pipeline (vertex + fragment).
///
/// After creating a pipeline, you can upload the bindings to the GPU using the `upload` method.
///
/// You can also bind the pipeline to a render pass using the `bind` method.
abstract class RenderPipelineBindings<TVertex extends VertexShaderBindings, TFragment extends FragmentShaderBindings> {
  RenderPipelineBindings({required this.vertex, required this.fragment, required this.ubos});

  final TVertex vertex;
  final TFragment fragment;
  gpu.RenderPipeline? _pipeline;

  /// The UBOs that are bound to this pipeline.
  final List<UniformBufferObjectBindings> ubos;

  gpu.DeviceBuffer? _uboBuffer;
  Map<gpu.UniformSlot, gpu.BufferView>? _uboBufferViews;

  late final bool _hasUbos = ubos.isNotEmpty;
  late final int _totalUboSizeInBytes = ubos.fold(0, (acc, ubo) => acc + ubo.lengthInBytes);

  /// Iterates through all UBOs and calls the callback with the UBO and offset in [_uboBuffer].
  void _iterateUbos(void Function(UniformBufferObjectBindings ubo, int offset) callback) {
    var offset = 0;

    for (final ubo in ubos) {
      callback(ubo, offset);
      offset += ubo.lengthInBytes;
    }
  }

  bool _isReady = false;
  bool get isReady => _isReady;

  /// Uploads the vertex and fragment shader bindings (and UBOs) to the GPU, and creates a render pipeline.
  void upload(gpu.GpuContext context) {
    if (_hasUbos) {
      // Create the UBO buffer if it doesn't exist
      if (_uboBuffer == null) {
        _uboBuffer = context.createDeviceBuffer(gpu.StorageMode.hostVisible, _totalUboSizeInBytes);
        _uboBufferViews = {};

        _iterateUbos((ubo, offset) {
          final bufferView = gpu.BufferView(_uboBuffer!, offsetInBytes: offset, lengthInBytes: ubo.lengthInBytes);
          _uboBufferViews![ubo.slot] = bufferView;
        });
      }

      // Go through all UBOs and upload them
      _iterateUbos((ubo, offset) {
        _uboBuffer!.overwrite(ubo.data, destinationOffsetInBytes: offset);
      });

      // Flush the UBO buffer
      _uboBuffer!.flush();
    }

    vertex.upload(context);
    fragment.upload(context);

    _pipeline = context.createRenderPipeline(vertex.shader, fragment.shader);
    _isReady = true;
  }

  /// Binds the render pipeline (and associated shaders) to the provided render pass.
  void bind(gpu.GpuContext context, gpu.RenderPass pass) {
    if (_pipeline == null) throw Exception('Pipeline has not been uploaded yet');

    if (_hasUbos) {
      var ubosNeededFlush = false;

      // Go through all UBOS and:
      // 1. Overwrite the UBO buffer if flush is needed (and set the flag)
      // 2. Bind the uniform to the pass
      _iterateUbos((ubo, offset) {
        if (ubo.needsFlush) {
          _uboBuffer!.overwrite(ubo.data, destinationOffsetInBytes: offset);
          ubo.needsFlush = false;
          ubosNeededFlush = true;
        }

        final slot = ubo.slot;
        pass.bindUniform(slot, _uboBufferViews![slot]!);
        if (slot.uniformName == 'Tile') {
          pass.bindUniform(fragment.shader.getUniformSlot(slot.uniformName), _uboBufferViews![slot]!);
        }
      });

      // Flush the UBO buffer if necessary
      if (ubosNeededFlush) _uboBuffer!.flush();
    }

    pass.bindPipeline(_pipeline!);

    vertex.bind(context, pass);
    fragment.bind(context, pass);
  }
}
