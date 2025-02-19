import 'package:flutter/material.dart';
import 'package:flutter_gpu/gpu.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gpu_vector_tile_renderer/_controller.dart';
import 'package:gpu_vector_tile_renderer/_renderer.dart';

class FlutterGpuVectorTileLayer extends StatefulWidget {
  const FlutterGpuVectorTileLayer({
    super.key,
    required this.styleProvider,
    this.tileSize = 256.0,
    required this.shaderLibrary,
    required this.createSingleTileLayerRenderer,
  });

  final StyleProviderFn styleProvider;
  final ShaderLibrary shaderLibrary;
  final CreateSingleTileLayerRendererFn createSingleTileLayerRenderer;
  final double tileSize;

  @override
  State<FlutterGpuVectorTileLayer> createState() => FlutterGpuVectorTileLayerState();
}

class FlutterGpuVectorTileLayerState extends State<FlutterGpuVectorTileLayer> with TickerProviderStateMixin {
  late final VectorTileLayerController _controller;
  late final VectorTileLayerRenderOrchestrator _orchestrator;

  @override
  void initState() {
    super.initState();

    _controller = VectorTileLayerController(styleProvider: widget.styleProvider, tickerProvider: this);
    _controller.load();

    _orchestrator = VectorTileLayerRenderOrchestrator(
      controller: _controller,
      shaderLibrary: widget.shaderLibrary,
      createSingleTileLayerRenderer: widget.createSingleTileLayerRenderer,
    );
  }

  @override
  void reassemble() {
    super.reassemble();
    _orchestrator.onReassemble();
  }

  @override
  void dispose() {
    _controller.dispose();
    _orchestrator.dispose();

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final camera = MapCamera.of(context);
    _controller.onCameraChanged(camera, widget.tileSize);
    _orchestrator.onCameraChanged(camera, widget.tileSize);
  }

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);

    return SizedBox.expand(
      child: CustomPaint(
        painter: RenderOrchestratorPainter(
          camera: camera,
          pixelRatio: pixelRatio,
          tileSize: widget.tileSize,
          orchestrator: _orchestrator,
        ),
      ),
    );
  }
}
