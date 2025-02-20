/// A template method used by `style_precompiler.dart` for generating the [setFeatureVertices] code.
List<String> fillLayerRendererSetFeatureVerticesGenerator(List<String> vertexEval, List<String> vertexSetters) {
  return [
    'int setFeatureVertices(spec.EvaluationContext eval, vt.PolygonFeature feature, int index) {',
    '  final paint = specLayer.paint;',
    ...vertexEval.map((v) => '      $v'),
    '',
    '  for (final polygon in feature.polygons) {',
    '    for (final vertex in polygon.vertices) {',
    '      pipeline.vertex.setVertex(',
    '        index,',
    '        position: vertex.vec2,',
    ...vertexSetters.map((v) => '        $v,'),
    '      );',
    '      index += 1;',
    '    }',
    '  }',
    '',
    '  return index;',
    '}',
  ];
}

/// A template method used by `style_precompiler.dart` for generating the `setUniforms` code.
List<String> fillLayerRendererSetUniformsGenerator(List<String> uniformEval, List<String> uniformSetters) {
  return [
    'void setUniforms(',
    '  RenderContext context,',
    '  Matrix4 cameraWorldToGl,',
    '  double cameraZoom,',
    '  Matrix4 tileLocalToWorld,',
    '  double tileSize,',
    '  double tileExtent,',
    '  double tileOpacity,',
    ') {',
    '  final eval = context.eval;',
    ...uniformEval.map((v) => '  $v'),
    '',
    '  pipeline.setUbos(',
    '    cameraWorldToGl: cameraWorldToGl,',
    '    cameraZoom: cameraZoom,',
    '    tileLocalToWorld: tileLocalToWorld,',
    '    tileSize: tileSize,',
    '    tileExtent: tileExtent,',
    '    tileOpacity: tileOpacity,',
    ...uniformSetters.map((v) => '        $v,'),
    '  );',
    '}',
  ];
}
