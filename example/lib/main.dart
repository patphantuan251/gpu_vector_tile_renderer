import 'package:example/vector_tile_layer_demo.dart';
import 'package:flutter/material.dart';
import 'package:gpu_vector_tile_renderer/_shaders.dart';
import 'package:logging/logging.dart';

Future<void> main() async {
  await HotReloadableShaderLibraryBindings.ensureInitialized();

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print(
      '[${record.loggerName}] ${record.level.name}: ${record.time}: ${record.message}',
    );
  });

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
        ),
      ),
      home: VectorTileLayerDemo(),
    ),
  );
}
