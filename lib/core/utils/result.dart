import '../errors/failures.dart';

abstract class Result<T, F extends Failure> {
  const Result();

  bool get isSuccess => this is Success<T, F>;
  bool get isError => this is Error<T, F>;

  T? get data => isSuccess ? (this as Success<T, F>).value : null;
  F? get failure => isError ? (this as Error<T, F>).error : null;

  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(F failure) onError,
  }) {
    if (this is Success<T, F>) {
      return onSuccess((this as Success<T, F>).value);
    } else {
      return onError((this as Error<T, F>).error);
    }
  }
}

class Success<T, F extends Failure> extends Result<T, F> {
  final T value;
  const Success(this.value);
}

class Error<T, F extends Failure> extends Result<T, F> {
  final F error;
  const Error(this.error);
}
