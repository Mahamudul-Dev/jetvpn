import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../../main.dart';

/// Model representing IP information with geolocation data
class IpInfo {
  final String ip;
  final String? country;
  final String? city;
  final String? region;
  final String? isp;
  final bool isVpn;
  final DateTime timestamp;

  IpInfo({
    required this.ip,
    this.country,
    this.city,
    this.region,
    this.isp,
    this.isVpn = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create IpInfo from JSON response
  factory IpInfo.fromJson(Map<String, dynamic> json) {
    return IpInfo(
      ip: json['ip'] ?? json['query'] ?? 'Unknown',
      country: json['country'] ?? json['countryName'],
      city: json['city'],
      region: json['region'] ?? json['regionName'],
      isp: json['isp'] ?? json['org'],
      isVpn: json['proxy'] == true || json['hosting'] == true,
    );
  }

  /// Check if this IP info is still fresh based on cache duration
  bool isFresh(Duration cacheDuration) {
    return DateTime.now().difference(timestamp) < cacheDuration;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IpInfo &&
          runtimeType == other.runtimeType &&
          ip == other.ip &&
          country == other.country;

  @override
  int get hashCode => ip.hashCode ^ country.hashCode;

  @override
  String toString() => 'IpInfo(ip: $ip, country: $country, city: $city, isp: $isp, vpn: $isVpn)';
}

/// Abstract interface for IP service
abstract class IpService {
  Future<IpInfo> getCurrentIpInfo();
  Future<String> getCurrentIp();
  void clearCache();
  bool get hasCache;
}

/// Enhanced IP service with caching, smart polling, and better error handling
class IpServiceImpl implements IpService {
  static const Duration _timeout = Duration(seconds: 10);
  static const Duration _cacheExpiration = Duration(minutes: 5);
  static const Duration _shortCacheExpiration = Duration(minutes: 1);
  
  // Cache for IP information
  IpInfo? _cachedIpInfo;
  String? _cachedIp;
  DateTime? _lastIpCheck;
  DateTime? _lastFullInfoCheck;
  
  // Request throttling to prevent API abuse
  DateTime? _lastRequestTime;
  static const Duration _requestThrottle = Duration(seconds: 2);
  
  // Multiple IP services with priorities (fastest first)
  static const List<_IpServiceEndpoint> _ipServices = [
    _IpServiceEndpoint(
      url: 'https://api.ipify.org?format=json',
      type: _ServiceType.ipify,
      priority: 1,
    ),
    _IpServiceEndpoint(
      url: 'https://httpbin.org/ip',
      type: _ServiceType.httpbin,
      priority: 2,
    ),
    _IpServiceEndpoint(
      url: 'http://ip-api.com/json',
      type: _ServiceType.ipApi,
      priority: 3,
    ),
    _IpServiceEndpoint(
      url: 'https://api.ipgeolocation.io/ipgeo?apiKey=free',
      type: _ServiceType.ipGeolocation,
      priority: 4,
    ),
  ];

  @override
  Future<IpInfo> getCurrentIpInfo() async {
    logger.d('Fetching current IP information...');
    
    // Check if we have fresh cached data
    if (_cachedIpInfo != null && _cachedIpInfo!.isFresh(_cacheExpiration)) {
      logger.d('Using cached IP info: ${_cachedIpInfo!.ip}');
      return _cachedIpInfo!;
    }

    // Throttle requests to prevent API abuse
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < _requestThrottle) {
        final waitTime = _requestThrottle - timeSinceLastRequest;
        logger.d('Throttling IP request, waiting ${waitTime.inMilliseconds}ms');
        await Future.delayed(waitTime);
      }
    }

    _lastRequestTime = DateTime.now();
    
    // Try services in order of priority until one works
    Exception? lastException;
    
    for (final service in _ipServices) {
      try {
        logger.d('Trying IP service: ${service.type.name}');
        
        final response = await http.get(
          Uri.parse(service.url),
          headers: {'Accept': 'application/json'},
        ).timeout(_timeout);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          logger.d('IP info fetched from ${service.type.name}: ${data['ip'] ?? data['query']}');
          
          final ipInfo = IpInfo.fromJson(data);
          
          // Cache the successful result
          _cachedIpInfo = ipInfo;
          _lastFullInfoCheck = DateTime.now();
          
          return ipInfo;
        } else {
          logger.w('IP service ${service.type.name} returned status: ${response.statusCode}');
        }
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        logger.w('IP service ${service.type.name} failed: $e');
      }
    }
    
    // All services failed - check if we have stale cached data as fallback
    if (_cachedIpInfo != null) {
      logger.w('All IP services failed, using stale cached data');
      return _cachedIpInfo!;
    }
    
    throw IpServiceException(
      'All IP services failed. Last error: ${lastException?.toString() ?? "Unknown error"}'
    );
  }

