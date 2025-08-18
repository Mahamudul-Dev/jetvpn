import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../main.dart';

class IpInfo {
  final String ip;
  final String? country;
  final String? city;
  final String? region;
  final String? isp;
  final bool isVpn;

  IpInfo({
    required this.ip,
    this.country,
    this.city,
    this.region,
    this.isp,
    this.isVpn = false,
  });

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

  @override
  String toString() => 'IpInfo(ip: $ip, country: $country, city: $city, isp: $isp)';
}

abstract class IpService {
  Future<IpInfo> getCurrentIpInfo();
}

class IpServiceImpl implements IpService {
  static const Duration _timeout = Duration(seconds: 10);
  
  // Multiple IP services as fallbacks
  static const List<String> _ipServices = [
    'https://api.ipify.org?format=json',
    'https://httpbin.org/ip',
    'https://api.ipgeolocation.io/ipgeo?apiKey=free',
    'http://ip-api.com/json',
  ];

  @override
  Future<IpInfo> getCurrentIpInfo() async {
    logger.d('Fetching current IP information...');
    
    // Try services in order until one works
    for (int i = 0; i < _ipServices.length; i++) {
      try {
        final response = await http.get(
          Uri.parse(_ipServices[i]),
          headers: {'Accept': 'application/json'},
        ).timeout(_timeout);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          logger.d('IP info fetched from service $i: $data');
          return IpInfo.fromJson(data);
        }
      } catch (e) {
        logger.w('IP service $i failed: $e');
        if (i == _ipServices.length - 1) {
          throw IpServiceException('All IP services failed. Last error: $e');
        }
      }
    }
    
    throw IpServiceException('Unable to fetch IP information');
  }

  /// Get simplified IP only (faster)
  Future<String> getCurrentIp() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.ipify.org'),
        headers: {'Accept': 'text/plain'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final ip = response.body.trim();
        logger.d('Current IP: $ip');
        return ip;
      }
    } catch (e) {
      logger.w('Failed to get simple IP: $e');
    }
    
    // Fallback to full IP info
    final ipInfo = await getCurrentIpInfo();
    return ipInfo.ip;
  }
}

class IpServiceException implements Exception {
  final String message;
  IpServiceException(this.message);
  
  @override
  String toString() => 'IpServiceException: $message';
}
