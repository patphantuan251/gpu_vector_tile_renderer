import 'dart:convert';
import 'dart:io';

import 'package:gpu_vector_tile_renderer/_spec.dart';
import 'package:gpu_vector_tile_renderer/src/shaders/serializer/parsed_shader.dart';
import 'package:gpu_vector_tile_renderer/src/shaders/serializer/shader_writer.dart';
import 'package:gpu_vector_tile_renderer/src/style_precompiler_2/style_precompiler.dart';

void main(List<String> args) {
  final styleFilePath = 'scratchpad/maptiler-streets-v2.json';
  final outDirectoryPath = 'example/lib/compiled_style';
  final styleFile = File(styleFilePath);
  final outDirectory = Directory(outDirectoryPath);
  final shadersOutDir = Directory('${outDirectory.path}/shaders');
  final shaderBindingOutFile = File('${outDirectory.path}/shader_bindings.gen.dart');
  final layerRenderersOutFile = File('${outDirectory.path}/layer_renderers.gen.dart');

  if (!shadersOutDir.existsSync()) shadersOutDir.createSync(recursive: true);

  final style = Style.fromJson(jsonDecode(styleFile.readAsStringSync()));
  final shaderBundleOutFile = File('${outDirectory.path}/${style.name}.shaderbundle.json');
  final (shaders, shaderBindingsCode, layerRenderersCode, shaderBundleCode) = precompileStyle(style);
  
  for (final shader in shaders) {
    final File file;

    if (shader is ParsedShaderVertex) {
      file = File('${shadersOutDir.path}/${shader.name}.vert');
    } else {
      file = File('${shadersOutDir.path}/${shader.name}.frag');
    }

    file.writeAsStringSync(writeShader(shader));
  }

  shaderBindingOutFile.writeAsStringSync(shaderBindingsCode);
  layerRenderersOutFile.writeAsStringSync(layerRenderersCode);
  shaderBundleOutFile.writeAsStringSync(shaderBundleCode);

  // Dart format
  Process.runSync('dart', ['format', shaderBindingOutFile.path]);
  Process.runSync('dart', ['format', layerRenderersOutFile.path]);
}
