import 'package:gpu_vector_tile_renderer/_spec.dart' as spec;
import 'package:gpu_vector_tile_renderer/_vector_tile.dart' as vt;

/// Filters features of a [vt.Layer] based on a [spec.Layer] filter.
///
/// Also allows to specify a list of allowed feature types.
List<T> filterFeatures<T extends vt.Feature>(
  vt.Layer vtLayer,
  spec.Layer specLayer,
  spec.EvaluationContext evalContext, {
  List<Type>? allowedFeatures,
}) {
  return vtLayer.features.whereType<T>().where((feature) {
    if (allowedFeatures != null) {
      if (!allowedFeatures.contains(feature.runtimeType)) return false;
    }

    if (specLayer.filter == null) return true;

    try {
      return specLayer.filter!(evalContext.extendWith(properties: feature.attributes));
    } catch (e) {
      return false;
    }
  }).toList();
}
