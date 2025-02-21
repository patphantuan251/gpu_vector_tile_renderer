import 'dart:ffi';
import 'dart:ui' as ui;

import 'package:ffi/ffi.dart';

import 'bindings.gen.dart' as bindings;
import 'package:gpu_vector_tile_renderer/gpu_vector_tile_renderer.dart' as vt;

Pointer<bindings.point> allocPoints(List<ui.Offset> points) {
  final pointsPtr = zoneArena<bindings.point>(points.length);

  for (var i = 0; i < points.length; i++) {
    pointsPtr[i].x = points[i].dx;
    pointsPtr[i].y = points[i].dy;
  }

  return pointsPtr;
}

Pointer<bindings.ring> allocRing(vt.Ring ring) {
  final points = allocPoints(ring.points);
  final count = ring.points.length;

  final ringPtr = zoneArena<bindings.ring>();
  ringPtr.ref.points = points;
  ringPtr.ref.count = count;

  return ringPtr;
}

Pointer<bindings.polygon> allocPolygon(vt.Polygon polygon) {
  final polygonPtr = zoneArena<bindings.polygon>();

  // Exterior
  final exteriorPtr = allocRing(polygon.exterior);
  polygonPtr.ref.exterior = exteriorPtr.ref;

  // Interiors
  if (polygon.interiors.isNotEmpty) {
    final interiorsPtr = zoneArena<bindings.ring>(polygon.interiors.length);

    for (var i = 0; i < polygon.interiors.length; i++) {
      interiorsPtr[i] = allocRing(polygon.interiors[i]).ref;
    }

    polygonPtr.ref.interiors = interiorsPtr;
    polygonPtr.ref.interior_count = polygon.interiors.length;
  } else {
    polygonPtr.ref.interiors = nullptr;
    polygonPtr.ref.interior_count = 0;
  }

  return polygonPtr;
}
