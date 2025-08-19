import 'dart:io';
import 'package:get_it/get_it.dart';

// Data layer
import '../../data/datasources/vpn_datasource.dart';
import '../../data/repositories/vpn_repository_impl.dart';
import '../../data/services/ip_service.dart';
import '../../data/services/vpn_config_service.dart';

// Domain layer
import '../../domain/repositories/vpn_repository.dart';
import '../../domain/usecases/connect_vpn.dart';
import '../../domain/usecases/disconnect_vpn.dart';
import '../../domain/usecases/get_available_configs.dart';
import '../../domain/usecases/initialize_v2ray.dart';
import '../../domain/usecases/watch_vpn_status.dart';

// Presentation layer - Specialized BLoCs
import '../../presentations/bloc/ip_bloc.dart';
import '../../presentations/bloc/vpn_bloc.dart';
import '../../presentations/bloc/vpn_connection_bloc.dart';
import '../../presentations/bloc/vpn_servers_bloc.dart';

// Core configuration
import '../routes/app_router.dart';

/// Global service locator instance
final getIt = GetIt.instance;

/// Dependency injection configuration for the JetVPN application
/// 
/// This class sets up all dependencies using the get_it service locator pattern.
/// The registration follows the clean architecture layers:
/// 1. External dependencies (HttpClient, Router)
/// 2. Services (IP service, VPN config service)
/// 3. Data sources and repositories
/// 4. Use cases (business logic)
/// 5. BLoCs (presentation logic)
/// 
/// Dependencies are registered as singletons for services that should persist
/// throughout the app lifecycle, and as lazy singletons for performance optimization.
class Locator {
  /// Initialize all application dependencies
  /// 
  /// Call this method once during app startup before running the app.
  /// The order of registration is important due to dependency relationships.
  static void initialize() {
    _registerExternalDependencies();
    _registerServices();
    _registerDataLayer();
    _registerUseCases();
    _registerBlocs();
  }

  /// Register external dependencies (network, routing, etc.)
  static void _registerExternalDependencies() {
    // HTTP client for network requests
    getIt.registerSingleton<HttpClient>(HttpClient());
    
    // App router for navigation
    getIt.registerLazySingleton<AppRouter>(() => AppRouter());
  }

  /// Register application services
  static void _registerServices() {
    // VPN configuration service for managing server configs
    getIt.registerSingleton<VpnConfigService>(VpnConfigServiceImpl());
    
    // IP service for monitoring IP address changes with caching
    getIt.registerLazySingleton<IpService>(() => IpServiceImpl());
  }

  /// Register data layer components (data sources and repositories)
  static void _registerDataLayer() {
    // VPN data source for low-level VPN operations
    getIt.registerLazySingleton<VpnDataSource>(
      () => VpnDataSourceImpl(httpClient: getIt<HttpClient>())
    );

    // VPN repository implementation following repository pattern
    getIt.registerLazySingleton<VpnRepository>(
      () => VpnRepositoryImpl(
        getIt<VpnDataSource>(), 
        getIt<VpnConfigService>()
      )
    );
  }

  /// Register business logic use cases
  static void _registerUseCases() {
    getIt
      // VPN connection use cases
      ..registerLazySingleton(() => ConnectVpn(getIt<VpnRepository>()))
      ..registerLazySingleton(() => DisconnectVpn(getIt<VpnRepository>()))
      
      // Server management use cases
      ..registerLazySingleton(() => GetAvailableConfigs(getIt<VpnRepository>()))
      
      // Status monitoring use cases
      ..registerLazySingleton(() => WatchVpnStatus(getIt<VpnRepository>()))
      
      // Initialization use cases
      ..registerLazySingleton<InitializeVpnService>(
        () => InitializeVpnService(getIt<VpnRepository>())
      );
  }

  /// Register BLoC components with proper dependency injection
  /// 
  /// BLoCs are registered in dependency order:
  /// 1. Specialized BLoCs (independent)
  /// 2. Coordinator BLoC (depends on specialized BLoCs)
  static void _registerBlocs() {
    // Specialized BLoCs - these handle specific domains independently
    
    // VPN connection management
    getIt.registerLazySingleton<VpnConnectionBloc>(
      () => VpnConnectionBloc(
        connectVpn: getIt<ConnectVpn>(),
        disconnectVpn: getIt<DisconnectVpn>(),
        watchVpnStatus: getIt<WatchVpnStatus>(),
      ),
    );

    // VPN server management and pagination
    getIt.registerLazySingleton<VpnServersBloc>(
      () => VpnServersBloc(
        getAvailableConfigs: getIt<GetAvailableConfigs>(),
      ),
    );

    // IP address monitoring with smart polling
    getIt.registerLazySingleton<IpBloc>(
      () => IpBloc(
        ipService: getIt<IpService>(),
      ),
    );

    // Main coordinator BLoC - orchestrates communication between specialized BLoCs
    getIt.registerLazySingleton<VpnBloc>(
      () => VpnBloc(
        connectionBloc: getIt<VpnConnectionBloc>(),
        serversBloc: getIt<VpnServersBloc>(),
        ipBloc: getIt<IpBloc>(),
        initializeVpnService: getIt<InitializeVpnService>(),
      ),
    );
  }

  /// Reset all dependencies (useful for testing)
  static void reset() {
    getIt.reset();
  }

  /// Check if all required dependencies are registered
  static bool get isInitialized {
    try {
      // Check for critical dependencies
      getIt<VpnBloc>();
      getIt<VpnConnectionBloc>();
      getIt<VpnServersBloc>();
      getIt<IpBloc>();
      return true;
    } catch (e) {
      return false;
    }
  }
}