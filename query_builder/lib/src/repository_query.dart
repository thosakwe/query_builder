import 'dart:async';
import 'results/results.dart';
import 'equality.dart';
import 'join_type.dart';
import 'order_by.dart';
import 'single_query.dart';
import 'union_type.dart';

abstract class RepositoryQuery<T> {
  Stream<T> get();

  Future<num> average(String fieldName);

  Future<int> count();

  Future<DeletionResult<T>> delete();

  RepositoryQuery<T> distinct(Iterable<String> fieldNames);

  SingleQuery<T> first();

  RepositoryQuery<T> groupBy(String fieldName);

  RepositoryQuery<T> inRandomOrder();

  RepositoryQuery<T> latest([String fieldName = 'created_at']) =>
      orderBy(fieldName, OrderBy.DESCENDING);

  // TODO: Join

  RepositoryQuery<T> orderBy(String fieldName,
      [OrderBy orderBy = OrderBy.ASCENDING]);

  Future<List<U>> map<U>(U convert(T t)) => get().map<U>(convert).toList();

  Future<num> min(String fieldName);

  Future<num> max(String fieldName);

  RepositoryQuery<T> oldest([String fieldName = 'created_at']) =>
      orderBy(fieldName, OrderBy.ASCENDING);

  Future<Iterable<U>> pluck<U>(Iterable<String> fieldNames);

  RepositoryQuery<T> select(Iterable selectors);

  RepositoryQuery<T> skip(int count);

  Future<num> sum(String fieldName);

  RepositoryQuery<T> take(int count);

  RepositoryQuery<T> join(
      String otherTable, String nearColumn, String farColumn,
      [JoinType joinType = JoinType.INNER]);

  RepositoryQuery<T> selfJoin(String t1, String t2);

  RepositoryQuery<T> union(RepositoryQuery<T> other,
      [UnionType unionType = UnionType.NORMAL]);

  Future<Iterable<UpdateResult<T>>> updateAll(Map<String, dynamic> fields);

  RepositoryQuery<T> when(
      bool condition, RepositoryQuery<T> ifTrue(RepositoryQuery<T> query),
      [RepositoryQuery<T> ifFalse(RepositoryQuery<T> query)]) {
    if (condition == true)
      return ifTrue(this);
    else if (ifFalse != null) return ifFalse(this);
    return this;
  }

  RepositoryQuery<T> where(String fieldName, value) =>
      whereEquality(fieldName, value, Equality.EQUAL);

  RepositoryQuery<T> whereNot(String fieldName, value) =>
      whereEquality(fieldName, value, Equality.NOT_EQUAL);

  RepositoryQuery<T> whereBetween(String fieldName, lower, upper);

  RepositoryQuery<T> whereNotBetween(String fieldName, lower, upper);

  RepositoryQuery<T> whereDate(String fieldName, DateTime date,
      {bool time: true});

  RepositoryQuery<T> whereDay(String fieldName, int day);

  RepositoryQuery<T> whereMonth(String fieldName, int month);

  RepositoryQuery<T> whereYear(String fieldName, int year);

  RepositoryQuery<T> whereIn(String fieldName, Iterable values);

  RepositoryQuery<T> whereNotIn(String fieldName, Iterable values);

  RepositoryQuery<T> whereEquality(String fieldName, value, Equality equality);

  RepositoryQuery<T> whereLike(String fieldName, value);

  RepositoryQuery<T> whereNull(String fieldName) => where(fieldName, null);

  RepositoryQuery<T> whereNotNull(String fieldName) =>
      whereNot(fieldName, null);

  Future<Iterable> chunk(int threshold, FutureOr callback(List<T> items)) {
    var c = new Completer<List>();
    StreamSubscription<T> sub;
    List results = [];
    List<T> items = [];

    sub = get().listen(
        (T item) async {
          items.add(item);

          if (items.length >= threshold) {
            var result = await callback(items);
            results.add(result);
            items.clear();

            if (result == false) await sub.cancel();
          }
        },
        cancelOnError: true,
        onDone: () async {
          if (items.isNotEmpty) {
            results.add(await callback(items));
            items.clear();
          }

          c.complete(results);
        },
        onError: c.completeError);

    return c.future;
  }

  RepositoryQuery<T> not(RepositoryQuery<T> other);

  RepositoryQuery<T> or(RepositoryQuery<T> other);
}
