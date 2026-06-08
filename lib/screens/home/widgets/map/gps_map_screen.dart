import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/translations.dart';
import '../../../../providers/app_provider.dart';
import '../../../../services/telemetry_service.dart';
import '../../../../theme.dart';
import 'widgets/coordinate_bar.dart';
import '../metrics_panel.dart';
import 'widgets/tracking_pill.dart';

class GpsMapScreen extends StatefulWidget {
  const GpsMapScreen({super.key});

  @override
  State<GpsMapScreen> createState() => _GpsMapScreenState();
}

class _GpsMapScreenState extends State<GpsMapScreen> {
  // Submarine state — updated from WebSocket, fallback to simulation
  double _lat = 10.82;
  double _lng = 108.20;
  double _depth = -35;
  double _heading = 60;
  double _speed = 4.2;
  double _pressure = 3.5;

  // Trail — last 40 positions
  final List<LatLng> _trail = [];

  // MapLibre GL
  MapLibreMapController? _mapCtrl;
  bool _mapReady = false;
  Symbol? _submarineSymbol;
  Line? _trailLine;

  // WebSocket telemetry
  late final TelemetryService _telemetry;
  StreamSubscription<TelemetryData>? _dataSub;
  StreamSubscription<bool>? _statusSub;
  bool _wsConnected = false;

  // Goong style URL
  String get _goongStyleUrl {
    final apiKey = dotenv.env['GOONG_MAP_TILES_KEY'] ?? '';
    return 'https://tiles.goong.io/assets/goong_light_v2.json?api_key=$apiKey';
  }

  @override
  void initState() {
    super.initState();

    _telemetry = TelemetryService();
    _telemetry.connect();

    // Listen for real telemetry data from WebSocket
    _dataSub = _telemetry.stream.listen(_onTelemetryData);

    // Track connection status
    _statusSub = _telemetry.statusStream.listen((connected) {
      if (!mounted) return;
      setState(() => _wsConnected = connected);
    });

  }

  @override
  void dispose() {
    _dataSub?.cancel();
    _statusSub?.cancel();
    _telemetry.dispose();
    super.dispose();
  }

  /// Called when the MapLibre map is fully initialized.
  void _onMapCreated(MapLibreMapController controller) {
    _mapCtrl = controller;
  }

  /// Called when the map style is loaded and ready for layers/symbols.
  Future<void> _onStyleLoaded() async {
    _mapReady = true;
    await _addSubmarineImage();
    await _updateMapElements();
  }

  /// Renders the submarine icon widget to a PNG and registers it with the map.
  Future<void> _addSubmarineImage() async {
    const size = 48.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    const cx = size / 2;
    const cy = size / 2;

    canvas.drawCircle(
      const Offset(cx, cy),
      16,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(cx, cy + 2), width: 28, height: 12),
      Paint()..color = AppColors.accent.withValues(alpha: 0.9),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(cx, cy - 4), width: 8, height: 10),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF00cc88),
    );

    canvas.drawCircle(
      const Offset(cx, cy + 2),
      3,
      Paint()..color = AppColors.background,
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    await _mapCtrl?.addImage('submarine-icon', bytes);
  }

  /// Called when a telemetry message arrives from the WebSocket.
  void _onTelemetryData(TelemetryData data) {
    if (!mounted) return;
    setState(() {
      _lat = data.latitude;
      _lng = data.longitude;
      _depth = data.depth;
      _heading = data.heading;
      _speed = data.speed;
      _pressure = data.pressure;
      _trail.add(LatLng(data.latitude, data.longitude));
      if (_trail.length > 40) _trail.removeAt(0);
    });
    _updateMapElements();
  }

  /// Syncs the submarine marker and trail line on the MapLibre map.
  Future<void> _updateMapElements() async {
    if (!_mapReady || _mapCtrl == null) return;

    // Update or create submarine marker
    final subPos = LatLng(_lat, _lng);
    if (_submarineSymbol != null) {
      await _mapCtrl!.updateSymbol(
        _submarineSymbol!,
        SymbolOptions(
          geometry: subPos,
          iconRotate: _heading - 90,
        ),
      );
    } else {
      _submarineSymbol = await _mapCtrl!.addSymbol(
        SymbolOptions(
          geometry: subPos,
          iconImage: 'submarine-icon',
          iconSize: 2.0,
          iconRotate: _heading - 90,
        ),
      );
    }

    // Update or create trail polyline
    if (_trailLine != null) {
      await _mapCtrl!.updateLine(
        _trailLine!,
        LineOptions(lineColor: '#ffa500', geometry: _trail),
      );
    } else {
      _trailLine = await _mapCtrl!.addLine(
        LineOptions(
          geometry: _trail,
          lineColor: '#ffa500',
          lineWidth: 2.0,
          lineOpacity: 0.7,
          // linePattern: 'dash',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppProvider>().t;
    final lang = context.watch<AppProvider>().lang;

    return Column(
      children: [
        CoordinateBar(
          latitude: _lat,
          longitude: _lng,
          currentPositionLabel: t.currentPos,
        ),

        MetricsPanel(
          depth: _depth,
          speed: _speed,
          heading: _heading,
          pressure: _pressure,
          t: t,
        ),

        Expanded(
          child: Stack(
            children: [
              MapLibreMap(
                styleString: _goongStyleUrl,
                initialCameraPosition: const CameraPosition(
                  target: LatLng(10.8, 108.5),
                  zoom: 7,
                ),
                onMapCreated: _onMapCreated,
                onStyleLoadedCallback: _onStyleLoaded,
                compassEnabled: false,
                myLocationEnabled: false,
                trackCameraPosition: true,
              ),

              // Live tracking pill (bottom-left) — shows connection status
              Positioned(
                bottom: 12,
                left: 12,
                child: TrackingPill(
                  isConnected: _wsConnected,
                  liveText: lang == Lang.vi ? 'TRỰC TIẾP' : 'LIVE',
                ),
              ),

              // Goong attribution (bottom-right)
              Positioned(
                bottom: 4,
                right: 8,
                child: Text(
                  '© Goong',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}