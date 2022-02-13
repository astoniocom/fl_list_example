import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:collection/collection.dart';
import 'package:fl_list_example/list_state.dart';
import 'package:fl_list_example/models.dart';
import 'package:fl_list_example/repository.dart';
import 'package:flutter/foundation.dart';

class RecordsUpdates {
  final Set<ID> deletedKeys;
  final Set<ExampleRecord> insertedRecords;
  final Set<ExampleRecord> updatedRecords;

  RecordsUpdates({this.deletedKeys = const {}, this.insertedRecords = const {}, this.updatedRecords = const {}});
}

class _ListChange {
  final Iterable<ExampleRecord> recordsToInsert;
  final Iterable<ID> recordsToRemove;

  _ListChange({this.recordsToInsert = const {}, this.recordsToRemove = const {}});
}

class _FetchRecordsResult {
  final List<ExampleRecord> records;
  final bool loadedAllRecords;

  _FetchRecordsResult({required this.records, required this.loadedAllRecords});
}

class ListController extends ValueNotifier<ListState> {
  ListController({required this.query}) : super(ListState()) {
    loadRecords(query);

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
        .map((change) {
          return value.records.where((r) => !change.recordsToRemove.contains(r.id)).toList()
            ..insertAll(0, change.recordsToInsert)
            ..sort(query.compareRecords);
        })
        .listen((updatedList) {
          value = value.copyWith(records: updatedList);
        });
  }
  
  final ExampleRecordQuery query;
  late StreamSubscription _changesSubscription;

  bool _recordFits(ExampleRecord record) {
    if (value.stage == ListStage.complete) return query.fits(record);
    return query.copyWith(weightLte: value.records.last.weight).fits(record);
  }

  _ListChange _filterRecords(RecordsUpdates change) {
    final Set<ID> recordsToRemove = Set.of(change.deletedKeys.where(change.deletedKeys.contains));
    final Set<ExampleRecord> rawRecordsToInsert = {};

    for (final r in change.insertedRecords.where(_recordFits)) {
      final ID decisionRecordKey = r.id;

      if (change.deletedKeys.contains(decisionRecordKey)) continue;

      final hasListRecord = value.records.firstWhereOrNull((recFromList) => recFromList.id == r.id) != null;
      if (hasListRecord) {
        recordsToRemove.add(decisionRecordKey);
      }
      rawRecordsToInsert.add(r);
    }

    for (final r in change.updatedRecords) {
      final ID decisionRecordKey = r.id;

      if (change.deletedKeys.contains(decisionRecordKey)) continue;

      if (_recordFits(r)) {
        final desigionRecord = rawRecordsToInsert.firstWhereOrNull((record) => record.id == decisionRecordKey);

        if (desigionRecord != null) rawRecordsToInsert.remove(desigionRecord);

        rawRecordsToInsert.add(r);
      }

      final hasListRecord = value.records.firstWhereOrNull((recFromList) => recFromList.id == r.id) != null;
      if (hasListRecord) {
        recordsToRemove.add(decisionRecordKey);
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

  Future<_FetchRecordsResult> _fetchRecords(ExampleRecordQuery? query) async {
    final loadedRecords = await MockRepository().queryRecords(query);
    return _FetchRecordsResult(
      records: loadedRecords,
      loadedAllRecords: loadedRecords.length < kBatchSize,
    );
  }

  Future<void> loadRecords(ExampleRecordQuery? query) async {
    if (value.isLoading) return;

    value = value.copyWith(stage: ListStage.loading);

    try {
      final fetchResult = await _fetchRecords(query);

      value = value.copyWith(
        stage: fetchResult.loadedAllRecords ? ListStage.complete : ListStage.idle,
        records: [...value.records, ...fetchResult.records],
      );
    } catch (e) {
      value = value.copyWith(stage: ListStage.error);
      rethrow;
    }
  }

  directionalLoad() async {
    final query = getNextRecordsQuery();
    await loadRecords(query);
  }

  ExampleRecordQuery getNextRecordsQuery() {
    if (value.records.isEmpty) throw Exception("Impossible to create query");
    return query.copyWith(weightGt: value.records.last.weight);
  }

  repeatQuery() {
    return value.records.isEmpty ? loadRecords(query) : directionalLoad();
  }
}
