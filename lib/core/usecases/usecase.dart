import '../errors/failures.dart';
import '../utils/result.dart';

abstract class UseCase<TType, Params> {
  Future<Result<TType, Failure>> call(Params params);
}

class NoParams {
  const NoParams();
}
