import 'package:gpu_vector_tile_renderer/_spec.dart' as spec;
import 'package:gpu_vector_tile_renderer/_vector_tile.dart' as vt;
import 'package:gpu_vector_tile_renderer/gpu_vector_tile_renderer.dart';

/// Filters features of a [vt.Layer] based on a [spec.Layer] filter.
///
/// Also allows to specify a list of allowed feature types.
List<T> filterFeatures<T extends vt.Feature>(
  vt.Layer vtLayer,
  spec.Layer specLayer,
  spec.EvaluationContext evalContext, {
  Property<num>? sortKey,
  List<Type>? allowedFeatures,
}) {
  final filteredFeatures =
      vtLayer.features.whereType<T>().where((feature) {
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

  if (sortKey != null) {
    filteredFeatures.sort((a, b) {
      final evalA = evalContext.extendWith(properties: a.attributes);
      final evalB = evalContext.extendWith(properties: b.attributes);

      final sortKeyA = sortKey.evaluate(evalA);
      final sortKeyB = sortKey.evaluate(evalB);

      return sortKeyA.compareTo(sortKeyB);
    });
  }

  return filteredFeatures;
}
