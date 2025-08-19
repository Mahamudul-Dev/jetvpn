import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../main.dart';
import '../../core/config/app_config.dart';
import '../../domain/entities/vpn_config.dart';
import '../../domain/usecases/get_available_configs.dart';

// Events
abstract class VpnServersEvent extends Equatable {
  const VpnServersEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load initial servers
class VpnServersLoadEvent extends VpnServersEvent {}

/// Event to refresh the server list
class VpnServersRefreshEvent extends VpnServersEvent {}

/// Event to load more servers (pagination)
class VpnServersLoadMoreEvent extends VpnServersEvent {}

/// Event to select a specific server
class VpnServersSelectEvent extends VpnServersEvent {
  final VpnConfig config;

  const VpnServersSelectEvent(this.config);

  @override
  List<Object> get props => [config];
}

/// Event to filter servers by country or other criteria
class VpnServersFilterEvent extends VpnServersEvent {
  final String? countryFilter;
  final String? searchQuery;

  const VpnServersFilterEvent({this.countryFilter, this.searchQuery});

  @override
  List<Object?> get props => [countryFilter, searchQuery];
}

// States
abstract class VpnServersState extends Equatable {
  const VpnServersState();

  @override
  List<Object?> get props => [];
}

/// Initial state when servers haven't been loaded yet
class VpnServersInitial extends VpnServersState {}

/// State when servers are being loaded for the first time
class VpnServersLoading extends VpnServersState {}

/// State when more servers are being loaded (pagination)
class VpnServersLoadingMore extends VpnServersState {
  final List<VpnConfig> currentServers;
  final VpnConfig? selectedConfig;

  const VpnServersLoadingMore({
    required this.currentServers,
    this.selectedConfig,
  });

  @override
  List<Object?> get props => [currentServers, selectedConfig];
}

/// State when servers are successfully loaded
class VpnServersLoaded extends VpnServersState {
  final List<VpnConfig> servers;
  final List<VpnConfig> filteredServers;
  final VpnConfig? selectedConfig;
  final int currentPage;
  final int? nextPage;
  final bool hasMorePages;
  final String? countryFilter;
  final String? searchQuery;
  final DateTime lastUpdated;

