import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import '../../../main.dart';
import '../../domain/usecases/connect_vpn.dart';
import '../../domain/usecases/disconnect_vpn.dart';
import '../../domain/usecases/watch_vpn_status.dart';
import '../../domain/usecases/usecase.dart';

// Events
abstract class VpnConnectionEvent extends Equatable {
  const VpnConnectionEvent();

  @override
  List<Object?> get props => [];
}

/// Event to initialize the VPN connection monitoring
class VpnConnectionInitializeEvent extends VpnConnectionEvent {}

/// Event to connect to a VPN server
class VpnConnectionConnectEvent extends VpnConnectionEvent {
  final String serverUrl;

  const VpnConnectionConnectEvent(this.serverUrl);

  @override
  List<Object> get props => [serverUrl];
}

/// Event to disconnect from the current VPN connection
class VpnConnectionDisconnectEvent extends VpnConnectionEvent {}

/// Event triggered when VPN connection status changes
class VpnConnectionStatusChangedEvent extends VpnConnectionEvent {
  final V2RayStatus statusData;

  const VpnConnectionStatusChangedEvent(this.statusData);

  @override
  List<Object> get props => [statusData];
}

// States
abstract class VpnConnectionState extends Equatable {
  const VpnConnectionState();

  @override
  List<Object?> get props => [];
}

/// Initial state of VPN connection
class VpnConnectionInitial extends VpnConnectionState {}

/// State when VPN connection is being initialized
class VpnConnectionInitializing extends VpnConnectionState {}

/// State when VPN is actively connecting to a server
class VpnConnectionConnecting extends VpnConnectionState {
  final String serverUrl;

  const VpnConnectionConnecting(this.serverUrl);

  @override
  List<Object> get props => [serverUrl];
}

/// State when VPN is successfully connected
class VpnConnectionConnected extends VpnConnectionState {
  final V2RayStatus statusData;
  final String connectedServerUrl;

  const VpnConnectionConnected({
    required this.statusData,
    required this.connectedServerUrl,
  });

  @override
  List<Object> get props => [statusData, connectedServerUrl];
}

/// State when VPN is in the process of disconnecting
class VpnConnectionDisconnecting extends VpnConnectionState {}

/// State when VPN is disconnected
class VpnConnectionDisconnected extends VpnConnectionState {
  final V2RayStatus? statusData;

  const VpnConnectionDisconnected({this.statusData});

  @override
  List<Object?> get props => [statusData];
}

/// State when VPN connection encounters an error
class VpnConnectionError extends VpnConnectionState {
  final String message;

  const VpnConnectionError(this.message);

  @override
  List<Object> get props => [message];
}

/// Bloc responsible for managing VPN connection operations
/// 
/// This bloc is focused solely on connection management:
/// - Connecting to VPN servers
/// - Disconnecting from VPN
/// - Monitoring connection status changes
/// - Handling connection errors
class VpnConnectionBloc extends Bloc<VpnConnectionEvent, VpnConnectionState> {
  final ConnectVpn _connectVpn;
  final DisconnectVpn _disconnectVpn;
  final WatchVpnStatus _watchVpnStatus;
  
  StreamSubscription<V2RayStatus>? _statusSubscription;
  String? _currentServerUrl;

  VpnConnectionBloc({
    required ConnectVpn connectVpn,
    required DisconnectVpn disconnectVpn,
    required WatchVpnStatus watchVpnStatus,
  })  : _connectVpn = connectVpn,
        _disconnectVpn = disconnectVpn,
        _watchVpnStatus = watchVpnStatus,
        super(VpnConnectionInitial()) {
    
    // Register event handlers
    on<VpnConnectionInitializeEvent>(_onInitialize);
    on<VpnConnectionConnectEvent>(_onConnect);
    on<VpnConnectionDisconnectEvent>(_onDisconnect);
    on<VpnConnectionStatusChangedEvent>(_onStatusChanged);
  }

  /// Initialize VPN connection monitoring
  /// Sets up the status stream to listen for connection changes
  Future<void> _onInitialize(
    VpnConnectionInitializeEvent event,
    Emitter<VpnConnectionState> emit,
  ) async {
    emit(VpnConnectionInitializing());
    
    try {
      logger.d('VpnConnectionBloc: Initializing connection monitoring...');
      _startStatusStream();
      emit(const VpnConnectionDisconnected());
      logger.d('VpnConnectionBloc: Connection monitoring initialized');
    } catch (e) {
      logger.e('VpnConnectionBloc: Failed to initialize: $e');
      emit(VpnConnectionError('Failed to initialize connection monitoring: $e'));
    }
  }

