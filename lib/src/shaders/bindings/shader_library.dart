import 'package:flutter_gpu/gpu.dart' as gpu;

/// Path to the generated shaderbundle file.
const String _kShaderBundlePath = 'build/shaderbundles/flutter_gpu_vector_tile.shaderbundle';

gpu.ShaderLibrary? _shaderLibrary;

/// Retrieves the shader library from the asset bundle.
///
/// The shader library is cached after the first retrieval.
gpu.ShaderLibrary get shaderLibrary {
  if (_shaderLibrary != null) return _shaderLibrary!;

  _shaderLibrary = gpu.ShaderLibrary.fromAsset(_kShaderBundlePath);

  if (_shaderLibrary == null) {
    throw Exception('Failed to load shader library from asset: $_kShaderBundlePath');
  }

  return _shaderLibrary!;
}
