
import 'package:gpu_vector_tile_renderer/_spec.dart' as spec;

/// A function that provides a style.
typedef StyleProviderFn = Future<spec.Style> Function();

/// A function that provides a style from a JSON object.
Future<spec.Style> Function() jsonStyleProvider(Map<String, dynamic> json) {
  return () async => spec.Style.fromJson(json);
}
