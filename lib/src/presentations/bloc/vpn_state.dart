part of 'vpn_bloc.dart';

sealed class VpnState extends Equatable {
  final int? currentPage;
  final int? nextPage;
  const VpnState(this.currentPage, {this.nextPage});
  @override
  List<Object?> get props => [currentPage, nextPage];
}

final class VpnInitial extends VpnState {
  const VpnInitial() : super(1, nextPage: null);

  @override
  List<Object?> get props => [];
}


class VpnLoading extends VpnState {
  const VpnLoading() : super(null, nextPage: null);

  @override
  List<Object?> get props => [];
}

class VpnLoaded extends VpnState {
  final V2RayStatus vpnStatus;
  final List<VpnConfig> availableConfigs;
  final VpnConfig? selectedConfig;
  final int? page;
  final int? next;

  const VpnLoaded({
    required this.vpnStatus,
    required this.availableConfigs,
    this.selectedConfig,
    this.page,
    this.next,
  }) : super(page, nextPage: next);

  VpnLoaded copyWith({
    V2RayStatus? vpnStatus,
    List<VpnConfig>? availableConfigs,
    VpnConfig? selectedConfig,
    int? page,
    int? next,
  }) {
    return VpnLoaded(
      vpnStatus: vpnStatus ?? this.vpnStatus,
      availableConfigs: availableConfigs ?? this.availableConfigs,
      selectedConfig: selectedConfig ?? this.selectedConfig,
      page: currentPage ?? this.page,
      next: nextPage ?? this.next,
    );
  }

  @override
  List<Object?> get props => [vpnStatus, availableConfigs, selectedConfig, currentPage, nextPage];
}

class VpnError extends VpnState {
  final String message;

  const VpnError(this.message) : super(null, nextPage: null);

  @override
  List<Object> get props => [message];
}
