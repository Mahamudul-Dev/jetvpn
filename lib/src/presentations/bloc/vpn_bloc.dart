import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:jetvpn/main.dart';
import 'package:jetvpn/src/domain/usecases/initialize_v2ray.dart';

import '../../core/config/app_config.dart';
import '../../domain/entities/vpn_config.dart';
import '../../domain/usecases/connect_vpn.dart';
import '../../domain/usecases/disconnect_vpn.dart';
import '../../domain/usecases/get_available_configs.dart';
import '../../domain/usecases/usecase.dart';
import '../../domain/usecases/watch_vpn_status.dart';

part 'vpn_event.dart';
part 'vpn_state.dart';

class VpnBloc extends Bloc<VpnEvent, VpnState> {
  final ConnectVpn connectVpn;
  final DisconnectVpn disconnectVpn;
  final GetAvailableConfigs getAvailableConfigs;
  final WatchVpnStatus watchVpnStatus;
  late StreamSubscription _vpnStatusSubscription;
  final InitializeVpnService initializeVpnService;

  VpnBloc({
    required this.connectVpn,
    required this.disconnectVpn,
    required this.getAvailableConfigs,
    required this.watchVpnStatus,
    required this.initializeVpnService,
  }) : super(VpnInitial()) {
    // Register event handlers
    on<VpnInitializeEvent>(_onInitialize);
    on<VpnConnectEvent>(_onConnect);
    on<VpnDisconnectEvent>(_onDisconnect);
    on<VpnRefreshConfigsEvent>(_onRefreshConfigs);
    on<VpnSelectConfigEvent>(_onSelectConfig);
    on<VpnStatusChangedEvent>(_onStatusChanged);
    on<LoadMoreConfigsEvent>(_onLoadMoreConfigs);
  }



  void _startStatusStream() {
    logger.d('VpnBloc: Setting up status stream listener...');
    _vpnStatusSubscription = watchVpnStatus(NoParams()).listen(
          (vpnStatus) {
        logger.d('VPN status updated in bloc: $vpnStatus');
        add(VpnStatusChangedEvent(vpnStatus));
      },
      onError: (error) {
        logger.e('VpnBloc: Status stream error: $error');
      },
      onDone: () {
        logger.d('VpnBloc: Status stream closed');
      },
    );
    logger.d('VpnBloc: Status stream listener setup completed');
  }

  Future<void> _onInitialize(VpnInitializeEvent event, Emitter<VpnState> emit) async {
    emit(VpnLoading());

    try {
      await initializeVpnService.call(NoParams());

      // Get current VPN status
      final configsResult = await getAvailableConfigs({
        'page': state.currentPage ?? 1,
        'limit': AppConfig.serverResultLimit
      });

      if (configsResult.isLeft()) {
        emit(const VpnError('Failed to initialize VPN'));
        return;
      }

      _startStatusStream();

      // statusResult.fold(((failure){
      //   vpnStatus = VpnStatus(
      //     status: VpnConnectionStatus.error,
      //     message: failure.message,
      //   );
      // }), (v2RayStatus) {
      //   if (v2RayStatus.state == 'CONNECTED') {
      //     vpnStatus = VpnStatus(
      //       status: VpnConnectionStatus.connected,
      //       message: v2RayStatus.state,
      //       connectedAt: DateTime.tryParse(v2RayStatus.duration),
      //     );
      //   } else {
      //     vpnStatus = VpnStatus(
      //       status: VpnConnectionStatus.disconnected,
      //       message: v2RayStatus.state,
      //     );
      //   }
      // });

      configsResult.fold(((failure){
        emit(const VpnError('Failed to initialize VPN'));
      }), (result) {
        final servers = result.data;
        final currentPage = result.currentPage;
        final nextPage = result.nextPageUrl != null ? result.currentPage! + 1 : null;

        emit(VpnLoaded(
          vpnStatus: V2RayStatus(state: 'DISCONNECTED'),
          availableConfigs: servers ?? [],
          selectedConfig: servers?.firstOrNull,
          page: currentPage,
          next: nextPage
        ));
      });
    } catch (e) {
      emit(VpnError('Initialization failed: ${e.toString()}'));
    }
  }