  /// Handle VPN connection request
  /// Manages the connection process and updates state accordingly
  Future<void> _onConnect(
    VpnConnectionConnectEvent event,
    Emitter<VpnConnectionState> emit,
  ) async {
    logger.d('VpnConnectionBloc: Connecting to ${event.serverUrl}');
    
    // Update state to connecting
    emit(VpnConnectionConnecting(event.serverUrl));
    _currentServerUrl = event.serverUrl;

    try {
      // Attempt to connect using the use case
      final result = await _connectVpn(ConnectVpnParams(url: event.serverUrl));
      
      result.fold(
        (failure) {
          logger.e('VpnConnectionBloc: Connection failed: ${failure.message}');
          emit(VpnConnectionError('Connection failed: ${failure.message}'));
          _currentServerUrl = null;
        },
        (success) {
          logger.d('VpnConnectionBloc: Connection initiated successfully');
          // Status will be updated via the status stream
        },
      );
    } catch (e) {
      logger.e('VpnConnectionBloc: Unexpected connection error: $e');
      emit(VpnConnectionError('Unexpected connection error: $e'));
      _currentServerUrl = null;
    }
  }

  /// Handle VPN disconnection request
  /// Manages the disconnection process
  Future<void> _onDisconnect(
    VpnConnectionDisconnectEvent event,
    Emitter<VpnConnectionState> emit,
  ) async {
    logger.d('VpnConnectionBloc: Disconnecting VPN...');
    
    // Update state to disconnecting
    emit(VpnConnectionDisconnecting());

    try {
      // Attempt to disconnect using the use case
      final result = await _disconnectVpn(NoParams());
      
      result.fold(
        (failure) {
          logger.e('VpnConnectionBloc: Disconnection failed: ${failure.message}');
          emit(VpnConnectionError('Disconnection failed: ${failure.message}'));
        },
        (success) {
          logger.d('VpnConnectionBloc: Disconnection initiated successfully');
          _currentServerUrl = null;
          // Status will be updated via the status stream
        },
      );
    } catch (e) {
      logger.e('VpnConnectionBloc: Unexpected disconnection error: $e');
      emit(VpnConnectionError('Unexpected disconnection error: $e'));
    }
  }

  /// Handle VPN status changes from the underlying VPN service
  /// Updates the connection state based on the received status
  Future<void> _onStatusChanged(
    VpnConnectionStatusChangedEvent event,
    Emitter<VpnConnectionState> emit,
  ) async {
    final status = event.statusData;
    logger.d('VpnConnectionBloc: Status changed to: ${status.state}');

    // Map V2Ray status to our connection states
    switch (status.state.toLowerCase()) {
      case 'connected':
        if (_currentServerUrl != null) {
          emit(VpnConnectionConnected(
            statusData: status,
            connectedServerUrl: _currentServerUrl!,
          ));
        } else {
          // Connected but we don't know the server URL
          emit(VpnConnectionConnected(
            statusData: status,
            connectedServerUrl: 'Unknown Server',
          ));
        }
        break;
        
      case 'connecting':
        if (state is! VpnConnectionConnecting) {
          // Only emit connecting state if we're not already in it
          emit(VpnConnectionConnecting(_currentServerUrl ?? 'Unknown Server'));
        }
        break;
        
      case 'disconnected':
      default:
        emit(VpnConnectionDisconnected(statusData: status));
        _currentServerUrl = null;
        break;
    }
  }

  /// Start listening to VPN status changes
  /// Sets up the stream subscription for real-time status updates
  void _startStatusStream() {
    logger.d('VpnConnectionBloc: Setting up status stream listener...');
    
    // Cancel any existing subscription
    _statusSubscription?.cancel();
    
    // Create new subscription
    _statusSubscription = _watchVpnStatus(NoParams()).listen(
      (vpnStatus) {
        add(VpnConnectionStatusChangedEvent(vpnStatus));
      },
      onError: (error) {
        logger.e('VpnConnectionBloc: Status stream error: $error');
        add(VpnConnectionStatusChangedEvent(
          V2RayStatus(state: 'disconnected'),
        ));
      },
      onDone: () {
        logger.d('VpnConnectionBloc: Status stream closed');
      },
    );
    
    logger.d('VpnConnectionBloc: Status stream listener setup completed');
  }

  /// Get the current connection status as a boolean
  bool get isConnected {
    return state is VpnConnectionConnected;
  }

  /// Get the current connection status as a boolean for connecting state
  bool get isConnecting {
    return state is VpnConnectionConnecting;
  }

  /// Get the currently connected server URL if available
  String? get connectedServerUrl {
    if (state is VpnConnectionConnected) {
      return (state as VpnConnectionConnected).connectedServerUrl;
    }
    return null;
  }

  @override
  Future<void> close() {
    logger.d('VpnConnectionBloc: Closing and cleaning up...');
    _statusSubscription?.cancel();
    return super.close();
  }
}