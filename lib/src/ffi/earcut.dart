import 'dart:ffi';
import 'dart:ui' as ui;

import 'package:ffi/ffi.dart';

import 'bindings.gen.dart' as bindings;
import 'package:gpu_vector_tile_renderer/gpu_vector_tile_renderer.dart' as vt;

List<int> ffiTessellatePolygon(vt.Polygon polygon) {
  return withZoneArena(() {
    Pointer<bindings.point> _allocPoints(List<ui.Offset> points) {
      final pointsPtr = zoneArena<bindings.point>(points.length);

      for (var i = 0; i < points.length; i++) {
        pointsPtr[i].x = points[i].dx;
        pointsPtr[i].y = points[i].dy;
      }

      return pointsPtr;
    }

    Pointer<bindings.ring> _allocRing(vt.Ring ring) {
      final points = _allocPoints(ring.points);
      final count = ring.points.length;

      final ringPtr = zoneArena<bindings.ring>();
      ringPtr.ref.points = points;
      ringPtr.ref.count = count;

      return ringPtr;
    }

    Pointer<bindings.polygon> _allocPolygon(vt.Polygon polygon) {
      final polygonPtr = zoneArena<bindings.polygon>();

      // Exterior
      final exteriorPtr = _allocRing(polygon.exterior);
      polygonPtr.ref.exterior = exteriorPtr.ref;

      // Interiors
      if (polygon.interiors.isNotEmpty) {
        final interiorsPtr = zoneArena<bindings.ring>(polygon.interiors.length);

        for (var i = 0; i < polygon.interiors.length; i++) {
          interiorsPtr[i] = _allocRing(polygon.interiors[i]).ref;
        }

        polygonPtr.ref.interiors = interiorsPtr;
        polygonPtr.ref.interior_count = polygon.interiors.length;
      } else {
        polygonPtr.ref.interiors = nullptr;
        polygonPtr.ref.interior_count = 0;
      }

      return polygonPtr;
    }

    final polygonPtr = _allocPolygon(polygon);
    final resultPtr = bindings.tessellate_polygon(polygonPtr);

    final indexCount = resultPtr.ref.count;
    final indexPtr = resultPtr.ref.indices;
    final indices = List<int>.generate(indexCount, (i) => indexPtr[i]);

    bindings.free_tessellation_result(resultPtr);
    return indices;
  });
}
