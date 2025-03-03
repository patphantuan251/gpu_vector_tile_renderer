// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_gpu_shaders/environment.dart';
import 'package:gpu_vector_tile_renderer/_spec.dart';
import 'package:gpu_vector_tile_renderer/src/shaders/serializer/parsed_shader.dart';
import 'package:gpu_vector_tile_renderer/src/shaders/serializer/shader_writer.dart';
import 'package:gpu_vector_tile_renderer/src/style_precompiler_2/style_precompiler.dart';

Future<void> main(List<String> args) async {
  // Args: `compile_style.dart <style_file_path> <out_directory_path>`
  // For now, those are hardcoded.
  final styleFilePath = 'scratchpad/maptiler-streets-v2.json';
  final outDirectoryPath = 'example/lib/compiled_style';

  // Suffix used for shader hot-reload.
  final hotReloadSuffix = Random().nextInt(1000000).toRadixString(16);

  final styleFileName = styleFilePath.split('/').last.split('.').first;

  print('Compiling style: $styleFilePath, output: $outDirectoryPath, using hot reload suffix: $hotReloadSuffix');

  final tempDir = Directory.systemTemp.createTempSync('gpu_vector_tile_renderer');
  print('- Created temp directory: ${tempDir.absolute.path}');

  final styleFile = File(styleFilePath);
  final outDirectory = Directory(outDirectoryPath);

  final style = Style.fromJson(jsonDecode(styleFile.readAsStringSync()));
  print('- Read style file: ${style.name}, layers: ${style.layers.length}');

  final (shaders, rendererCode, shaderBundleCode) = precompileStyle(
    styleFileName,
    style,
    hotReloadSuffix: hotReloadSuffix,
  );

  print('- Precompiled style: ${shaders.length} shaders');

  for (final shader in shaders) {
    final File file;

    if (shader is ParsedShaderVertex) {
      file = File('${tempDir.path}/${shader.name}.vert');
    } else {
      file = File('${tempDir.path}/${shader.name}.frag');
    }

    file.writeAsStringSync(writeShader(shader));
  }

  print('- Wrote shaders to temp directory');

  final impellercExec = await findImpellerC();
  final shaderbundleOutFile = File('${outDirectory.path}/$styleFileName.shaderbundle');

  final impellercArgs = [
    '--sl=${shaderbundleOutFile.absolute.path}',
    '--shader-bundle=$shaderBundleCode',
  ];

  print('- Starting shader compilation, impellerc: ${impellercExec.toFilePath()}');
  final impellerc = Process.runSync(impellercExec.toFilePath(), impellercArgs, workingDirectory: tempDir.path);
  if (impellerc.exitCode != 0) {
    throw Exception('Failed to build shader bundle: ${impellerc.stderr}\n${impellerc.stdout}');
  }

  print('- Shader compilation complete, shaderbundle written to ${shaderbundleOutFile.absolute.path}');

  final dartRenderersOutFile = File('${outDirectory.path}/$styleFileName.gen.dart');
  dartRenderersOutFile.writeAsStringSync(rendererCode, flush: true);
  print('- Wrote Dart renderers to ${dartRenderersOutFile.absolute.path}');

  print('- Formatting');
  final dartfmt = Process.runSync('dart', ['format', dartRenderersOutFile.absolute.path]);
  if (dartfmt.exitCode != 0) {
    throw Exception('Failed to format Dart renderers: ${dartfmt.stderr}\n${dartfmt.stdout}');
  }
}
