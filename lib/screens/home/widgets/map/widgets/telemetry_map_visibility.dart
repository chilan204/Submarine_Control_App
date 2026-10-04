import 'package:flutter/widgets.dart';

/// Keep the native map alive across telemetry gaps, but never show stale data.
class TelemetryMapVisibility extends StatefulWidget {
  const TelemetryMapVisibility({
    super.key,
    required this.hasData,
    required this.waiting,
    required this.child,
  });

  final bool hasData;
  final Widget waiting;
  final Widget child;

  @override
  State<TelemetryMapVisibility> createState() => _TelemetryMapVisibilityState();
}

class _TelemetryMapVisibilityState extends State<TelemetryMapVisibility> {
  bool _hasReceivedData = false;

  @override
  void initState() {
    super.initState();
    _hasReceivedData = widget.hasData;
  }

  @override
  void didUpdateWidget(TelemetryMapVisibility oldWidget) {
    super.didUpdateWidget(oldWidget);
    _hasReceivedData = _hasReceivedData || widget.hasData;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_hasReceivedData)
          Offstage(offstage: !widget.hasData, child: widget.child),
        if (!widget.hasData) widget.waiting,
      ],
    );
  }
}
