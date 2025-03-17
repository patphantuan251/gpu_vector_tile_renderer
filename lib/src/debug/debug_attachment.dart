import 'package:flutter/foundation.dart';
import 'package:gpu_vector_tile_renderer/_controller.dart';

class DebugAttachment with ChangeNotifier {
  DebugAttachment()
      : layerState = {},
        layerRendererCount = {},
        debugPaintLayers = [];

  final Map<String, bool> layerState;
  final Map<String, int> layerRendererCount;

  final List<String> debugPaintLayers;

  void setup(VectorTileLayerController controller) {
    for (final layer in controller.style.layers) {
      layerState[layer.id] = true;
    }

    notifyListeners();
  }

  void setLayerState(String layerId, bool state) {
    layerState[layerId] = state;
    notifyListeners();
  }

  void setAllLayerState(bool state) {
    for (final layerId in layerState.keys) {
      layerState[layerId] = state;
    }

    notifyListeners();
  }

  void setLayerRendererCount(String layerId, int count) {
    layerRendererCount[layerId] = count;
    notifyListeners();
  }

  void setDebugPaintLayer(String layerId, bool debugPaint) {
    if (debugPaint) {
      debugPaintLayers.add(layerId);
    } else {
      debugPaintLayers.remove(layerId);
    }

    notifyListeners();
  }
}
