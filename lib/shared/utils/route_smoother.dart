import 'package:latlong2/latlong.dart';

/// Helper utility for offline GPS route noise reduction and polyline simplification.
class RouteSmoother {
  /// Applies a 1D/2D Kalman filter to smooth out GPS noise and jitter from raw location coordinates.
  static List<LatLng> kalmanFilter(
    List<LatLng> points, {
    double processNoise = 3.0, // Q: variance of process noise
    double measurementNoise = 15.0, // R: variance of measurement noise (GPS inaccuracy)
  }) {
    if (points.length < 3) return List.from(points);

    final List<LatLng> smoothed = [];

    double lat = points.first.latitude;
    double lng = points.first.longitude;
    double pLat = measurementNoise;
    double pLng = measurementNoise;

    smoothed.add(points.first);

    for (int i = 1; i < points.length; i++) {
      final point = points[i];

      // Time update (prediction)
      pLat = pLat + processNoise;
      pLng = pLng + processNoise;

      // Measurement update (correction)
      final kLat = pLat / (pLat + measurementNoise);
      final kLng = pLng / (pLng + measurementNoise);

      lat = lat + kLat * (point.latitude - lat);
      lng = lng + kLng * (point.longitude - lng);

      pLat = (1 - kLat) * pLat;
      pLng = (1 - kLng) * pLng;

      smoothed.add(LatLng(lat, lng));
    }

    return smoothed;
  }

  /// Implements Ramer-Douglas-Peucker algorithm to simplify a polyline by removing redundant points.
  static List<LatLng> douglasPeucker(List<LatLng> points, double epsilon) {
    if (points.length < 3) return List.from(points);

    double maxDistance = 0.0;
    int index = 0;

    final start = points.first;
    final end = points.last;

    for (int i = 1; i < points.length - 1; i++) {
      final distance = _perpendicularDistance(points[i], start, end);
      if (distance > maxDistance) {
        maxDistance = distance;
        index = i;
      }
    }

    if (maxDistance > epsilon) {
      final recResults1 = douglasPeucker(points.sublist(0, index + 1), epsilon);
      final recResults2 = douglasPeucker(points.sublist(index), epsilon);

      return [...recResults1.sublist(0, recResults1.length - 1), ...recResults2];
    } else {
      return [start, end];
    }
  }

  /// Calculates perpendicular distance from point P to line segment (A, B) in meters approx.
  static double _perpendicularDistance(LatLng p, LatLng a, LatLng b) {
    final dx = b.longitude - a.longitude;
    final dy = b.latitude - a.latitude;

    if (dx == 0 && dy == 0) {
      return _distanceInMeters(p, a);
    }

    final t = ((p.longitude - a.longitude) * dx + (p.latitude - a.latitude) * dy) / (dx * dx + dy * dy);

    if (t < 0) {
      return _distanceInMeters(p, a);
    } else if (t > 1) {
      return _distanceInMeters(p, b);
    }

    final nearest = LatLng(a.latitude + t * dy, a.longitude + t * dx);
    return _distanceInMeters(p, nearest);
  }

  static double _distanceInMeters(LatLng p1, LatLng p2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, p1, p2);
  }

  /// Public entrypoint: Smoothes raw GPS trace using Kalman filtering and Douglas-Peucker reduction.
  static List<LatLng> smoothRoute(List<LatLng> rawPoints, {double epsilonMeters = 5.0}) {
    if (rawPoints.length < 3) return List.from(rawPoints);
    final kalmanPoints = kalmanFilter(rawPoints);
    return douglasPeucker(kalmanPoints, epsilonMeters);
  }
}
