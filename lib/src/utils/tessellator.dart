import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:dart_earcut/dart_earcut.dart' as earcut;
import 'package:flutter_map/flutter_map.dart';
import 'package:gpu_vector_tile_renderer/_vector_tile.dart' as vt;
import 'package:gpu_vector_tile_renderer/src/ffi/earcut.dart';

class Tessellator {
  static List<int> tessellatePolygonFfi(vt.Polygon polygon) {
    return ffiTessellatePolygon(polygon);
  }

  static List<int> tessellatePolygon(vt.Polygon polygon) {
    final vertices = <ui.Offset>[];
    final holeIndices = <int>[];

    vertices.addAll(polygon.exterior.points);

    for (final interiorRing in polygon.interiors) {
      holeIndices.add(vertices.length);
      vertices.addAll(interiorRing.points);
    }

    return earcut.Earcut.triangulateFromPoints(vertices.map((v) => v.toPoint()), holeIndices: holeIndices);
  }

  static Future<List<int>> tessellatePolygonAsync(vt.Polygon polygon) async {
    return SchedulerBinding.instance.scheduleTask(() => tessellatePolygon(polygon), Priority.touch);
  }
}
