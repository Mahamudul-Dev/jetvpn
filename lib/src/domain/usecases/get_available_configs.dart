import 'package:dartz/dartz.dart';
import '../../shared/models/pagination_response.dart';
import '../entities/failures.dart';
import '../entities/vpn_config.dart';
import '../repositories/vpn_repository.dart';
import 'usecase.dart';


class GetAvailableConfigs implements UseCase<PaginationResponse<VpnConfig>, Map<String, dynamic>> {
  final VpnRepository repository;

  GetAvailableConfigs(this.repository);

  @override
  Future<Either<Failure, PaginationResponse<VpnConfig>>> call(Map<String, dynamic> params) async {
    return await repository.getVpnServers(params['page'], params['limit']);
  }
}