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
  final ExampleRecordQuery query;

  ListController({required this.query}) : super(ListState()) {
    loadRecords(query: query);
  }

  Future<_FetchRecordsResult> fetchRecords(ExampleRecordQuery? query) async {
    final loadedRecords = await MockRepository().queryRecords(query);
    return _FetchRecordsResult(records: loadedRecords, loadedAllRecords: loadedRecords.length < kBatchSize);
  }

  Future<void> loadRecords({ExampleRecordQuery? query, bool replace = true}) async {
    if (value.isLoading) return;

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
