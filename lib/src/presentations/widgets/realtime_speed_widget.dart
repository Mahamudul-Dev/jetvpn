import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';

/// Model for cached speed calculations to avoid redundant computations
class _SpeedData {
  final double uploadMbps;
  final double downloadMbps;
  final String uploadText;
  final String downloadText;

  const _SpeedData({
    required this.uploadMbps,
    required this.downloadMbps,
    required this.uploadText,
    required this.downloadText,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SpeedData &&
          uploadMbps == other.uploadMbps &&
          downloadMbps == other.downloadMbps;

  @override
  int get hashCode => uploadMbps.hashCode ^ downloadMbps.hashCode;
}

/// Optimized widget for displaying real-time VPN speed information
/// 
/// Features:
/// - Caches speed calculations to avoid redundant math operations
/// - Smart formatting for different speed ranges (B/s, KB/s, MB/s)
/// - Optimized rebuilds using immutable speed data
/// - Better visual hierarchy and accessibility
class RealtimeSpeedWidget extends StatefulWidget {
  final V2RayStatus vpnStatus;

  const RealtimeSpeedWidget({
    super.key,
    required this.vpnStatus,
  });

  @override
  State<RealtimeSpeedWidget> createState() => _RealtimeSpeedWidgetState();
}

class _RealtimeSpeedWidgetState extends State<RealtimeSpeedWidget> {
  _SpeedData? _cachedSpeedData;
  V2RayStatus? _lastStatus;

  @override
  Widget build(BuildContext context) {
    final speedData = _getSpeedData();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Upload speed indicator
        _SpeedIndicator(
          icon: Icons.upload_outlined,
          iconColor: Theme.of(context).colorScheme.secondary,
          label: 'Upload',
          speed: speedData.uploadText,
        ),
        
        // Download speed indicator  
        _SpeedIndicator(
          icon: Icons.download_outlined,
          iconColor: Theme.of(context).colorScheme.primary,
          label: 'Download',
          speed: speedData.downloadText,
        ),
      ],
    );
  }

  /// Get speed data with caching to avoid unnecessary recalculations
  _SpeedData _getSpeedData() {
    // Check if we can use cached data
    if (_cachedSpeedData != null && 
        _lastStatus != null &&
        _lastStatus!.uploadSpeed == widget.vpnStatus.uploadSpeed &&
        _lastStatus!.downloadSpeed == widget.vpnStatus.downloadSpeed) {
      return _cachedSpeedData!;
    }

    // Calculate new speed data
    final uploadMbps = widget.vpnStatus.uploadSpeed / 1000;
    final downloadMbps = widget.vpnStatus.downloadSpeed / 1000;

    final speedData = _SpeedData(
      uploadMbps: uploadMbps,
      downloadMbps: downloadMbps,
      uploadText: _formatSpeed(widget.vpnStatus.uploadSpeed),
      downloadText: _formatSpeed(widget.vpnStatus.downloadSpeed),
    );

    // Cache the results
    _cachedSpeedData = speedData;
    _lastStatus = widget.vpnStatus;

    return speedData;
  }

  /// Format speed values with appropriate units for better readability
  /// Handles different ranges: B/s, KB/s, MB/s, GB/s
  String _formatSpeed(int speedBps) {
    if (speedBps < 1024) {
      // Less than 1 KB/s - show bytes
      return '${speedBps.toStringAsFixed(0)} B/s';
    } else if (speedBps < 1024 * 1024) {
      // Less than 1 MB/s - show kilobytes
      final speedKbps = speedBps / 1024;
      return '${speedKbps.toStringAsFixed(1)} KB/s';
    } else if (speedBps < 1024 * 1024 * 1024) {
      // Less than 1 GB/s - show megabytes
      final speedMbps = speedBps / (1024 * 1024);
      return '${speedMbps.toStringAsFixed(1)} MB/s';
    } else {
      // 1 GB/s or more - show gigabytes
      final speedGbps = speedBps / (1024 * 1024 * 1024);
      return '${speedGbps.toStringAsFixed(2)} GB/s';
    }
  }
}

/// Individual speed indicator component
/// Separates upload and download display logic for better maintainability
class _SpeedIndicator extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String speed;

  const _SpeedIndicator({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.speed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Semantics(
      label: '$label speed: $speed',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 20,
            semanticLabel: label,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                speed,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
