double getNearestFloorValue(double value, List<double> stops) {
  for (var i = 0; i < stops.length; i++) {
    if (value < stops[i]) {
      return stops[i];
    }
  }

  return stops.last;
}

double getNearestCeilValue(double value, List<double> stops) {
  for (var i = stops.length - 1; i >= 0; i--) {
    if (value > stops[i]) {
      return stops[i];
    }
  }

  return stops.first;
}
