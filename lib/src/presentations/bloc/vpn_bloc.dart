import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import '../../../main.dart';
import '../../domain/entities/vpn_config.dart';
import '../../domain/usecases/initialize_v2ray.dart';
import '../../domain/usecases/usecase.dart';
import 'vpn_connection_bloc.dart';
import 'vpn_servers_bloc.dart';
import 'ip_bloc.dart';

part 'vpn_event.dart';
part 'vpn_state.dart';

/// Coordinator bloc that manages communication between specialized VPN blocs
/// 
/// This bloc serves as the main interface for VPN functionality and coordinates:
/// - VPN connection management (via VpnConnectionBloc)
/// - Server management and selection (via VpnServersBloc)  
/// - IP monitoring (via IpBloc)
/// 
/// Benefits of this architecture:
/// - Separation of concerns - each bloc has a single responsibility
/// - Better performance - heavy operations are isolated
/// - Easier testing and maintenance
/// - Improved error handling and recovery
class VpnBloc extends Bloc<VpnEvent, VpnState> {
  final VpnConnectionBloc _connectionBloc;
  final VpnServersBloc _serversBloc;
  final IpBloc _ipBloc;
  final InitializeVpnService _initializeVpnService;
  
  // Stream subscriptions for coordinating between blocs
  StreamSubscription<VpnConnectionState>? _connectionSubscription;
  StreamSubscription<VpnServersState>? _serversSubscription;
  StreamSubscription<IpState>? _ipSubscription;

  VpnBloc({
    required VpnConnectionBloc connectionBloc,
    required VpnServersBloc serversBloc,
    required IpBloc ipBloc,
    required InitializeVpnService initializeVpnService,
  })  : _connectionBloc = connectionBloc,
        _serversBloc = serversBloc,
        _ipBloc = ipBloc,
        _initializeVpnService = initializeVpnService,
        super(VpnInitial()) {
    
    // Register event handlers
    on<VpnInitializeEvent>(_onInitialize);
    on<VpnConnectEvent>(_onConnect);
    on<VpnDisconnectEvent>(_onDisconnect);
    on<VpnRefreshConfigsEvent>(_onRefreshConfigs);
    on<VpnSelectConfigEvent>(_onSelectConfig);
    on<VpnStatusChangedEvent>(_onStatusChanged);
    on<LoadMoreConfigsEvent>(_onLoadMoreConfigs);
    
    // Set up inter-bloc communication
    _setupBlocCoordination();
  }

  /// Initialize VPN system and all related blocs
  /// This sets up the entire VPN subsystem including connection monitoring,
  /// server loading, and IP tracking
  Future<void> _onInitialize(VpnInitializeEvent event, Emitter<VpnState> emit) async {
    emit(VpnLoading());
    logger.d('VpnBloc: Initializing VPN system...');

    try {
      // Initialize the core VPN service
      await _initializeVpnService.call(NoParams());
      logger.d('VpnBloc: VPN service initialized');

      // Initialize all sub-blocs
      _connectionBloc.add(VpnConnectionInitializeEvent());
      _serversBloc.add(VpnServersLoadEvent());
      
      logger.d('VpnBloc: VPN system initialization completed');
    } catch (e) {
      logger.e('VpnBloc: Initialization failed: $e');
      emit(VpnError('Initialization failed: $e'));
    }
  }

  /// Connect to a VPN server
  /// Delegates the actual connection to the connection bloc
  Future<void> _onConnect(VpnConnectEvent event, Emitter<VpnState> emit) async {
    logger.d('VpnBloc: Initiating connection to ${event.serverUrl}');
    _connectionBloc.add(VpnConnectionConnectEvent(event.serverUrl));
  }

  /// Disconnect from VPN
  /// Delegates the actual disconnection to the connection bloc
  Future<void> _onDisconnect(VpnDisconnectEvent event, Emitter<VpnState> emit) async {
    logger.d('VpnBloc: Initiating disconnection');
    _connectionBloc.add(VpnConnectionDisconnectEvent());
  }

