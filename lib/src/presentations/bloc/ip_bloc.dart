import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../main.dart';
import '../../data/services/ip_service.dart';
import '../../domain/entities/vpn_status.dart';

// Events
abstract class IpEvent extends Equatable {
  const IpEvent();

  @override
  List<Object> get props => [];
}

class IpRefreshEvent extends IpEvent {}

class IpVpnStatusChangedEvent extends IpEvent {
  final VpnStatus vpnStatus;

  const IpVpnStatusChangedEvent(this.vpnStatus);

  @override
  List<Object> get props => [vpnStatus];
}

// States
abstract class IpState extends Equatable {
  const IpState();

  @override
  List<Object?> get props => [];
}

class IpInitial extends IpState {}

class IpLoading extends IpState {}

class IpLoaded extends IpState {
  final IpInfo ipInfo;
  final bool isVpnConnected;

  const IpLoaded({
    required this.ipInfo,
    required this.isVpnConnected,
  });

  @override
  List<Object> get props => [ipInfo, isVpnConnected];

  IpLoaded copyWith({
    IpInfo? ipInfo,
    bool? isVpnConnected,
  }) {
    return IpLoaded(
      ipInfo: ipInfo ?? this.ipInfo,
      isVpnConnected: isVpnConnected ?? this.isVpnConnected,
    );
  }
}

class IpError extends IpState {
  final String message;

  const IpError(this.message);

  @override
  List<Object> get props => [message];
}

// Bloc
class IpBloc extends Bloc<IpEvent, IpState> {
  final IpService ipService;
  String? _lastKnownIp;
  Timer? _periodicTimer;

  IpBloc({
    required this.ipService,
  }) : super(IpInitial()) {
    on<IpRefreshEvent>(_onRefresh);
    on<IpVpnStatusChangedEvent>(_onVpnStatusChanged);
    
    // Start periodic IP checking
    _startPeriodicCheck();
    
    // Initial IP fetch
    add(IpRefreshEvent());
  }

  void _startPeriodicCheck() {
    // Check IP every 30 seconds to detect changes
    _periodicTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (state is IpLoaded) {
        add(IpRefreshEvent());
      }
    });
  }

  Future<void> _onRefresh(IpRefreshEvent event, Emitter<IpState> emit) async {
    try {
      // Don't show loading if we already have data
      if (state is! IpLoaded) {
        emit(IpLoading());
      }

      final ipInfo = await ipService.getCurrentIpInfo();
      logger.d('IP refresh completed: $ipInfo');

      // Check if IP actually changed
      if (_lastKnownIp != null && _lastKnownIp == ipInfo.ip) {
        logger.d('IP unchanged, skipping update');
        return;
      }

      _lastKnownIp = ipInfo.ip;

      emit(IpLoaded(
        ipInfo: ipInfo,
        isVpnConnected: _isVpnConnectedFromState(),
      ));
    } catch (e) {
      logger.e('Failed to refresh IP: $e');
      emit(IpError('Failed to get IP: ${e.toString()}'));
    }
  }

  Future<void> _onVpnStatusChanged(
    IpVpnStatusChangedEvent event, 
    Emitter<IpState> emit
  ) async {
    logger.d('VPN status changed in IP bloc: ${event.vpnStatus.status}');
    
    final isVpnConnected = event.vpnStatus.isConnected;
    
    if (state is IpLoaded) {
      final currentState = state as IpLoaded;
      
      // If VPN status changed, refresh IP
      if (currentState.isVpnConnected != isVpnConnected) {
        logger.d('VPN connection status changed, refreshing IP...');
        
        // Add a small delay to let VPN establish connection
        if (isVpnConnected) {
          await Future.delayed(const Duration(seconds: 3));
        }
        
        add(IpRefreshEvent());
        return;
      }
    }
    
    // Update VPN status in current state if we have one
    if (state is IpLoaded) {
      final currentState = state as IpLoaded;
      emit(currentState.copyWith(isVpnConnected: isVpnConnected));
    }
  }

  bool _isVpnConnectedFromState() {
    if (state is IpLoaded) {
      return (state as IpLoaded).isVpnConnected;
    }
    return false;
  }

  @override
  Future<void> close() {
    _periodicTimer?.cancel();
    return super.close();
  }
}
