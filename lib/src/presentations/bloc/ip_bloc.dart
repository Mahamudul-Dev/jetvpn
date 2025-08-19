import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import '../../../main.dart';
import '../../data/services/ip_service.dart';

// Events
abstract class IpEvent extends Equatable {
  const IpEvent();

  @override
  List<Object> get props => [];
}

/// Event to refresh IP information
class IpRefreshEvent extends IpEvent {}

/// Event triggered when VPN connection status changes
class IpVpnStatusChangedEvent extends IpEvent {
  final V2RayStatus vpnStatus;

  const IpVpnStatusChangedEvent(this.vpnStatus);

  @override
  List<Object> get props => [vpnStatus];
}

/// Event to clear IP cache
class IpClearCacheEvent extends IpEvent {}

/// Event to adjust polling frequency based on usage
class IpAdjustPollingEvent extends IpEvent {
  final bool isActive;

  const IpAdjustPollingEvent(this.isActive);

  @override
  List<Object> get props => [isActive];
}

// States
abstract class IpState extends Equatable {
  const IpState();

  @override
  List<Object?> get props => [];
}

/// Initial state when IP hasn't been loaded yet
class IpInitial extends IpState {}

/// State when IP information is being loaded
class IpLoading extends IpState {}

/// State when IP information is successfully loaded
class IpLoaded extends IpState {
  final IpInfo ipInfo;
  final bool isVpnConnected;
  final DateTime lastUpdated;

  const IpLoaded({
    required this.ipInfo,
    required this.isVpnConnected,
    required this.lastUpdated,
  });

  @override
  List<Object> get props => [ipInfo, isVpnConnected, lastUpdated];

