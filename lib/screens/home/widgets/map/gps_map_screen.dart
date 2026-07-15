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
  // Submarine state — updated from WebSocket
  bool _hasData = false;
  double _lat = 0.0;
  double _lng = 0.0;
  double _depth = 0.0;
  double _heading = 0.0;
  double _speed = 0.0;
  double _pressure = 0.0;

  // Trail — last 40 positions
  final List<LatLng> _trail = [];

  bool _showPopup = false;

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

    // Listen for real telemetry data from WebSocket
    _dataSub = _telemetry.stream.listen(_onTelemetryData);

    // Track connection status
    _statusSub = _telemetry.statusStream.listen((connected) {
      if (!mounted) return;
      setState(() {
        _wsConnected = connected;
        if (!connected) {
          _hasData = false;
        }
      });
    });

    // Start connection AFTER subscribing so we don't miss the first 'true' event
    _telemetry.connect();
  }

  @override
  void dispose() {
    _dataSub?.cancel();
    _statusSub?.cancel();
    _telemetry.disconnect();
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
    // Create a submarine icon as a simple painted image
    const size = 48.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final cx = size / 2;
    final cy = size / 2;

    // Sonar ring
    canvas.drawCircle(
      Offset(cx, cy),
      16,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Hull
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 2), width: 28, height: 12),
      Paint()..color = AppColors.accent.withValues(alpha: 0.9),
    );

    // Conning tower
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy - 4), width: 8, height: 10),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF00cc88),
    );

    // Center dot
    canvas.drawCircle(
      Offset(cx, cy + 2),
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
      _hasData = true;
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
          iconSize: 1.0,
          iconRotate: _heading - 90,
        ),
      );
    }

    // Update or create trail polyline
    if (_trailLine != null) {
      await _mapCtrl!.updateLine(
        _trailLine!,
        LineOptions(lineColor: '#FF3D00', geometry: _trail),
      );
    } else {
      _trailLine = await _mapCtrl!.addLine(
        LineOptions(
          geometry: _trail,
          lineColor: '#FF3D00',
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

    if (!_hasData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.accent),
            const SizedBox(height: 16),
            Text(
              lang == Lang.vi ? 'Đang chờ dữ liệu tàu ngầm...' : 'Waiting for submarine data...',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _wsConnected 
                  ? (lang == Lang.vi ? 'Trạng thái: Đã kết nối máy chủ' : 'Status: Connected to server')
                  : (lang == Lang.vi ? 'Trạng thái: Đang kết nối...' : 'Status: Connecting...'),
              style: TextStyle(
                color: _wsConnected ? AppColors.accent : AppColors.amber,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

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
                initialCameraPosition: CameraPosition(
                  target: LatLng(_lat, _lng),
                  zoom: 7,
                ),
                onMapCreated: _onMapCreated,
                onStyleLoadedCallback: _onStyleLoaded,
                onMapClick: (_, __) => setState(() => _showPopup = false),
                compassEnabled: false,
                myLocationEnabled: false,
                trackCameraPosition: true,
              ),

              // Popup has been removed upstream, so no SubmarinePopup here

              // Tap target for popup toggle on map area
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onDoubleTap: () => setState(() => _showPopup = !_showPopup),
                  child: const SizedBox.shrink(),
                ),
              ),

              // Live tracking pill (bottom-left) — shows connection status
              Positioned(
                bottom: 12,
                left: 12,
                child: TrackingPill(
                  isConnected: _wsConnected,
                  liveText: _wsConnected 
                      ? (lang == Lang.vi ? 'TRỰC TIẾP' : 'LIVE')
                      : (lang == Lang.vi ? 'MẤT KẾT NỐI' : 'DISCONNECTED'),
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