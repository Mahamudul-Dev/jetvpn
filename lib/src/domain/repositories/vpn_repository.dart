import 'package:dartz/dartz.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import '../../shared/models/pagination_response.dart';
import '../entities/failures.dart';
import '../entities/vpn_config.dart';
import '../entities/vpn_status.dart';

abstract class VpnRepository {
  /// Initialize VPN
  Future<Either<Failure, void>> init();

  Future<Either<Failure, PaginationResponse<VpnConfig>>> getVpnServers(int? page, int? limit);

  /// Connect to V2Ray with the specified server url
  Future<Either<Failure, void>> connectV2Ray(String url);

  /// Disconnect from V2Ray
  Future<Either<Failure, bool>> disconnectV2Ray();


  /// Stream of VPN status changes
  Stream<V2RayStatus> get vpnStatusStream;
}