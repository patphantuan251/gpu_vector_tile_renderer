double getNearestCeilValue(double value, List<double> stops) {
  for (final stop in stops) {
    if (value <= stop) return stop;
  }

  return stops.last;
}

double getNearestFloorValue(double value, List<double> stops) {
  for (final stop in stops.reversed) {
    if (value >= stop) return stop;
  }

  return stops.first;
}
