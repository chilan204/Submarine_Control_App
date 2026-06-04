import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../../translations/translations.dart';
import '../../../../providers/app_provider.dart';
import '../../../../services/telemetry_service.dart';
import '../../../../theme.dart';
import 'widgets/submarine_popup.dart';
import 'widgets/coordinate_bar.dart';
import '../metrics_panel.dart';
import 'widgets/tracking_pill.dart';
import 'widgets/submarine_icon.dart';

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
  double _pressure = 100.0;

  // Trail — last 40 positions
  final List<LatLng> _trail = [
    LatLng(10.70, 107.9),
    LatLng(10.74, 108.0),
    LatLng(10.78, 108.1),
    LatLng(10.82, 108.2),
  ];

  bool _showPopup = false;
  Timer? _fallbackTimer;
  final MapController _mapCtrl = MapController();

  // WebSocket telemetry
  late final TelemetryService _telemetry;
  StreamSubscription<TelemetryData>? _dataSub;
  StreamSubscription<bool>? _statusSub;
  bool _wsConnected = false;

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

      if (connected) {
        // WebSocket connected — stop fallback simulation
        _fallbackTimer?.cancel();
        _fallbackTimer = null;
      } else {
        // WebSocket disconnected — start fallback simulation
        _startFallbackSimulation();
      }
    });

    // Start fallback simulation until WebSocket connects
    _startFallbackSimulation();
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _dataSub?.cancel();
    _statusSub?.cancel();
    _telemetry.dispose();
    super.dispose();
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
  }

  /// Fallback simulation when WebSocket is not available.
  void _startFallbackSimulation() {
    if (_fallbackTimer != null) return;
    _fallbackTimer = Timer.periodic(const Duration(seconds: 2), (_) => _moveSub());
  }

  void _moveSub() {
    if (!mounted) return;
    final rad = (_heading * math.pi) / 180;
    var newLat = _lat + math.cos(rad) * 0.003;
    var newLng = _lng + math.sin(rad) * 0.003;
    // var newHeading = _heading;

    // // Bounce at boundary — mirrors the React heading flip logic
    // if (newLat > 12 || newLat < 9) newHeading = (newHeading + 180) % 360;
    // if (newLng > 110 || newLng < 106) newHeading = (360 - newHeading + 180) % 360;

    setState(() {
      _lat = newLat;
      _lng = newLng;
      // _heading = newHeading;
      _trail.add(LatLng(newLat, newLng));
      if (_trail.length > 40) _trail.removeAt(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppProvider>().t;
    final lang = context.watch<AppProvider>().lang;
    final subPos = LatLng(_lat, _lng);

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
              FlutterMap(
                mapController: _mapCtrl,
                options: MapOptions(
                  initialCenter: const LatLng(10.8, 108.5),
                  initialZoom: 7,
                  onTap: (_, __) => setState(() => _showPopup = false),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.nauticom.submarine',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _trail,
                        strokeWidth: 2,
                        color: AppColors.blue.withValues(alpha: 0.7),
                        pattern: StrokePattern.dashed(
                          segments: [12, 8],
                        ),
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: subPos,
                        width: 48,
                        height: 48,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _showPopup = !_showPopup),
                          child: SubmarineIcon(heading: _heading),
                        ),
                      ),
                    ],
                  ),
                  if (_showPopup)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(_lat + 0.08, _lng),
                          width: 200,
                          height: 140,
                          child: SubmarinePopup(
                            lat: _lat,
                            lng: _lng,
                            depth: _depth,
                            speed: _speed,
                            heading: _heading,
                            pressure: _pressure,
                            t: t,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // Dark tint — military map aesthetic (replaces Google Maps dark styles)
              IgnorePointer(
                child: Container(
                  color: AppColors.background.withValues(alpha: 0.45),
                ),
              ),

              // Live tracking pill (bottom-left) — shows connection status
              Positioned(
                bottom: 12,
                left: 12,
                child: TrackingPill(
                  isConnected: _wsConnected,
                  liveText: lang == Lang.vi ? 'TRỰC TIẾP' : 'LIVE',
                  simulatedText: lang == Lang.vi ? 'MÔ PHỎNG' : 'SIMULATED',
                ),
              ),

              // OSM attribution (bottom-right, required by OSM terms)
              Positioned(
                bottom: 4,
                right: 8,
                child: Text(
                  '© OpenStreetMap contributors',
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