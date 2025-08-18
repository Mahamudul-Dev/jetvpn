part of 'vpn_bloc.dart';

sealed class VpnEvent extends Equatable {
  const VpnEvent();

  @override
  List<Object?> get props => [];
}


class VpnInitializeEvent extends VpnEvent {}

class VpnConnectEvent extends VpnEvent {
  final String serverUrl;

  const VpnConnectEvent(this.serverUrl);

  @override
  List<Object> get props => [serverUrl];
}

class VpnDisconnectEvent extends VpnEvent {}

class VpnRefreshConfigsEvent extends VpnEvent {}

class LoadMoreConfigsEvent extends VpnEvent {}

class VpnSelectConfigEvent extends VpnEvent {
  final VpnConfig config;

  const VpnSelectConfigEvent(this.config);

  @override
  List<Object> get props => [config];
}

class VpnStatusChangedEvent extends VpnEvent {
  final V2RayStatus statusData;

  const VpnStatusChangedEvent(this.statusData);

  @override
  List<Object> get props => [statusData];
}