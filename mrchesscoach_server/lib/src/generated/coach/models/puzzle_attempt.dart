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

/// One rated puzzle attempt.
abstract class PuzzleAttempt
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  PuzzleAttempt._({
    this.id,
    required this.userId,
    required this.puzzleId,
    required this.solved,
    required this.puzzleRating,
    required this.ratingAfter,
    required this.themes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory PuzzleAttempt({
    int? id,
    required _is.UuidValue userId,
    required String puzzleId,
    required bool solved,
    required int puzzleRating,
    required int ratingAfter,
    required String themes,
    DateTime? createdAt,
  }) = _PuzzleAttemptImpl;

  factory PuzzleAttempt.fromJson(Map<String, dynamic> jsonSerialization) {
    return PuzzleAttempt(
      id: jsonSerialization['id'] as int?,
      userId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      puzzleId: jsonSerialization['puzzleId'] as String,
      solved: _is.BoolJsonExtension.fromJson(jsonSerialization['solved']),
      puzzleRating: jsonSerialization['puzzleRating'] as int,
      ratingAfter: jsonSerialization['ratingAfter'] as int,
      themes: jsonSerialization['themes'] as String,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = PuzzleAttemptTable();

  static const db = PuzzleAttemptRepository._();

  @override
  int? id;

  _is.UuidValue userId;

  String puzzleId;

  bool solved;

  int puzzleRating;

  int ratingAfter;

  /// Space-separated Lichess themes of the puzzle.
  String themes;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [PuzzleAttempt]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PuzzleAttempt copyWith({
    int? id,
    _is.UuidValue? userId,
    String? puzzleId,
    bool? solved,
    int? puzzleRating,
    int? ratingAfter,
    String? themes,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PuzzleAttempt',
      if (id != null) 'id': id,
      'userId': userId.toJson(),
      'puzzleId': puzzleId,
      'solved': solved,
      'puzzleRating': puzzleRating,
      'ratingAfter': ratingAfter,
      'themes': themes,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static PuzzleAttemptInclude include() {
    return PuzzleAttemptInclude._();
  }

  static PuzzleAttemptIncludeList includeList({
    _is.WhereExpressionBuilder<PuzzleAttemptTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PuzzleAttemptTable>? orderBy,
    _is.OrderByListBuilder<PuzzleAttemptTable>? orderByList,
    PuzzleAttemptInclude? include,
  }) {
    return PuzzleAttemptIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PuzzleAttempt.t),
      orderByList: orderByList?.call(PuzzleAttempt.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PuzzleAttemptImpl extends PuzzleAttempt {
  _PuzzleAttemptImpl({
    int? id,
    required _is.UuidValue userId,
    required String puzzleId,
    required bool solved,
    required int puzzleRating,
    required int ratingAfter,
    required String themes,
    DateTime? createdAt,
  }) : super._(
         id: id,
         userId: userId,
         puzzleId: puzzleId,
         solved: solved,
         puzzleRating: puzzleRating,
         ratingAfter: ratingAfter,
         themes: themes,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [PuzzleAttempt]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PuzzleAttempt copyWith({
    Object? id = _Undefined,
    _is.UuidValue? userId,
    String? puzzleId,
    bool? solved,
    int? puzzleRating,
    int? ratingAfter,
    String? themes,
    DateTime? createdAt,
  }) {
    return PuzzleAttempt(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      puzzleId: puzzleId ?? this.puzzleId,
      solved: solved ?? this.solved,
      puzzleRating: puzzleRating ?? this.puzzleRating,
      ratingAfter: ratingAfter ?? this.ratingAfter,
      themes: themes ?? this.themes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class PuzzleAttemptUpdateTable extends _is.UpdateTable<PuzzleAttemptTable> {
  PuzzleAttemptUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> userId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.userId,
        value,
      );

  _is.ColumnValue<String, String> puzzleId(String value) => _is.ColumnValue(
    table.puzzleId,
    value,
  );

  _is.ColumnValue<bool, bool> solved(bool value) => _is.ColumnValue(
    table.solved,
    value,
  );

  _is.ColumnValue<int, int> puzzleRating(int value) => _is.ColumnValue(
    table.puzzleRating,
    value,
  );

  _is.ColumnValue<int, int> ratingAfter(int value) => _is.ColumnValue(
    table.ratingAfter,
    value,
  );

  _is.ColumnValue<String, String> themes(String value) => _is.ColumnValue(
    table.themes,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class PuzzleAttemptTable extends _is.Table<int?> {
  PuzzleAttemptTable({super.tableRelation})
    : super(tableName: 'puzzle_attempt') {
    updateTable = PuzzleAttemptUpdateTable(this);
    userId = _is.ColumnUuid(
      'userId',
      this,
    );
    puzzleId = _is.ColumnString(
      'puzzleId',
      this,
    );
    solved = _is.ColumnBool(
      'solved',
      this,
    );
    puzzleRating = _is.ColumnInt(
      'puzzleRating',
      this,
    );
    ratingAfter = _is.ColumnInt(
      'ratingAfter',
      this,
    );
    themes = _is.ColumnString(
      'themes',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
  }

  late final PuzzleAttemptUpdateTable updateTable;

  late final _is.ColumnUuid userId;

  late final _is.ColumnString puzzleId;

  late final _is.ColumnBool solved;

  late final _is.ColumnInt puzzleRating;

  late final _is.ColumnInt ratingAfter;

  /// Space-separated Lichess themes of the puzzle.
  late final _is.ColumnString themes;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    userId,
    puzzleId,
    solved,
    puzzleRating,
    ratingAfter,
    themes,
    createdAt,
  ];
}

class PuzzleAttemptInclude extends _is.IncludeObject {
  PuzzleAttemptInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => PuzzleAttempt.t;
}

class PuzzleAttemptIncludeList extends _is.IncludeList {
  PuzzleAttemptIncludeList._({
    _is.WhereExpressionBuilder<PuzzleAttemptTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(PuzzleAttempt.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => PuzzleAttempt.t;
}

class PuzzleAttemptRepository {
  const PuzzleAttemptRepository._();

  /// Returns a list of [PuzzleAttempt]s matching the given query parameters.
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
  Future<List<PuzzleAttempt>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PuzzleAttemptTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PuzzleAttemptTable>? orderBy,
    _is.OrderByListBuilder<PuzzleAttemptTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<PuzzleAttempt>(
      where: where?.call(PuzzleAttempt.t),
      orderBy: orderBy?.call(PuzzleAttempt.t),
      orderByList: orderByList?.call(PuzzleAttempt.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [PuzzleAttempt]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `PuzzleAttempt.t`.
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
  _ida.Stream<List<PuzzleAttempt>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PuzzleAttemptTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PuzzleAttemptTable>? orderBy,
    _is.OrderByListBuilder<PuzzleAttemptTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<PuzzleAttempt>(
      where: where?.call(PuzzleAttempt.t),
      orderBy: orderBy?.call(PuzzleAttempt.t),
      orderByList: orderByList?.call(PuzzleAttempt.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [PuzzleAttempt] matching the given query parameters.
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
  Future<PuzzleAttempt?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PuzzleAttemptTable>? where,
    int? offset,
    _is.OrderByBuilder<PuzzleAttemptTable>? orderBy,
    _is.OrderByListBuilder<PuzzleAttemptTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<PuzzleAttempt>(
      where: where?.call(PuzzleAttempt.t),
      orderBy: orderBy?.call(PuzzleAttempt.t),
      orderByList: orderByList?.call(PuzzleAttempt.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [PuzzleAttempt] by its [id] or null if no such row exists.
  Future<PuzzleAttempt?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<PuzzleAttempt>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [PuzzleAttempt]s in the list and returns the inserted rows.
  ///
  /// The returned [PuzzleAttempt]s will have their `id` fields set.
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
  Future<List<PuzzleAttempt>> insert(
    _is.DatabaseSession session,
    List<PuzzleAttempt> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<PuzzleAttempt>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [PuzzleAttempt] and returns the inserted row.
  ///
  /// The returned [PuzzleAttempt] will have its `id` field set.
  Future<PuzzleAttempt> insertRow(
    _is.DatabaseSession session,
    PuzzleAttempt row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<PuzzleAttempt>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [PuzzleAttempt]s in the list and returns the resulting rows.
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
  /// The returned [PuzzleAttempt]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PuzzleAttempt>> upsert(
    _is.DatabaseSession session,
    List<PuzzleAttempt> rows, {
    required _is.ColumnSelections<PuzzleAttemptTable> conflictColumns,
    _is.ColumnSelections<PuzzleAttemptTable>? updateColumns,
    _is.WhereExpressionBuilder<PuzzleAttemptTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<PuzzleAttempt>(
      rows,
      conflictColumns: conflictColumns(PuzzleAttempt.t),
      updateColumns: updateColumns?.call(PuzzleAttempt.t),
      updateWhere: updateWhere?.call(PuzzleAttempt.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [PuzzleAttempt] and returns the resulting row.
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
  /// The returned [PuzzleAttempt] will have its `id` field set.
  Future<PuzzleAttempt?> upsertRow(
    _is.DatabaseSession session,
    PuzzleAttempt row, {
    required _is.ColumnSelections<PuzzleAttemptTable> conflictColumns,
    _is.ColumnSelections<PuzzleAttemptTable>? updateColumns,
    _is.WhereExpressionBuilder<PuzzleAttemptTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<PuzzleAttempt>(
      row,
      conflictColumns: conflictColumns(PuzzleAttempt.t),
      updateColumns: updateColumns?.call(PuzzleAttempt.t),
      updateWhere: updateWhere?.call(PuzzleAttempt.t),
      transaction: transaction,
    );
  }

  /// Updates all [PuzzleAttempt]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PuzzleAttempt>> update(
    _is.DatabaseSession session,
    List<PuzzleAttempt> rows, {
    _is.ColumnSelections<PuzzleAttemptTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<PuzzleAttempt>(
      rows,
      columns: columns?.call(PuzzleAttempt.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [PuzzleAttempt]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<PuzzleAttempt> updateRow(
    _is.DatabaseSession session,
    PuzzleAttempt row, {
    _is.ColumnSelections<PuzzleAttemptTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<PuzzleAttempt>(
      row,
      columns: columns?.call(PuzzleAttempt.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PuzzleAttempt] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<PuzzleAttempt?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<PuzzleAttemptUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<PuzzleAttempt>(
      id,
      columnValues: columnValues(PuzzleAttempt.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [PuzzleAttempt]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PuzzleAttempt>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<PuzzleAttemptUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<PuzzleAttemptTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PuzzleAttemptTable>? orderBy,
    _is.OrderByListBuilder<PuzzleAttemptTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<PuzzleAttempt>(
      columnValues: columnValues(PuzzleAttempt.t.updateTable),
      where: where(PuzzleAttempt.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PuzzleAttempt.t),
      orderByList: orderByList?.call(PuzzleAttempt.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [PuzzleAttempt]s in the list and returns the deleted rows.
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
  Future<List<PuzzleAttempt>> delete(
    _is.DatabaseSession session,
    List<PuzzleAttempt> rows, {
    _is.OrderByBuilder<PuzzleAttemptTable>? orderBy,
    _is.OrderByListBuilder<PuzzleAttemptTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<PuzzleAttempt>(
      rows,
      orderBy: orderBy?.call(PuzzleAttempt.t),
      orderByList: orderByList?.call(PuzzleAttempt.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [PuzzleAttempt].
  Future<PuzzleAttempt> deleteRow(
    _is.DatabaseSession session,
    PuzzleAttempt row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<PuzzleAttempt>(
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
  Future<List<PuzzleAttempt>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PuzzleAttemptTable> where,
    _is.OrderByBuilder<PuzzleAttemptTable>? orderBy,
    _is.OrderByListBuilder<PuzzleAttemptTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<PuzzleAttempt>(
      where: where(PuzzleAttempt.t),
      orderBy: orderBy?.call(PuzzleAttempt.t),
      orderByList: orderByList?.call(PuzzleAttempt.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PuzzleAttemptTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<PuzzleAttempt>(
      where: where?.call(PuzzleAttempt.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [PuzzleAttempt] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PuzzleAttemptTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<PuzzleAttempt>(
      where: where(PuzzleAttempt.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
