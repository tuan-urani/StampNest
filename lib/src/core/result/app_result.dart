import 'failure.dart';

sealed class AppResult<T> {
  const AppResult();

  bool get isSuccess => this is AppSuccess<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) {
    final AppResult<T> current = this;
    if (current is AppSuccess<T>) {
      return success(current.data);
    }
    return failure((current as AppFailure<T>).error);
  }
}

final class AppSuccess<T> extends AppResult<T> {
  const AppSuccess(this.data);

  final T data;
}

final class AppFailure<T> extends AppResult<T> {
  const AppFailure(this.error);

  final Failure error;
}
