// // This is an example of how you should update your dependency injection
// // Add this to your main.dart or dependency injection setup
//
// import 'package:jetvpn/src/data/services/vpn_config_service.dart';
//
// // In your dependency injection setup:
// void setupDependencies() {
//   // Register the VpnConfigService
//   final vpnConfigService = VpnConfigServiceImpl();
//
//   // Register VpnNativeDataSource
//   final vpnNativeDataSource = VpnNativeDataSourceImpl();
//
//   // Register VpnRepository with both dependencies
//   final vpnRepository = VpnRepositoryImpl(
//     vpnNativeDataSource,
//     vpnConfigService, // Add this new dependency
//   );
//
//   // Register your use cases
//   final connectVpn = ConnectVpn(vpnRepository);
//   final disconnectVpn = DisconnectVpn(vpnRepository);
//   final getVpnStatus = GetVpnStatus(vpnRepository);
//   final getAvailableConfigs = GetAvailableConfigs(vpnRepository);
//   final watchVpnStatus = WatchVpnStatus(vpnRepository);
//
//   // Register VpnBloc
//   final vpnBloc = VpnBloc(
//     connectVpn: connectVpn,
//     disconnectVpn: disconnectVpn,
//     getVpnStatus: getVpnStatus,
//     getAvailableConfigs: getAvailableConfigs,
//     watchVpnStatus: watchVpnStatus,
//   );
// }
