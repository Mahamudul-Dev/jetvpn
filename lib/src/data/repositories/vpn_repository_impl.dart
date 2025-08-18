import 'package:dartz/dartz.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:jetvpn/src/shared/models/pagination_response.dart';
import '../../../main.dart';
import '../../domain/entities/failures.dart';
import '../../domain/entities/vpn_config.dart';
import '../../domain/entities/vpn_status.dart';
import '../../domain/repositories/vpn_repository.dart';
import '../datasources/vpn_datasource.dart';
import '../services/vpn_config_service.dart';
import 'dart:async';


class VpnRepositoryImpl implements VpnRepository {
  final VpnDataSource vpnDataSource;
  final VpnConfigService configService;

  late final StreamController<V2RayStatus> _statusController;

  VpnRepositoryImpl(this.vpnDataSource, this.configService) {
    _statusController = StreamController<V2RayStatus>.broadcast();
  }

  void _setupStreams() {
    logger.d('Setting up VPN repository streams...');
    
    // Listen to native status changes
    vpnDataSource.v2rayStatusStream.listen(
          (statusData) {
        logger.d('VPN status changed: ${statusData.state}');
        try {

          
          VpnConnectionStatus status;
          if (statusData.state == 'connected') {
            status = VpnConnectionStatus.connected;
            logger.d('Set status to connected');
          } else if (statusData.state == 'connecting') {
            status = VpnConnectionStatus.connecting;
            logger.d('Set status to connecting');
          } else {
            status = VpnConnectionStatus.disconnected;
            logger.d('Set status to disconnected');
          }
          
          logger.d('About to create VpnStatus object...');

          
          logger.d('VpnStatus created successfully: ${statusData.state}');
          logger.d('About to add to stream controller...');
          
          _statusController.add(statusData);
          logger.d('VPN status added to repository stream controller');
          
        } catch (e, stackTrace) {
          logger.e('Error in VPN status processing: $e');
          logger.e('Stack trace: $stackTrace');
          logger.e('StatusData that caused error: $statusData');
        }
      },
      onError: (error) {
        logger.e('VPN status stream error: $error');
      },
    );
    logger.d('VPN repository streams setup completed');
  }



  @override
  Stream<V2RayStatus> get vpnStatusStream => _statusController.stream;


  void dispose() {
    _statusController.close();
  }

  @override
  Future<Either<Failure, void>> connectV2Ray(String url) async {
    try {
      logger.d('Connecting to $url');
      await vpnDataSource.connectV2Ray(url);
      return Right(null);
    } on VpnPlatformException catch (e) {
      return Left(VpnConnectionFailure(e.message));
    } catch (e) {
      return Left(VpnConnectionFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> disconnectV2Ray() async {
    try {
      final result = await vpnDataSource.disconnectV2Ray();
      return Right(true);
    } on VpnPlatformException catch (e) {
      return Left(VpnConnectionFailure(e.message));
    } catch (e) {
      return Left(VpnConnectionFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, PaginationResponse<VpnConfig>>> getVpnServers(int? page, int? limit) async {
    try {
      final result = await vpnDataSource.getVpnConfigurations(page, limit);
      return Right(result);
    } catch (e) {
      return Future.value(Left(VpnConnectionFailure('Unexpected error: ${e.toString()}')));
    }
  }

  @override
  Future<Either<Failure, void>> init() async {
    try {
      _setupStreams();
      await vpnDataSource.init();
      return Right(null);
    } on VpnPlatformException catch (e) {
      return Future.value(Left(VpnConnectionFailure(e.message)));
    } catch (e) {
      return Future.value(Left(VpnConnectionFailure('Unexpected error: ${e.toString()}')));
    }
  }
}