  Future<void> _onConnect(VpnConnectEvent event, Emitter<VpnState> emit) async {
    logger.d('Connecting to ${event.serverUrl}');
    if (state is! VpnLoaded) return;

    final currentState = state as VpnLoaded;

    // Update status to connecting
    emit(currentState.copyWith(
      vpnStatus: currentState.vpnStatus
    ));

    final result = await connectVpn(ConnectVpnParams(url: event.serverUrl));

    logger.d('Connection result: $result');

    result.fold(
      (failure) {
        emit(currentState.copyWith(
          vpnStatus: currentState.vpnStatus
        ));
      },
      (success) {
        emit(currentState.copyWith(
          vpnStatus: currentState.vpnStatus
        ));
      },
    );
  }

  Future<void> _onDisconnect(VpnDisconnectEvent event, Emitter<VpnState> emit) async {
    if (state is! VpnLoaded) return;

    final currentState = state as VpnLoaded;

    // Update status to disconnecting
    emit(currentState.copyWith(
      vpnStatus: currentState.vpnStatus
    ));

    final result = await disconnectVpn(NoParams());

    result.fold(
          (failure) {
        emit(currentState.copyWith(
          vpnStatus: currentState.vpnStatus
        ));
      },
          (success) {
        // Status will be updated via stream
            emit(currentState.copyWith(
                vpnStatus: currentState.vpnStatus
            ));
      },
    );
  }

  Future<void> _onRefreshConfigs(VpnRefreshConfigsEvent event, Emitter<VpnState> emit) async {
    if (state is! VpnLoaded) return;

    final currentState = state as VpnLoaded;

    final result = await getAvailableConfigs({
      'page': currentState.page,
      'limit': AppConfig.serverResultLimit
    });

    result.fold(
          (failure) {
        emit(VpnError('Failed to refresh configurations: ${failure.message}'));
      },
          (res) {
        final selectedConfig = currentState.selectedConfig ??
            (res.data?.firstOrNull);

        emit(currentState.copyWith(
          availableConfigs: res.data ?? [],
          selectedConfig: selectedConfig,
        ));
      },
    );
  }

  Future<void> _onSelectConfig(VpnSelectConfigEvent event, Emitter<VpnState> emit) async {
    if (state is! VpnLoaded) return;

    final currentState = state as VpnLoaded;

    emit(currentState.copyWith(selectedConfig: event.config));
  }

  Future<void> _onStatusChanged(VpnStatusChangedEvent event, Emitter<VpnState> emit) async {
    if (state is! VpnLoaded) return;

    final currentState = state as VpnLoaded;
    final newStatus = event.statusData;

    emit(currentState.copyWith(vpnStatus: newStatus));
  }

  Future<void> _onLoadMoreConfigs(LoadMoreConfigsEvent event, Emitter<VpnState> emit) async {
    if (state is! VpnLoaded) return;

    try {
      final currentState = state as VpnLoaded;

      final result = await getAvailableConfigs({
        'page': currentState.nextPage,
        'limit': AppConfig.serverResultLimit
      });

      result.fold(
            (failure) {
          emit(VpnError('Failed to load more configurations: ${failure.message}'));
        },
            (res) {
          emit(currentState.copyWith(
            availableConfigs: currentState.availableConfigs + (res.data ?? []),
            page: res.currentPage,
            next: res.nextPageUrl == null ? null : int.parse(res.nextPageUrl!.split('page=')[1]),
          ));
        },
      );
    } catch (e) {
      emit(VpnError('Failed to load more configurations: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _vpnStatusSubscription.cancel();
    return super.close();
  }
}
