import 'package:flutter/services.dart';
import 'dart:convert';

abstract class VpnConfigService {
  Future<String> loadConfigContent(String configFileName);
  Future<List<String>> getAvailableConfigFiles();
}

class VpnConfigServiceImpl implements VpnConfigService {
  
  @override
  Future<String> loadConfigContent(String configFileName) async {
    try {
      // For now, load from assets. In production, you can modify this
      // to load from API, cache, or other sources
      final String content = await rootBundle.loadString('assets/ovpns/$configFileName');
      return content;
    } catch (e) {
      throw VpnConfigException('Failed to load config file: $configFileName. Error: $e');
    }
  }

  /// Load config content from API (for production use)
  Future<String> loadConfigContentFromApi(String configUrl) async {
    try {
      // TODO: Implement API call to fetch config content
      // Example:
      // final response = await http.get(Uri.parse(configUrl));
      // if (response.statusCode == 200) {
      //   return response.body;
      // } else {
      //   throw VpnConfigException('Failed to fetch config from API');
      // }
      throw UnimplementedError('API config loading not implemented yet');
    } catch (e) {
      throw VpnConfigException('Failed to load config from API: $e');
    }
  }

  /// Load config content from JSON API response
  Future<String> loadConfigContentFromJson(Map<String, dynamic> apiResponse) async {
    try {
      // Assuming the API returns a JSON with a 'configContent' field
      if (apiResponse.containsKey('configContent')) {
        return apiResponse['configContent'] as String;
      } else {
        throw VpnConfigException('Config content not found in API response');
      }
    } catch (e) {
      throw VpnConfigException('Failed to parse config from JSON: $e');
    }
  }

  @override
  Future<List<String>> getAvailableConfigFiles() async {
    try {
      // For assets-based configs (development/testing)
      // In production, this would fetch available configs from your API
      return ['test.ovpn']; // You can expand this list or make it dynamic
    } catch (e) {
      throw VpnConfigException('Failed to get available configs: $e');
    }
  }

  /// Get available configs from API (for production use)
  Future<List<Map<String, String>>> getAvailableConfigsFromApi() async {
    try {
      // TODO: Implement API call to fetch available configs
      // Example:
      // final response = await http.get(Uri.parse('your-api-endpoint/configs'));
      // if (response.statusCode == 200) {
      //   final List<dynamic> configs = json.decode(response.body);
      //   return configs.map((config) => {
      //     'name': config['name'] as String,
      //     'content': config['content'] as String,
      //   }).toList();
      // }
      throw UnimplementedError('API config listing not implemented yet');
    } catch (e) {
      throw VpnConfigException('Failed to get configs from API: $e');
    }
  }
}

class VpnConfigException implements Exception {
  final String message;
  VpnConfigException(this.message);
  
  @override
  String toString() => 'VpnConfigException: $message';
}
