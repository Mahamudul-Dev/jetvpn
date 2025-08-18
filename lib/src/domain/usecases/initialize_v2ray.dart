
import 'package:dartz/dartz.dart';
import '../entities/failures.dart';
import '../repositories/vpn_repository.dart';
import 'usecase.dart';

class InitializeVpnService implements UseCase<void, NoParams> {
  final VpnRepository repository;

  InitializeVpnService(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.init();
  }
}
