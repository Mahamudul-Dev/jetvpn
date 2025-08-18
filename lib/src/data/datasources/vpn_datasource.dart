import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'dart:async';

import '../../../main.dart';
import '../../core/config/app_config.dart';
import '../../shared/models/pagination_response.dart';
import '../models/vpn_config_model.dart';
import '../services/vpn_config_service.dart';

abstract class VpnDataSource {

  Future<void> init();
  Future<void> connectV2Ray(String url);
  Future<void> disconnectV2Ray();
  Future<int> getV2RayServerDelay(String url);
  Future<int> getConnectedV2RayServerDelay();
  Future<PaginationResponse<VpnConfigModel>> getVpnConfigurations(int? page, int? limit);
  Stream<V2RayStatus> get v2rayStatusStream;
}


class VpnDataSourceImpl implements VpnDataSource {
  final HttpClient httpClient;


  VpnDataSourceImpl({required this.httpClient});

  static const platform = MethodChannel(AppConfig.vpnMethodChannel);

  final StreamController<V2RayStatus> _statusController =
  StreamController<V2RayStatus>.broadcast();

  // V2Ray instance
  late final FlutterV2ray  _flutterV2Ray;
  bool _isInitialized = false;


  // subnets for V2Ray
  final List<String> subnets = [
    "0.0.0.0/5",
    "8.0.0.0/7",
    "11.0.0.0/8",
    "12.0.0.0/6",
    "16.0.0.0/4",
    "32.0.0.0/3",
    "64.0.0.0/2",
    "128.0.0.0/3",
    "160.0.0.0/5",
    "168.0.0.0/6",
    "172.0.0.0/12",
    "172.32.0.0/11",
    "172.64.0.0/10",
    "172.128.0.0/9",
    "173.0.0.0/8",
    "174.0.0.0/7",
    "176.0.0.0/4",
    "192.0.0.0/9",
    "192.128.0.0/11",
    "192.160.0.0/13",
    "192.169.0.0/16",
    "192.170.0.0/15",
    "192.172.0.0/14",
    "192.176.0.0/12",
    "192.192.0.0/10",
    "193.0.0.0/8",
    "194.0.0.0/7",
    "196.0.0.0/6",
    "200.0.0.0/5",
    "208.0.0.0/4",
    "240.0.0.0/4",
  ];


  void dispose() {
    _statusController.close();
  }

  @override
  Future<void> connectV2Ray(String url) async {
    logger.d('Connecting to $url');
    final granted = await _flutterV2Ray.requestPermission();
    logger.d('Permission status: $granted');

    V2RayURL parser = FlutterV2ray.parseFromURL(url);
    String remark = parser.remark;
    String config = parser.getFullConfiguration();

    if(granted){
      _flutterV2Ray.startV2Ray(remark: remark, config: config, bypassSubnets: subnets, proxyOnly: false);
    }
  }

  @override
  Future<void> disconnectV2Ray() {
    return _flutterV2Ray.stopV2Ray();
  }

  @override
  Future<int> getV2RayServerDelay(String url) async {
    final parser = FlutterV2ray.parseFromURL(url);
    final delay = await _flutterV2Ray.getServerDelay(config: parser.getFullConfiguration());
    logger.d('Server delay: $delay');
    return delay;
  }


  @override
  Stream<V2RayStatus> get v2rayStatusStream => _statusController.stream;

  @override
  Future<void> init() async {
    if(!_isInitialized){
      _flutterV2Ray = FlutterV2ray(
        onStatusChanged: (status) {
          logger.d('V2Ray status changed: ');
          _statusController.add(status);
        },
      );

      await _flutterV2Ray.initializeV2Ray();
      _isInitialized = true;
    }
  }

  @override
  Future<PaginationResponse<VpnConfigModel>> getVpnConfigurations(int? page, int? limit) async {
    try {
      final httpRequest = await httpClient.getUrl(Uri.parse('${AppConfig.serversPath}/?page=$page&limit=$limit'),);
      final httpResponse = await httpRequest.close();
      final responseBody = await httpResponse.transform(utf8.decoder).join();
      logger.d('Response: $responseBody');
      if (httpResponse.statusCode == 200) {
        final result = PaginationResponse<VpnConfigModel>.fromJson(json.decode(responseBody), VpnConfigModel.fromJson);
        return result;
      } else {
        throw VpnConfigException('Failed to get configs from API');
      }
    } on HttpException catch (e){
      throw VpnConfigException('Failed to get configs from API: $e');
    }
  }

  @override
  Future<int> getConnectedV2RayServerDelay() {
    return _flutterV2Ray.getConnectedServerDelay();
  }

}

class VpnPlatformException implements Exception {
  final String message;
  VpnPlatformException(this.message);
}