  /// Refresh server configurations
  /// Delegates to the servers bloc
  Future<void> _onRefreshConfigs(VpnRefreshConfigsEvent event, Emitter<VpnState> emit) async {
    logger.d('VpnBloc: Refreshing server configurations');
    _serversBloc.add(VpnServersRefreshEvent());
  }

  /// Select a server configuration
  /// Updates both the servers bloc and triggers UI update
  Future<void> _onSelectConfig(VpnSelectConfigEvent event, Emitter<VpnState> emit) async {
    logger.d('VpnBloc: Selecting server: ${event.config.country}');
    _serversBloc.add(VpnServersSelectEvent(event.config));
  }

  /// Load more server configurations (pagination)
  /// Delegates to the servers bloc
  Future<void> _onLoadMoreConfigs(LoadMoreConfigsEvent event, Emitter<VpnState> emit) async {
    logger.d('VpnBloc: Loading more server configurations');
    _serversBloc.add(VpnServersLoadMoreEvent());
  }

  /// Handle VPN status changes from connection bloc
  /// Updates IP bloc when connection state changes
  Future<void> _onStatusChanged(VpnStatusChangedEvent event, Emitter<VpnState> emit) async {
    logger.d('VpnBloc: VPN status changed: ${event.statusData.state}');
    
    // Notify IP bloc of connection state changes
    _ipBloc.add(IpVpnStatusChangedEvent(event.statusData));
  }

  /// Set up coordination between the specialized blocs
  /// This creates the communication channels that allow the coordinator
  /// to respond to state changes in the specialized blocs
  void _setupBlocCoordination() {
    logger.d('VpnBloc: Setting up inter-bloc coordination...');

    // Listen to connection bloc state changes
    _connectionSubscription = _connectionBloc.stream.listen(
      (connectionState) {
        _handleConnectionStateChange(connectionState);
      },
      onError: (error) {
        logger.e('VpnBloc: Connection bloc stream error: $error');
        add(VpnStatusChangedEvent(V2RayStatus(state: 'error')));
      },
    );

    // Listen to servers bloc state changes
    _serversSubscription = _serversBloc.stream.listen(
      (serversState) {
        _handleServersStateChange(serversState);
      },
      onError: (error) {
        logger.e('VpnBloc: Servers bloc stream error: $error');
      },
    );

    // Listen to IP bloc state changes
    _ipSubscription = _ipBloc.stream.listen(
      (ipState) {
        _handleIpStateChange(ipState);
      },
      onError: (error) {
        logger.e('VpnBloc: IP bloc stream error: $error');
      },
    );

    logger.d('VpnBloc: Inter-bloc coordination setup completed');
  }

  /// Handle connection state changes from the connection bloc
  /// Emits appropriate VPN states based on connection status
  void _handleConnectionStateChange(VpnConnectionState connectionState) {
    if (connectionState is VpnConnectionConnected && 
        _serversBloc.state is VpnServersLoaded) {
      
      final serversState = _serversBloc.state as VpnServersLoaded;
      
      emit(VpnLoaded(
        vpnStatus: connectionState.statusData,
        availableConfigs: serversState.filteredServers,
        selectedConfig: serversState.selectedConfig,
        page: serversState.currentPage,
        next: serversState.nextPage,
      ));
      
    } else if (connectionState is VpnConnectionDisconnected &&
               _serversBloc.state is VpnServersLoaded) {
      
      final serversState = _serversBloc.state as VpnServersLoaded;
      
      emit(VpnLoaded(
        vpnStatus: connectionState.statusData ?? V2RayStatus(state: 'disconnected'),
        availableConfigs: serversState.filteredServers,
        selectedConfig: serversState.selectedConfig,
        page: serversState.currentPage,
        next: serversState.nextPage,
      ));
      
    } else if (connectionState is VpnConnectionError) {
      emit(VpnError('Connection error: ${connectionState.message}'));
    }
  }

