import 'dart:convert';
import 'dart:io';

import 'package:gpu_vector_tile_renderer/_spec.dart';
import 'package:gpu_vector_tile_renderer/_style_compiler.dart';
import 'package:gpu_vector_tile_renderer/src/shaders/bindings/shader_bindings_generator.dart';
import 'package:gpu_vector_tile_renderer/src/shaders/serializer/parsed_shader.dart';
import 'package:gpu_vector_tile_renderer/src/shaders/serializer/shader_writer.dart';
import 'package:gpu_vector_tile_renderer/src/style_precompiler/layer_renderer_generator.dart';
import 'package:gpu_vector_tile_renderer/src/utils/string_utils.dart';

void main(List<String> args) {
  final styleFilePath = 'scratchpad/maptiler-streets-v2.json';
  final outDirectoryPath = 'scratchpad';
  final styleFile = File(styleFilePath);
  final outDirectory = Directory(outDirectoryPath);
  final shadersOutDir = Directory('${outDirectory.path}/shaders');
  final shaderBindingOutFile = File('${outDirectory.path}/shader_bindings.gen.dart');
  final layerRenderersOutFile = File('${outDirectory.path}/layer_renderers.gen.dart');

  if (!shadersOutDir.existsSync()) shadersOutDir.createSync(recursive: true);

  final style = Style.fromJson(jsonDecode(styleFile.readAsStringSync()));
  final compiledLayerShaders = precompileStyle(style);

  final shaders = <ParsedShader>[];

  for (final entry in compiledLayerShaders.entries) {
    final layerName = entry.key;
    final shaderName = toSnakeCase(layerName);
    final (vertexShader, fragmentShader) = entry.value;
    shaders.addAll([vertexShader, fragmentShader]);

    final vertexShaderFile = File('${shadersOutDir.path}/$shaderName.vert');
    final fragmentShaderFile = File('${shadersOutDir.path}/$shaderName.frag');

    vertexShaderFile.writeAsStringSync(writeShader(vertexShader));
    fragmentShaderFile.writeAsStringSync(writeShader(fragmentShader));
  }

  final bindings = generateShaderBindings(shaders);
  shaderBindingOutFile.writeAsStringSync(bindings);

  final layerRenderers = generateLayerRenderers(style.layers, shaders);
  layerRenderersOutFile.writeAsStringSync(layerRenderers);

  // Dart format
  Process.runSync('dart', ['format', shaderBindingOutFile.path]);
  Process.runSync('dart', ['format', layerRenderersOutFile.path]);
}
