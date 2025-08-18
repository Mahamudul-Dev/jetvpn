import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../main.dart';
import '../entities/failures.dart';
import '../repositories/vpn_repository.dart';
import 'usecase.dart';


class ConnectVpn implements UseCase<bool, ConnectVpnParams> {
  final VpnRepository repository;

  ConnectVpn(this.repository);

  @override
  Future<Either<Failure, bool>> call(ConnectVpnParams params) async {
    try {
      await repository.connectV2Ray(params.url!);
      return Right(true);
    } catch (e) {
      return Left(VpnConnectionFailure('Unexpected error: ${e.toString()}'));
    }
  }
}

class ConnectVpnParams extends Equatable {
  final String? configFileName;
  final String? url;
  const ConnectVpnParams({this.configFileName, this.url});

  @override
  List<Object?> get props => [configFileName, url];
}