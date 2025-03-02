import 'dart:ffi';
import 'dart:isolate';

import 'package:gpu_vector_tile_renderer/src/ffi/bindings.gen.dart' as ffi;
import 'package:gpu_vector_tile_renderer/src/isolates/core/worker_isolate.dart';
import 'package:gpu_vector_tile_renderer/src/isolates/core/worker_isolate_pool.dart';

typedef _TArg = Pointer<ffi.polygon>;
typedef _TReturn = Pointer<ffi.tessellation_result>;

class TesselatorWorkerIsolate extends WorkerIsolate<_TArg, _TReturn> {
  TesselatorWorkerIsolate(super.name, super.commands, super.responses);

  static Future<TesselatorWorkerIsolate> spawn() {
    return WorkerIsolate.spawnWrapper(startRemoteIsolate, TesselatorWorkerIsolate.new);
  }

  static void startRemoteIsolate(SendPort sendPort) {
    return WorkerIsolate.startRemoteIsolateWrapper(sendPort, work);
  }

  static _TReturn work(_TArg arg) {
    return ffi.tessellate_polygon(arg);
  }
}

class TesselatorWorkerIsolatePool extends WorkerIsolatePool<_TArg, _TReturn, TesselatorWorkerIsolate> {
  TesselatorWorkerIsolatePool(int size) : super(size, TesselatorWorkerIsolate.spawn);
}
