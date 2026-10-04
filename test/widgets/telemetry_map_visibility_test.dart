import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:submarine_flutter/screens/home/widgets/map/widgets/telemetry_map_visibility.dart';

void main() {
  testWidgets('map survives repeated disconnects without showing stale data',
      (tester) async {
    var created = 0;
    var disposed = 0;
    Widget screen(bool hasData) => MaterialApp(
          home: TelemetryMapVisibility(
            hasData: hasData,
            waiting: const Text('Waiting'),
            child: _MapProbe(
              onCreate: () => created++,
              onDispose: () => disposed++,
            ),
          ),
        );

    await tester.pumpWidget(screen(false));
    expect(created, 0);
    expect(find.text('Waiting'), findsOneWidget);

    await tester.pumpWidget(screen(true));
    final originalState = tester.state(find.byType(_MapProbe));
    for (var i = 0; i < 3; i++) {
      await tester.pumpWidget(screen(false));
      expect(find.text('Map'), findsNothing);
      expect(find.text('Waiting'), findsOneWidget);
      expect(disposed, 0);
      await tester.pumpWidget(screen(true));
      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Waiting'), findsNothing);
      expect(tester.state(find.byType(_MapProbe)), same(originalState));
    }
    expect(created, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(disposed, 1);
  });

  testWidgets('map mounts when telemetry is already available', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: TelemetryMapVisibility(
        hasData: true,
        waiting: Text('Waiting'),
        child: Text('Map'),
      ),
    ));
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Waiting'), findsNothing);
  });
}

class _MapProbe extends StatefulWidget {
  const _MapProbe({required this.onCreate, required this.onDispose});
  final VoidCallback onCreate;
  final VoidCallback onDispose;

  @override
  State<_MapProbe> createState() => _MapProbeState();
}

class _MapProbeState extends State<_MapProbe> {
  @override
  void initState() {
    super.initState();
    widget.onCreate();
  }

  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Text('Map');
}