  @override
  Future<String> getCurrentIp() async {
    logger.d('Fetching current IP address...');
    
    // Check if we have fresh cached IP
    if (_cachedIp != null && _lastIpCheck != null) {
      final cacheAge = DateTime.now().difference(_lastIpCheck!);
      if (cacheAge < _shortCacheExpiration) {
        logger.d('Using cached IP: $_cachedIp');
        return _cachedIp!;
      }
    }

    // Throttle requests
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < _requestThrottle) {
        final waitTime = _requestThrottle - timeSinceLastRequest;
        await Future.delayed(waitTime);
      }
    }

    _lastRequestTime = DateTime.now();

    // Try fast IP-only endpoint first
    try {
      final response = await http.get(
        Uri.parse('https://api.ipify.org'),
        headers: {'Accept': 'text/plain'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final ip = response.body.trim();
        logger.d('Current IP fetched: $ip');
        
        // Cache the result
        _cachedIp = ip;
        _lastIpCheck = DateTime.now();
        
        return ip;
      }
    } catch (e) {
      logger.w('Failed to get simple IP: $e');
    }
    
    // Fallback to full IP info if simple method fails
    try {
      final ipInfo = await getCurrentIpInfo();
      _cachedIp = ipInfo.ip;
      _lastIpCheck = DateTime.now();
      return ipInfo.ip;
    } catch (e) {
      // Final fallback - return cached IP if available
      if (_cachedIp != null) {
        logger.w('Using stale cached IP as final fallback');
        return _cachedIp!;
      }
      rethrow;
    }
  }

  @override
  void clearCache() {
    logger.d('Clearing IP service cache');
    _cachedIpInfo = null;
    _cachedIp = null;
    _lastIpCheck = null;
    _lastFullInfoCheck = null;
  }

  @override
  bool get hasCache {
    return _cachedIpInfo != null || _cachedIp != null;
  }

  /// Check if IP has changed since last check
  Future<bool> hasIpChanged() async {
    if (_cachedIp == null) return true;
    
    try {
      final currentIp = await getCurrentIp();
      return currentIp != _cachedIp;
    } catch (e) {
      logger.w('Failed to check IP change: $e');
      return false; // Assume no change if we can't check
    }
  }

  /// Get cache status for debugging
  Map<String, dynamic> getCacheStatus() {
    return {
      'hasCachedIp': _cachedIp != null,
      'hasCachedInfo': _cachedIpInfo != null,
      'lastIpCheck': _lastIpCheck?.toIso8601String(),
      'lastFullInfoCheck': _lastFullInfoCheck?.toIso8601String(),
      'ipCacheAge': _lastIpCheck != null 
          ? DateTime.now().difference(_lastIpCheck!).inMinutes 
          : null,
      'infoCacheAge': _lastFullInfoCheck != null 
          ? DateTime.now().difference(_lastFullInfoCheck!).inMinutes 
          : null,
    };
  }
}

/// Exception thrown by IP service operations
class IpServiceException implements Exception {
  final String message;
  IpServiceException(this.message);
  
  @override
  String toString() => 'IpServiceException: $message';
}

/// Internal class to represent IP service endpoints
class _IpServiceEndpoint {
  final String url;
  final _ServiceType type;
  final int priority;

  const _IpServiceEndpoint({
    required this.url,
    required this.type,
    required this.priority,
  });
}

/// Enum for different IP service types
enum _ServiceType {
  ipify,
  httpbin,
  ipApi,
  ipGeolocation,
}
