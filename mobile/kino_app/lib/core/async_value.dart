/// Loading, loaded, or broken — the three states every screen here has.
///
/// A sealed family rather than the usual `T? data; bool loading; Object? error`,
/// because those three fields can spell four states that cannot happen and one
/// that matters gets forgotten. `switch` over this is exhaustive: the compiler
/// asks for the failure case, so no screen quietly renders a spinner forever.
library;

sealed class AsyncValue<T> {
  const AsyncValue();
}

final class Loading<T> extends AsyncValue<T> {
  const Loading();
}

final class Data<T> extends AsyncValue<T> {
  const Data(this.value);

  final T value;
}

final class Failure<T> extends AsyncValue<T> {
  const Failure(this.error);

  final Object error;
}
