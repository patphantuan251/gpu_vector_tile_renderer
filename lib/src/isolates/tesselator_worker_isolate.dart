import 'dart:isolate';

import 'package:gpu_vector_tile_renderer/_vector_tile.dart' as vt;
import 'package:gpu_vector_tile_renderer/gpu_vector_tile_renderer.dart';
import 'package:gpu_vector_tile_renderer/src/isolates/core/worker_isolate.dart';
import 'package:gpu_vector_tile_renderer/src/isolates/core/worker_isolate_pool.dart';

typedef _TArg = vt.Polygon;
typedef _TReturn = List<int>;

class TesselatorWorkerIsolate extends WorkerIsolate<_TArg, _TReturn> {
  TesselatorWorkerIsolate(super.name, super.commands, super.responses);

  static Future<TesselatorWorkerIsolate> spawn() {
    return WorkerIsolate.spawnWrapper(startRemoteIsolate, TesselatorWorkerIsolate.new);
  }

  static void startRemoteIsolate(SendPort sendPort) {
    return WorkerIsolate.startRemoteIsolateWrapper(sendPort, work);
  }

  static _TReturn work(_TArg arg) {
    return Tessellator.tessellatePolygonFfi(arg);
  }
}

class TesselatorWorkerIsolatePool extends WorkerIsolatePool<_TArg, _TReturn, TesselatorWorkerIsolate> {
  TesselatorWorkerIsolatePool(int size) : super(size, TesselatorWorkerIsolate.spawn);
}
