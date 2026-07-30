import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'A backend error occurred']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local cache access failed']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No network connection']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation failed']);
}