  const VpnServersLoaded({
    required this.servers,
    required this.filteredServers,
    this.selectedConfig,
    required this.currentPage,
    this.nextPage,
    required this.hasMorePages,
    this.countryFilter,
    this.searchQuery,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [
    servers,
    filteredServers,
    selectedConfig,
    currentPage,
    nextPage,
    hasMorePages,
    countryFilter,
    searchQuery,
    lastUpdated,
  ];

  /// Create a copy of this state with updated values
  VpnServersLoaded copyWith({
    List<VpnConfig>? servers,
    List<VpnConfig>? filteredServers,
    VpnConfig? selectedConfig,
    int? currentPage,
    int? nextPage,
    bool? hasMorePages,
    String? countryFilter,
    String? searchQuery,
    DateTime? lastUpdated,
  }) {
    return VpnServersLoaded(
      servers: servers ?? this.servers,
      filteredServers: filteredServers ?? this.filteredServers,
      selectedConfig: selectedConfig ?? this.selectedConfig,
      currentPage: currentPage ?? this.currentPage,
      nextPage: nextPage ?? this.nextPage,
      hasMorePages: hasMorePages ?? this.hasMorePages,
      countryFilter: countryFilter ?? this.countryFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// State when server operations encounter an error
class VpnServersError extends VpnServersState {
  final String message;
  final List<VpnConfig>? cachedServers;
  final VpnConfig? selectedConfig;

  const VpnServersError({
    required this.message,
    this.cachedServers,
    this.selectedConfig,
  });

  @override
  List<Object?> get props => [message, cachedServers, selectedConfig];
}

/// Bloc responsible for managing VPN server operations
/// 
/// This bloc handles all server-related functionality:
/// - Loading server configurations from API
/// - Pagination for large server lists
/// - Server selection and filtering
/// - Caching for better performance
/// - Search functionality
class VpnServersBloc extends Bloc<VpnServersEvent, VpnServersState> {
  final GetAvailableConfigs _getAvailableConfigs;
  
  // Cache configuration
  static const Duration _cacheExpiration = Duration(minutes: 15);
  Timer? _cacheRefreshTimer;

  VpnServersBloc({
    required GetAvailableConfigs getAvailableConfigs,
  })  : _getAvailableConfigs = getAvailableConfigs,
        super(VpnServersInitial()) {
    
    // Register event handlers
    on<VpnServersLoadEvent>(_onLoad);
    on<VpnServersRefreshEvent>(_onRefresh);
    on<VpnServersLoadMoreEvent>(_onLoadMore);
    on<VpnServersSelectEvent>(_onSelect);
    on<VpnServersFilterEvent>(_onFilter);

    // Start automatic cache refresh
    _startCacheRefreshTimer();
  }

  /// Load initial servers from the API
  /// This is typically called when the app starts or user navigates to servers
  Future<void> _onLoad(
    VpnServersLoadEvent event,
    Emitter<VpnServersState> emit,
  ) async {
    logger.d('VpnServersBloc: Loading initial servers...');
    emit(VpnServersLoading());

    try {
      final result = await _getAvailableConfigs({
        'page': 1,
        'limit': AppConfig.serverResultLimit,
      });

      result.fold(
        (failure) {
          logger.e('VpnServersBloc: Failed to load servers: ${failure.message}');
          emit(VpnServersError(message: 'Failed to load servers: ${failure.message}'));
        },
        (response) {
          final servers = response.data ?? [];
          logger.d('VpnServersBloc: Loaded ${servers.length} servers');

          emit(VpnServersLoaded(
            servers: servers,
            filteredServers: servers,
            selectedConfig: servers.isNotEmpty ? servers.first : null,
            currentPage: response.currentPage ?? 1,
            nextPage: response.nextPageUrl != null 
                ? (response.currentPage ?? 1) + 1 
                : null,
            hasMorePages: response.nextPageUrl != null,
            lastUpdated: DateTime.now(),
          ));
        },
      );
    } catch (e) {
      logger.e('VpnServersBloc: Unexpected error loading servers: $e');
      emit(VpnServersError(message: 'Unexpected error: $e'));
    }
  }

  /// Refresh the server list
  /// This replaces the current server list with fresh data from the API
  Future<void> _onRefresh(
    VpnServersRefreshEvent event,
    Emitter<VpnServersState> emit,
  ) async {
    logger.d('VpnServersBloc: Refreshing servers...');
    
    // Keep current state if we have one
    VpnConfig? currentSelection;
    if (state is VpnServersLoaded) {
      currentSelection = (state as VpnServersLoaded).selectedConfig;
    }

    try {
      final result = await _getAvailableConfigs({
        'page': 1,
        'limit': AppConfig.serverResultLimit,
      });

      result.fold(
        (failure) {
          logger.e('VpnServersBloc: Failed to refresh servers: ${failure.message}');
          
          // If we have cached servers, keep them and show error
          if (state is VpnServersLoaded) {
            final currentState = state as VpnServersLoaded;
            emit(VpnServersError(
              message: 'Refresh failed: ${failure.message}',
              cachedServers: currentState.servers,
              selectedConfig: currentState.selectedConfig,
            ));
          } else {
            emit(VpnServersError(message: 'Refresh failed: ${failure.message}'));
          }
        },
        (response) {
          final servers = response.data ?? [];
          logger.d('VpnServersBloc: Refreshed with ${servers.length} servers');

          // Try to maintain the current selection if it still exists
          VpnConfig? selectedConfig = currentSelection;
          if (selectedConfig != null) {
            final stillExists = servers.any((s) => s.id == selectedConfig!.id);
            if (!stillExists) {
              selectedConfig = servers.isNotEmpty ? servers.first : null;
            }
          } else {
            selectedConfig = servers.isNotEmpty ? servers.first : null;
          }

          emit(VpnServersLoaded(
            servers: servers,
            filteredServers: servers,
            selectedConfig: selectedConfig,
            currentPage: response.currentPage ?? 1,
            nextPage: response.nextPageUrl != null 
                ? (response.currentPage ?? 1) + 1 
                : null,
            hasMorePages: response.nextPageUrl != null,
            lastUpdated: DateTime.now(),
          ));
        },
      );
    } catch (e) {
      logger.e('VpnServersBloc: Unexpected error refreshing servers: $e');
      
      if (state is VpnServersLoaded) {
        final currentState = state as VpnServersLoaded;
        emit(VpnServersError(
          message: 'Refresh failed: $e',
          cachedServers: currentState.servers,
          selectedConfig: currentState.selectedConfig,
        ));
      } else {
        emit(VpnServersError(message: 'Refresh failed: $e'));
      }
    }
  }

  /// Load more servers for pagination
  /// Appends additional servers to the existing list
  Future<void> _onLoadMore(
    VpnServersLoadMoreEvent event,
    Emitter<VpnServersState> emit,
  ) async {
    if (state is! VpnServersLoaded) return;

    final currentState = state as VpnServersLoaded;
    if (!currentState.hasMorePages) {
      logger.d('VpnServersBloc: No more pages to load');
      return;
    }

    logger.d('VpnServersBloc: Loading more servers (page ${currentState.nextPage})...');
    emit(VpnServersLoadingMore(
      currentServers: currentState.servers,
      selectedConfig: currentState.selectedConfig,
    ));

    try {
      final result = await _getAvailableConfigs({
        'page': currentState.nextPage,
        'limit': AppConfig.serverResultLimit,
      });

      result.fold(
        (failure) {
          logger.e('VpnServersBloc: Failed to load more servers: ${failure.message}');
          emit(VpnServersError(
            message: 'Failed to load more servers: ${failure.message}',
            cachedServers: currentState.servers,
            selectedConfig: currentState.selectedConfig,
          ));
        },
        (response) {
          final newServers = response.data ?? [];
          final allServers = [...currentState.servers, ...newServers];
          logger.d('VpnServersBloc: Loaded ${newServers.length} more servers, total: ${allServers.length}');

          emit(currentState.copyWith(
            servers: allServers,
            filteredServers: _applyFilters(
              allServers, 
              currentState.countryFilter, 
              currentState.searchQuery,
            ),
            currentPage: response.currentPage ?? currentState.currentPage,
            nextPage: response.nextPageUrl != null 
                ? (response.currentPage ?? currentState.currentPage) + 1 
                : null,
            hasMorePages: response.nextPageUrl != null,
            lastUpdated: DateTime.now(),
          ));
        },
      );
    } catch (e) {
      logger.e('VpnServersBloc: Unexpected error loading more servers: $e');
      emit(VpnServersError(
        message: 'Failed to load more servers: $e',
        cachedServers: currentState.servers,
        selectedConfig: currentState.selectedConfig,
      ));
    }
  }

  /// Select a specific server configuration
  /// Updates the currently selected server
  Future<void> _onSelect(
    VpnServersSelectEvent event,
    Emitter<VpnServersState> emit,
  ) async {
    if (state is! VpnServersLoaded) return;

    final currentState = state as VpnServersLoaded;
    logger.d('VpnServersBloc: Selecting server: ${event.config.country}');

    emit(currentState.copyWith(selectedConfig: event.config));
  }

  /// Filter servers by country or search query
  /// Applies filters to the current server list
  Future<void> _onFilter(
    VpnServersFilterEvent event,
    Emitter<VpnServersState> emit,
  ) async {
    if (state is! VpnServersLoaded) return;

    final currentState = state as VpnServersLoaded;
    logger.d('VpnServersBloc: Filtering servers - country: ${event.countryFilter}, search: ${event.searchQuery}');

    final filteredServers = _applyFilters(
      currentState.servers,
      event.countryFilter,
      event.searchQuery,
    );

    // If current selection is not in filtered results, select first available
    VpnConfig? selectedConfig = currentState.selectedConfig;
    if (selectedConfig != null && !filteredServers.contains(selectedConfig)) {
      selectedConfig = filteredServers.isNotEmpty ? filteredServers.first : null;
    }

    emit(currentState.copyWith(
      filteredServers: filteredServers,
      selectedConfig: selectedConfig,
      countryFilter: event.countryFilter,
      searchQuery: event.searchQuery,
    ));
  }

  /// Apply filters to server list
  /// Helper method to filter servers based on country and search criteria
  List<VpnConfig> _applyFilters(
    List<VpnConfig> servers,
    String? countryFilter,
    String? searchQuery,
  ) {
    List<VpnConfig> filtered = servers;

    // Apply country filter
    if (countryFilter != null && countryFilter.isNotEmpty) {
      filtered = filtered
          .where((server) => 
              server.country?.toLowerCase() == countryFilter.toLowerCase())
          .toList();
    }

    // Apply search query
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered
          .where((server) =>
              server.country?.toLowerCase().contains(query) == true ||
              server.remark?.toLowerCase().contains(query) == true ||
              server.serverAddress?.toLowerCase().contains(query) == true)
          .toList();
    }

    return filtered;
  }

  /// Start automatic cache refresh timer
  /// Refreshes server data periodically to keep it up-to-date
  void _startCacheRefreshTimer() {
    _cacheRefreshTimer = Timer.periodic(_cacheExpiration, (timer) {
      if (state is VpnServersLoaded) {
        final currentState = state as VpnServersLoaded;
        final timeSinceLastUpdate = DateTime.now().difference(currentState.lastUpdated);
        
        if (timeSinceLastUpdate >= _cacheExpiration) {
          logger.d('VpnServersBloc: Cache expired, refreshing servers...');
          add(VpnServersRefreshEvent());
        }
      }
    });
  }

  /// Get list of unique countries from current servers
  List<String> get availableCountries {
    if (state is VpnServersLoaded) {
      final servers = (state as VpnServersLoaded).servers;
      return servers
          .map((s) => s.country)
          .where((country) => country != null && country.isNotEmpty)
          .map((country) => country!)
          .toSet()
          .toList()
        ..sort();
    }
    return [];
  }

  /// Get the currently selected server
  VpnConfig? get selectedServer {
    if (state is VpnServersLoaded) {
      return (state as VpnServersLoaded).selectedConfig;
    }
    return null;
  }

  /// Check if more servers can be loaded
  bool get canLoadMore {
    if (state is VpnServersLoaded) {
      return (state as VpnServersLoaded).hasMorePages;
    }
    return false;
  }

  @override
  Future<void> close() {
    logger.d('VpnServersBloc: Closing and cleaning up...');
    _cacheRefreshTimer?.cancel();
    return super.close();
  }
}