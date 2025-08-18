import 'dart:io';

import 'package:get_it/get_it.dart';

import '../../data/datasources/vpn_datasource.dart';
import '../../data/repositories/vpn_repository_impl.dart';
import '../../data/services/ip_service.dart';
import '../../data/services/vpn_config_service.dart';
import '../../domain/repositories/vpn_repository.dart';
import '../../domain/usecases/connect_vpn.dart';
import '../../domain/usecases/disconnect_vpn.dart';
import '../../domain/usecases/get_available_configs.dart';
import '../../domain/usecases/initialize_v2ray.dart';
import '../../domain/usecases/watch_vpn_status.dart';
import '../../presentations/bloc/ip_bloc.dart';
import '../../presentations/bloc/vpn_bloc.dart';
import '../routes/app_router.dart';

final getIt = GetIt.instance;


class Locator {
  static initialize(){
    getIt.registerSingleton<HttpClient>(HttpClient());
    getIt.registerLazySingleton<AppRouter>(()=> AppRouter());

    getIt.registerSingleton<VpnConfigService>(VpnConfigServiceImpl());

    getIt.registerLazySingleton<IpService>(() => IpServiceImpl());

    // datasources
    getIt.registerLazySingleton<VpnDataSource>(() => VpnDataSourceImpl(httpClient: getIt<HttpClient>()));


    // repositories
    getIt.registerLazySingleton<VpnRepository>(() => VpnRepositoryImpl(getIt<VpnDataSource>(), getIt<VpnConfigService>()));

    // usecases
    getIt
    ..registerLazySingleton(()=>ConnectVpn(getIt<VpnRepository>()))
    ..registerLazySingleton(()=>DisconnectVpn(getIt<VpnRepository>()))
    ..registerLazySingleton(()=>GetAvailableConfigs(getIt<VpnRepository>()))
    ..registerLazySingleton(()=>WatchVpnStatus(getIt<VpnRepository>()))
    ..registerLazySingleton<InitializeVpnService>(() => InitializeVpnService(getIt<VpnRepository>()));
    
    // blocs
    getIt.registerLazySingleton<VpnBloc>(() => VpnBloc(
      connectVpn: getIt<ConnectVpn>(),
      disconnectVpn: getIt<DisconnectVpn>(),
      getAvailableConfigs: getIt<GetAvailableConfigs>(),
      watchVpnStatus: getIt<WatchVpnStatus>(),
      initializeVpnService: getIt<InitializeVpnService>(),
    ));
    
    getIt.registerLazySingleton<IpBloc>(() => IpBloc(
      ipService: getIt<IpService>(),
    ));
  }
}