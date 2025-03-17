import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gpu_vector_tile_renderer/_controller.dart';
import 'package:gpu_vector_tile_renderer/_renderer.dart';
import 'package:gpu_vector_tile_renderer/_shaders.dart';

class FlutterGpuVectorTileLayer extends StatefulWidget {
  const FlutterGpuVectorTileLayer({
    super.key,
    required this.styleProvider,
    this.tileSize = 256.0,
    required this.shaderLibraryProvider,
    required this.createSingleTileLayerRenderer,
    this.enableRender = true,
  });

  final StyleProviderFn styleProvider;
  final ShaderLibraryProvider shaderLibraryProvider;
  final CreateSingleTileLayerRendererFn createSingleTileLayerRenderer;
  final double tileSize;
  final bool enableRender; // Temporary!

  @override
  State<FlutterGpuVectorTileLayer> createState() => FlutterGpuVectorTileLayerState();
}

class FlutterGpuVectorTileLayerState extends State<FlutterGpuVectorTileLayer> with TickerProviderStateMixin {
  late final VectorTileLayerController controller;
  late final VectorTileLayerRenderOrchestrator orchestrator;

  @override
  void initState() {
    super.initState();

    controller = VectorTileLayerController(styleProvider: widget.styleProvider, tickerProvider: this);
    controller.load();

    orchestrator = VectorTileLayerRenderOrchestrator(
      controller: controller,
      shaderLibraryProvider: widget.shaderLibraryProvider,
      createSingleTileLayerRenderer: widget.createSingleTileLayerRenderer,
    );
  }

  @override
  void reassemble() {
    super.reassemble();
    controller.onReassemble();
  }

  @override
  void dispose() {
    controller.dispose();
    orchestrator.dispose();

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final camera = MapCamera.of(context);
    controller.onCameraChanged(camera, widget.tileSize);
    orchestrator.onCameraChanged(camera, widget.tileSize);
  }

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.enableRender)
            CustomPaint(
              painter: RenderOrchestratorPainter(
                camera: camera,
                pixelRatio: pixelRatio,
                tileSize: widget.tileSize,
                orchestrator: orchestrator,
              ),
            ),
        ],
      ),
    );
  }
}
