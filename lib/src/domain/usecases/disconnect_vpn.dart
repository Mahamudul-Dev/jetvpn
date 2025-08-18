import 'package:dartz/dartz.dart';
import '../entities/failures.dart';
import '../repositories/vpn_repository.dart';
import 'usecase.dart';


class DisconnectVpn implements UseCase<bool, NoParams> {
  final VpnRepository repository;

  DisconnectVpn(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    return await repository.disconnectV2Ray();
  }
}
