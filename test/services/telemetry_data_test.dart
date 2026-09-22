import 'package:flutter_test/flutter_test.dart';
import 'package:submarine_flutter/services/telemetry_service.dart';

void main() {
  test('parses telemetry and supplies optional defaults', () {
    final data = TelemetryData.fromJson({
      'latitude': 10.25,
      'longitude': 106.75,
    });

    expect(data.latitude, 10.25);
    expect(data.longitude, 106.75);
    expect(data.depth, 0);
    expect(data.heading, 0);
    expect(data.speed, 0);
    expect(data.pressure, 0);
  });

  test('rejects telemetry without required coordinates', () {
    expect(
      () => TelemetryData.fromJson({'depth': 4}),
      throwsA(isA<TypeError>()),
    );
  });
}
