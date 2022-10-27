import 'dart:async';

abstract class Store {
  Iterable<String> get keys;

  Stream<Map<String, dynamic>?> watch(String dataId);

  FutureOr<Map<String, dynamic>?> get(String dataId);

  FutureOr<void> put(String dataId, Map<String, dynamic>? value);

  FutureOr<void> putAll(Map<String, Map<String, dynamic>?> data);

  FutureOr<void> delete(String dataId);

  FutureOr<void> deleteAll(Iterable<String> dataIds);

  FutureOr<void> clear();

  Future<void> dispose() async => null;
}
