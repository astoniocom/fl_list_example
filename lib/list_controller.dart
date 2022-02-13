import 'package:fl_list_example/list_state.dart';
import 'package:fl_list_example/models.dart';
import 'package:fl_list_example/repository.dart';
import 'package:flutter/foundation.dart';

class _FetchRecordsResult {
  final List<ExampleRecord> records;
  final bool loadedAllRecords;

  _FetchRecordsResult({required this.records, required this.loadedAllRecords});
}

class ListController extends ValueNotifier<ListState> {
  ListController({required this.query}) : super(ListState()) {
    loadRecords(query);
  }

  final ExampleRecordQuery query;

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