  /// Create a copy of this state with updated values
  IpLoaded copyWith({
    IpInfo? ipInfo,
    bool? isVpnConnected,
    DateTime? lastUpdated,
  }) {
    return IpLoaded(
      ipInfo: ipInfo ?? this.ipInfo,
      isVpnConnected: isVpnConnected ?? this.isVpnConnected,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Check if the data is fresh enough
  bool get isFresh {
    const maxAge = Duration(minutes: 5);
    return DateTime.now().difference(lastUpdated) < maxAge;
  }
}

/// State when IP operations encounter an error
class IpError extends IpState {
  final String message;
  final IpInfo? cachedInfo;

  const IpError({required this.message, this.cachedInfo});

  @override
  List<Object?> get props => [message, cachedInfo];
}

/// Optimized bloc for managing IP information and VPN-related IP changes
/// 
/// This bloc intelligently manages IP fetching with:
/// - Smart polling that adjusts frequency based on VPN connection state
/// - Caching to reduce unnecessary API calls
/// - Efficient IP change detection
/// - Error handling with cached data fallbacks
class IpBloc extends Bloc<IpEvent, IpState> {
  final IpService _ipService;
  
  // Timers for different polling scenarios
  Timer? _normalPollingTimer;
  Timer? _vpnPollingTimer;
  Timer? _inactivePollingTimer;
  
  // Polling intervals based on context
  static const Duration _normalInterval = Duration(minutes: 2);
  static const Duration _vpnTransitionInterval = Duration(seconds: 10);
  static const Duration _inactiveInterval = Duration(minutes: 10);
  
  // State tracking
  String? _lastKnownIp;
  bool _isVpnConnected = false;
  bool _isAppActive = true;
  DateTime? _lastVpnStateChange;

  IpBloc({
    required IpService ipService,
  })  : _ipService = ipService,
        super(IpInitial()) {
    
    // Register event handlers
    on<IpRefreshEvent>(_onRefresh);
    on<IpVpnStatusChangedEvent>(_onVpnStatusChanged);
    on<IpClearCacheEvent>(_onClearCache);
    on<IpAdjustPollingEvent>(_onAdjustPolling);
    
    // Start with normal polling
    _startNormalPolling();
    
    // Initial IP fetch
    add(IpRefreshEvent());
  }

  /// Handle IP refresh requests
  /// Uses caching and smart fetching to minimize API calls
  Future<void> _onRefresh(IpRefreshEvent event, Emitter<IpState> emit) async {
    try {
      logger.d('IpBloc: Refreshing IP information...');
      
      // Don't show loading if we already have fresh data
      if (state is! IpLoaded) {
        emit(IpLoading());
      }

      final ipInfo = await _ipService.getCurrentIpInfo();
      logger.d('IpBloc: IP refresh completed: ${ipInfo.ip}');

      // Check if IP actually changed to avoid unnecessary UI updates
      final hasChanged = _lastKnownIp != ipInfo.ip;
      _lastKnownIp = ipInfo.ip;

      if (hasChanged) {
        logger.d('IpBloc: IP changed to ${ipInfo.ip}');
      }

      emit(IpLoaded(
        ipInfo: ipInfo,
        isVpnConnected: _isVpnConnected,
        lastUpdated: DateTime.now(),
      ));

    } catch (e) {
      logger.e('IpBloc: Failed to refresh IP: $e');
      
      // Try to provide cached data if available
      if (_ipService.hasCache && state is IpLoaded) {
        final currentState = state as IpLoaded;
        emit(IpError(
          message: 'Failed to refresh IP: ${e.toString()}',
          cachedInfo: currentState.ipInfo,
        ));
      } else {
        emit(IpError(message: 'Failed to get IP: ${e.toString()}'));
      }
    }
  }

  /// Handle VPN status changes
  /// Adjusts polling frequency and triggers IP refresh when needed
  Future<void> _onVpnStatusChanged(
    IpVpnStatusChangedEvent event,
    Emitter<IpState> emit,
  ) async {
    final vpnStatus = event.vpnStatus;
    final wasConnected = _isVpnConnected;
    _isVpnConnected = vpnStatus.state.toLowerCase() == 'connected';
    
    logger.d('IpBloc: VPN status changed from $wasConnected to $_isVpnConnected');

    // If VPN connection state changed, adjust polling and refresh IP
    if (wasConnected != _isVpnConnected) {
      _lastVpnStateChange = DateTime.now();
      
      // Clear IP cache since connection changed
      _ipService.clearCache();
      
      if (_isVpnConnected) {
        logger.d('IpBloc: VPN connected, starting intensive polling...');
        _startVpnPolling();
        
        // Wait for VPN to establish properly before checking IP
        await Future.delayed(const Duration(seconds: 5));
      } else {
        logger.d('IpBloc: VPN disconnected, returning to normal polling...');
        _startNormalPolling();
      }
      
      // Trigger immediate IP refresh
      add(IpRefreshEvent());
      return;
    }
    
    // Update VPN status in current state without changing IP
    if (state is IpLoaded) {
      final currentState = state as IpLoaded;
      emit(currentState.copyWith(isVpnConnected: _isVpnConnected));
    }
  }

  /// Clear IP cache
  /// Useful when user wants to force refresh or troubleshoot
  Future<void> _onClearCache(IpClearCacheEvent event, Emitter<IpState> emit) async {
    logger.d('IpBloc: Clearing IP cache');
    _ipService.clearCache();
    _lastKnownIp = null;
    
    // Trigger immediate refresh
    add(IpRefreshEvent());
  }

  /// Adjust polling frequency based on app activity
  /// Reduces polling when app is in background to save resources
  Future<void> _onAdjustPolling(IpAdjustPollingEvent event, Emitter<IpState> emit) async {
    _isAppActive = event.isActive;
    logger.d('IpBloc: App activity changed to ${event.isActive ? "active" : "inactive"}');
    
    if (_isAppActive) {
      // Resume normal polling based on VPN state
      if (_isVpnConnected || _isRecentVpnTransition()) {
        _startVpnPolling();
      } else {
        _startNormalPolling();
      }
    } else {
      // Reduce polling frequency when inactive
      _startInactivePolling();
    }
  }

  /// Start normal polling interval
  /// Used when VPN is stable and app is active
  void _startNormalPolling() {
    _cancelAllTimers();
    
    logger.d('IpBloc: Starting normal polling (${_normalInterval.inMinutes} minutes)');
    _normalPollingTimer = Timer.periodic(_normalInterval, (timer) {
      if (state is IpLoaded || state is IpError) {
        add(IpRefreshEvent());
      }
    });
  }

  /// Start intensive polling during VPN transitions
  /// Used immediately after VPN connects/disconnects
  void _startVpnPolling() {
    _cancelAllTimers();
    
    logger.d('IpBloc: Starting VPN transition polling (${_vpnTransitionInterval.inSeconds} seconds)');
    _vpnPollingTimer = Timer.periodic(_vpnTransitionInterval, (timer) {
      // Switch back to normal polling after 2 minutes
      if (_lastVpnStateChange != null && 
          DateTime.now().difference(_lastVpnStateChange!) > const Duration(minutes: 2)) {
        logger.d('IpBloc: VPN transition period ended, switching to normal polling');
        _startNormalPolling();
        return;
      }
      
      if (state is IpLoaded || state is IpError) {
        add(IpRefreshEvent());
      }
    });
  }

  /// Start reduced polling when app is inactive
  /// Conserves battery and data usage
  void _startInactivePolling() {
    _cancelAllTimers();
    
    logger.d('IpBloc: Starting inactive polling (${_inactiveInterval.inMinutes} minutes)');
    _inactivePollingTimer = Timer.periodic(_inactiveInterval, (timer) {
      if (state is IpLoaded || state is IpError) {
        add(IpRefreshEvent());
      }
    });
  }

  /// Cancel all active timers
  void _cancelAllTimers() {
    _normalPollingTimer?.cancel();
    _vpnPollingTimer?.cancel();
    _inactivePollingTimer?.cancel();
  }

  /// Check if we're in a recent VPN transition period
  bool _isRecentVpnTransition() {
    if (_lastVpnStateChange == null) return false;
    const transitionPeriod = Duration(minutes: 2);
    return DateTime.now().difference(_lastVpnStateChange!) < transitionPeriod;
  }

  /// Get current IP information if available
  IpInfo? get currentIpInfo {
    if (state is IpLoaded) {
      return (state as IpLoaded).ipInfo;
    }
    return null;
  }

  /// Get VPN connection status
  bool get isVpnConnected => _isVpnConnected;

  /// Get cache status for debugging
  Map<String, dynamic> get debugInfo {
    final serviceStatus = _ipService is IpServiceImpl 
        ? (_ipService as IpServiceImpl).getCacheStatus()
        : <String, dynamic>{};
    
    return {
      'lastKnownIp': _lastKnownIp,
      'isVpnConnected': _isVpnConnected,
      'isAppActive': _isAppActive,
      'lastVpnStateChange': _lastVpnStateChange?.toIso8601String(),
      'isRecentVpnTransition': _isRecentVpnTransition(),
      'activeTimer': _getActiveTimerType(),
      'serviceCache': serviceStatus,
    };
  }

  /// Get the type of currently active timer
  String _getActiveTimerType() {
    if (_vpnPollingTimer?.isActive == true) return 'vpn';
    if (_normalPollingTimer?.isActive == true) return 'normal';
    if (_inactivePollingTimer?.isActive == true) return 'inactive';
    return 'none';
  }

  @override
  Future<void> close() {
    logger.d('IpBloc: Closing and cleaning up...');
    _cancelAllTimers();
    return super.close();
  }
}
