import 'dart:async';
import 'package:fl_list_example/record_cubit.dart';
import 'package:rxdart/rxdart.dart';
import 'package:collection/collection.dart';
import 'package:fl_list_example/list_state.dart';
import 'package:fl_list_example/models.dart';
import 'package:fl_list_example/repository.dart';
import 'package:flutter/foundation.dart';
import 'package:synchronized/synchronized.dart';

class RecordsUpdates {
  final Set<ID> deletedKeys;
  final Set<ExampleRecord> insertedRecords;
  final Set<ExampleRecord> updatedRecords;

  RecordsUpdates({this.deletedKeys = const {}, this.insertedRecords = const {}, this.updatedRecords = const {}});
}

class _ListChange {
  final Iterable<ExampleRecord> recordsToInsert;
  final Iterable<ExampleRecordCubit> recordsToRemove;

  _ListChange({this.recordsToInsert = const {}, this.recordsToRemove = const {}});
}

class _FetchRecordsResult {
  final List<ExampleRecordCubit> records;
  final bool loadedAllRecords;

  _FetchRecordsResult({required this.records, required this.loadedAllRecords});
}

class ListController extends ValueNotifier<ListState> {
  final ExampleRecordQuery query;
  late StreamSubscription _changesSubscription;
  final lock = Lock();

  ListController({required this.query}) : super(ListState()) {
    loadRecords(query: query);

    _changesSubscription = MockRepository()
        .rawEvents
        .where((event) => value.isInitialized)
        .bufferTime(const Duration(milliseconds: 300))
        .where((event) => event.isNotEmpty)
        .asyncMap((event) async {
          final createdIds = event.whereType<RecordCreatedEvent>().map((e) => e.id);
          final resolvedRecords = (await MockRepository().getByIds(createdIds)).toSet();

          return RecordsUpdates(
            insertedRecords: resolvedRecords.where((r) => createdIds.contains(r.id)).toSet(),
            updatedRecords: {},
            deletedKeys: event.whereType<RecordDeletedEvent>().map((e) => e.id).toSet(),
          );
        })
        .map(_filterRecords)
        .where((event) => event.recordsToInsert.isNotEmpty || event.recordsToRemove.isNotEmpty)
        .map((change) {
          change.recordsToRemove.every((r) => r.close());
          final result = List.of(value.records)..removeWhere((r) => change.recordsToRemove.contains(r));
          return result..insertAll(0, change.recordsToInsert.map((r) => ExampleRecordCubit(r)));
        })
        .map((updatedList) {
          return updatedList..sort((r1, r2) => query.compareRecords(r1.value, r2.value));
        })
        .listen((updatedList) {
          value = value.copyWith(records: updatedList);
        });
  }

  bool _recordSuits(ExampleRecord record) {
    if (value.hasLoadedAllRecords) return query.suits(record);
    return query.copyWith(weightLte: value.records.last.weight).suits(record);
  }

  _ListChange _filterRecords(RecordsUpdates change) {
    final recordsToRemove = value.records.where((r) => change.deletedKeys.contains(r.id)).toSet();

    final Set<ExampleRecord> rawRecordsToInsert = change.insertedRecords.where((r) => _recordSuits(r)).toSet();

    for (final r in change.updatedRecords) {
      final recordInList = value.records.firstWhereOrNull((recFromList) => recFromList.id == r.id);

      if (recordInList != null && !_recordSuits(r)) {
        recordsToRemove.add(recordInList);
      } else if (recordInList == null && _recordSuits(r)) {
        final ExampleRecord? inR = rawRecordsToInsert.firstWhereOrNull((recFromList) => recFromList.id == r.id);
        if (inR != null) rawRecordsToInsert.remove(inR);

        rawRecordsToInsert.add(r);
      } else if (recordInList != null && _recordSuits(r)) {
        // Can we remove repetition of the line
        final ExampleRecord? inR = rawRecordsToInsert.firstWhereOrNull((recFromList) => recFromList.id == r.id);
        if (inR != null) rawRecordsToInsert.remove(inR);

        recordsToRemove.add(recordInList);
        rawRecordsToInsert.add(r);
      }
    }
    return _ListChange(
      recordsToInsert: rawRecordsToInsert,
      recordsToRemove: recordsToRemove,
    );
  }

  _closeAllRecords() {
    for (final r in value.records) {
      r.close();
    }
  }

  @override
  void dispose() {
    _closeAllRecords();
    _changesSubscription.cancel();
    super.dispose();
  }

  Future<_FetchRecordsResult> fetchRecords(ExampleRecordQuery? query) async {
    final loadedRecords = await MockRepository().queryRecords(query);
    return _FetchRecordsResult(
        records: loadedRecords.map((r) => ExampleRecordCubit(r)).toList(), loadedAllRecords: loadedRecords.length < kBatchSize);
  }

  Future<void> loadRecords({ExampleRecordQuery? query, bool replace = true}) async {
    if (value.isLoading) return;
    lock.synchronized(() async {
      value = value.copyWith(loadingFor: replace ? LoadingFor.replace : LoadingFor.add, error: "");

      try {
        final fetchResult = await fetchRecords(query);

        if (replace) _closeAllRecords();

        final records = [
          if (!replace) ...value.records,
          ...fetchResult.records,
        ];

        value = value.copyWith(loadingFor: LoadingFor.idle, records: records, hasLoadedAllRecords: fetchResult.loadedAllRecords);
      } catch (e) {
        value = value.copyWith(loadingFor: LoadingFor.idle, error: e.toString());
        rethrow;
      }
    });
  }

  directionalLoad() async {
    final query = getNextRecordsQuery();
    await loadRecords(query: query, replace: false);
  }

  ExampleRecordQuery getNextRecordsQuery() {
    if (value.records.isEmpty) throw Exception("Impossible to create query");
    return query.copyWith(weightGt: value.records.last.weight);
  }

  repeatQuery() {
    return value.records.isEmpty ? loadRecords(query: query) : directionalLoad();
  }
}
