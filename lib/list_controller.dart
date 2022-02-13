import 'dart:async';
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
  final Iterable<ExtendedExampleRecord> recordsToRemove;

  _ListChange({this.recordsToInsert = const {}, this.recordsToRemove = const {}});
}

class _FetchRecordsResult {
  final List<ExtendedExampleRecord> records;
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
          final updatedIds = event.whereType<RecordUpdatedEvent>().map((e) => e.id);
          final idsToResolve = {...createdIds, ...updatedIds};
          final resolvedRecords = (await MockRepository().getByIds(idsToResolve)).toSet();

          return RecordsUpdates(
            insertedRecords: resolvedRecords.where((r) => createdIds.contains(r.id)).toSet(),
            updatedRecords: resolvedRecords.where((r) => updatedIds.contains(r.id)).toSet(),
            deletedKeys: event.whereType<RecordDeletedEvent>().map((e) => e.id).toSet(),
          );
        })
        .map(_filterRecords)
        .where((event) => event.recordsToInsert.isNotEmpty || event.recordsToRemove.isNotEmpty)
        .asyncMap((change) async {
          return lock.synchronized(() async {
            final result = List.of(value.records)..removeWhere((r) => change.recordsToRemove.contains(r));
            return result..insertAll(0, await MockRepository().extendRecords(change.recordsToInsert));
          });
        })
        .map((updatedList) {
          return updatedList..sort((r1, r2) => query.compareRecords(r1.base, r2.base));
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

  @override
  void dispose() {
    _changesSubscription.cancel();
    super.dispose();
  }

  Future<_FetchRecordsResult> fetchRecords(ExampleRecordQuery? query) async {
    final loadedRecords = await MockRepository().queryRecords(query);
    return _FetchRecordsResult(records: await MockRepository().extendRecords(loadedRecords), loadedAllRecords: loadedRecords.length < kBatchSize);
  }

  Future<void> loadRecords({ExampleRecordQuery? query, bool replace = true}) async {
    if (value.isLoading) return;
    lock.synchronized(() async {
      value = value.copyWith(loadingFor: replace ? LoadingFor.replace : LoadingFor.add, error: "");

      try {
        final fetchResult = await fetchRecords(query);

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
