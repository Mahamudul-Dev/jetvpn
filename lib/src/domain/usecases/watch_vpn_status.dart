import 'package:flutter_v2ray/flutter_v2ray.dart';

import '../entities/vpn_status.dart';
import '../repositories/vpn_repository.dart';
import 'usecase.dart';
import '../../../main.dart';


class WatchVpnStatus implements StreamUseCase<V2RayStatus, NoParams> {
  final VpnRepository repository;

  WatchVpnStatus(this.repository);

  @override
  Stream<V2RayStatus> call(NoParams params) {
    logger.d('WatchVpnStatus: Getting repository stream');
    return repository.vpnStatusStream.map((vpnStatus) {
      logger.d('WatchVpnStatus: Stream emitted: $vpnStatus');
      return vpnStatus;
    });
  }
}