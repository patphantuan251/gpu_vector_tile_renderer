// ignore_for_file: avoid_print

import 'package:flutter_gpu_shaders/build.dart';
import 'package:native_assets_cli/native_assets_cli.dart';

Future<void> main(List<String> args) async {
  await build(args, (config, output) async {
    await buildShaderBundleJson(
      buildConfig: config,
      buildOutput: output,
      manifestFileName: 'lib/compiled_style/streets_dark.shaderbundle.json',
    );
  });
}
