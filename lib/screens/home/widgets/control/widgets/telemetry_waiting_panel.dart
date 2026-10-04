import 'package:flutter/material.dart';
import '../../../../../theme.dart';

class TelemetryWaitingPanel extends StatelessWidget {
  const TelemetryWaitingPanel({
    super.key,
    required this.isVietnamese,
    required this.connected,
    required this.recording,
    required this.busy,
    required this.onStop,
  });

  final bool isVietnamese;
  final bool connected;
  final bool recording;
  final bool busy;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.accent),
          const SizedBox(height: 16),
          Text(
            isVietnamese
                ? 'Đang chờ dữ liệu tàu ngầm...'
                : 'Waiting for submarine data...',
            style: const TextStyle(color: AppColors.muted, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            connected
                ? (isVietnamese ? 'Đã kết nối máy chủ' : 'Connected to server')
                : (isVietnamese ? 'Đang kết nối...' : 'Connecting...'),
            style: TextStyle(
              color: connected ? AppColors.accent : AppColors.amber,
              fontSize: 12,
            ),
          ),
          if (recording) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: busy ? null : onStop,
              icon: const Icon(Icons.stop),
              label: Text(isVietnamese
                  ? 'Dừng và hủy ghi âm'
                  : 'Stop and discard recording'),
            ),
          ],
        ],
      ),
    );
  }
}