  /// Handle server state changes from the servers bloc
  /// Updates the main state when servers are loaded or changed
  void _handleServersStateChange(VpnServersState serversState) {
    if (serversState is VpnServersLoaded) {
      // Only emit if we're not currently in an error state
      if (state is! VpnError) {
        V2RayStatus currentVpnStatus = V2RayStatus(state: 'disconnected');
        
        // Get current connection status if available
        if (_connectionBloc.state is VpnConnectionConnected) {
          final connectionState = _connectionBloc.state as VpnConnectionConnected;
          currentVpnStatus = connectionState.statusData;
        } else if (_connectionBloc.state is VpnConnectionDisconnected) {
          final connectionState = _connectionBloc.state as VpnConnectionDisconnected;
          currentVpnStatus = connectionState.statusData ?? V2RayStatus(state: 'disconnected');
        }

        emit(VpnLoaded(
          vpnStatus: currentVpnStatus,
          availableConfigs: serversState.filteredServers,
          selectedConfig: serversState.selectedConfig,
          page: serversState.currentPage,
          next: serversState.nextPage,
        ));
      }
    } else if (serversState is VpnServersError) {
      // Only show server error if we don't have cached data to fall back on
      if (serversState.cachedServers == null) {
        emit(VpnError('Server error: ${serversState.message}'));
      }
    }
  }

  /// Handle IP state changes from the IP bloc
  /// Currently used for logging and monitoring, but could trigger UI updates
  void _handleIpStateChange(IpState ipState) {
    if (ipState is IpLoaded) {
      logger.d('VpnBloc: IP updated - ${ipState.ipInfo.ip} (VPN: ${ipState.isVpnConnected})');
    } else if (ipState is IpError && ipState.cachedInfo == null) {
      logger.w('VpnBloc: IP error - ${ipState.message}');
    }
  }

  /// Get the currently selected server configuration
  VpnConfig? get selectedServer {
    return _serversBloc.selectedServer;
  }

  /// Get current connection status
  bool get isConnected {
    return _connectionBloc.isConnected;
  }

  /// Get current IP information
  String? get currentIp {
    return _ipBloc.currentIpInfo?.ip;
  }

  /// Check if more servers can be loaded
  bool get canLoadMoreServers {
    return _serversBloc.canLoadMore;
  }

  /// Get available countries for filtering
  List<String> get availableCountries {
    return _serversBloc.availableCountries;
  }

  /// Filter servers by country
  void filterServersByCountry(String? country) {
    _serversBloc.add(VpnServersFilterEvent(countryFilter: country));
  }

  /// Search servers by query
  void searchServers(String query) {
    _serversBloc.add(VpnServersFilterEvent(searchQuery: query));
  }

  /// Force refresh IP information
  void refreshIp() {
    _ipBloc.add(IpRefreshEvent());
  }

  /// Adjust polling based on app lifecycle
  void setAppActive(bool isActive) {
    _ipBloc.add(IpAdjustPollingEvent(isActive));
  }

  /// Get debug information from all blocs
  Map<String, dynamic> get debugInfo {
    return {
      'coordinator': {
        'state': state.runtimeType.toString(),
        'selectedServer': selectedServer?.country,
        'isConnected': isConnected,
        'currentIp': currentIp,
        'canLoadMore': canLoadMoreServers,
      },
      'connection': {
        'state': _connectionBloc.state.runtimeType.toString(),
        'isConnected': _connectionBloc.isConnected,
        'connectedServer': _connectionBloc.connectedServerUrl,
      },
      'servers': {
        'state': _serversBloc.state.runtimeType.toString(),
        'serverCount': _serversBloc.state is VpnServersLoaded 
            ? (_serversBloc.state as VpnServersLoaded).servers.length 
            : 0,
        'availableCountries': availableCountries.length,
      },
      'ip': _ipBloc.debugInfo,
    };
  }

  @override
  Future<void> close() {
    logger.d('VpnBloc: Closing coordinator and cleaning up...');
    
    // Cancel all subscriptions
    _connectionSubscription?.cancel();
    _serversSubscription?.cancel();
    _ipSubscription?.cancel();
    
    return super.close();
  }
}
