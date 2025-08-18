import 'package:equatable/equatable.dart';

enum VpnConnectionStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

class VpnStatus extends Equatable {
  final VpnConnectionStatus status;
  final String message;
  final String? selectedConfig;
  final DateTime? connectedAt;
  final String? errorMessage;
  final String? duration;
  final int? uploadSpeed;
  final int? downloadSpeed;
  final int? upload;
  final int? download;


  const VpnStatus({
    required this.status,
    required this.message,
    this.selectedConfig,
    this.connectedAt,
    this.errorMessage,
    this.duration,
    this.uploadSpeed,
    this.downloadSpeed,
    this.upload,
    this.download
  });

  factory VpnStatus.initial() {
    return const VpnStatus(
      status: VpnConnectionStatus.disconnected,
      message: 'Disconnected',
    );
  }

  VpnStatus copyWith({
    VpnConnectionStatus? status,
    String? message,
    String? selectedConfig,
    DateTime? connectedAt,
    String? errorMessage,
  }) {
    return VpnStatus(
      status: status ?? this.status,
      message: message ?? this.message,
      selectedConfig: selectedConfig ?? this.selectedConfig,
      connectedAt: connectedAt ?? this.connectedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isConnected => status == VpnConnectionStatus.connected;
  bool get isConnecting => status == VpnConnectionStatus.connecting;
  bool get isDisconnecting => status == VpnConnectionStatus.disconnecting;
  bool get hasError => status == VpnConnectionStatus.error;

  @override
  List<Object?> get props => [
    status,
    message,
    selectedConfig,
    connectedAt,
    errorMessage,
  ];
}