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
          return specLayer.filter!(evalContext.forFeature(feature));
        } catch (e) {
          return false;
        }
      }).toList();

  if (sortKey != null) {
    filteredFeatures.sort((a, b) {
      final sortKeyA = sortKey.evaluate(evalContext.forFeature(a));
      final sortKeyB = sortKey.evaluate(evalContext.forFeature(b));

      return sortKeyA.compareTo(sortKeyB);
    });
  }

  return filteredFeatures;
}

extension ForFeature on spec.EvaluationContext {
  spec.EvaluationContext forFeature(vt.Feature feature) {
    return copyWith(
      properties: feature.attributes,
      // geometryType: switch (feature) {
      //   vt.PointFeature _ => 'Point',
      //   vt.LineStringFeature _ => 'LineString',
      //   vt.PolygonFeature _ => 'Polygon',
      //   _ => throw UnimplementedError('Unsupported feature type: ${feature.runtimeType}'),
      // },
    );
  }
}
