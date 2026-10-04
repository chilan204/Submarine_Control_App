import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:submarine_flutter/screens/home/widgets/control/widgets/telemetry_waiting_panel.dart';

void main() {
  testWidgets('telemetry loss leaves recording stop action available',
      (tester) async {
    var stopped = false;
    await tester.pumpWidget(MaterialApp(
      home: TelemetryWaitingPanel(
        isVietnamese: false,
        connected: false,
        recording: true,
        busy: false,
        onStop: () => stopped = true,
      ),
    ));
    await tester.tap(find.text('Stop and discard recording'));
    expect(stopped, isTrue);
  });

  testWidgets('pending teardown cannot be submitted twice', (tester) async {
    var stopped = false;
    await tester.pumpWidget(MaterialApp(
      home: TelemetryWaitingPanel(
        isVietnamese: false,
        connected: false,
        recording: true,
        busy: true,
        onStop: () => stopped = true,
      ),
    ));
    await tester.tap(find.text('Stop and discard recording'));
    expect(stopped, isFalse);
  });
}
