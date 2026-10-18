/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _ida;
import 'package:serverpod/serverpod.dart' as _is;

/// The coach's written summary of a finished game.
abstract class GameSummary
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  GameSummary._({
    this.id,
    required this.gameId,
    required this.summary,
    required this.plies,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory GameSummary({
    int? id,
    required int gameId,
    required String summary,
    required int plies,
    DateTime? createdAt,
  }) = _GameSummaryImpl;

  factory GameSummary.fromJson(Map<String, dynamic> jsonSerialization) {
    return GameSummary(
      id: jsonSerialization['id'] as int?,
      gameId: jsonSerialization['gameId'] as int,
      summary: jsonSerialization['summary'] as String,
      plies: jsonSerialization['plies'] as int,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = GameSummaryTable();

  static const db = GameSummaryRepository._();

  @override
  int? id;

  int gameId;

  String summary;

  /// How many moves the game had when it was summarised.
  int plies;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [GameSummary]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  GameSummary copyWith({
    int? id,
    int? gameId,
    String? summary,
    int? plies,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GameSummary',
      if (id != null) 'id': id,
      'gameId': gameId,
      'summary': summary,
      'plies': plies,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static GameSummaryInclude include() {
    return GameSummaryInclude._();
  }

  static GameSummaryIncludeList includeList({
    _is.WhereExpressionBuilder<GameSummaryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<GameSummaryTable>? orderBy,
    _is.OrderByListBuilder<GameSummaryTable>? orderByList,
    GameSummaryInclude? include,
  }) {
    return GameSummaryIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(GameSummary.t),
      orderByList: orderByList?.call(GameSummary.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GameSummaryImpl extends GameSummary {
  _GameSummaryImpl({
    int? id,
    required int gameId,
    required String summary,
    required int plies,
    DateTime? createdAt,
  }) : super._(
         id: id,
         gameId: gameId,
         summary: summary,
         plies: plies,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [GameSummary]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  GameSummary copyWith({
    Object? id = _Undefined,
    int? gameId,
    String? summary,
    int? plies,
    DateTime? createdAt,
  }) {
    return GameSummary(
      id: id is int? ? id : this.id,
      gameId: gameId ?? this.gameId,
      summary: summary ?? this.summary,
      plies: plies ?? this.plies,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class GameSummaryUpdateTable extends _is.UpdateTable<GameSummaryTable> {
  GameSummaryUpdateTable(super.table);

  _is.ColumnValue<int, int> gameId(int value) => _is.ColumnValue(
    table.gameId,
    value,
  );

  _is.ColumnValue<String, String> summary(String value) => _is.ColumnValue(
    table.summary,
    value,
  );

  _is.ColumnValue<int, int> plies(int value) => _is.ColumnValue(
    table.plies,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class GameSummaryTable extends _is.Table<int?> {
  GameSummaryTable({super.tableRelation}) : super(tableName: 'game_summary') {
    updateTable = GameSummaryUpdateTable(this);
    gameId = _is.ColumnInt(
      'gameId',
      this,
    );
    summary = _is.ColumnString(
      'summary',
      this,
    );
    plies = _is.ColumnInt(
      'plies',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
  }

  late final GameSummaryUpdateTable updateTable;

  late final _is.ColumnInt gameId;

  late final _is.ColumnString summary;

  /// How many moves the game had when it was summarised.
  late final _is.ColumnInt plies;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    gameId,
    summary,
    plies,
    createdAt,
  ];
}

class GameSummaryInclude extends _is.IncludeObject {
  GameSummaryInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => GameSummary.t;
}

class GameSummaryIncludeList extends _is.IncludeList {
  GameSummaryIncludeList._({
    _is.WhereExpressionBuilder<GameSummaryTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(GameSummary.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => GameSummary.t;
}

class GameSummaryRepository {
  const GameSummaryRepository._();

  /// Returns a list of [GameSummary]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<GameSummary>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<GameSummaryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<GameSummaryTable>? orderBy,
    _is.OrderByListBuilder<GameSummaryTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<GameSummary>(
      where: where?.call(GameSummary.t),
      orderBy: orderBy?.call(GameSummary.t),
      orderByList: orderByList?.call(GameSummary.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [GameSummary]s matching the given query parameters every time the
  /// source tables are modified.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// Use [throttle] to specify the minimum interval between queries. It can
  /// also be set to `null`, in which case the stream will only be throttled
  /// when its subscription is paused.
  ///
  /// Source tables are collected from the queried table, [where], [orderBy],
  /// [orderByList], and the [include] graph. [alsoTriggerOnTables] is added
  /// to that set. Pass [Table] instances such as `GameSummary.t`.
  ///
  /// Raw [Expression] SQL is not inspected. Tables referenced only in raw
  /// SQL must be passed via [alsoTriggerOnTables].
  ///
  /// The stream always reads committed state and never joins an ambient
  /// [Transaction]. Emissions for a write fire after that write commits.
  ///
  /// Currently only supported on SQLite. Calling this method on PostgreSQL
  /// throws an [UnsupportedError].
  ///
  /// ```dart
  /// var subscription = Persons.db.watch(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// ).listen((persons) {
  ///   // Handle the latest matching rows.
  /// });
  /// ```
  _ida.Stream<List<GameSummary>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<GameSummaryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<GameSummaryTable>? orderBy,
    _is.OrderByListBuilder<GameSummaryTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<GameSummary>(
      where: where?.call(GameSummary.t),
      orderBy: orderBy?.call(GameSummary.t),
      orderByList: orderByList?.call(GameSummary.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [GameSummary] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<GameSummary?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<GameSummaryTable>? where,
    int? offset,
    _is.OrderByBuilder<GameSummaryTable>? orderBy,
    _is.OrderByListBuilder<GameSummaryTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<GameSummary>(
      where: where?.call(GameSummary.t),
      orderBy: orderBy?.call(GameSummary.t),
      orderByList: orderByList?.call(GameSummary.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [GameSummary] by its [id] or null if no such row exists.
  Future<GameSummary?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<GameSummary>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [GameSummary]s in the list and returns the inserted rows.
  ///
  /// The returned [GameSummary]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  ///
  /// If [noReturn] is set to `true`, the inserted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<GameSummary>> insert(
    _is.DatabaseSession session,
    List<GameSummary> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<GameSummary>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [GameSummary] and returns the inserted row.
  ///
  /// The returned [GameSummary] will have its `id` field set.
  Future<GameSummary> insertRow(
    _is.DatabaseSession session,
    GameSummary row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<GameSummary>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [GameSummary]s in the list and returns the resulting rows.
  ///
  /// If a row conflicts on the given [conflictColumns], the existing row is
  /// updated with the new values. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies to rows matching the
  /// given expression. Conflicting rows that don't match are skipped and not
  /// returned, so the resulting list may be shorter than [rows].
  ///
  /// The returned [GameSummary]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<GameSummary>> upsert(
    _is.DatabaseSession session,
    List<GameSummary> rows, {
    required _is.ColumnSelections<GameSummaryTable> conflictColumns,
    _is.ColumnSelections<GameSummaryTable>? updateColumns,
    _is.WhereExpressionBuilder<GameSummaryTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<GameSummary>(
      rows,
      conflictColumns: conflictColumns(GameSummary.t),
      updateColumns: updateColumns?.call(GameSummary.t),
      updateWhere: updateWhere?.call(GameSummary.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [GameSummary] and returns the resulting row.
  ///
  /// If the row conflicts on the given [conflictColumns], the existing row is
  /// updated. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies when the existing
  /// row matches the expression. Returns `null` if no row was affected — for
  /// example when [updateWhere] does not match the conflicting row.
  ///
  /// The returned [GameSummary] will have its `id` field set.
  Future<GameSummary?> upsertRow(
    _is.DatabaseSession session,
    GameSummary row, {
    required _is.ColumnSelections<GameSummaryTable> conflictColumns,
    _is.ColumnSelections<GameSummaryTable>? updateColumns,
    _is.WhereExpressionBuilder<GameSummaryTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<GameSummary>(
      row,
      conflictColumns: conflictColumns(GameSummary.t),
      updateColumns: updateColumns?.call(GameSummary.t),
      updateWhere: updateWhere?.call(GameSummary.t),
      transaction: transaction,
    );
  }

  /// Updates all [GameSummary]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<GameSummary>> update(
    _is.DatabaseSession session,
    List<GameSummary> rows, {
    _is.ColumnSelections<GameSummaryTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<GameSummary>(
      rows,
      columns: columns?.call(GameSummary.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [GameSummary]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<GameSummary> updateRow(
    _is.DatabaseSession session,
    GameSummary row, {
    _is.ColumnSelections<GameSummaryTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<GameSummary>(
      row,
      columns: columns?.call(GameSummary.t),
      transaction: transaction,
    );
  }

  /// Updates a single [GameSummary] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<GameSummary?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<GameSummaryUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<GameSummary>(
      id,
      columnValues: columnValues(GameSummary.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [GameSummary]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<GameSummary>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<GameSummaryUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<GameSummaryTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<GameSummaryTable>? orderBy,
    _is.OrderByListBuilder<GameSummaryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<GameSummary>(
      columnValues: columnValues(GameSummary.t.updateTable),
      where: where(GameSummary.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(GameSummary.t),
      orderByList: orderByList?.call(GameSummary.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [GameSummary]s in the list and returns the deleted rows.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<GameSummary>> delete(
    _is.DatabaseSession session,
    List<GameSummary> rows, {
    _is.OrderByBuilder<GameSummaryTable>? orderBy,
    _is.OrderByListBuilder<GameSummaryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<GameSummary>(
      rows,
      orderBy: orderBy?.call(GameSummary.t),
      orderByList: orderByList?.call(GameSummary.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [GameSummary].
  Future<GameSummary> deleteRow(
    _is.DatabaseSession session,
    GameSummary row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<GameSummary>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<GameSummary>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<GameSummaryTable> where,
    _is.OrderByBuilder<GameSummaryTable>? orderBy,
    _is.OrderByListBuilder<GameSummaryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<GameSummary>(
      where: where(GameSummary.t),
      orderBy: orderBy?.call(GameSummary.t),
      orderByList: orderByList?.call(GameSummary.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<GameSummaryTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<GameSummary>(
      where: where?.call(GameSummary.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [GameSummary] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<GameSummaryTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<GameSummary>(
      where: where(GameSummary.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
